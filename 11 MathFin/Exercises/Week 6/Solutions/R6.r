####### Problem 6.5: Simulation of stochastic integrals #######

#################################################################
#### HELPER FUNCTIONS ####
#################################################################

# Simulates N paths of a Brownian motion up to time T (ttm).
# The return value is a matrix whose rows are sample paths.
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

  # apply(..., 1, cumsum) returns the transpose of the desired layout.
  paths_without_zero <- t(apply(increments, 1, cumsum))
  cbind(0, paths_without_zero)
}

# Calculates the path of a left-endpoint approximation to
# the stochastic integral of a deterministic integrand with respect
# to a given Brownian path.
calculate_integral_path <- function(integrand, bm_path) {
  if (length(integrand) != length(bm_path)) {
    stop("integrand and bm_path must have the same length.")
  }

  increments <- diff(bm_path)
  integrand_points <- integrand[-length(integrand)]
  c(0, cumsum(integrand_points * increments))
}

# Calculates all endpoint values efficiently when the Brownian paths
# are stored rowwise in a matrix.
calculate_integral_endpoints <- function(integrand, bm_paths) {
  if (length(integrand) != ncol(bm_paths)) {
    stop("integrand length must equal the number of grid points.")
  }

  increments <- bm_paths[, -1, drop = FALSE] -
    bm_paths[, -ncol(bm_paths), drop = FALSE]
  as.numeric(increments %*% integrand[-length(integrand)])
}

#################################################################
#### SETUP ####
#################################################################

ttm <- 1
dt <- 0.01
time_grid <- seq(0, ttm, by = dt)
N <- 10000

set.seed(2024)

# Deterministic integrands used below.
h_sin <- sin(time_grid)
h_cos <- cos(time_grid)
h_exp <- exp(time_grid)

#################################################################
#### Question (a): Paths of W^(2) and W^(3) ####
#################################################################

# Simulate five pairs of independent Brownian paths.
bm1_paths <- sim_bm(5, ttm, dt)
bm2_paths <- sim_bm(5, ttm, dt)

w2_paths <- apply(
  bm1_paths, 1, calculate_integral_path, integrand = h_sin
) + apply(
  bm2_paths, 1, calculate_integral_path, integrand = h_cos
)

w3_paths <- apply(
  bm1_paths, 1, calculate_integral_path, integrand = h_cos
) + apply(
  bm2_paths, 1, calculate_integral_path, integrand = h_sin
)

par(mfrow = c(1, 2))
matplot(
  time_grid, w2_paths,
  type = "l", lty = 1,
  main = "Five paths of W^(2)",
  xlab = "Time (t)", ylab = "Value"
)
matplot(
  time_grid, w3_paths,
  type = "l", lty = 1,
  main = "Five paths of W^(3)",
  xlab = "Time (t)", ylab = "Value"
)

#################################################################
#### Question (b): Distributions of W_1^(2) and W_1^(3) ####
#################################################################

bm1_large <- sim_bm(N, ttm, dt)
bm2_large <- sim_bm(N, ttm, dt)

w2_endpoints <-
  calculate_integral_endpoints(h_sin, bm1_large) +
  calculate_integral_endpoints(h_cos, bm2_large)

w3_endpoints <-
  calculate_integral_endpoints(h_cos, bm1_large) +
  calculate_integral_endpoints(h_sin, bm2_large)

par(mfrow = c(1, 2))
hist(
  w2_endpoints,
  breaks = 50, probability = TRUE,
  main = "Distribution of W_1^(2)",
  xlab = "Value"
)
curve(dnorm(x), add = TRUE, col = "red", lwd = 2)
legend(
  "topright",
  legend = "Standard normal density",
  col = "red", lty = 1, lwd = 2
)

hist(
  w3_endpoints,
  breaks = 50, probability = TRUE,
  main = "Distribution of W_1^(3)",
  xlab = "Value"
)
curve(dnorm(x), add = TRUE, col = "red", lwd = 2)
legend(
  "topright",
  legend = "Standard normal density",
  col = "red", lty = 1, lwd = 2
)

cat("\n--- Question (b): Endpoint summaries ---\n")
cat("W_1^(2): sample mean =", mean(w2_endpoints),
    ", sample variance =", var(w2_endpoints), "\n")
cat("W_1^(3): sample mean =", mean(w3_endpoints),
    ", sample variance =", var(w3_endpoints), "\n")
cat("The theoretical mean is 0 and the theoretical variance is 1.\n")

#################################################################
#### Question (c): Paths of M_t = integral_0^t e^s dB_s ####
#################################################################

par(mfrow = c(1, 1))
bm_c_paths <- sim_bm(5, ttm, dt)
m_paths <- apply(
  bm_c_paths, 1, calculate_integral_path, integrand = h_exp
)

matplot(
  time_grid, m_paths,
  type = "l", lty = 1,
  main = "Five paths of the stochastic integral M(t)",
  xlab = "Time (t)", ylab = "Value"
)

#################################################################
#### Question (d): Mean and variance of M_1 ####
#################################################################

bm_d_large <- sim_bm(N, ttm, dt)
m_endpoints <- calculate_integral_endpoints(h_exp, bm_d_large)

# Var(M_1) = integral_0^1 e^(2s) ds = (e^2 - 1) / 2.
theoretical_mean_m1 <- 0
theoretical_var_m1 <- 0.5 * (exp(2 * ttm) - 1)

cat("\n--- Question (d): Mean and variance of M_1 ---\n")
cat("Theoretical mean:", theoretical_mean_m1, "\n")
cat("Sample mean:", mean(m_endpoints), "\n")
cat("Theoretical variance:", theoretical_var_m1, "\n")
cat("Sample variance:", var(m_endpoints), "\n")

#################################################################
#### Questions (e) and (f): Numerical check of Itô's formula ####
#################################################################

# Itô's formula/integration by parts gives
# integral_0^1 e^s dB_s = e B_1 - integral_0^1 e^s B_s ds.
# The ordinary integral is approximated by a left Riemann sum.
integrand_ordinary <- sweep(bm_d_large, 2, h_exp, `*`)
integral_ordinary <- rowSums(
  integrand_ordinary[, -ncol(integrand_ordinary), drop = FALSE]
) * dt

ito_formula_rhs <-
  exp(ttm) * bm_d_large[, ncol(bm_d_large)] - integral_ordinary

cat("\n--- Question (e): Moments from Itô's formula ---\n")
cat("Mean of the right-hand side:", mean(ito_formula_rhs), "\n")
cat("Variance of the right-hand side:", var(ito_formula_rhs), "\n")
cat("Mean of the direct stochastic-integral approximation:",
    mean(m_endpoints), "\n")
cat("Variance of the direct stochastic-integral approximation:",
    var(m_endpoints), "\n")

pathwise_errors <- abs(m_endpoints - ito_formula_rhs)
error_ito <- mean(pathwise_errors)

cat("\n--- Question (f): Discretisation error ---\n")
cat("Mean absolute discretisation error:", error_ito, "\n")
cat("Maximum absolute discretisation error:", max(pathwise_errors), "\n")
cat(
  "The error is caused by discretisation and should decrease when dt is reduced.\n"
)

#################################################################
#### Question (g): Cross-variation of W^(2) and W^(3) ####
#################################################################

# Use the first pair of Brownian paths from Question (a).
w2_path_one <-
  calculate_integral_path(h_sin, bm1_paths[1, ]) +
  calculate_integral_path(h_cos, bm2_paths[1, ])

w3_path_one <-
  calculate_integral_path(h_cos, bm1_paths[1, ]) +
  calculate_integral_path(h_sin, bm2_paths[1, ])

# Discrete cross-variation along the simulation grid.
cross_variation <- sum(diff(w2_path_one) * diff(w3_path_one))

# Theoretical value: integral_0^1 sin(2s) ds = (1 - cos(2)) / 2.
theoretical_cross_var <- 0.5 * (1 - cos(2 * ttm))

cat("\n--- Question (g): Cross-variation ---\n")
cat("Theoretical <W^(2), W^(3)>_1:", theoretical_cross_var, "\n")
cat("Estimate from one discretised path:", cross_variation, "\n")
cat("Absolute error:", abs(cross_variation - theoretical_cross_var), "\n")
cat(
  "The estimate is based on one discretised path and may show noticeable ",
  "sampling and discretisation error.\n",
  sep = ""
)

#################################################################
#### Question (h): Distribution of M_1 ####
#################################################################

par(mfrow = c(1, 1))
hist(
  m_endpoints,
  breaks = 50, probability = TRUE,
  main = "Distribution of M(1)",
  xlab = "Value"
)
curve(
  dnorm(x, mean = theoretical_mean_m1, sd = sqrt(theoretical_var_m1)),
  add = TRUE, col = "blue", lwd = 2
)
legend(
  "topright",
  legend = "Theoretical normal density",
  col = "blue", lty = 1, lwd = 2
)
