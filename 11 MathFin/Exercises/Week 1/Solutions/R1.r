####### Problem 1.5: Simulation Exercise in R #######

#### Question (a) ####
# Assume that E[g(X)^2] < infinity. By the strong law of large numbers,
#
# (1/N) * sum(g(X_j)^2) -> E[g(X)^2]
#
# and
#
# ((1/N) * sum(g(X_j)))^2 -> E[g(X)]^2
#
# almost surely. Hence the sample variance converges almost surely
# to Var(g(X)). The denominator N - 1 also makes the estimator
# unbiased for finite N.


# Set plot layout to show one plot at a time.
par(mfrow = c(1, 1))

# Define simulation parameters.
N <- 1000      # Total number of simulations/observations.
mu <- 0.0      # Mean of the normal distribution.
sigma <- 1.0   # Standard deviation of the normal distribution.

#### Question (b) ####
# Simulate N random numbers from a standard normal distribution.
# 'rnorm' stands for "random normal".
X <- rnorm(N, mean = mu, sd = sigma)

# Print the first few values to inspect them.
print(head(X))


#### Question (c) ####
## Subquestion (i): Plot the running sample mean ##

# --- Method 1: Using a for-loop  ---
# Preallocating memory is much faster and better practice in R than growing a vector with c().
means_loop <- numeric(N) 
for (n in 1:N) {
  means_loop[n] <- mean(X[1:n])
}
plot(1:N, means_loop, type='l', main="Running Sample Mean", xlab="n", ylab="Mean")


## Subquestion (ii): Plot the running sample variance ##

# --- Method 1: Using a for-loop  ---
vars_loop <- numeric(N)
vars_loop[1] <- NA # Variance is undefined for a single observation
for (n in 2:N) {
  vars_loop[n] <- var(X[1:n])
}
# Plot the running variance. We expect it to converge to the true variance (sigma^2 = 1).
plot(2:N, vars_loop[2:N], type='l', main="Running Sample Variance", xlab="n", ylab="Variance")


#### Question (d) ####
## Subquestion (i) & (ii): Histogram with theoretical density ##
# Create a sequence of x-values for plotting the theoretical curve.
xs <- seq(min(X), max(X), length.out = 100)

# Overlay the theoretical density curve for N(mu, sigma).
# `dnorm` calculates the probability density function (PDF).
# We use prob = TRUE to ensure the histogram shows density rather than raw frequencies.
hist(X, prob = TRUE, main = "Histogram with Theoretical Normal Density", xlab = "x")
lines(xs, dnorm(xs, mu, sigma), col = "blue", lwd = 2)


#### Question (e) ####
# Plot the Empirical Cumulative Distribution Function (ECDF).

# Define a function to calculate the ECDF at a point x.
empdist <- function(x) {
  mean(X <= x)
}

# Apply this function to all points in our x-sequence `xs`.
# Using `sapply` instead of `lapply` to return a numeric vector, which `plot()` handles perfectly.
empdistX <- sapply(xs, empdist) 

# Plot the ECDF and overlay the theoretical CDF.
# `pnorm` calculates the cumulative distribution function (CDF).
plot(xs, empdistX, type = 'l', col = "red", main = "Empirical vs. Theoretical CDF", xlab = "x", ylab = "Probability")
lines(xs, pnorm(xs, mu, sigma), col = "blue", lty = 2, lwd = 2)
legend("topleft", legend = c("Empirical", "Theoretical"), col = c("red", "blue"), lty = 1:2)


#### Question (f) ####
# Visualize the Central Limit Theorem (CLT).

# Function to generate M sample means, each from a sample of size N.
sample_m_means <- function(M) {
replicate(M, mean(rnorm(N, mean = mu, sd = sigma)))
}

par(mfrow = c(2, 1))

for (M in c(100, 1000)) {
  sample_means <- sample_m_means(M)

  hist(
    sample_means,
    probability = TRUE,
    main = paste("Distribution of sample means (M =", M, ")"),
    xlab = "Sample mean"
  )

  curve(
    dnorm(x, mean = mu, sd = sigma / sqrt(N)),
    add = TRUE,
    col = "blue",
    lwd = 2
  )
}

par(mfrow = c(1, 1))

#### Question (g) ####
# Numerical verification of Stein's Identity: E[X*f(X)] = E[f'(X)]

# --- Case 1: f(x) = e^x, so f'(x) = e^x ---
# We check if the sample mean of X*exp(X) is close to the sample mean of exp(X).
cat("Case 1 (e^x) - E[X*f(X)]:", mean(X * exp(X)), "\n")
cat("Case 1 (e^x) - E[f'(X)]:", mean(exp(X)), "\n\n")

# --- Case 2: f(x) = sin(x), so f'(x) = cos(x) ---
# We check if the sample mean of X*sin(X) is close to the sample mean of cos(X).
cat("Case 2 (sin) - E[X*f(X)]:", mean(X * sin(X)), "\n")
cat("Case 2 (sin) - E[f'(X)]:", mean(cos(X)), "\n\n")

# --- Plot the convergence of the estimators as a function of n ---
# Generate a much larger sample to see the convergence clearly.
N_large <- 200000
Xs <- rnorm(N_large)
expXs <- exp(Xs)

# Calculate the running mean for the left-hand side of the identity: E[X*f(X)]
res1 <- cumsum(Xs * expXs) / (1:N_large)
# Calculate the running mean for the right-hand side of the identity: E[f'(X)]
res2 <- cumsum(expXs) / (1:N_large)

# Plot the two running means against log(n) to see convergence.
# They should converge to the same value as n -> infinity.
plot(log(1:N_large), res1, type = 'l', col = "red",
     main = "Convergence for Stein's Identity (f(x)=exp(x))",
     xlab = "log(n)", ylab = "Estimated Value")
lines(log(1:N_large), res2, col = "blue")
legend("topleft", legend = c("E[X*exp(X)]", "E[exp(X)]"), col = c("red", "blue"), lty = 1)
