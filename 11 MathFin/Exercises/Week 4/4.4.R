#########################
########## 4.4 ##########
#########################
library(ggplot2)
library(tidyr)

DiscreteBrownianMotionGenerator <- function(deltaT, N, a = 0, b = 1, seed = 2026)
{
  if (!is.na(seed))
  {
    set.seed(seed)
  }

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

#########
### a ###
#########
sim1 <- DiscreteBrownianMotionGenerator(deltaT = 0.001, 1)

plot_data <- data.frame(
  t = sim1 |> attr("times"),
  B = as.vector(sim1)
)

ggplot(plot_data, aes(x = t, y = B)) +
  geom_line(color = "#2C3E50", linewidth = 0.6) +
  labs(
    title = "A simulated Brownian motion path",
    subtitle = expression(paste(Delta, "t = 0.001, t ", "∈", " [0, 1]")),
    x = "t",
    y = expression(B[t])
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

#########
### b ###
#########
RiemannSumApproximator <- function(deltaT, seed = 2026, N = 100000, a = 0, b = 1) {
  simN <- DiscreteBrownianMotionGenerator(deltaT = deltaT, N = N, a = a, b = b, seed = seed)

  RiemannSums <- deltaT * simN |> rowSums()
  attr(RiemannSums, 'mean') <- mean(RiemannSums)
  attr(RiemannSums, 'var') <- var(RiemannSums)
  return(RiemannSums)
}

RiemannSums <- RiemannSumApproximator(deltaT = 0.1, N = 100000)
attr(RiemannSums, 'mean') #0.001159463, should be 0
attr(RiemannSums, 'var') #0.3868746, should be 1/3

ggplot(data.frame(x = RiemannSums), aes(x = x)) +
  geom_histogram(bins = 100, fill = "#4C72B0", color = "white", linewidth = 0.1) +
  geom_vline(
    xintercept = attr(RiemannSums, 'mean'),
    color = "#C0392B", linetype = "dashed", linewidth = 0.7
  ) +
  labs(
    title = "Simulated values of integrated Brownian motion",
    subtitle = expression(paste("Left Riemann sum approximation, ", Delta, "t = 0.1, N = 100,000")),
    x = expression(hat(I)[Delta]),
    y = "Count"
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

#########
### c ###
#########
TrapezoidApproximator <- function(deltaT, seed = 2026, N = 100000, a = 0, b = 1) {
  simN <- DiscreteBrownianMotionGenerator(deltaT = deltaT, N = N, a = a, b = b, seed = seed)

  TrapezoidSums <- deltaT * (rowSums(simN[, 2:(ncol(simN) - 1), drop = FALSE]) + 0.5 * (simN[, 1] + simN[, ncol(simN)]))
  attr(TrapezoidSums, 'mean') <- mean(TrapezoidSums)
  attr(TrapezoidSums, 'var') <- var(TrapezoidSums)
  return(TrapezoidSums)
}
TrapezoudSums <- TrapezoidApproximator(deltaT = 0.1, N = 100000)

#########
### d ###
#########
attr(TrapezoudSums, 'mean') #0.001132829, should be 0
attr(TrapezoudSums, 'var') #0.3342548, should be 1/3

#Variance estimate is numerically more accurate

#########
### e ###
#########

# Numerical-integration formulas applied directly to one already-simulated
# path (a vector of B_t values on an equispaced grid), so the same
# realization can be reused at every deltaT instead of re-simulating.
LeftRiemannFromPath <- function(deltaT, path) {
  n <- length(path)
  deltaT * sum(path[1:(n - 1)]) # left endpoints t_0, ..., t_{n-1}
}

TrapezoidFromPath <- function(deltaT, path) {
  n <- length(path)
  deltaT * (sum(path[2:(n - 1)]) + 0.5 * (path[1] + path[n]))
}

deltaTs <- c(0.1, 0.05, 0.02, 0.01, 0.005)
deltaTRef <- 0.0005

# One fine-grid path: all deltaTs above are integer multiples of deltaTRef,
# so subsampling it gives the SAME path on each coarser grid.
finePath <- DiscreteBrownianMotionGenerator(deltaT = deltaTRef, N = 1, seed = 1234)[1, ]

I_ref <- TrapezoidFromPath(deltaTRef, finePath)

resultsConv <- data.frame(
  'deltaT' = deltaTs,
  'Riemann' = rep(NA_real_, length(deltaTs)),
  'Trapezoid' = rep(NA_real_, length(deltaTs))
)

for (i in seq_along(deltaTs)) {
  step <- round(deltaTs[i] / deltaTRef)

  #chooses a subpath on the finest path to use for the coarser
  subPath <- finePath[seq(1, length(finePath), by = step)]

  resultsConv[i, 'Riemann'] <- LeftRiemannFromPath(deltaTs[i], subPath)
  resultsConv[i, 'Trapezoid'] <- TrapezoidFromPath(deltaTs[i], subPath)
}

absError <- cbind(
  deltaT = resultsConv[,'deltaT'],
  abs(resultsConv[,c('Riemann', 'Trapezoid')] - I_ref)
)
(absError)

absErrorLong <- pivot_longer(
  absError,
  cols = c('Riemann', 'Trapezoid'),
  names_to = "method",
  values_to = "abs_error"
)

ggplot(absErrorLong, aes(x = log(deltaT), y = log(abs_error), color = method)) +
  geom_point(size = 2.5) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 0.7) +
  scale_color_brewer(palette = "Set1") +
  labs(
    title = "Convergence of left Riemann sum vs trapezoidal rule",
    subtitle = "Error against a reference solution on a log-log scale",
    x = expression(log(Delta * t)),
    y = expression(log("|" * hat(I)[Delta] - I[ref] * "|")),
    color = "Method"
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"), legend.position = "bottom")

# Slope of the log-log fit = estimated convergence rate k (error ~ deltaT^k)
coef(lm(log(abs_error) ~ log(deltaT), data = subset(absErrorLong, method == "Riemann")))
coef(lm(log(abs_error) ~ log(deltaT), data = subset(absErrorLong, method == "Trapezoid")))

#Seems that the slope is approximately linear
#Then the absoulute error is propertional to the DeltaT


#########
### f ###
#########

# Matches 4.3(g): (0.5)^2 * (1/2 - 0.5/6) = 1/4 * (1/2 - 1/12) = 1/4 * 5/12 = 5/48
theoCov <- 5/48

s <- 0.5
t <- 1

# (ii) N = 100,000 paths on [0, t] with deltaT = 0.01, trapezoidal rule for
# both int_0^s and int_0^t reusing the SAME simulated paths (s is a multiple
# of deltaT, so the first s/deltaT + 1 columns are exactly the path on [0, s]).
TrapezoidFromMatrix <- function(deltaT, mat) {
  n <- ncol(mat)
  deltaT * (rowSums(mat[, 2:(n - 1), drop = FALSE]) + 0.5 * (mat[, 1] + mat[, n]))
}

deltaTf <- 0.01
simF <- DiscreteBrownianMotionGenerator(deltaT = deltaTf, N = 100000, a = 0, b = t, seed = 2026)

sCols <- round(s / deltaTf) + 1 # columns for r = 0, ..., s

Is <- TrapezoidFromMatrix(deltaTf, simF[, 1:sCols, drop = FALSE])       # int_0^s B_r dr
It <- TrapezoidFromMatrix(deltaTf, simF)                                # int_0^t B_r dr

# (iii) Sample covariance
empCov <- cov(Is, It)

# (iv) Compare
theoCov
empCov
empCov - theoCov

#Empirical covariance should be close to the theoretical 5/48 = 0.1041667,
#with the small discrepancy coming from Monte Carlo sampling error (somewhat order
#1/sqrt(N)) and the trapezoidal discretization bias (order deltaT).


#########
### g ###
#########

# (i) 
# I_t = int_0^t B_s ds needs a VALUE AT EVERY t, not just t = 2, so
# TrapezoidFromMatrix (which collapses each path to one number) isn't enough.
# Instead cumsum the trapezoidal segment between each pair of adjacent grid
# points: I_{t_i} = I_{t_{i-1}} + deltaT/2 * (B_{t_{i-1}} + B_{t_i}), I_0 = 0.
CumulativeTrapezoidFromMatrix <- function(deltaT, mat) {
  segments <- deltaT / 2 * (mat[, -ncol(mat), drop = FALSE] + mat[, -1, drop = FALSE])
  res <- cbind(0, t(apply(segments, 1, cumsum)))
  colnames(res) <- colnames(mat)
  attr(res, "times") <- attr(mat, "times")
  res
}

deltaTf <- 0.01
simG <- DiscreteBrownianMotionGenerator(deltaT = deltaTf, N = 10000, a = 0, b = 2, seed = 2026)

I_t <- CumulativeTrapezoidFromMatrix(deltaTf, simG) # N x length(times) matrix of I_t paths 

# (ii)
Inc1 <- I_t[,0.5/deltaTf + 1] - I_t[, 1]
Inc2 <- I_t[,1.5/deltaTf + 1] - I_t[,1.0/deltaTf + 1]

# (iii)
plot_data_inc <- data.frame(
  nsim <- rep(1:length(Inc1), each = 2),
  nincrement = rep(c('Increment 1', 'Increment 2'), each = length(Inc1)),
  increment = append(Inc1, Inc2)
)

ggplot(plot_data_inc, aes(x = increment, fill = nincrement)) +
  geom_histogram(position = "identity", alpha = 0.6, bins = 100, color = NA) +
  scale_fill_brewer(
    palette = "Set1",
    labels = c(
      expression(I[0.5] - I[0]),
      expression(I[1.5] - I[1.0])
    )
  ) +
  labs(
    title = "Non-stationary increments of integrated Brownian motion",
    subtitle = "Same length (h = 0.5), different starting points",
    x = "Increment size",
    y = "Count",
    fill = "Increment"
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"), legend.position = "bottom")

# (iv)
#In exercise 4.3 (g) I showed that the increment I_t+h - I_t has variance
#equal t*h^2 + h^3/3


#Compare Inc 1
empVarInc1 <- var(Inc1)
teoVarInc1 <- 0 + 0.5**3/3

#Absoulute error
abs(empVarInc1 - teoVarInc1) #0.000657072
#Relative error to teoretical
abs(empVarInc1 - teoVarInc1)/abs(teoVarInc1)*100     # 1.57 %


#Compare Inc 2
empVarInc2 <- var(Inc2)
teoVarInc2 <- 1*0.5**2 + 0.5**3/3

#Absoulute error
abs(empVarInc2 - teoVarInc2) #0.005044052
#Relative error to teoretical
abs(empVarInc2 - teoVarInc2)/abs(teoVarInc2)*100      # 1.72 %

#Clearly this simulation study shows that the increments are not stationary
#and the results corresponds very well with the theoretical values.