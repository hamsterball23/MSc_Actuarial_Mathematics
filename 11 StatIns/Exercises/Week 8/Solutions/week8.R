# Solutions for week 8 in StatIns

# Practical exercise 1

library(tidyverse)

## a.

n <- 500
set.seed(2026)
X_sim <- rnorm(n)
Y_sim <- (X_sim <= 1)*exp(X_sim) + (X_sim > 1)*log(abs(X_sim)) + rnorm(n, sd = 0.6) #note that we compute log(abs()) rather than log() for numerical stability.
df_to_plot <- data.frame("X" = X_sim, "Y" = Y_sim)

ggplot(df_to_plot) +
  geom_point(aes(x = X, y = Y)) + theme_bw()

spline_fit <- lm(Y_sim ~ splines::ns(X_sim,df=10))

grid_chosen <- seq(-2.5,2.5,length.out = n)

ggplot(df_to_plot %>% 
         mutate("Fit" = predict(spline_fit,newdata = data.frame(x=X_sim)))) +
  geom_point(aes(x = X_sim, y = Y_sim)) +
  geom_line(aes(x = X_sim, y = Fit), color = "blue") +
  ggtitle("Spline fit w. 10 degrees of freedom") + theme_bw()

## b.

B <- 1000
samples <- matrix(NA,B,length(X_sim))                     # Matrix to hold bootstrap predictions, which we will use in c.

df_B <- data.frame("X_vals" = NA, "pred" = NA, "B" = NA)  # Data frame to save bootstrap predictions
for(b in 1:B){
  inx <- sample(1:n , replace=T) #We sample indicies WITH replacement to draw from the simulated data
  X_boot <- X_sim[inx]           #Bootstrap sample   
  Y_boot <- Y_sim[inx]           #Bootstrap sample
  spline_fit_b <- lm(Y_boot ~ splines::ns(X_boot, df=10)) #Fit spline model on bootstrap sample 
  boot_pred <- predict(spline_fit_b, newdata = data.frame(X_boot=grid_chosen)) #Predict with spline bootstrap model
  samples[b,] <- boot_pred       # Save for c.
  current_b <- b       
  print(current_b)
  pred_df <- data.frame("X_vals" = grid_chosen, "pred" = as.vector(boot_pred), "B" = rep(as.factor(current_b), length(grid_chosen))) #Construct temporary data frame
  df_B <- rbind(df_B, pred_df) #Save bootstrap prediction.
}

ggplot(df_B %>% drop_na(), aes(x = X_vals, y = pred, group = B)) +
  geom_line(stat="identity", alpha = 0.1, color = "black")  + 
  theme(legend.position="none") + theme_bw() +
  geom_point(data = df_to_plot, aes(x = X_sim, y = Y_sim), color = "red")+ xlim(-2.5, 2.5) #+ ylim(-1.5, 5) 


bagging_estimate <- 
  df_B %>% drop_na() %>%
  select(-B) %>%
  group_by(X_vals) %>%
  summarise("bagging_value" = mean(pred)) 

head(df_B)
head(bagging_estimate)

## c.

library(matrixStats)

upper <- colQuantiles(samples,probs = c(0.975)) #Empirical .975 quantile of bootstrap predicitons
lower <- colQuantiles(samples,probs = c(0.025)) #Empirical .025 quantile of bootstrap predicitons

conf_interval <- predict(spline_fit, newdata = data.frame(X_sim = grid_chosen), 
                         interval="confidence",
                         level = 0.95) #Return lower .025 and upper .975 confidence interval

df_B_W_CI <- df_B %>% 
  drop_na() %>%
  cbind("upper" = rep(upper, B), "lower" =  rep(lower, B)) %>%
  cbind("upper_model" = rep(conf_interval[,3], B), "lower_model" = rep(conf_interval[,2], B))

ggplot(df_B_W_CI , aes(x = X_vals, y = pred,  group = B)) +
  geom_line(stat="identity", alpha = 0.2,  color = "black")  + 
  theme(legend.position="none") + theme_bw() + 
  geom_line(aes(x = X_vals, y = upper), color = "red", linewidth=1) + 
  geom_line(aes(x = X_vals, y = lower), color = "red", linewidth=1) + 
  geom_line(aes(x = X_vals, y = upper_model), color = "green", linewidth=1) + 
  geom_line(aes(x = X_vals, y = lower_model), color = "green", linewidth=1) +
  ggtitle("Confidence bands for single spline model (green) vs empirical bootstrap (red)") +
  geom_line(data = bagging_estimate, aes(x = X_vals, y = bagging_value), color = "blue", linewidth=1)

# Practical exercise 2

set.seed(2026)

B <- 100

## b.

# simulate observations
simulate_data <- function(n) {
  x <- runif(n, -pi, pi)
  y <- 2 + 3 * x + 2 * sin(x) + rt(n, df = 10)
  data.frame(x = x, y = y)
}

train <- simulate_data(500)
test  <- simulate_data(200)

## i.

# original linear regression
fit <- lm(y ~ x, data = train)
pred_original <- predict(fit, newdata = test)

# store predictions from all bootstrap models
pred_parametric <- matrix(NA, nrow = 200, ncol = B)
pred_nonparametric <- matrix(NA, nrow = 200, ncol = B)

for (b in 1:B) {
  # parametric bootstrap
  boot_parametric <- train
  boot_parametric$y <- fitted(fit) + rt(500, df = 10)
  
  fit_parametric <- lm(y ~ x, data = boot_parametric)
  pred_parametric[, b] <- predict(fit_parametric, newdata = test)
  
  # nonparametric bootstrap
  indices <- sample(1:500, size = 500, replace = TRUE)
  boot_nonparametric <- train[indices, ]
  
  fit_nonparametric <- lm(y ~ x, data = boot_nonparametric)
  pred_nonparametric[, b] <- predict(fit_nonparametric, newdata = test)
}

# bagged predictions
pred_bag_parametric <- rowMeans(pred_parametric)
pred_bag_nonparametric <- rowMeans(pred_nonparametric)

# test MSEs
mse <- c(
  Original = mean((test$y - pred_original)^2),
  Parametric = mean((test$y - pred_bag_parametric)^2),
  Nonparametric = mean((test$y - pred_bag_nonparametric)^2)
)
mse

### ii.

library(rpart)

fit_tree <- rpart(y ~ x, data = train)
pred_tree <- predict(fit_tree, newdata = data.frame(x = test$x))

pred_tree_bag <- matrix(0, 200, B)

# perform nonparametric bootstrap
for (b in 1:B) {
  idx <- sample(1:500, replace = TRUE)
  df_boot <- data.frame(X = train$x[idx], Y = train$y[idx])
  fit_star <- rpart(Y ~ X, data = df_boot)
  pred_tree_bag[, b] <- predict(fit_star, newdata = data.frame(X = test$x))
}

pred_tree_bag_mean <- rowMeans(pred_tree_bag)

mse_tree      <- mean((pred_tree - test$y)^2)
mse_tree_bag  <- mean((pred_tree_bag_mean - test$y)^2)

mse_tree      # 3.384202
mse_tree_bag  # 2.207303

### iii.

# Linear model bootstrap variance
var_lm_boot  <- apply(pred_nonparametric, 1, var)

# Tree model bootstrap variance
var_tree_boot <- apply(pred_tree_bag, 1, var)

par(mfrow=c(1,2))
plot(test$x, var_lm_boot, main="Bootstrap variance: Linear model")
plot(test$x, var_tree_boot, main="Bootstrap variance: Decision tree")

# the variance is certainly larger for the decision tree, and the MSE is also
# larger, definitely due to the much higher variance
