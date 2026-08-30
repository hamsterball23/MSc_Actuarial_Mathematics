library(ggplot2)
library(tidyr)

# ---------------------------------------------------------------------------
# Problem 1.5(a)-(f): Monte Carlo approximation of E[X], g(x) = x throughout
# ---------------------------------------------------------------------------

MonteCarloApprox <- function(
  seed,
  N = 1000,
  M = c(100, 1000),
  Mean = 0,
  Sd = 1
) {

  dXdist = function(x) dnorm(x, mean = Mean, sd = Sd)
  pXdist = function(q) pnorm(q, mean = Mean, sd = Sd)
  rXdist = function(n) rnorm(n, mean = Mean, sd = Sd)
  set.seed(seed)

  # b) sample X
  vec <- rXdist(N)

  # c) running sample mean and variance
  runningMean <- cumsum(vec) / seq_along(vec)

  runningVar <- rep(NA_real_, N) # need n >= 2
  for (n in 2:N) {
    runningVar[n] <- sum((vec[1:n] - runningMean[n])^2) / (n - 1)
  }

  plotSampleMean <- ggplot(data.frame(n = seq_along(runningMean), mean = runningMean),
                            aes(x = n, y = mean)) +
    geom_line() +
    geom_hline(yintercept = Mean, color = "red", linetype = "dashed") +
    geom_point(size = 0.5) +
    labs(x = "n", y = expression(bar(x)[n]), title = "Running sample mean of X")

  plotSampleVar <- ggplot(data.frame(n = seq_along(runningVar), var = runningVar),
                           aes(x = n, y = var)) +
    geom_line() +
    geom_hline(yintercept = Sd, color = "red", linetype = "dashed") +
    geom_point(size = 0.5) +
    labs(x = "n", y = expression(hat(sigma)[n]^2), title = "Running sample variance of X")

  # d) density histogram of X vs the theoretical density of X
  plotDensity <- ggplot(data.frame(x = vec), aes(x = x)) +
    geom_histogram(aes(y = after_stat(density)), bins = 30, colour = "black", fill = "grey80") +
    stat_function(fun = dXdist, colour = "red", linewidth = 1) +
    labs(title = "Empirical vs theoretical density of X")

  # e) empirical vs theoretical distribution function of X
  empDistFunc <- function(t) sapply(t, function(tt) mean(vec <= tt))

  plotDistFunc <- ggplot(data.frame(x = c(-4, 4)), aes(x = x)) +
    geom_function(fun = empDistFunc, colour = "black") +
    geom_function(fun = pXdist, colour = "red", linetype = "dashed") +
    labs(title = "Empirical vs theoretical CDF of X")

  # f) distribution of the sample mean, for each choice of M
  sampleMeanPlots <- vector("list", length(M))
  maxWidth <- 0.00000001
  
  for (i in seq_along(M)) {
    Mchoice <- M[i]
    newVec  <- rXdist(Mchoice * N)

    independentSampleMeans <- numeric(Mchoice)
    for (j in seq_len(Mchoice)) {
      independentSampleMeans[j] <- mean(newVec[((j - 1) * N + 1):(j * N)])
    }

    maxWidth <- max(maxWidth, quantile(independentSampleMeans, probs = c(0.999)))

    # Exact density of the sample mean: X ~ N(0,1), so the mean of N iid
    # draws is exactly N(0, 1/N) -- no need to approximate.
    p <- ggplot(data.frame(m = independentSampleMeans), aes(x = m)) +
      geom_histogram(aes(y = after_stat(density)), bins = 30, colour = "black", fill = "grey80") +
      stat_function(fun = function(m) dnorm(m, mean = 0, sd = 1 / sqrt(N)),
                    colour = "red", linetype = "dashed", linewidth = 1) +
      labs(title = paste0("Sample means of X, M = ", Mchoice, ", N = ", N)) +
      xlim(c(-maxWidth, maxWidth))

    sampleMeanPlots[[i]] <- p
  }

  list(
    plotSampleMean  = plotSampleMean,
    plotSampleVar   = plotSampleVar,
    plotDensity     = plotDensity,
    plotDistFunc    = plotDistFunc,
    sampleMeanPlots = sampleMeanPlots
  )
}

# first run
firstRun <- MonteCarloApprox(
  seed = 2026,
  N = 1000,
  M = 10**seq(2,4)
)

# print everything
print(firstRun$plotSampleMean)
print(firstRun$plotSampleVar)
print(firstRun$plotDensity)
print(firstRun$plotDistFunc)
for (p in firstRun$sampleMeanPlots) print(p) 
#Clearly the histogram resembles the N(0,1/N) distribution far better for bigger N


# ---------------------------------------------------------------------------
# Problem 1.5(g): Stein's identity, illustrated numerically
# ---------------------------------------------------------------------------
# Stein's identity (1.1(b)): for X ~ N(0,1),  E[X f(X)] = E[f'(X)].
# We estimate both sides by Monte Carlo and watch them converge.

steinIdentity <- function(f, fprime, N = 10000, seed = 2026, plot = TRUE) {
  set.seed(seed)
  x <- rnorm(N)

  runningLHS <- cumsum(x * f(x)) / seq_len(N)   # estimate of E[X f(X)]
  runningRHS <- cumsum(fprime(x)) / seq_len(N)  # estimate of E[f'(X)]

  cat("E[X f(X)] approx:", round(tail(runningLHS, 1), 4), "\n")
  cat("E[f'(X)]  approx:", round(tail(runningRHS, 1), 4), "\n\n")

  if (plot) {
    df <- data.frame(n = seq_len(N), LHS = runningLHS, RHS = runningRHS)
    df <- pivot_longer(df, cols = c(LHS, RHS), names_to = "side", values_to = "value")
    print(
      ggplot(df, aes(x = n, y = value, colour = side)) +
        geom_line() +
        labs(title = "Stein's identity: E[Xf(X)] vs E[f'(X)]", y = NULL)
    )
  }

  invisible(list(lhs = tail(runningLHS, 1), rhs = tail(runningRHS, 1)))
}

# f(x) = exp(x), f'(x) = exp(x)
steinIdentity(f = exp, fprime = exp)

# f(x) = sin(x), f'(x) = cos(x)
steinIdentity(f = sin, fprime = cos)

# # f(x) = x**2, f'(x) = 2x
# steinIdentity(f = function(x){x**2}, fprime = function(x){2*x})
