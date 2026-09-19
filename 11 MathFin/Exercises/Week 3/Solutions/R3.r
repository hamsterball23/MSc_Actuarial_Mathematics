####### Problem 3.5: Simulation exercise: Brownian motion and hitting times #######

# Set a seed to make the simulations reproducible.
set.seed(1234)


#### Helper function: Brownian motion simulator ####

# Simulate N Brownian paths on [0, ttm] using time-step size dt.
# The returned matrix has one path per row and includes B_0 = 0.
sim_bm <- function(N, ttm, dt) {
  K <- as.integer(round(ttm / dt))

  increments <- matrix(
    rnorm(N * K, mean = 0, sd = sqrt(dt)),
    nrow = N,
    ncol = K
  )

  paths <- t(apply(increments, 1, cumsum))
  cbind(0, paths)
}


#### Question (a): The process S_t = exp(B_t - t/4) ####

## Question (a)(i): Simulate and plot ten sample paths ##

number_of_paths <- 10
ttm_s <- 10
dt_s <- 0.01
K_s <- as.integer(round(ttm_s / dt_s))
time_grid_s <- seq(0, ttm_s, length.out = K_s + 1)

brownian_paths_s <- sim_bm(number_of_paths, ttm_s, dt_s)

# Construct S_t = exp(B_t - t/4) for each Brownian path.
time_component <- matrix(
  time_grid_s / 4,
  nrow = number_of_paths,
  ncol = K_s + 1,
  byrow = TRUE
)

s_paths <- exp(brownian_paths_s - time_component)

matplot(
  time_grid_s,
  t(s_paths),
  type = "l",
  lty = 1,
  col = seq_len(number_of_paths),
  main = expression(paste("Ten Sample Paths of ", S[t])),
  xlab = "Time",
  ylab = expression(S[t])
)

# Although most sample paths eventually become small, occasional paths can
# attain very large values. This reflects the substantial right tail of S_t.


## Question (a)(ii): Estimate E[S_10] ##

N_s <- 10000

# Only B_10 is required to estimate E[S_10], so there is no need to store
# the complete paths. Since B_10 is N(0, 10), simulate the endpoints directly.
b_10 <- rnorm(N_s, mean = 0, sd = sqrt(ttm_s))
s_10 <- exp(b_10 - ttm_s / 4)

estimated_mean_s_10 <- mean(s_10)
theoretical_mean_s_10 <- exp(ttm_s / 4)

cat("\nQuestion (a)(ii)\n")
cat(sprintf("Monte Carlo estimate of E[S_10]: %.4f\n", estimated_mean_s_10))
cat(sprintf("Theoretical value of E[S_10]:    %.4f\n", theoretical_mean_s_10))
cat(sprintf("Sample variance of S_10:         %.4f\n", var(s_10)))

# The theoretical value follows from
#
#   E[S_10] = exp(-10/4) E[exp(B_10)]
#           = exp(-10/4) exp(10/2)
#           = exp(10/4).
#
# The Monte Carlo estimate may vary noticeably because S_10 has high variance.


#### Questions (b) and (c): The maximum of Brownian motion ####

N_max <- 100000
ttm_max <- 1

# Simulate the discretised maximum for a given time-step size without
# retaining the path matrix after the function returns.
simulate_discrete_maximum <- function(N, ttm, dt) {
  paths <- sim_bm(N, ttm, dt)
  apply(paths, 1, max)
}

max_dt_01 <- simulate_discrete_maximum(N_max, ttm_max, 0.1)
max_dt_001 <- simulate_discrete_maximum(N_max, ttm_max, 0.01)


## Question (b): Compare two discretisation ##

# Use common histogram breaks that cover all simulated values.
upper_limit <- ceiling(
  max(c(max_dt_01, max_dt_001)) * 10
) / 10

common_breaks <- seq(
  from = 0,
  to = upper_limit,
  length.out = 81
)

par(mfrow = c(1, 2))

hist(
  max_dt_01,
  breaks = common_breaks,
  probability = TRUE,
  main = expression(
    paste("Discretised Maximum, ", Delta * t == 0.1)
  ),
  xlab = expression(max(B[t])),
  ylab = "Density",
  xlim = c(0, upper_limit)
)

hist(
  max_dt_001,
  breaks = common_breaks,
  probability = TRUE,
  main = expression(
    paste("Discretised Maximum, ", Delta * t == 0.01)
  ),
  xlab = expression(max(B[t])),
  ylab = "Density",
  xlim = c(0, upper_limit)
)

par(mfrow = c(1, 1))


# A discrete grid may miss a maximum attained between consecutive grid points.
# The discretised maximum therefore tends to underestimate the continuous-time
# maximum. The histogram for dt = 0.01 should be closer to the theoretical
# distribution than the histogram for dt = 0.1.


## Question (c): Compare with the theoretical density of |B_1| ##

hist(
  max_dt_001,
  breaks = common_breaks,
  probability = TRUE,
  main = expression(paste("Maximum of Brownian Motion on ", "[0,1]")),
  xlab = "Value",
  ylab = "Density",
  xlim = c(0, 4)
)

# By the reflection principle, max_{0 <= t <= 1} B_t has the same
# distribution as |B_1|. Its density is 2 * phi(x) for x >= 0.
curve(
  2 * dnorm(x),
  from = 0,
  to = 4,
  add = TRUE,
  col = "blue",
  lwd = 2
)

legend(
  "topright",
  legend = c("Simulated maximum", "Density of |B_1|"),
  col = c("grey40", "blue"),
  lty = c(NA, 1),
  lwd = c(NA, 2),
  pch = c(15, NA),
  bty = "n"
)

# The histogram should be close to the density of |B_1|. Any remaining
# discrepancy is primarily due to observing the path only on a discrete grid.


#### Questions (d), (e), and (f): First hitting time of level 1 ####

N_hit <- 10000
ttm_hit <- 10
level <- 1

# For each path, record the first grid time at which the path reaches the
# specified level. If no such grid time exists, record the capped value ttm.
# The function also records whether the level was reached before ttm.
find_capped_hitting_times <- function(paths, level, dt, ttm) {
  hit_matrix <- paths >= level
  reached_on_grid <- rowSums(hit_matrix) > 0

  first_hit_index <- max.col(hit_matrix, ties.method = "first")
  hitting_times <- (first_hit_index - 1) * dt
  hitting_times[!reached_on_grid] <- ttm

  final_index <- ncol(paths)
  reached_before_ttm <- rowSums(hit_matrix[, -final_index, drop = FALSE]) > 0

  list(
    capped_times = pmin(hitting_times, ttm),
    reached_on_grid = reached_on_grid,
    reached_before_ttm = reached_before_ttm
  )
}

paths_hit_01 <- sim_bm(N_hit, ttm_hit, 0.1)
hit_results_01 <- find_capped_hitting_times(
  paths_hit_01,
  level,
  0.1,
  ttm_hit
)
rm(paths_hit_01)

invisible(gc())

paths_hit_001 <- sim_bm(N_hit, ttm_hit, 0.01)
hit_results_001 <- find_capped_hitting_times(
  paths_hit_001,
  level,
  0.01,
  ttm_hit
)
rm(paths_hit_001)

invisible(gc())


## Question (d): Histograms of T capped at 10 ##

par(mfrow = c(1, 2))

hist(
  hit_results_01$capped_times,
  breaks = seq(0, 10, by = 0.25),
  probability = TRUE,
  main = "T capped at 10, dt = 0.1",
  xlab = "Capped hitting time",
  ylab = "Density",
  xlim = c(0, 10)
)

hist(
  hit_results_001$capped_times,
  breaks = seq(0, 10, by = 0.25),
  probability = TRUE,
  main = "T capped at 10, dt = 0.01",
  xlab = "Capped hitting time",
  ylab = "Density",
  xlim = c(0, 10)
)

par(mfrow = c(1, 1))

# The concentration at 10 represents paths whose capped hitting time equals
# 10. A finer grid detects more crossings between the coarser observation
# times and should therefore reduce the discretisation bias.


## Question (e): Estimate E[T capped at 10] ##

estimated_capped_mean <- mean(hit_results_001$capped_times)

cat("\nQuestion (e)\n")
cat(sprintf(
  "Estimated E[T capped at 10] for dt = 0.01: %.4f\n",
  estimated_capped_mean
))


## Question (f): Estimate the probability of not reaching level 1 before 10 ##

estimated_non_hitting_probability <- mean(
  !hit_results_001$reached_before_ttm
)

cat("\nQuestion (f)\n")
cat(sprintf(
  "Estimated probability of not reaching level 1 before time 10: %.4f\n",
  estimated_non_hitting_probability
))

# This estimate is based on the discrete grid. A path may cross level 1
# between two grid points and return below it before the next observation.
# The simulation may therefore slightly overestimate the non-hitting
# probability.


#### Questions (g) and (h): Two-dimensional Brownian motion ####

N_2d <- 2
ttm_2d <- 1
dt_2d <- 0.001

# Simulate two independent Brownian motions using the same time grid.
bm_2d <- sim_bm(N_2d, ttm_2d, dt_2d)
b1_path <- bm_2d[1, ]
b2_path <- bm_2d[2, ]


## Question (g): Two-dimensional standard Brownian motion ##

par(mfrow = c(1, 3))

plot(
  b1_path,
  b2_path,
  type = "l",
  asp = 1,
  main = "Two-Dimensional Brownian Motion",
  xlab = expression(B[t]^{(1)}),
  ylab = expression(B[t]^{(2)})
)

points(b1_path[1], b2_path[1], pch = 16, col = "green4")
points(tail(b1_path, 1), tail(b2_path, 1), pch = 16, col = "red")


## Question (h): Correlated Brownian motion for rho = 0.7 and rho = -0.7 ##

plot_correlated_path <- function(rho, b1_path, b2_path) {
  w1_path <- sqrt(1 - rho^2) * b1_path + rho * b2_path

  plot(
    w1_path,
    b2_path,
    type = "l",
    asp = 1,
    main = substitute(rho == value, list(value = rho)),
    xlab = expression(W[t]^{(1)}),
    ylab = expression(B[t]^{(2)})
  )

  points(w1_path[1], b2_path[1], pch = 16, col = "green4")
  points(tail(w1_path, 1), tail(b2_path, 1), pch = 16, col = "red")
}

plot_correlated_path(0.7, b1_path, b2_path)
plot_correlated_path(-0.7, b1_path, b2_path)

par(mfrow = c(1, 1))

# For rho = 0.7, the two coordinates tend to move in the same direction,
# producing a path elongated around the increasing diagonal. For rho = -0.7,
# they tend to move in opposite directions, producing a path elongated around
# the decreasing diagonal. The green and red points mark the start and end of
# each path, respectively.
