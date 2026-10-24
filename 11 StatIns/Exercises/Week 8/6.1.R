###################################
########## Practical 6.1 ##########
###################################
library(splines)
library(ggplot2)
library(tidyverse)

sim_data <- function(n, sigma = 0.6, seed = 2026)
{
  set.seed(seed)
  X <- rnorm(n)
  epsilon <- rnorm(n, mean = 0, sd = sigma)
  Y <- ifelse(X <= 1, exp(X), log(pmax(X,1))) + epsilon

  return (
    data.frame(
      X = X,
      smaller_than_one = X <= 1,
      epsilon = epsilon,
      Y = Y
    )
  )
}


#########
### a ###
#########
data_sim <- sim_data(500)

lm_spline10 <- lm(Y ~ ns(X, df = 10), data = data_sim)
summary(lm_spline10)

data_sim$Y_pred <- lm_spline10$fitted.values

data_sim |> 
  ggplot(aes(x = X, y = Y, color = smaller_than_one)) +
  geom_point(size = 0.5) +
  geom_point(aes(x = X, y = Y_pred), size = 0.8, color = "black") +
  geom_line(aes(x = X, y = Y_pred), color = "black") +
  labs(
    title = "Simulated data vs. fitted regression",
    subtitle = "Fitted regression uses splines with 10 degrees of freedom",
    x = "X",
    y = "Y"
  )


#########
### b ###
#########

B <- 1000
n <- nrow(data_sim)
grid <- data.frame(X = seq(-2.5, 2.5, length.out = 200))
boot_pred <- matrix(NA, nrow = B, ncol = nrow(grid))
seed <- 2026

for (i in 1:B)
{
  if (i == 1) {set.seed(seed)}
  idx <- sample(1:n, size = n, replace = TRUE)
  fit_model <- lm(Y ~ ns(X, df = 10), data = data_sim[idx,])
  boot_pred[i, ] <- predict(fit_model, newdata = grid)   #Predict the the grid [-2.5 , 2.5]
}

grid$bagged <- colMeans(boot_pred)
grid$single <- predict(lm_spline10, newdata = grid)

plot_b <- data_sim |> 
  ggplot(aes(x = X, y = Y)) +
  geom_point(size = 0.5, alpha = 0.5) +
  geom_line(data = grid, aes(x = X, y = single, color = "Single spline fit")) +
  geom_line(data = grid, aes(x = X, y = bagged, color = "Bagged (B=1000)")) +
  labs(
    title = "Simulated data vs. bagging regressions",
    subtitle = "Bagging uses splines with 10 degrees of freedom",
    x = "X",
    y = "Y"
  )

plot_b

#########
### c ###
#########
grid$low <- apply(boot_pred, 2, quantile, 0.025)
grid$high <- apply(boot_pred, 2, quantile, 0.975)

ci <- predict(lm_spline10, newdata = grid, interval = "confidence")
grid$ci_low <- ci[, "lwr"]
grid$ci_high <- ci[, "upr"]

ggplot() +
  geom_point(data = data_sim, aes(x = X, y = Y), size = 0.5, alpha = 0.3) +
  geom_ribbon(data = grid, aes(x = X, ymin = low, ymax = high, fill = "Bootstrap 95% band"), alpha = 0.3) +
  geom_ribbon(data = grid, aes(x = X, ymin = ci_low, ymax = ci_high, fill = "lm 95% confidence band"), alpha = 0.3) +
  geom_line(data = grid, aes(x = X, y = single, color = "Single spline fit")) +
  geom_line(data = grid, aes(x = X, y = bagged, color = "Bagged (B=1000)")) +
  labs(
    title = "Bootstrap percentile band vs. model-based confidence band",
    x = "X", y = "Y", color = NULL, fill = NULL
  ) +
  theme(legend.position = "bottom", legend.box = "vertical")
