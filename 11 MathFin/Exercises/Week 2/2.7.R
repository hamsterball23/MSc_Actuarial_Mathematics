#########################
########## 2.7 ##########
#########################
library(ggplot2)

DiscreteBrownianMotionGenerator <- function(deltaT, N, a = 0, b = 1, seed = 2026)
{
  set.seed(seed)

  nGrid <- (b - a) / deltaT

  if (abs(nGrid - round(nGrid)) > 1e-8)
  {
    stop("deltaT should divide b - a evenly")
  }

  nGrid <- round(nGrid) #Makes it an integer

  res <- matrix(NA_real_, nrow = N, ncol = nGrid + 1)

  res[, 1] <- rep(0, length = N)

  for (i in 1:nrow(res))
  {
    gaussianVec <- rnorm(nGrid, mean = 0, sd = 1)

    # B_{t_i} = B_{t_{i-1}} + sqrt(deltaT) * z_i, so B_{t_i} = sqrt(deltaT) * cumsum(z_1, ..., z_i)
    res[i, 2:(nGrid + 1)] <- cumsum(sqrt(deltaT) * gaussianVec)
  }

  # Column j holds B_{t} at time t = times[j], so columns can be looked up by time
  times <- seq(a, b, by = deltaT)
  colnames(res) <- times
  attr(res, "times") <- times

  return(res)
}

# Total variation V_k and quadratic variation Q_k of a path `p` (on a grid of
# spacing 2^-kMax over [0,1]) along the uniform partitions pi_k, k = 1, ..., kMax
computeVariations <- function(p, kMax)
{
  Vk <- numeric(kMax)
  Qk <- numeric(kMax)

  for (k in 1:kMax)
  {
    # pi_k = {t_i^k = i / 2^k, i = 0, ..., 2^k}: every stepIndex-th point of the
    # 2^-kMax grid, since t_i^k / 2^-kMax = i * 2^(kMax - k) is an integer index
    stepIndex <- 2^(kMax - k)
    pOnPartition <- p[seq(1, length(p), by = stepIndex)]

    increments <- diff(pOnPartition)

    Vk[k] <- sum(abs(increments))
    Qk[k] <- sum(increments^2)
  }

  return(data.frame(k = 1:kMax, V_k = Vk, Q_k = Qk))
}

# ----- a) -----
samples <- list(
  T0.1 = DiscreteBrownianMotionGenerator(deltaT = 0.1, N = 10000),
  T0.01 = DiscreteBrownianMotionGenerator(deltaT = 0.01, N = 10000),
  T0.001 = DiscreteBrownianMotionGenerator(deltaT = 0.001, N = 10000)
)

summaryStats <- matrix(NA_real_, nrow = length(samples), ncol = 2)

for (i in 1:length(samples))
{
  sample <- samples[[i]]

  B1s <- sample[,ncol(sample)]

  # (i)
  print(paste("Calculating sample mean and variance for B_1 for ", names(samples)[i]))
  summaryStats[i, 1] <- mean(B1s)
  summaryStats[i, 2] <- var(B1s)
  print(paste("Sample mean for endpoints B1: ", summaryStats[i, 1]))
  print(paste("Sample variance for endpoints B1: ", summaryStats[i, 2]))

  # (ii)
  p <- ggplot(data = data.frame(B1 = B1s), aes(x = B1)) +
    geom_histogram(aes(y = after_stat(density)), bins = 50, colour = "black", fill = "grey80") +
    stat_function(fun = dnorm, colour = "red", linewidth = 1) +
    labs(title = paste0("Density of B_1 (deltaT = ", names(samples)[i], ")"),
         x = expression(B[1]), y = "Density")

  print(p)
}

# ----- b) -----
kMax <- 20
highResolutionBrownianPath <- DiscreteBrownianMotionGenerator(deltaT = 2**(-kMax), N = 1)
path <- as.numeric(highResolutionBrownianPath[1, ]) # path[i + 1] = B_{i * 2^-kMax}

variationDF <- computeVariations(path, kMax) # (i) V_k in $V_k column, (iii) Q_k in $Q_k column

# (ii) total variation should blow up as k grows (Brownian paths have infinite variation)
ggplot(variationDF, aes(x = k, y = V_k)) +
  geom_line() + geom_point() +
  labs(title = "Total variation of a simulated Brownian path",
       x = "k", y = expression(V[k]))

# (iv) quadratic variation should converge to the length of the interval, 1
ggplot(variationDF, aes(x = k, y = Q_k)) +
  geom_line() + geom_point() +
  geom_hline(yintercept = 1, linetype = "dashed", colour = "red") +
  labs(title = "Quadratic variation of a simulated Brownian path",
       x = "k", y = expression(Q[k]))

# ----- c) -----
nPaths_c <- 5
deltaT_c <- 0.001
mu_pos <- 2
mu_neg <- -2

# (i) five sample Brownian paths, generated once and reused below
fivePaths <- DiscreteBrownianMotionGenerator(deltaT = deltaT_c, N = nPaths_c)
times_c <- attr(fivePaths, "times")

# Reshape an N x (nGrid+1) path matrix into a long data frame for ggplot
matrixToLongDF <- function(mat, times, process)
{
  data.frame(
    path = factor(rep(1:nrow(mat), times = ncol(mat))),
    time = rep(times, each = nrow(mat)),
    value = as.vector(mat),
    process = process
  )
}

bmDF <- matrixToLongDF(fivePaths, times_c, "Brownian motion")

# (ii) same five paths, with drift added: X_t = B_t + mu * t
driftPosPaths <- sweep(fivePaths, 2, mu_pos * times_c, "+")
driftNegPaths <- sweep(fivePaths, 2, mu_neg * times_c, "+")

driftPosDF <- matrixToLongDF(driftPosPaths, times_c, "Drift (mu = 2)")
driftNegDF <- matrixToLongDF(driftNegPaths, times_c, "Drift (mu = -2)")

# (iii) same five paths, as Brownian bridges: b_t = B_t - t * B_1
B1_c <- fivePaths[, ncol(fivePaths)]
bridgePaths <- fivePaths - outer(B1_c, times_c)

bridgeDF <- matrixToLongDF(bridgePaths, times_c, "Brownian bridge")

# (iv) compare all four side by side; each panel uses the *same* underlying
# randomness (same colour = same path), so only the construction differs
allProcessesDF <- rbind(bmDF, driftPosDF, driftNegDF, bridgeDF)
allProcessesDF$process <- factor(allProcessesDF$process,
  levels = c("Brownian motion", "Drift (mu = 2)", "Drift (mu = -2)", "Brownian bridge"))

ggplot(allProcessesDF, aes(x = time, y = value, colour = path)) +
  geom_line() +
  facet_wrap(~ process, nrow = 2) +
  labs(title = "Five Brownian paths and derived processes",
       x = "t", y = "Value", colour = "Path") +
  theme(legend.position = "bottom")

# ----- Remark: repeat the variation analysis from b) for drift and bridge -----
# Reuse the single high-resolution path from b), turned into a drift and a
# bridge path, and compare their V_k / Q_k against plain Brownian motion.
times_fine <- attr(highResolutionBrownianPath, "times")
driftPath <- path + mu_pos * times_fine
bridgePath <- path - times_fine * path[length(path)]

remarkDF <- rbind(
  cbind(computeVariations(path, kMax), process = "Brownian motion"),
  cbind(computeVariations(driftPath, kMax), process = "Drift (mu = 2)"),
  cbind(computeVariations(bridgePath, kMax), process = "Brownian bridge")
)

# Total variation: drift/bridge are BM plus a smooth (finite-variation) term,
# so all three still blow up like BM's V_k as k grows
ggplot(remarkDF, aes(x = k, y = V_k, colour = process)) +
  geom_line() + geom_point() +
  labs(title = "Total variation: Brownian motion vs. drift vs. bridge",
       x = "k", y = expression(V[k]), colour = "Process")

# Quadratic variation: adding a smooth drift or subtracting a linear term
# doesn't change the quadratic variation, so all three still converge to 1
ggplot(remarkDF, aes(x = k, y = Q_k, colour = process)) +
  geom_line() + geom_point() +
  geom_hline(yintercept = 1, linetype = "dashed", colour = "black") +
  labs(title = "Quadratic variation: Brownian motion vs. drift vs. bridge",
       x = "k", y = expression(Q[k]), colour = "Process")

