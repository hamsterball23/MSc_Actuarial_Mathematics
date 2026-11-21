####### Problem 9.6: Itô sums and quadratic variation #######

#################################################################
#### HELPER FUNCTIONS ####
#################################################################

# Simulate N Brownian paths on [0,T]. Each row is one path.
sim_bm_paths <- function(N, T, dt) {
  K <- round(T / dt)

  if (abs(K * dt - T) > 1e-12) {
    stop("T must be an integer multiple of dt.")
  }

  increments <- matrix(
    rnorm(N * K, mean = 0, sd = sqrt(dt)),
    nrow = N,
    ncol = K
  )

  paths_without_zero <- t(apply(increments, 1, cumsum))
  cbind(0, paths_without_zero)
}

# Compute the three discrete quantities for one Brownian path.
calculate_sums <- function(path) {
  increments <- diff(path)
  K <- length(increments)
  left_values <- path[seq_len(K)]
  right_values <- path[seq_len(K) + 1]

  ito_sum <- sum(left_values * increments)
  symmetric_sum <- sum(0.5 * (left_values + right_values) * increments)
  quadratic_variation <- sum(increments^2)

  c(
    ito = ito_sum,
    symmetric = symmetric_sum,
    qv = quadratic_variation
  )
}

# Estimate the errors in batches to keep memory use moderate.
estimate_errors <- function(N, T, dt, batch_size = 500) {
  qv_absolute_error <- numeric(N)
  ito_absolute_error <- numeric(N)
  ito_identity_residual <- numeric(N)
  symmetric_identity_residual <- numeric(N)

  first_index <- 1

  while (first_index <= N) {
    last_index <- min(first_index + batch_size - 1, N)
    current_N <- last_index - first_index + 1

    paths <- sim_bm_paths(current_N, T, dt)
    increments <- paths[, -1, drop = FALSE] -
      paths[, -ncol(paths), drop = FALSE]
    left_values <- paths[, -ncol(paths), drop = FALSE]
    right_values <- paths[, -1, drop = FALSE]

    W_T <- paths[, ncol(paths)]
    qv <- rowSums(increments^2)
    ito_sum <- rowSums(left_values * increments)
    symmetric_sum <- rowSums(
      0.5 * (left_values + right_values) * increments
    )

    target_ito <- 0.5 * (W_T^2 - T)
    target_symmetric <- 0.5 * W_T^2

    index <- first_index:last_index
    qv_absolute_error[index] <- abs(qv - T)
    ito_absolute_error[index] <- abs(ito_sum - target_ito)
    ito_identity_residual[index] <- abs(
      ito_sum - 0.5 * (W_T^2 - qv)
    )
    symmetric_identity_residual[index] <- abs(
      symmetric_sum - target_symmetric
    )

    first_index <- last_index + 1
  }

  c(
    mean_qv_error = mean(qv_absolute_error),
    mean_ito_error = mean(ito_absolute_error),
    max_ito_identity_residual = max(ito_identity_residual),
    max_symmetric_identity_residual = max(symmetric_identity_residual)
  )
}

#################################################################
#### SETUP ####
#################################################################

T_val <- 1
N_paths <- 5000
set.seed(42)

#################################################################
#### PART (a): ALGEBRAIC IDENTITIES ####
#################################################################

cat("--- Part (a): Algebraic identities ---\n")
cat(
  "For each increment,\n",
  "  0.5 * (W_i + W_{i+1}) * Delta W_i\n",
  "    = 0.5 * (W_{i+1}^2 - W_i^2).\n",
  "After summation, the symmetric sum is exactly 0.5 * W_T^2.\n\n",
  sep = ""
)
cat(
  "Also,\n",
  "  W_i * Delta W_i\n",
  "    = 0.5 * (W_{i+1}^2 - W_i^2) - 0.5 * (Delta W_i)^2.\n",
  "Hence the Itô sum is exactly 0.5 * W_T^2 - 0.5 * Q.\n\n",
  sep = ""
)

#################################################################
#### PART (b): ONE FINELY DISCRETISED PATH ####
#################################################################

cat("--- Part (b): One path with dt = 0.0001 ---\n")
dt_single <- 0.0001
K_single <- round(T_val / dt_single)
path_single <- sim_bm_paths(1, T_val, dt_single)[1, ]
values_single <- calculate_sums(path_single)
W_T_single <- tail(path_single, 1)

target_ito_single <- 0.5 * (W_T_single^2 - T_val)
target_symmetric_single <- 0.5 * W_T_single^2
identity_ito_single <- 0.5 * (W_T_single^2 - values_single["qv"])

cat(sprintf("Number of time steps: %d\n", K_single))
cat(sprintf("W_1: %.8f\n", W_T_single))
cat(sprintf("Realised quadratic variation Q: %.8f\n", values_single["qv"]))
cat(sprintf("Itô sum: %.8f\n", values_single["ito"]))
cat(sprintf("Itô target 0.5*(W_1^2-1): %.8f\n", target_ito_single))
cat(sprintf("Symmetric sum: %.8f\n", values_single["symmetric"]))
cat(sprintf("Symmetric target 0.5*W_1^2: %.8f\n", target_symmetric_single))
cat(sprintf(
  "Residual in Itô identity: %.3e\n",
  abs(values_single["ito"] - identity_ito_single)
))
cat(sprintf(
  "Residual in symmetric identity: %.3e\n\n",
  abs(values_single["symmetric"] - target_symmetric_single)
))

#################################################################
#### PART (c): MEAN ABSOLUTE ERRORS ####
#################################################################

cat("--- Part (c): Mean absolute errors ---\n")
dt_values <- c(0.1, 0.01, 0.001)
results <- data.frame(
  dt = dt_values,
  qv_error = numeric(length(dt_values)),
  ito_error = numeric(length(dt_values)),
  max_ito_identity_residual = numeric(length(dt_values)),
  max_symmetric_identity_residual = numeric(length(dt_values))
)

for (i in seq_along(dt_values)) {
  current <- estimate_errors(
    N = N_paths,
    T = T_val,
    dt = dt_values[i],
    batch_size = 500
  )

  results$qv_error[i] <- current["mean_qv_error"]
  results$ito_error[i] <- current["mean_ito_error"]
  results$max_ito_identity_residual[i] <-
    current["max_ito_identity_residual"]
  results$max_symmetric_identity_residual[i] <-
    current["max_symmetric_identity_residual"]

  cat(sprintf(
    paste0(
      "dt = %.3f | mean |Q-1| = %.6f | ",
      "mean Itô error = %.6f | ratio = %.6f\n"
    ),
    results$dt[i],
    results$qv_error[i],
    results$ito_error[i],
    results$ito_error[i] / results$qv_error[i]
  ))
}

cat(
  "\nThe ratio is 0.5 because, pathwise,\n",
  "  Itô sum - 0.5*(W_1^2-1) = -0.5*(Q-1).\n\n",
  sep = ""
)

#################################################################
#### PART (d): LOG-LOG PLOT AND ESTIMATED SLOPES ####
#################################################################

fit_qv <- lm(log(qv_error) ~ log(dt), data = results)
fit_ito <- lm(log(ito_error) ~ log(dt), data = results)
slope_qv <- unname(coef(fit_qv)[2])
slope_ito <- unname(coef(fit_ito)[2])

plot(
  results$dt,
  results$qv_error,
  type = "b",
  log = "xy",
  col = "darkgreen",
  pch = 19,
  xlab = "Time step (Delta t)",
  ylab = "Mean absolute error",
  main = "Quadratic-variation and Itô-sum errors",
  ylim = range(c(results$qv_error, results$ito_error)),
  panel.first = grid()
)
lines(
  results$dt,
  results$ito_error,
  type = "b",
  col = "blue",
  pch = 17
)
legend(
  "topleft",
  legend = c(
    sprintf("Quadratic variation, slope %.3f", slope_qv),
    sprintf("Itô sum, slope %.3f", slope_ito)
  ),
  col = c("darkgreen", "blue"),
  lty = 1,
  pch = c(19, 17)
)

cat("--- Part (d): Estimated log-log slopes ---\n")
cat(sprintf("Quadratic-variation error: %.4f\n", slope_qv))
cat(sprintf("Itô-sum error: %.4f\n", slope_ito))
cat(
  "Both slopes should be close to 0.5. The two estimated slopes are\n",
  "the same up to numerical precision because the Itô error is exactly\n",
  "one half of the quadratic-variation error path by path.\n\n",
  sep = ""
)

#################################################################
#### PART (e): INTERPRETATION ####
#################################################################

cat("--- Part (e): Interpretation ---\n")
cat(
  "The symmetric endpoint sum reproduces the ordinary chain rule exactly:\n",
  "  I_sym = 0.5 * W_T^2.\n\n",
  "The difference between the symmetric and Itô sums is\n",
  "  I_sym - I_Ito = 0.5 * Q.\n",
  "Since the realised quadratic variation Q converges to T, the limiting\n",
  "difference is 0.5 * T. Thus\n",
  "  integral W dW = 0.5 * (W_T^2 - T).\n\n",
  "The correction is caused by the non-zero quadratic variation of Brownian\n",
  "motion, not by an ordinary smooth-path calculus effect. Equivalently,\n",
  "(dW_t)^2 contributes dt in Itô's formula, giving\n",
  "  d(W_t^2) = 2 * W_t dW_t + dt.\n",
  sep = ""
)
