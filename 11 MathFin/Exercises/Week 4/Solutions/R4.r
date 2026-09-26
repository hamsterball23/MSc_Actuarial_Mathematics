####### Problem 4.4: Simulation questions #######

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

# Returns the integrated path on the grid using left Riemann sums.
riemann_sum_left_on_grid <- function(path, dt) {
  c(0, cumsum(path[-length(path)]) * dt)
}

# Returns the integral over the full grid using a left Riemann sum.
riemann_sum_left_total <- function(path, dt) {
  sum(path[-length(path)]) * dt
}

# Returns the integral over the full grid using the trapezoidal rule.
trapezoidal_rule_total <- function(path, dt) {
  sum((path[-1] + path[-length(path)]) / 2) * dt
}

# Integrates a path up to t_end using the trapezoidal rule.
integrate_path_trap <- function(path, dt, t_end) {
  end_index <- round(t_end / dt) + 1
  if (end_index > length(path)) {
    stop("t_end lies outside the simulated time interval.")
  }
  trapezoidal_rule_total(path[seq_len(end_index)], dt)
}

# Returns the integrated path on the grid using the trapezoidal rule.
trapezoidal_rule_on_grid <- function(path, dt) {
  c(0, cumsum((path[-1] + path[-length(path)]) / 2) * dt)
}

# Theoretical variances of the numerical approximations on [0, T].
# These formulas assume that T is an integer multiple of dt.
variance_left_sum <- function(T, dt) {
  T^3 / 3 - T^2 * dt / 2 + T * dt^2 / 6
}

variance_trapezoidal <- function(T, dt) {
  T^3 / 3 - T * dt^2 / 12
}

#################################################################
#### SOLUTIONS TO QUESTIONS ####
#################################################################

# Set a seed if reproducible output is desired.
set.seed(1234)

#### Question (a): Plot a single path ####

ttm_a <- 1
dt_a <- 0.01
tpts_a <- seq(0, ttm_a, by = dt_a)

bm1_a <- as.numeric(sim_bm(1, ttm_a, dt_a))
ibm1_a <- riemann_sum_left_on_grid(bm1_a, dt_a)

plot(
  tpts_a, bm1_a,
  type = "l", col = "blue",
  ylim = range(c(bm1_a, ibm1_a)),
  main = "Brownian Motion and Its Integral",
  xlab = "Time (t)", ylab = "Value", lwd = 2
)
lines(tpts_a, ibm1_a, col = "red", lwd = 2)
legend(
  "topleft",
  legend = c("Brownian motion B(t)", "Integrated Brownian motion"),
  col = c("blue", "red"), lty = 1, lwd = 2
)

#### Question (b): Simulation with left Riemann sums ####

N_b <- 100000
ttm_b <- 1
dt_b <- 0.1

bm_paths_b <- sim_bm(N_b, ttm_b, dt_b)

# A left sum can be computed rowwise without apply().
ibm_left_sims_b <- rowSums(bm_paths_b[, -ncol(bm_paths_b), drop = FALSE]) * dt_b

hist(
  ibm_left_sims_b,
  breaks = 50, probability = TRUE,
  main = "Integrated Brownian Motion: Left Sums",
  xlab = "Approximation of the integral at t = 1"
)
curve(
  dnorm(x, mean = 0, sd = sqrt(1 / 3)),
  add = TRUE, col = "darkred", lwd = 2
)
legend(
  "topright",
  legend = "Limiting N(0, 1/3) density",
  col = "darkred", lty = 1, lwd = 2
)

left_discrete_var_b <- variance_left_sum(ttm_b, dt_b)

cat("--- Question (b): Left Riemann sum results ---\n")
cat("Theoretical mean of the integral: 0\n")
cat("Sample mean:", mean(ibm_left_sims_b), "\n")
cat("Theoretical variance of the integral:", 1 / 3, "\n")
cat("Exact variance of the left-sum approximation:", left_discrete_var_b, "\n")
cat("Sample variance:", var(ibm_left_sims_b), "\n\n")

#### Question (c): Simulation with the trapezoidal rule ####

ibm_trap_sims_c <- (
  rowSums(bm_paths_b[, -c(1, ncol(bm_paths_b)), drop = FALSE]) +
    0.5 * bm_paths_b[, ncol(bm_paths_b)]
) * dt_b

hist(
  ibm_trap_sims_c,
  breaks = 50, probability = TRUE,
  main = "Integrated Brownian Motion: Trapezoidal Rule",
  xlab = "Approximation of the integral at t = 1"
)
curve(
  dnorm(x, mean = 0, sd = sqrt(1 / 3)),
  add = TRUE, col = "darkblue", lwd = 2
)
legend(
  "topright",
  legend = "Limiting N(0, 1/3) density",
  col = "darkblue", lty = 1, lwd = 2
)

trap_discrete_var_c <- variance_trapezoidal(ttm_b, dt_b)

cat("--- Question (c): Trapezoidal-rule results ---\n")
cat("Theoretical mean of the integral: 0\n")
cat("Sample mean:", mean(ibm_trap_sims_c), "\n")
cat("Theoretical variance of the integral:", 1 / 3, "\n")
cat("Exact variance of the trapezoidal approximation:", trap_discrete_var_c, "\n")
cat("Sample variance:", var(ibm_trap_sims_c), "\n\n")

#### Question (d): Comparison ####

cat("--- Question (d): Comparison of sample variances ---\n")
cat("Theoretical variance of the integral:", 1 / 3, "\n")
cat("Left-sum sample variance:", var(ibm_left_sims_b), "\n")
cat("Trapezoidal sample variance:", var(ibm_trap_sims_c), "\n")
cat("Absolute left-sum variance error:",
    abs(var(ibm_left_sims_b) - 1 / 3), "\n")
cat("Absolute trapezoidal variance error:",
    abs(var(ibm_trap_sims_c) - 1 / 3), "\n")
cat("The trapezoidal rule is expected to have the smaller discretisation error.\n\n")

#### Question (e): Convergence analysis ####

cat("--- Question (e): Convergence analysis ---\n")

deltas_e <- c(0.1, 0.05, 0.02, 0.01, 0.005)
reference_dt_e <- 0.0005
ttm_e <- 1

# Simulate one path on a grid finer than all grids investigated.
bm_path_e <- as.numeric(sim_bm(1, ttm_e, reference_dt_e))

# Use one common fine-grid trapezoidal approximation as the reference value.
I_reference_e <- trapezoidal_rule_total(bm_path_e, reference_dt_e)

results_left_e <- numeric(length(deltas_e))
results_trap_e <- numeric(length(deltas_e))

for (i in seq_along(deltas_e)) {
  current_dt <- deltas_e[i]
  step <- round(current_dt / reference_dt_e)
  grid_indices <- seq(1, length(bm_path_e), by = step)
  sub_path <- bm_path_e[grid_indices]

  results_left_e[i] <- riemann_sum_left_total(sub_path, current_dt)
  results_trap_e[i] <- trapezoidal_rule_total(sub_path, current_dt)
}

errors_left_e <- abs(results_left_e - I_reference_e)
errors_trap_e <- abs(results_trap_e - I_reference_e)

# Estimate slopes rather than imposing first- or second-order convergence.
fit_left_e <- lm(log(errors_left_e) ~ log(deltas_e))
fit_trap_e <- lm(log(errors_trap_e) ~ log(deltas_e))
slope_left_e <- unname(coef(fit_left_e)[2])
slope_trap_e <- unname(coef(fit_trap_e)[2])

plot(
  deltas_e, errors_left_e,
  type = "b", log = "xy", col = "red", pch = 16,
  main = "Absolute Error versus Time Step",
  xlab = "Time step (Delta)", ylab = "Absolute error",
  ylim = range(c(errors_left_e, errors_trap_e)),
  panel.first = grid()
)
lines(deltas_e, errors_trap_e, type = "b", col = "blue", pch = 16)

# Add fitted lines on the original log-log axes.
left_fitted <- exp(predict(fit_left_e))
trap_fitted <- exp(predict(fit_trap_e))
lines(deltas_e, left_fitted, col = "red", lty = 2)
lines(deltas_e, trap_fitted, col = "blue", lty = 2)

legend(
  "bottomright",
  legend = c(
    "Left-sum error",
    "Trapezoidal error",
    sprintf("Left fit: slope %.2f", slope_left_e),
    sprintf("Trapezoidal fit: slope %.2f", slope_trap_e)
  ),
  col = c("red", "blue", "red", "blue"),
  lty = c(1, 1, 2, 2),
  pch = c(16, 16, NA, NA)
)

cat("Common fine-grid reference value:", I_reference_e, "\n")
cat("Estimated slope for the left sum:", slope_left_e, "\n")
cat("Estimated slope for the trapezoidal rule:", slope_trap_e, "\n")
cat(
  "For integrated Brownian motion, both methods have root-mean-square ",
  "error of order Delta; the trapezoidal rule has a smaller error constant.\n",
  sep = ""
)
cat(
  "Slopes estimated from one path can vary substantially and should be ",
  "interpreted cautiously.\n\n",
  sep = ""
)

#### Question (f): Empirical covariance ####

cat("--- Question (f): Empirical covariance ---\n")

s_f <- 0.5
t_f <- 1
theoretical_cov_f <- s_f^2 * (t_f / 2 - s_f / 6)

cat("Theoretical covariance for s = 0.5 and t = 1:", theoretical_cov_f, "\n")

N_f <- 100000
dt_f <- 0.01
bm_paths_f <- sim_bm(N_f, t_f, dt_f)

idx_s_f <- round(s_f / dt_f) + 1
weights_s_f <- rep(1, idx_s_f)
weights_s_f[c(1, idx_s_f)] <- 0.5
integrals_s_f <- as.numeric(
  bm_paths_f[, seq_len(idx_s_f), drop = FALSE] %*% weights_s_f
) * dt_f

weights_t_f <- rep(1, ncol(bm_paths_f))
weights_t_f[c(1, length(weights_t_f))] <- 0.5
integrals_t_f <- as.numeric(bm_paths_f %*% weights_t_f) * dt_f

empirical_cov_f <- cov(integrals_s_f, integrals_t_f)

cat("Empirical covariance:", empirical_cov_f, "\n")
cat("Absolute error:", abs(empirical_cov_f - theoretical_cov_f), "\n\n")

#### Question (g): Visualising non-stationary increments ####

cat("--- Question (g): Visualising non-stationary increments ---\n")

N_g <- 10000
ttm_g <- 2
dt_g <- 0.01
bm_paths_g <- sim_bm(N_g, ttm_g, dt_g)

# Integrate all paths on the grid using cumulative trapezoidal sums.
trap_increments_g <- (
  bm_paths_g[, -1, drop = FALSE] +
    bm_paths_g[, -ncol(bm_paths_g), drop = FALSE]
) * (dt_g / 2)
integrated_paths_g <- cbind(0, t(apply(trap_increments_g, 1, cumsum)))

idx_05_g <- round(0.5 / dt_g) + 1
idx_10_g <- round(1.0 / dt_g) + 1
idx_15_g <- round(1.5 / dt_g) + 1

inc1_g <- integrated_paths_g[, idx_05_g] - integrated_paths_g[, 1]
inc2_g <- integrated_paths_g[, idx_15_g] - integrated_paths_g[, idx_10_g]

plot_range_g <- range(c(inc1_g, inc2_g))
col1_g <- rgb(1, 0, 0, alpha = 0.5)
col2_g <- rgb(0, 0, 1, alpha = 0.5)

hist(
  inc1_g,
  breaks = 50, col = col1_g,
  xlim = plot_range_g, probability = TRUE,
  main = "Distributions of Equal-Length Increments",
  xlab = "Increment"
)
hist(
  inc2_g,
  breaks = 50, col = col2_g,
  add = TRUE, probability = TRUE
)
legend(
  "topright",
  legend = c("Increment [0, 0.5]", "Increment [1.0, 1.5]"),
  fill = c(col1_g, col2_g)
)

increment_length_g <- 0.5
start1_g <- 0
start2_g <- 1
var_inc1_theory_g <- start1_g * increment_length_g^2 + increment_length_g^3 / 3
var_inc2_theory_g <- start2_g * increment_length_g^2 + increment_length_g^3 / 3

cat("Increment [0, 0.5]: theoretical variance =", var_inc1_theory_g,
    ", sample variance =", var(inc1_g), "\n")
cat("Increment [1.0, 1.5]: theoretical variance =", var_inc2_theory_g,
    ", sample variance =", var(inc2_g), "\n")
cat(
  "The unequal variances for increments of equal length demonstrate that ",
  "integrated Brownian motion does not have stationary increments.\n",
  sep = ""
)
