####### Problem 5.7: Simulation of a stochastic integral #######

#################################################################
#### HELPER FUNCTIONS
#################################################################

# Simulates N paths of a Brownian motion up to time T.
# Each row of the returned matrix is one sample path.
sim_bm <- function(N, ttm, dt) {
  K <- round(ttm / dt)

  if (abs(K * dt - ttm) > 1e-12) {
    stop("ttm must be an integer multiple of dt.")
  }

  increments <- matrix(
    rnorm(N * K, mean = 0, sd = sqrt(dt)),
    nrow = N,
    ncol = K
  )

  paths_without_zero <- t(apply(increments, 1, cumsum))
  cbind(0, paths_without_zero)
}


# Calculates the entire path of the left-endpoint approximation
# to the Itô integral int_0^t B_s dB_s.
calculate_ito_path <- function(path) {
  increments <- diff(path)
  integrand <- path[-length(path)]

  c(0, cumsum(integrand * increments))
}


# Calculates the endpoint of the left-endpoint approximation
# to the Ito integral int_0^t B_s dB_s.
calculate_ito_endpoint <- function(path) {
  sum(path[-length(path)] * diff(path))
}


# Calculates the endpoints of the Itô approximations for every
# row in a matrix of Brownian paths.
calculate_ito_endpoints <- function(paths) {
  increments <- paths[, -1, drop = FALSE] -
    paths[, -ncol(paths), drop = FALSE]

  rowSums(
    paths[, -ncol(paths), drop = FALSE] * increments
  )
}


# Simulates Itô-integral endpoints in batches.
# This avoids storing all Brownian paths simultaneously.
simulate_ito_endpoints <- function(N, ttm, dt, batch_size = 1000) {
  result <- numeric(N)
  first_index <- 1

  while (first_index <= N) {
    last_index <- min(first_index + batch_size - 1, N)
    current_N <- last_index - first_index + 1

    paths <- sim_bm(current_N, ttm, dt)

    result[first_index:last_index] <-
      calculate_ito_endpoints(paths)

    first_index <- last_index + 1
  }

  result
}


# Simulates approximation errors in batches.
#
# For every path, the error is
#
# abs(0.5 * (B_T^2 - T) - discrete Itô sum).
simulate_mean_absolute_error <- function(
    N, ttm, dt, batch_size = 1000) {

  total_error <- 0
  number_simulated <- 0

  while (number_simulated < N) {
    current_N <- min(batch_size, N - number_simulated)

    paths <- sim_bm(current_N, ttm, dt)
    ito_approximation <- calculate_ito_endpoints(paths)

    B_T <- paths[, ncol(paths)]
    exact_value <- 0.5 * (B_T^2 - ttm)

    total_error <- total_error +
      sum(abs(exact_value - ito_approximation))

    number_simulated <- number_simulated + current_N
  }

  total_error / N
}


# Density of 0.5 * (Z^2 - 1), where Z is standard normal.
#
# This is the density of int_0^1 B_s dB_s.
ito_integral_density_t1 <- function(x) {
  density <- numeric(length(x))
  support <- x > -0.5

  density[support] <-
    dchisq(2 * x[support] + 1, df = 1) * 2

  density
}


#################################################################
#### SIMULATION PARAMETERS
#################################################################

set.seed(42)

ttm <- 1
N <- 10000


#################################################################
#### QUESTION (a): SIMULATE AND PLOT ONE PATH
#################################################################

dt_a <- 0.001
time_grid_a <- seq(0, ttm, by = dt_a)

bm_path_a <- as.numeric(sim_bm(1, ttm, dt_a))
ito_path_a <- calculate_ito_path(bm_path_a)

plot(
  time_grid_a,
  bm_path_a,
  type = "l",
  col = "black",
  lwd = 1.5,
  ylim = range(c(bm_path_a, ito_path_a)),
  main = "Brownian Motion and Its Itô Integral",
  xlab = "Time (t)",
  ylab = "Value"
)

lines(
  time_grid_a,
  ito_path_a,
  col = "blue",
  lwd = 2
)

legend(
  "topleft",
  legend = c(
    "Brownian motion B(t)",
    "Ito integral"
  ),
  col = c("black", "blue"),
  lty = 1,
  lwd = c(1.5, 2)
)


#################################################################
#### QUESTION (b): ESTIMATE MEAN AND VARIANCE
#################################################################

dt_b <- 0.001

ito_integral_endpoints_b <- simulate_ito_endpoints(
  N = N,
  ttm = ttm,
  dt = dt_b,
  batch_size = 1000
)

theoretical_mean_b <- 0
theoretical_variance_b <- ttm^2 / 2

cat("\n--- Question (b): Moment estimates ---\n")
cat(
  "Theoretical mean:",
  theoretical_mean_b,
  "\n"
)
cat(
  "Sample mean:",
  mean(ito_integral_endpoints_b),
  "\n"
)
cat(
  "Theoretical variance:",
  theoretical_variance_b,
  "\n"
)
cat(
  "Sample variance:",
  var(ito_integral_endpoints_b),
  "\n"
)


#################################################################
#### QUESTION (c): CONVERGENCE ERROR
#################################################################

dt_values_c <- c(0.1, 0.01, 0.001)
error_values_c <- numeric(length(dt_values_c))

cat("\n--- Question (c): Mean absolute errors ---\n")

for (i in seq_along(dt_values_c)) {
  current_dt <- dt_values_c[i]

  error_values_c[i] <- simulate_mean_absolute_error(
    N = N,
    ttm = ttm,
    dt = current_dt,
    batch_size = 1000
  )

  cat(
    sprintf(
      "Mean absolute error for dt = %.3f: %.6f\n",
      current_dt,
      error_values_c[i]
    )
  )
}


#################################################################
#### QUESTION (d): CONVERGENCE RATE
#################################################################

dt_values_d <- 2^(-c(4, 6, 8, 10))
error_values_d <- numeric(length(dt_values_d))

cat("\n--- Question (d): Convergence rate ---\n")

for (i in seq_along(dt_values_d)) {
  current_dt <- dt_values_d[i]

  error_values_d[i] <- simulate_mean_absolute_error(
    N = N,
    ttm = ttm,
    dt = current_dt,
    batch_size = 1000
  )

  cat(
    sprintf(
      "Mean absolute error for dt = %.8f: %.6f\n",
      current_dt,
      error_values_d[i]
    )
  )
}

convergence_fit <- lm(
  log(error_values_d) ~ log(dt_values_d)
)

estimated_slope <- unname(coef(convergence_fit)[2])

plot(
  dt_values_d,
  error_values_d,
  type = "b",
  log = "xy",
  pch = 19,
  col = "blue",
  main = "Convergence Rate of the Itô Approximation",
  xlab = "Time step",
  ylab = "Mean absolute error",
  panel.first = grid()
)

# Add the fitted line on the original log-log axes.
fitted_errors <- exp(predict(convergence_fit))

lines(
  dt_values_d,
  fitted_errors,
  col = "red",
  lty = 2,
  lwd = 2
)

legend(
  "topleft",
  legend = c(
    "Estimated errors",
    sprintf("Log-log fit: slope %.3f", estimated_slope)
  ),
  col = c("blue", "red"),
  lty = c(1, 2),
  pch = c(19, NA),
  lwd = c(1, 2)
)

cat(
  "Estimated slope:",
  estimated_slope,
  "\n"
)
cat(
  "The estimated slope should be close to 0.5.\n"
)


#################################################################
#### QUESTION (e): DISTRIBUTION OF THE ITO INTEGRAL
#################################################################

hist(
  ito_integral_endpoints_b,
  breaks = 60,
  probability = TRUE,
  col = "grey85",
  border = "white",
  main = "Distribution of the Itô Integral at t = 1",
  xlab = "Value of the integral"
)

# Add the exact density of 0.5 * (Z^2 - 1).
curve(
  ito_integral_density_t1(x),
  from = -0.5,
  to = max(ito_integral_endpoints_b),
  add = TRUE,
  col = "blue",
  lwd = 2,
  n = 1000
)

# Add a normal density with the same mean and variance for comparison.
curve(
  dnorm(
    x,
    mean = theoretical_mean_b,
    sd = sqrt(theoretical_variance_b)
  ),
  add = TRUE,
  col = "red",
  lty = 2,
  lwd = 2
)

legend(
  "topright",
  legend = c(
    "Simulated distribution",
    "Exact shifted chi-squared density",
    "Normal comparison"
  ),
  col = c("grey50", "blue", "red"),
  lty = c(1, 1, 2),
  lwd = c(5, 2, 2)
)

cat("\n--- Question (e): Distribution ---\n")
cat(
  "The Itô integral has the same distribution as ",
  "0.5 * (Z^2 - 1), where Z is standard normal.\n",
  sep = ""
)
cat(
  "Its distribution is bounded below by -0.5 and skewed to the right.\n"
)
cat(
  "It is therefore not normally distributed.\n"
)


#################################################################
#### QUESTION (f): ALTERNATIVE EVALUATION POINTS
#################################################################

dt_f <- 0.001
fine_dt_f <- dt_f / 2

# A single fine-grid path is used for the path comparison.
bm_path_fine <- as.numeric(
  sim_bm(1, ttm, fine_dt_f)
)

# Coarse-grid Brownian values.
coarse_indices <- seq(
  1,
  length(bm_path_fine),
  by = 2
)

bm_path_coarse <- bm_path_fine[coarse_indices]

# Brownian values at the midpoint times of the coarse intervals.
midpoint_indices <- seq(
  2,
  length(bm_path_fine) - 1,
  by = 2
)

bm_midpoints <- bm_path_fine[midpoint_indices]

coarse_increments <- diff(bm_path_coarse)

ito_steps <- (
  bm_path_coarse[-length(bm_path_coarse)] *
    coarse_increments
)

stratonovich_steps <- (
  bm_midpoints *
    coarse_increments
)

right_endpoint_steps <- (
  bm_path_coarse[-1] *
    coarse_increments
)

ito_path_f <- c(0, cumsum(ito_steps))
stratonovich_path_f <- c(
  0,
  cumsum(stratonovich_steps)
)
right_endpoint_path_f <- c(
  0,
  cumsum(right_endpoint_steps)
)

time_grid_f <- seq(0, ttm, by = dt_f)

plot(
  time_grid_f,
  ito_path_f,
  type = "l",
  col = "blue",
  lwd = 2,
  ylim = range(
    c(
      ito_path_f,
      stratonovich_path_f,
      right_endpoint_path_f
    )
  ),
  main = "Stochastic Sums with Different Evaluation Points",
  xlab = "Time (t)",
  ylab = "Value"
)

lines(
  time_grid_f,
  stratonovich_path_f,
  col = "darkgreen",
  lwd = 2
)

lines(
  time_grid_f,
  right_endpoint_path_f,
  col = "red",
  lwd = 2
)

legend(
  "topleft",
  legend = c(
    "Ito, alpha = 0",
    "Stratonovich, alpha = 0.5",
    "Right endpoint, alpha = 1"
  ),
  col = c("blue", "darkgreen", "red"),
  lty = 1,
  lwd = 2
)


#################################################################
#### QUESTION (f): MOMENT ESTIMATES IN BATCHES
#################################################################

simulate_alpha_integrals <- function(
    N, ttm, dt, batch_size = 500) {

  ito_values <- numeric(N)
  stratonovich_values <- numeric(N)
  right_endpoint_values <- numeric(N)

  first_index <- 1

  while (first_index <= N) {
    last_index <- min(
      first_index + batch_size - 1,
      N
    )

    current_N <- last_index - first_index + 1

    fine_paths <- sim_bm(
      current_N,
      ttm,
      dt / 2
    )

    coarse_paths <- fine_paths[
      ,
      seq(1, ncol(fine_paths), by = 2),
      drop = FALSE
    ]

    midpoint_values <- fine_paths[
      ,
      seq(2, ncol(fine_paths) - 1, by = 2),
      drop = FALSE
    ]

    coarse_increments <- (
      coarse_paths[, -1, drop = FALSE] -
        coarse_paths[
          ,
          -ncol(coarse_paths),
          drop = FALSE
        ]
    )

    current_ito <- rowSums(
      coarse_paths[
        ,
        -ncol(coarse_paths),
        drop = FALSE
      ] * coarse_increments
    )

    current_stratonovich <- rowSums(
      midpoint_values * coarse_increments
    )

    current_right <- rowSums(
      coarse_paths[, -1, drop = FALSE] *
        coarse_increments
    )

    ito_values[first_index:last_index] <-
      current_ito

    stratonovich_values[first_index:last_index] <-
      current_stratonovich

    right_endpoint_values[first_index:last_index] <-
      current_right

    first_index <- last_index + 1
  }

  list(
    ito = ito_values,
    stratonovich = stratonovich_values,
    right_endpoint = right_endpoint_values
  )
}


alpha_simulations <- simulate_alpha_integrals(
  N = N,
  ttm = ttm,
  dt = dt_f,
  batch_size = 500
)

ito_values_f <- alpha_simulations$ito
stratonovich_values_f <- (
  alpha_simulations$stratonovich
)
right_endpoint_values_f <- (
  alpha_simulations$right_endpoint
)

# For general T, the limiting process is
#
# L_T^(alpha) = 0.5 * (B_T^2 - T) + alpha * T.
#
# Hence,
#
# E[L_T^(alpha)] = alpha * T
# Var(L_T^(alpha)) = T^2 / 2.

theoretical_variance_f <- ttm^2 / 2

cat("\n--- Question (f): Moment estimates ---\n")

cat(
  sprintf(
    "%-30s | %12s | %12s | %12s | %12s\n",
    "Integral type",
    "Mean",
    "Theory",
    "Variance",
    "Theory"
  )
)

cat(
  paste0(
    paste(rep("-", 92), collapse = ""),
    "\n"
  )
)

cat(
  sprintf(
    "%-30s | %12.4f | %12.4f | %12.4f | %12.4f\n",
    "Itô, alpha = 0",
    mean(ito_values_f),
    0,
    var(ito_values_f),
    theoretical_variance_f
  )
)

cat(
  sprintf(
    "%-30s | %12.4f | %12.4f | %12.4f | %12.4f\n",
    "Stratonovich, alpha = 0.5",
    mean(stratonovich_values_f),
    0.5 * ttm,
    var(stratonovich_values_f),
    theoretical_variance_f
  )
)

cat(
  sprintf(
    "%-30s | %12.4f | %12.4f | %12.4f | %12.4f\n",
    "Right endpoint, alpha = 1",
    mean(right_endpoint_values_f),
    ttm,
    var(right_endpoint_values_f),
    theoretical_variance_f
  )
)

