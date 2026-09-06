###############
##### 1.3 #####
###############
library(ggplot2)

# ----- a) -----
ExpSampler <- function(n, seed, lambda = 0.5)
{
  set.seed(seed)
  return(rexp(n, rate = lambda))
}

FDist <- function(vec, x) {
  sapply(x, function(xi) mean(vec <= xi))
}

ExpSamplerToFDist <- function(n, seed, lambda = 0.5)
{
  vec <- ExpSampler(n, seed, lambda = lambda)

  FDist_n <- function(x){
    FDist(vec, x)
  }
  attr(FDist_n, "n") <- n

  return(FDist_n)
}

FDistToPlot <- function(FDist, z_low = 0.00001, z_high = 10)
{
  ggplot() +
    xlim(z_low, z_high) +
    geom_function(fun = FDist, colour = "black")
}

# By Theorem 1.22, sqrt(n)(F^(n) - F) converges to B o F, a Brownian bridge
# time-changed by F. Since Var(B(s)) = s(1-s), this gives the pointwise
# asymptotic variance Var(F^(n)(t)) ~ F(t)(1 - F(t)) / n, from which we build
# a 95% CI for F(t) around the empirical distribution F^(n)(t).
FDistToCIBounds <- function(FDist, n, level = 0.95)
{
  z <- qnorm(1 - (1 - level) / 2)

  se <- function(x) sqrt(FDist(x) * (1 - FDist(x)) / n)

  list(
    lower = function(x) pmax(0, FDist(x) - z * se(x)),
    upper = function(x) pmin(1, FDist(x) + z * se(x))
  )
}

# n defaults to the sample size attached to FDist by ExpSamplerToFDist, so
# it only needs to be given explicitly when FDist doesn't carry it.
FDistToPlotWithCI <- function(FDist, n = attr(FDist, "n"), z_low = 0.00001, z_high = 10, level = 0.95, n_points = 500)
{
  if (is.null(n)) stop("n is not attached to FDist; pass n explicitly")

  CI <- FDistToCIBounds(FDist, n, level = level)
  x  <- seq(z_low, z_high, length.out = n_points)
  ci_df <- data.frame(x = x, lower = CI$lower(x), upper = CI$upper(x))

  ggplot() +
    xlim(z_low, z_high) +
    geom_ribbon(data = ci_df, aes(x = x, ymin = lower, ymax = upper), fill = "grey80") +
    geom_line(data = ci_df, aes(x = x, y = lower), colour = "grey45", linetype = "dashed") +
    geom_line(data = ci_df, aes(x = x, y = upper), colour = "grey45", linetype = "dashed") +
    geom_function(fun = FDist, colour = "black")
}

ns <- c(10, 100, 1000)

for (n in ns)
{
  ExpSamplerToFDist(n, 2026) |> FDistToPlotWithCI() |> print()
}



# ----- b) -----
library(e1071)

# By Theorem 1.22, sqrt(n)(F^(n) - F) -> B o F in distribution (l-infinity
# norm). The sup-norm is a continuous functional, so by the continuous
# mapping theorem sqrt(n)*D_n = sqrt(n)*sup_x|F^(n)(x) - F(x)| converges in
# distribution to sup_{t in [0,1]} |B(t)|, the Kolmogorov distribution. We
# simulate its finite-n behaviour and see the histograms stabilise as n grows.
ExpTheoretical <- function(x, lambda = 0.5) {1-exp(-lambda*x)}

RealizationsOfSqrtND_n <- function(FDist, ExpTheoretical, n = attr(FDist, "n"), z_low = 0.00001, z_high = 10, n_points = 2000){
  # Find D_n = sup_x |F_n(x) - F(x)|, approximated on a fine grid over
  # [z_low, z_high] (the empirical CDF's jumps make the true sup exact only
  # at the sample points, but a fine enough grid is indistinguishable here).
  x <- seq(z_low, z_high, length.out = n_points)
  D_n <- max(abs(FDist(x) - ExpTheoretical(x)))

  return(sqrt(n) * D_n)
}

SimulateSqrtND_n <- function(n, reps = 1000, seed_start = 0, lambda = 0.5, ...)
{
  sapply(seq_len(reps), function(i) {
    FDist_i <- ExpSamplerToFDist(n, seed = seed_start + i, lambda = lambda)
    RealizationsOfSqrtND_n(FDist_i, function(x) ExpTheoretical(x, lambda = lambda), ...)
  })
}

# Exact limit density: sup_{t in [0,1]} |B(t)| has CDF
# P(K <= z) = 1 - 2 sum_{k=1}^inf (-1)^(k-1) exp(-2 k^2 z^2), z > 0
# (the Kolmogorov distribution). Differentiating term-by-term gives its density.
KolmogorovDensity <- function(z, k_max = 1000)
{
  sapply(z, function(zi) {
    if (zi <= 0) return(0)
    k <- 1:k_max
    8 * zi * sum((-1)^(k - 1) * k^2 * exp(-2 * k^2 * zi^2))
  })
}

# Simulation-based alternative: draw sup|B(t)| directly from realised
# Brownian bridge paths via e1071::rbridge().
SimulateBridgeSup <- function(reps = 1000, freq = 1000, seed = 2026)
{
  replicate(reps, max(abs(e1071::rbridge(end = 1, frequency = freq))))
}

bridge_sup <- SimulateBridgeSup(seed = 2026)

for (n in ns)
{
  sqrtnDn <- SimulateSqrtND_n(n)
  x_max <- max(sqrtnDn, bridge_sup) * 1.05

  p <- ggplot(data.frame(sqrtnDn = sqrtnDn), aes(x = sqrtnDn)) +
    geom_histogram(aes(y = after_stat(density)), bins = 25, fill = "grey80", colour = "grey45") +
    geom_density(data = data.frame(x = bridge_sup), aes(x = x, colour = "Simulated (rbridge)"), linewidth = 1, key_glyph = "path") +
    stat_function(fun = KolmogorovDensity, aes(colour = "Exact limit density"), linewidth = 1) +
    scale_colour_manual(name = NULL, values = c("Exact limit density" = "firebrick", "Simulated (rbridge)" = "steelblue")) +
    xlim(0, x_max) +
    labs(title = paste0("n = ", n), x = expression(sqrt(n) * D[n]), y = "Density")

  print(p)
}


