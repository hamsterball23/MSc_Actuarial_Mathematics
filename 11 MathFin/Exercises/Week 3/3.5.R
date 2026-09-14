#########################
########## 3.5 ##########
#########################
library(ggplot2)

#From 2.7.R
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

#####  a  ##### 

SBMMotionGenerator <- function(deltaT, N, a = 0, b = 10, seed = 2026)
{
  set.seed(seed)

  nGrid <- (b - a) / deltaT

  if (abs(nGrid - round(nGrid)) > 1e-8)
  {
    stop("deltaT should divide b - a evenly")
  }

  nGrid <- round(nGrid) #Makes it an integer


  BM_paths <- DiscreteBrownianMotionGenerator(deltaT, N, a, b, seed)

  expBM <- exp(BM_paths)

  multiplicativeFactor <- exp(-seq(a, b, by = deltaT)/4)

  # Scale each column (time point) by its factor -- expBM * multiplicativeFactor
  # would recycle the vector down columns instead of across them.
  return(sweep(expBM, 2, multiplicativeFactor, "*"))
}

#(a)(i)
S_paths <- SBMMotionGenerator(deltaT = 0.01, N = 10, a = 0, b = 10)

df <- data.frame(
  t = as.numeric(rep(colnames(S_paths), each = nrow(S_paths))),
  path = factor(rep(1:nrow(S_paths), ncol(S_paths))),
  S = as.vector(S_paths)
)

ggplot(df, aes(x = t, y = S, color = path)) +
  geom_line() +
  labs(x = "t", y = expression(S[t]), title = "Ten sample paths of S on [0, 10]") +
  theme_minimal()


#(a)(ii)
S_paths_10000 <- SBMMotionGenerator(0.01, 10000)
S10Data <- S_paths_10000[,ncol(S_paths_10000)]

plot_data <- data.frame(
  x = S10Data
)

ggplot(plot_data, aes(x = x)) +
  geom_histogram(aes(y = ..density..), alpha = 0.2) +
  geom_vline(xintercept = exp(10/4)) +
  xlim(0,20) #one observation at 4534 is very extreme


#Emperical estimate
mean(S10Data)

#Theoretical value 
exp(10*1/4)

#Variance of the distribution is extreme so we would expect big confidence intervals
SD <- (exp(10)-1)*exp(-2*10*1/4 + 10) |> sqrt()

confidence_int <- exp(10*1/4) + c(-1,1)*SD/sqrt(10000)
(confidence_int) #Crazy big


#####  b and c ##### 
N <- 100000
Data01 <- DiscreteBrownianMotionGenerator(0.1, N)
barB1_01 <- apply(Data01, 1, max)

Data001 <- DiscreteBrownianMotionGenerator(0.01, N)
barB1_001 <- apply(Data001, 1, max)

plot_data_barB1 <- data.frame(
  sim = factor(rep(c("0.1", "0.01"), each = N), levels = c("0.1", "0.01")),
  barB1 = append(barB1_01, barB1_001)
)

#Theoretical distribution of abs(B1)
theoretical_norm_dis <- function(x){ dnorm(x) + dnorm(-x)}

ggplot(plot_data_barB1, aes(x=barB1, fill = sim)) +
  geom_histogram(aes(y = ..density..)) +
  geom_function(fun = theoretical_norm_dis, linetype = "dashed") +
  facet_wrap(~sim)


##### d, e and f #####
N <- 10000
HitVal <- 1
get_hitting_time_idx <- function(vec) { 
  idx <- which(vec >= HitVal)[1] 
  return( ifelse(idx |> is.na(), length(vec), idx) )
}

Data01_10 <- DiscreteBrownianMotionGenerator(0.1, N, a = 0, b = 10)
HitTimes01_10 <- attr(Data01_10, "times")[apply(Data01_10, 1, get_hitting_time_idx)]
(HitTimes01_10)

Data001_10 <- DiscreteBrownianMotionGenerator(0.01, N, a = 0, b = 10)
HitTimes001_10 <- attr(Data001_10, "times")[apply(Data001_10, 1, get_hitting_time_idx)]
(HitTimes001_10)

plot_data_hit_times <- data.frame(
  deltaT = rep(c("0.1", "0.01"), each = N),
  T = append(HitTimes01_10, HitTimes001_10)
)

# d
ggplot(plot_data_hit_times, aes(x = T, fill = deltaT)) +
  geom_histogram(aes(y = ..density..)) +
  facet_wrap(~deltaT)

# e
mean(HitTimes001_10) #4.2937

# f
mean(HitTimes001_10 == 10) #26.2 %


##### g and h #####
#A two-dimensional Brownian motion consists of two independent BMs
xBM <- DiscreteBrownianMotionGenerator(0.001, 1, a = 0, b = 1, seed = 123)[1,]
yBM <- DiscreteBrownianMotionGenerator(0.001, 1, a = 0, b = 1, seed = 1234)[1,]
t <- seq(0,1, 0.001)


plot_trace <- data.frame(
  t = t,
  x = xBM,
  y = yBM
)

# g
ggplot(plot_trace, aes(x = x, y = y, color = t)) +
  geom_path(linewidth = 0.5) +
  coord_fixed() +
  labs(
    x = expression(B[1](t)),
    y = expression(B[2](t)),
    color = "Time"
  )

# h
plotter <- function(rho)
{
  W <- sqrt(1-rho**2) * xBM + rho * yBM

  plot_trace_internal <- data.frame(
    t = t,
    x = W,
    y = yBM
  )

  ggplot(plot_trace_internal, aes(x = x, y = y, color = t)) +
    geom_path(linewidth = 0.5) +
    coord_fixed() +
    labs(
      x = expression(W[1](t)),
      y = expression(B[2](t)),
      color = "Time"
    )
}

plotter(0.7) #Positive correlation - higher B2 correlates with higher W1
plotter(-0.7) #Negative correlation - higher B2 correlates with lower W1
