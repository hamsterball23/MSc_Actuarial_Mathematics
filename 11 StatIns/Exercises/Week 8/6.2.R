###################################
########## Practical 6.2 ##########
###################################
library(tidyverse)
library(rpart)

#########
### b ###
#########

simulate_data <- function(n, seed = 2026)
{
  set.seed(seed)
  X <- rnorm(n)
  e <- rt(n, df = 10)

  Y <- 2 + 3*X + 2*sin(X) + e

  return(
    data.frame(
      X = X,
      e = e,
      Y = Y
    )
  )
}

# Both baggers return a B x nrow(grid) matrix: row b holds the predictions
# of the b'th bootstrap fit on the grid. The bagged prediction is colMeans().
non_parametric_bootstrap_bagger <- function(
  fitter,
  grid_fitter,
  grid,
  data,
  B,
  seed,
  replace = TRUE
)
{
  result <- matrix(NA, nrow = B, ncol = nrow(grid))

  rows_in_data <- nrow(data)

  set.seed(seed)
  for (i in 1:B){
    idx <- sample(1:rows_in_data, rows_in_data, replace = replace)
    fit_model <- fitter(data[idx,])
    result[i, ] <- grid_fitter(fit_model, grid)
  }

  return(result)
}

parametric_bootstrap_bagger <- function(
  fitter,
  original_model,
  grid_fitter,
  grid,
  data,
  B,
  seed
)
{
  result <- matrix(NA, nrow = B, ncol = nrow(grid))

  set.seed(seed)
  for (i in 1:B){
    #Make parametric data
    parametric_data <- data
    parametric_data$Y <- simulate(original_model)[[1]]

    fit_model <- fitter(parametric_data)
    result[i, ] <- grid_fitter(fit_model, grid)
  }

  return(result)
}

mse <- function(y, y_hat) {mean((y - y_hat)^2)}


train_data <- simulate_data(500, seed = 2026)
test_data <- simulate_data(200, seed = 1234)



## i) ##
lm_fitter <- function(data) {lm(Y ~ X + sin(X), data = data)}
lm_grid_fitter <- function(lm, grid) {predict(lm, newdata = grid)}

lm_original <- lm_fitter(train_data)

lm_nonpara <- non_parametric_bootstrap_bagger(
  fitter = lm_fitter,
  grid_fitter = lm_grid_fitter,
  grid = test_data,
  data = train_data,
  B = 100,
  seed = 1,
  replace = TRUE
)

lm_para <- parametric_bootstrap_bagger(
  fitter = lm_fitter,
  original_model = lm_original,
  grid_fitter = lm_grid_fitter,
  grid = test_data,
  data = train_data,
  B = 100,
  seed = 1
)

lm_mse <- tibble(
  model = c("Original", "Nonparametric bagging", "Parametric bagging"),
  test_MSE = c(
    mse(test_data$Y, predict(lm_original, newdata = test_data)),
    mse(test_data$Y, colMeans(lm_nonpara)),
    mse(test_data$Y, colMeans(lm_para))
  )
)

(lm_mse)



## ii) ##
rpart_fitter <- function(data) {rpart(Y ~ X, data = data)}
rpart_grid_fitter <- function(rpart, grid) {predict(rpart, newdata = grid)}

rpart_original <- rpart_fitter(train_data)

rpart_nonpara <- non_parametric_bootstrap_bagger(
  fitter = rpart_fitter,
  grid_fitter = rpart_grid_fitter,
  grid = test_data,
  data = train_data,
  B = 100,
  seed = 1,
  replace = TRUE
)

rpart_mse <- tibble(
  model = c("Original", "Nonparametric bagging"),
  test_MSE = c(
    mse(test_data$Y, predict(rpart_original, newdata = test_data)),
    mse(test_data$Y, colMeans(rpart_nonpara))
  )
)

(rpart_mse)
#In light of a) then this model really benefits from bagging, where the linear model really did not
#The decision tree is very non-linear and can get better using bagging



## iii) ##
# Column j of a prediction matrix is the prediction at test_data$X[j]
pivot_predictions <- function(pred, model_name, grid = test_data)
{
  colnames(pred) <- seq_len(ncol(pred))

  pred |>
    as_tibble() |>
    mutate(B = row_number()) |>
    pivot_longer(
      cols = -B,
      names_to = "obs",
      names_transform = as.integer,
      values_to = "Y_pred"
    ) |>
    mutate(
      X = grid$X[obs],
      model = model_name
    ) |>
    select(model, B, X, Y_pred)
}

plot_data <- bind_rows(
  pivot_predictions(lm_para, "Linear model"),
  pivot_predictions(rpart_nonpara, "Decision tree")
)

(plot_data)


plot_data |>
  ggplot(aes(x = X, y = Y_pred, color = B, group = B)) +
  geom_line(alpha = 0.2) +
  geom_function(
    fun = function(x) {2 + 3*x + 2*sin(x)},
    inherit.aes = FALSE, color = "red", linewidth = 0.8
  ) +
  facet_wrap(~model, nrow = 2)

# Empirical variance across bootstraps and squared bias of the bagged
# prediction, both averaged over the test points
plot_data |>
  mutate(f_true = 2 + 3*X + 2*sin(X)) |>
  group_by(model, X) |>
  summarise(
    variance = var(Y_pred),
    bias2 = (mean(Y_pred) - first(f_true))^2,
    .groups = "drop"
  ) |>
  group_by(model) |>
  summarise(
    avg_variance = mean(variance),
    avg_bias2 = mean(bias2)
  )

# Variance: the linear bootstrap curves form a very tight band. 
# The tree curves scatter widely, especially near the split points, 
# because small changes in the data move the splits. The tree's variance 
# is about 60× larger.

# Bias: the linear model is correctly specified (Y ~ X + sin(X)), 
# so its bias is near zero. The tree approximates a smooth curve with steps, 
# so it is biased.

# Who benefits most from bagging: the tree. Bagging only reduces the variance 
# part. The linear model has almost no variance to remove, and by (a) its 
# bagged estimator is just $\hat\beta$ plus noise.

# Does this match the simulation? Yes. The tree's test MSE fell from 1.96 to 
# 1.50, while the linear model stayed at about 1.32. Bagging leaves the tree's 
# bias in place, so the bagged tree is still worse than the linear model and 
# above the noise floor $\text{Var}(t_{10}) = 1.25$.