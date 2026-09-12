####### Problem 2.7: Simulation exercise: Brownian paths #######

# Set a seed to make the simulation reproducible.
set.seed(1234)

# General parameters.
ttm <- 1       # End of the time interval [0, T].
N <- 10000     # Number of simulated paths in Question (a).


#### Question (a): Distribution of the endpoint B_1 ####

# Simulate N Brownian paths on [0, T] using K time steps.
#
# For each time step, the increment is normally distributed with
# mean zero and variance dt. Increments over different time
# intervals are generated independently.
simulate_bm_paths <- function(N, K, dt) {
  paths <- matrix(0, nrow = N, ncol = K + 1)

  for (i in seq_len(K)) {
    increments <- rnorm(N, mean = 0, sd = sqrt(dt))
    paths[, i + 1] <- paths[, i] + increments
  }

  paths
}


# Simulate the paths and analyse their endpoints for a given
# time-step size.
analyse_endpoints <- function(dt) {
  K <- as.integer(round(ttm / dt))

  # Simulate N Brownian paths.
  paths <- simulate_bm_paths(N, K, dt)

  # The final column contains the endpoint B_1 of each path.
  endpoints <- paths[, K + 1]

  # The theoretical mean and variance of B_1 are both known:
  #
  #   E[B_1] = 0
  #   Var(B_1) = 1.
  #
  # The sample mean and sample variance should therefore be close
  # to zero and one, respectively.
  cat(sprintf("\nFor dt = %.3f:\n", dt))
  cat(sprintf(
    "  Sample mean of B_1:     %.4f\n",
    mean(endpoints)
  ))
  cat(sprintf(
    "  Sample variance of B_1: %.4f\n",
    var(endpoints)
  ))
 

  # Plot a density histogram of the simulated endpoints.
  hist(
    endpoints,
    probability = TRUE,
    breaks = 50,
    main = paste("Endpoints for dt =", dt),
    xlab = expression(B[1]),
    ylab = "Density",
    xlim = c(-4, 4)
  )

  # Since B_1 is normally distributed with mean zero and variance
  # one, superimpose the density of the N(0, 1) distribution.
  curve(
    dnorm(x, mean = 0, sd = sqrt(ttm)),
    from = -4,
    to = 4,
    add = TRUE,
    col = "blue",
    lwd = 2
  )

  legend(
    "topright",
    legend = "Theoretical density",
    col = "blue",
    lwd = 2,
    bty = "n"
  )
}


# Compare the simulated endpoints for the three time-step sizes.
par(mfrow = c(1, 3))

for (dt in c(0.1, 0.01, 0.001)) {
  analyse_endpoints(dt)
}

par(mfrow = c(1, 1))


# For every value of dt, the simulated endpoint is a sum of
# independent Gaussian increments:
#
#   B_1 = sqrt(dt) * (Z_1 + ... + Z_K),
#
# where K * dt = 1. Hence B_1 has the exact distribution N(0, 1)
# for each of the three time-step sizes. Decreasing dt produces a
# finer representation of the path, but it does not improve the
# distributional approximation of the endpoint.


#### Question (b): Variation of a Brownian path ####

# Simulate one Brownian path from its independent increments.
simulate_one_bm_path <- function(K, dt) {
  increments <- rnorm(K, mean = 0, sd = sqrt(dt))

  # Prepend B_0 = 0 to the cumulative sums of the increments.
  c(0, cumsum(increments))
}


# Generate one high-resolution Brownian path using dt = 2^(-20).
max_k <- 20
dt_high_resolution <- 2^(-max_k)
K_high_resolution <- 2^max_k

bm_path <- simulate_one_bm_path(
  K_high_resolution,
  dt_high_resolution
)


# Return the indices corresponding to the uniform partition of
# [0, 1] into 2^k subintervals.
#
# The simulated path is defined on the finest grid with 2^max_k
# subintervals. The coarser partitions are obtained by selecting
# the appropriate points from this grid.
partition_indices <- function(k, max_k) {
  step_size <- 2^(max_k - k)

  seq(
    from = 1,
    to = 2^max_k + 1,
    by = step_size
  )
}


## Question (b)(i): Total variation ##

# Compute the total variation of a path along a given partition.
total_variation <- function(path, indices) {
  increments <- diff(path[indices])
  sum(abs(increments))
}

k_values <- 1:max_k

# Compute the total variation along each of the nested
# partitions pi_1, ..., pi_20.
total_variations <- sapply(k_values, function(k) {
  indices <- partition_indices(k, max_k)
  total_variation(bm_path, indices)
})


## Question (b)(ii): Plot the total variation ##

plot(
  k_values,
  total_variations,
  type = "l",
  col = "red",
  lwd = 2,
  main = "Total Variation",
  xlab = "k",
  ylab = expression(V[k])
)


# As k increases, the partition becomes finer. The simulated total
# variation generally increases and does not appear to converge to
# a finite value. This illustrates the theoretical result that
# Brownian paths have infinite total variation almost surely.


## Question (b)(iii): Quadratic variation ##

# Compute the quadratic variation of a path along a given
# partition.
quadratic_variation <- function(path, indices) {
  increments <- diff(path[indices])
  sum(increments^2)
}

# Compute the quadratic variation along each of the nested
# partitions pi_1, ..., pi_20.
quadratic_variations <- sapply(k_values, function(k) {
  indices <- partition_indices(k, max_k)
  quadratic_variation(bm_path, indices)
})


## Question (b)(iv): Plot the quadratic variation ##

plot(
  k_values,
  quadratic_variations,
  type = "l",
  col = "blue",
  lwd = 2,
  main = "Quadratic Variation",
  xlab = "k",
  ylab = expression(Q[k]),
  ylim = range(c(quadratic_variations, ttm))
)

# Add a horizontal line at the theoretical value T = 1.
abline(
  h = ttm,
  col = "black",
  lty = 2,
  lwd = 2
)

legend(
  "topright",
  legend = c(
    "Simulated quadratic variation",
    "Theoretical value"
  ),
  col = c("blue", "black"),
  lty = c(1, 2),
  lwd = 2,
  bty = "n"
)


# As k increases, the quadratic variation approaches T = 1.
# This illustrates the result that the quadratic variation of a
# Brownian motion on [0, T] is equal to T.


#### Question (c): Comparison of related processes ####

number_of_paths <- 5
dt_paths <- 0.001
K_paths <- as.integer(round(ttm / dt_paths))
time_grid <- seq(0, ttm, length.out = K_paths + 1)


# Generate the Brownian increments for all five paths.
increments <- matrix(
  rnorm(
    number_of_paths * K_paths,
    mean = 0,
    sd = sqrt(dt_paths)
  ),
  nrow = number_of_paths,
  ncol = K_paths
)

# Compute the cumulative sums along the rows of the matrix.
brownian_paths <- t(apply(increments, 1, cumsum))

# Prepend B_0 = 0 to each path.
brownian_paths <- cbind(0, brownian_paths)


# Use the same colour for corresponding paths in all four plots.
path_colours <- seq_len(number_of_paths)

par(mfrow = c(2, 2))


## Question (c)(i): Standard Brownian motion ##

matplot(
  time_grid,
  t(brownian_paths),
  type = "l",
  lty = 1,
  col = path_colours,
  main = "Standard Brownian Motion",
  xlab = "Time",
  ylab = expression(B[t])
)


# All paths start at zero. They fluctuate randomly around zero,
# and their dispersion tends to increase with time because
# Var(B_t) = t.


## Question (c)(ii): Brownian motion with positive drift ##

mu_positive <- 2

# Add the deterministic drift mu * t to each Brownian path.
positive_drift_paths <-
  brownian_paths +
  matrix(
    mu_positive * time_grid,
    nrow = number_of_paths,
    ncol = K_paths + 1,
    byrow = TRUE
  )

matplot(
  time_grid,
  t(positive_drift_paths),
  type = "l",
  lty = 1,
  col = path_colours,
  main = expression(paste("Brownian Motion with ", mu == 2)),
  xlab = "Time",
  ylab = expression(X[t])
)


# The positive drift shifts the Brownian paths upwards. The random
# fluctuations are unchanged, but the paths fluctuate around the
# increasing function t -> 2t.


## Question (c)(ii): Brownian motion with negative drift ##

mu_negative <- -2

# Add the deterministic drift mu * t to each Brownian path.
negative_drift_paths <-
  brownian_paths +
  matrix(
    mu_negative * time_grid,
    nrow = number_of_paths,
    ncol = K_paths + 1,
    byrow = TRUE
  )

matplot(
  time_grid,
  t(negative_drift_paths),
  type = "l",
  lty = 1,
  col = path_colours,
  main = expression(paste("Brownian Motion with ", mu == -2)),
  xlab = "Time",
  ylab = expression(X[t])
)


# The negative drift shifts the Brownian paths downwards. The paths
# fluctuate around the decreasing function t -> -2t.


## Question (c)(iii): Brownian bridge ##

# Extract the endpoint B_1 of each Brownian path.
endpoints <- brownian_paths[, K_paths + 1]

# The outer product creates a matrix whose (i, j)-entry is
#
#   B_1^(i) * t_j.
#
# Subtracting this matrix from the Brownian paths gives
#
#   b_t = B_t - t * B_1.
bridge_adjustment <- outer(
  endpoints,
  time_grid
)

bridge_paths <- brownian_paths - bridge_adjustment

matplot(
  time_grid,
  t(bridge_paths),
  type = "l",
  lty = 1,
  col = path_colours,
  main = "Brownian Bridge",
  xlab = "Time",
  ylab = expression(b[t])
)

par(mfrow = c(1, 1))


## Question (c)(iv): Comparison ##

# The standard Brownian paths start at zero and have random
# endpoints at time one.
#
# Adding a positive drift shifts the paths upwards, whereas adding
# a negative drift shifts them downwards. The drift changes the
# mean function but not the random fluctuations around it.
#
# The Brownian bridge paths are pinned at zero at both endpoints:
#
#   b_0 = b_1 = 0.
#
# Unlike Brownian motion, their dispersion decreases as time
# approaches one because every bridge must return to zero at the
# endpoint.



