###################################
########## Practical 6.4 ##########
###################################
library(tidyverse)
library(splines)


sim_data <- function(n, seed, var = c("Y", "Z"))
{
  set.seed(seed)
  X <- runif(n, min = -2.5, max = 2.5)
  epsilon <- rnorm(n, 0, 0.2)

  if (var == "Y") {
    Y <- sin(2*X) + epsilon

    return (
      data.frame(
        X = X,
        epsilon = epsilon,
        Y = Y
      )
    )
  }

  if (var == "Z") {
    Z <- sin(2*X) + 2.2 * (X < 0) * cos(2*X) + epsilon

    return (
      data.frame(
        X = X,
        epsilon = epsilon,
        Z = Z
      )
    )
  }

}

#########
### a ###
#########
simY <- sim_data(1000, 2026, "Y")
simZ <- sim_data(1000, 2026, "Z")

M <- c(1,2,3,4)
knots <- c(-1.25, 0, 1.25)

Y_bsfits <- vector("list", length(M))
Z_bsfits <- vector("list", length(M))

for (m in M){
  Y_bsfits[[m]] <- lm(Y ~ bs(X, knots = knots, degree = m), data = simY)
  Z_bsfits[[m]] <- lm(Z ~ bs(X, knots = knots, degree = m), data = simZ)
}

# Predict each fit on a grid and stack into one long data frame
# The grid is slighly bigger than used covariates to see bad
# extrapolation of the splines
grid <- data.frame(X = seq(-2.7, 2.7, length.out = 500))

pred_df <- function(fits)
{
  map_dfr(M, \(m) tibble(X = grid$X, fit = predict(fits[[m]], newdata = grid),
                         M = paste("M =", m)))
}

plot_fits <- function(sim, fits, var, truth)
{
  preds <- pred_df(fits)

  ggplot(sim, aes(X, .data[[var]])) +
    geom_point(alpha = 0.2, size = 0.6) +
    geom_function(fun = truth, aes(colour = "true")) +
    geom_line(data = preds, aes(y = fit, colour = "bs fit"), linewidth = 0.8) +
    geom_vline(xintercept = knots, linetype = "dotted", colour = "grey50") +
    facet_wrap(~ M, nrow = 2) +
    scale_colour_manual(values = c("bs fit" = "red", "true" = "black")) +
    labs(title = paste("Spline fits for", var), colour = NULL)
}

plot_fits(simY, Y_bsfits, "Y", \(x) sin(2*x))
plot_fits(simZ, Z_bsfits, "Z", \(x) sin(2*x) + 2.2 * (x < 0) * cos(2*x))

#########
### b ###
#########

bootstrap_iteration <- function(n, seed, knots = c(-1.25, 0, 1.25), Mvec = seq(1,15, 1))
{
  simY <- sim_data(n, seed, var = "Y")
  simZ <- sim_data(n, seed, var = "Z")
  nY <- nrow(simY)
  nZ <- nrow(simZ)

  #Train data split
  trainY <- simY[1:(nY/2),]
  trainZ <- simZ[1:(nZ/2),]

  #Test data split
  testY <- simY[(nY/2 + 1):nY, ]
  testZ <- simZ[(nZ/2 + 1):nZ, ]

  #Train and test error
  trainErrorY <- vector("numeric", length(Mvec))
  trainErrorZ <- vector("numeric", length(Mvec))

  testErrorY <- vector("numeric", length(Mvec))
  testErrorZ <- vector("numeric", length(Mvec))


  # Boundary knots fixed at the support of X, so test points outside the
  # training range don't trigger bs() extrapolation warnings
  for (i in seq_along(Mvec)){
    m <- Mvec[i]
    fitY <- lm(Y ~ bs(X, knots = knots, degree = m, Boundary.knots = c(-2.5, 2.5)), data = trainY)
    fitZ <- lm(Z ~ bs(X, knots = knots, degree = m, Boundary.knots = c(-2.5, 2.5)), data = trainZ)

    trainErrorY[[i]] <- mean(fitY$residuals^2)
    trainErrorZ[[i]] <- mean(fitZ$residuals^2)

    testErrorY[[i]] <- mean((testY$Y - predict(fitY, newdata = testY))^2)
    testErrorZ[[i]] <- mean((testZ$Z - predict(fitZ, newdata = testZ))^2)
  }

  return(
    data.frame(
      M = Mvec,
      trainErrorY = trainErrorY,
      trainErrorZ = trainErrorZ,
      testErrorY = testErrorY,
      testErrorZ = testErrorZ
    )
  )
}

B <- 100
seed <- 2026
n <- 100

errors <- map_dfr(1:B, \(b) bootstrap_iteration(n, seed + b - 1), .id = "sim")

# Long format: one row per (sim, M, train/test, Y/Z)
errors_long <- errors |>
  pivot_longer(-c(sim, M), names_to = c("set", "model"),
               names_pattern = "(train|test)Error(Y|Z)", values_to = "error")

mean_errors <- errors_long |>
  group_by(M, set, model) |>
  summarise(error = mean(error), .groups = "drop")

ggplot(errors_long, aes(M, error, colour = set)) +
  geom_line(aes(group = interaction(sim, set)), alpha = 0.1) +
  geom_line(data = mean_errors, linewidth = 1.2) +
  geom_point(data = mean_errors, size = 2) +
  facet_wrap(~ model, labeller = label_both) +
  scale_x_continuous(breaks = 1:15) +
  scale_y_log10() +
  labs(title = "Training and test error by spline order", y = "MSE (log scale)", colour = NULL)

# Order M with minimal mean test error for each model
mean_errors |>
  filter(set == "test") |>
  group_by(model) |>
  slice_min(error)

# For train data this is trivially equal to M=15 because a higher modelfit
# will give better training error