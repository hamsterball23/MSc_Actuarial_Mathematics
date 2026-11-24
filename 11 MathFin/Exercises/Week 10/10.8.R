#########################
######### 10.8 ##########
#########################
library(ggplot2)
library(tidyr)
library(dplyr)

EulerMaruyama <- function(
  mu,
  sigma,
  a, b, deltaT, N,
  initial_value, 
  seed
){
  set.seed(seed)
  sqrtDeltaT <- sqrt(deltaT)
  #Check mu and sigma is functions of two parameters??
  #--

  #check if delta t is multiple of 
  nGrid <- (b - a) / deltaT

  if (abs(nGrid - round(nGrid)) > 1e-8)
  {
    stop("deltaT should divide b - a evenly")
  }

  nGrid <- round(nGrid)

  res <- matrix(NA_real_, nrow = N, ncol = nGrid + 1)
  WtGrid <- matrix(NA_real_, nrow = N, ncol = nGrid + 1)
  time_grid <- seq(a, b, by = deltaT)

  res[, 1] <- rep(initial_value, length = N)
  WtGrid[, 1] <- rep(0, length = N)


  for (j in 1:(ncol(res)-1))
  {
    dW <- sqrtDeltaT * rnorm(N)
    WtGrid[,j+1] <- WtGrid[,j] + dW

    res[,j+1] <- res[,j] +
      mu(time_grid[j], res[,j]) * deltaT +
      sigma(time_grid[j], res[,j]) * dW
  }

  colnames(res) <- time_grid
  attr(res, "time_grid") <- time_grid
  attr(res, "WtGrid") <- WtGrid

  return(res)
}

plot_paths <- function(res, title = NULL, alpha = 0.5) {
  as.data.frame(res) |>
    mutate(path = factor(row_number())) |>
    pivot_longer(-path, names_to = "t", values_to = "X") |>
    mutate(t = as.numeric(t)) |>
    ggplot(aes(t, X, colour = path)) +
    geom_line(alpha = alpha) +
    labs(title = title)
}

CompareGeometricBrownianMotion <- function(res, alpha, sigma, s0){
  dims_res <- dim(res)
  WtGrid <- attr(res, "WtGrid")
  time_grid <- attr(res, "time_grid")

  #Exact Geometric Brownian solution with simulated BM
  exact_res <- s0 * exp((alpha - sigma**2/2)*rep(time_grid, each = nrow(res)) + sigma * WtGrid)
  colnames(exact_res) <- time_grid

  pathwise_maximum_error <- apply(abs(exact_res - res), 1, function(x) max(x))

  list(exact = exact_res, mean_max_error = mean(pathwise_maximum_error))
}

#########
### a ###
#########
sim_a <- EulerMaruyama(
  mu = function(t, S) {-S},
  sigma = function(t, S) {1},
  a = 0, b = 5, deltaT = 0.01, N = 5,
  initial_value = 1,
  seed = 2026
)
sim_a
plot_paths(sim_a, "Ornstein-Uhlenbeck for 5 paths using Euler-Maruyama")

#Seems to mean reverse towards 0

#########
### b ###
#########
alpha <- 0.1
sigma <- 0.3
s0 <- 1

for (dt in c(0.1, 0.01, 0.001)) {
  sim_b <- EulerMaruyama(
    mu = function(t, S) {alpha*S},
    sigma = function(t, S) {sigma*S},
    a = 0, b = 1, deltaT = dt, N = 1000,
    initial_value = s0,
    seed = 2026
  )
  cmp <- CompareGeometricBrownianMotion(sim_b, alpha, sigma, s0)
  cat("deltaT =", dt, " mean max error =", cmp$mean_max_error, "\n")

  # path 1 = Euler-Maruyama, path 2 = exact
  print(plot_paths(rbind(sim_b[1, ], cmp$exact[1, ]), paste("deltaT =", dt)) +
          scale_colour_discrete(labels = c("Euler-Maruyama", "Exact")))
}

#########
### c ###
#########
sigma <- 0.5
sim_c_first <- EulerMaruyama(
    mu = function(t, S) {(S-S**3)},
    sigma = function(t, S) {sigma},
    a = 0, b = 50, deltaT = 0.01, N = 5,
    initial_value = 0,
    seed = 2026
)

plot_paths(sim_c_first, "Double-well model, deltaT = 0.01")

sim_c_second <- EulerMaruyama(
    mu = function(t, S) {(S-S**3)},
    sigma = function(t, S) {sigma},
    a = 0, b = 50, deltaT = 0.005, N = 5,
    initial_value = 0,
    seed = 2026
)

plot_paths(sim_c_second, "Double-well model, deltaT = 0.005")

#########
### d ###
#########
# Set each row to NA from the first grid point where stop_cond is TRUE
stop_paths <- function(mat, stop_cond) {
  for (i in 1:nrow(mat)) {
    k <- which(stop_cond[i, ])[1]
    if (!is.na(k)) mat[i, k:ncol(mat)] <- NA
  }
  mat
}

sim_d <- EulerMaruyama(
  mu = function(t, S) {S**3},
  sigma = function(t, S) {S**2},
  a = 0, b = 2, deltaT = 0.001, N = 10,
  initial_value = 1,
  seed = 2026
)
W_d <- attr(sim_d, "WtGrid")

em_d    <- stop_paths(sim_d, !is.finite(sim_d) | abs(sim_d) > 1e3)
exact_d <- stop_paths(1 / (1 - W_d), W_d >= 1)
colnames(exact_d) <- colnames(em_d)

# reuse plot_paths' long-format data, one panel per path
df_d <- bind_rows(
  plot_paths(em_d)$data    |> mutate(method = "Euler-Maruyama"),
  plot_paths(exact_d)$data |> mutate(method = "Exact")
)
ggplot(df_d, aes(t, X, colour = method)) +
  geom_line(na.rm = TRUE) +
  facet_wrap(~ path, scales = "free_y") +
  labs(title = "Y_t = 1/(1 - W_t): Euler-Maruyama vs exact")

#Why Euler–Maruyama can't represent the explosion: 
# each step adds Y^3*deltaT + Y^2*dW, and that is finite whenever Y is finite. 
# So the scheme can never reach ∞ at a specific time. Instead, near the 
# explosion it overshoots, and Y^3*deltaT grows to the point where the next 
# step overflows to Inf/NaN. Where that happens depends on Δt and the 
# grid, not on when W actually hits 1. The exact solution goes to 
# infinity as t approaches the time W first hits 1, which is a true 
# singularity that a grid of finite steps can't land on.