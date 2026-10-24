###################################
########## Practical 6.3 ##########
###################################
library(tidyverse)
library(rpart)
library(randomForest)
library(gbm)

simulate_data <- function(n, seed = 2026)
{
  set.seed(seed)
  X <- runif(n)
  S <- runif(n)
  eta <- function(x){0.3 + 2*dnorm(x, mean = 0.2, sd = 0.05)}
  Y <- S**(-eta(X)) + 20 * (X > 3/4)
  return(
    data.frame(
      X = X,
      S = S,
      Y = Y
    )
  )
}

#########
### a ###
#########
data_sim <- simulate_data(1000, seed = 2026)

tree_d2 <- rpart(Y ~ X, data = data_sim, control = rpart.control(maxdepth = 2, cp = 0))
tree_d4 <- rpart(Y ~ X, data = data_sim, control = rpart.control(maxdepth = 4, cp = 0))
tree_d6 <- rpart(Y ~ X, data = data_sim, control = rpart.control(maxdepth = 6, cp = 0))

data_sim$pred_d2 <- predict(tree_d2, newdata = data_sim)
data_sim$pred_d4 <- predict(tree_d4, newdata = data_sim)
data_sim$pred_d6 <- predict(tree_d6, newdata = data_sim)

pivot_data_sim <- function(data, names_to, names_prefix, names_transform){
  data |>
  pivot_longer(
    cols = starts_with("pred_"),
    names_to = names_to,
    names_prefix = names_prefix, names_transform = names_transform,
    values_to = "prediction"
  )
}

pivot_data_sim(
  data_sim,
  names_to = "tree_depth", names_prefix = "pred_d", names_transform = as.factor
)|>
  ggplot(aes(x = X, y = prediction, color = tree_depth, group = tree_depth)) +
  geom_point(aes(y = Y), alpha = 0.3, color = "grey40") +
  geom_line() +
  scale_y_log10() +
  labs(
    title = "Decision tree fit to simulated data",
    color = "Tree depth"
  )

# Conclusion (a):
# eta(x) peaks at 0.3 + 2*phi(0) ~ 16.3 at x = 0.2, and S^(-eta) has tail index 1/eta,
# so E[Y | X = x] is infinite wherever eta(x) > 1. The sample reflects this: one point
# near X ~ 0.251 is ~6e28, and several others near X ~ 0.2 are ~1e16.
# With squared-error loss the trees spend their splits isolating these points. All three
# depths put a leaf of ~8e27 around the largest point.
# - d = 2 is far too coarse: ~7e14 for X < 0.25 and ~3e6 for all X > 0.25.
# - Deeper trees localise the outliers better. The level away from the bump drops to
#   ~55 (d = 4) and ~9.6 (d = 6), but neither tree splits at X = 3/4.
#   The +20 jump is invisible next to the tail in terms of squared error.
# So a deeper tree helps, but none of the trees recovers the regression structure.


#########
### b ###
#########

fit_forest <- randomForest(
  Y ~ X,
  data = data_sim,
  ntree = 400, maxnodes = 15
)

data_sim$pred_random_forest <- predict(fit_forest, newdata = data_sim)

pivot_data_sim(
  data_sim,
  names_to = "model", names_prefix = "pred_", names_transform = as.factor
) |> 
  ggplot(aes(x = X, y = prediction, color = model, group = model)) +
  geom_point(aes(y = Y), alpha = 0.3, color = "grey40") +
  geom_line() +
  scale_y_log10() +
  labs(
    title = "Random forest fit to simulated data",
    color = "Model"
  )

# Conclusion (b):
# With a single covariate mtry = 1, so this is really bagging: the random feature
# selection does nothing.
# The forest does worse than the deep tree. Each tree has at most 15 leaves and is grown
# on a bootstrap sample, so the leaf containing an outlier is often wide, and its
# boundaries vary from tree to tree. Averaging 400 such trees smears the influence of the
# extreme points across the whole X range: predictions are ~1e10-1e13 even at X = 0.95,
# where E[Y | X] ~ 21.
# Like the trees, the forest does not find the jump at X = 3/4.
# Averaging reduces variance, but it cannot fix a loss function that is dominated by an
# infinite-variance response.



#########
### c ###
#########

fit_gbm <- gbm(
  Y ~ X,
  data = data_sim[, c("X", "Y")], # keep the pred_ columns out of the formula's data
  distribution = "gaussian",      # squared error loss
  n.trees = 400,
  shrinkage = 0.1,                # nu = 0.1
  interaction.depth = 3,          # J = 4 terminal nodes = 3 splits
  bag.fraction = 1                # plain (non-stochastic) boosting, mathces the text
)

data_sim$pred_gbm_gaussian <- predict(fit_gbm, newdata = data_sim, n.trees = 400)

pivot_data_sim(
  data_sim,
  names_to = "model", names_prefix = "pred_", names_transform = as.factor
) |> 
  ggplot(aes(x = X, y = prediction, color = model, group = model)) +
  geom_point(aes(y = Y), alpha = 0.3, color = "grey40") +
  geom_line() +
  scale_y_log10() +
  labs(
    title = "Tree, forest and boosting fits",
    color = "Model"
  )

# Conclusion (c), squared loss:
# Boosting fits the residuals y - f(x) one tree at a time, so the ~6e28 point keeps
# producing the largest residual and attracts most of the 400 trees. The model almost
# interpolates it (max prediction ~5e28) and overshoots next to it: two predictions near
# X ~ 0.25 are ~ -3e27. A negative mean for a positive response; these points are dropped
# by the log axis, which is why the line has a gap.
# For X > 0.3 the prediction is flat at ~6.3e10, so the jump at 3/4 is missed again.
# Training error is still decreasing at tree 400.
# Of the three methods, boosting is the most aggressive at chasing the outliers.


fit_gbm_laplace <- gbm(
  Y ~ X,
  data = data_sim[, c("X", "Y")], # keep the pred_ columns out of the formula's data
  distribution = "laplace",      # squared error loss
  n.trees = 400,
  shrinkage = 0.1,                # nu = 0.1
  interaction.depth = 3,          # J = 4 terminal nodes = 3 splits
  bag.fraction = 1                # plain (non-stochastic) boosting, mathces the text
)

data_sim$pred_gbm_laplace <- predict(fit_gbm_laplace, newdata = data_sim, n.trees = 400)

pivot_data_sim(
  data_sim,
  names_to = "model", names_prefix = "pred_", names_transform = as.factor
) |> 
  ggplot(aes(x = X, y = prediction, color = model, group = model)) +
  geom_point(aes(y = Y), alpha = 0.3, color = "grey40") +
  geom_line() +
  scale_y_log10() +
  labs(
    title = "Tree, forest and boosting fits",
    color = "Model"
  )

# Extra: absolute (Laplace) loss
# The pseudo-residuals become sign(y - f(x)), which are bounded by 1, so no single point
# can dominate. The model estimates the conditional median, which is finite everywhere:
# med(Y | X = x) = 2^eta(x) + 20 * 1(x > 3/4).
# The fit matches this closely: peak ~1e5 near x = 0.2 (2^16.3 ~ 7.8e4), ~1.2 away from
# the bump, and a clear step to ~21 at X = 3/4.
# Overall conclusion: with an infinite-variance response, the squared-error loss is the
# problem, not the choice of tree, forest or boosting. All three fail under squared loss.
# A robust loss (or modelling log Y) recovers both the bump and the jump.
