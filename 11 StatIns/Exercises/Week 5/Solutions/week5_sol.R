# Solutions for week 5 in StatIns

## Practical Exercise 1

library(ggplot2)
library(actuar) # For Burr distribution

# Simulate Data
set.seed(2026)
n <- 1000

burr_data   <- rburr(n, shape1 = 1, shape2 = 2) # Burr distribution with beta = 1, eta = 2
normal_data <- rnorm(n)

## a.

hill_estimator <- function(data, k) {
  sorted_data   <- sort(data, decreasing = TRUE)
  tail_data     <- sorted_data[1:k]
  hill_estimate <- 1/(mean(log(tail_data) - log(sorted_data[k + 1])))
  hill_estimate
}

## b.

# function to make a Hill plot (note that I choose to plot the reciprocal)
hill_plot <- function(data) {
  k_vals    <- 1:(length(data) - 1)
  hill_vals <- sapply(k_vals, hill_estimator, data = data)
  
  # Create data frame for ggplot
  hill_data <- data.frame(k = k_vals, hill = hill_vals)
  
  # Plot using ggplot2
  ggplot(hill_data, aes(x = k, y = hill)) +
    geom_line(color = "blue") +
    labs(
      x = "k (Order Statistics)",
      y = "Hill Estimator",
      title = "Hill Plot"
    ) +
    theme_bw()
}

# make Hill plots for Burr and normal data
hill_plot(burr_data)  # recall that the true value is 2
hill_plot(normal_data)

# for Burr, I would choose k = 200, corresponding to
hill_estimator(burr_data, 200)  # 1.759092
# for normal, I don't know what I would choose, maybe k = 50?
hill_estimator(normal_data, 50) # 4.59759

## c.

excess_mean_plot <- function(data) {
  sorted_data <- sort(data)
  
  # Calculate excess means
  excess_means <- sapply(1:(length(sorted_data) - 1), function(k) {
    mean(sorted_data[(k + 1):length(sorted_data)] - sorted_data[k])
  })
  
  # Create data frame for ggplot
  excess_mean_data <- data.frame(
    threshold = sorted_data[-length(sorted_data)],
    excess_mean = excess_means
  )
  
  # Plot using ggplot2
  ggplot(excess_mean_data, aes(x = threshold, y = excess_mean)) +
    geom_line(color = "red") +
    labs(
      x = "Threshold (u)",
      y = "Mean Excess",
      title = "Mean Excess Function"
    ) +
    theme_bw()
}

excess_mean_plot(burr_data) # would expect linear in u because that's the case for Pareto
excess_mean_plot(normal_data) # goes to zero as expected

## d.

# Theoretical quantiles
quantiles_theoretical <- qburr(c(0.90, 0.99, 0.9999), shape1 = 1, shape2 = 2)

# Quantile Function (based on Hill estimator)
# Sort the Burr data first
BurrSort <- sort(burr_data, decreasing = FALSE)

quantile_fun <- function(p, k, Z, hill) {
  (n / k * (1 - p))^(-1/hill) * Z[n - k]
}

# Estimating the quantiles using the Hill estimator
tail_index_estimated <- hill_estimator(burr_data, 200)
hill_quantile <- c(
  quantile_fun(0.9, 150, BurrSort, tail_index_estimated),
  quantile_fun(0.99, 150, BurrSort, tail_index_estimated),
  quantile_fun(0.9999, 150, BurrSort, tail_index_estimated)
)

cat("Estimated Quantiles using Hill estimator:\n", hill_quantile)
cat("Theoretical Quantiles (Burr Distribution):\n", quantiles_theoretical, "\n")

## e.

quantiles_empirical <- quantile(burr_data, probs = c(0.90, 0.99, 0.9999))
cat("Empirical Quantiles (Burr Data):\n", quantiles_empirical, "\n")

# the empirical estimates are way too low
