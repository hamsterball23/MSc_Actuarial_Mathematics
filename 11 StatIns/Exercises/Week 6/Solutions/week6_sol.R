# Solutions for week 6 in StatIns

## Practical Exercise 2

library(CASdatasets)
data("beaonre")
claims <- beaonre$ClaimCost

## a.

# use the Hill estimator from Practical Exercise 1
hill_estimator <- function(data, k) {
  sorted_data   <- sort(data, decreasing = TRUE)
  tail_data     <- sorted_data[1:k]
  hill_estimate <- 1/(mean(log(tail_data) - log(sorted_data[k + 1])))
  return(hill_estimate)
}

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

hill_plot(claims)

# there seems to be a stable region in [250, 750], we choose k = 250
(hill <- hill_estimator(claims, 250)) # 0.598247 (= 1/gamma)
# the true value could very well be 0.60

## b.

# make 100 experiments each with 300 samples
hill <- rep(0, 100)
# here we choose k = n/5
k = 300/5

set.seed(2026)
for (b in 1:100) {
  claim_sample <- sample(claims, 300, replace = TRUE)
  hill[b] <- hill_estimator(claim_sample, k)
}

# say we believe the true index is 0.6, then we get
library(tidyverse)
ggplot() + 
  geom_histogram(mapping = aes(x = hill), colour = "white") +
  geom_vline(xintercept = 0.60, colour = "red") +
  theme_bw() + xlab("Hill estimator") + ggtitle("Bootstrap estimators")

# we know sqrt(k)(gamma_n,k - gamma) -> N(0, gamma^2)
hill_weak_estimator <- sqrt(k) * (hill - 0.60)

ggplot() + 
  geom_qq(mapping = aes(sample = hill_weak_estimator), distribution = qnorm,
          dparams = list("mean" = 0, "sd" = 0.60)) + theme_bw() +
  geom_qq_line(mapping = aes(sample = hill_weak_estimator), distribution = qnorm,
          dparams = list("mean" = 0, "sd" = 0.60), color = "red")

# a bit deviation in the tails but otherwise quite good
