#########################
########## 5.7 ##########
#########################
library(ggplot2)
library(tidyr)
library(dplyr)

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
N <- 1
deltaT <- 0.001
integrand <- DiscreteBrownianMotionGenerator(deltaT, N, seed = 2026)
integrator <- DiscreteBrownianMotionGenerator(deltaT, N, seed = 2026)

ito_sum_path <- function(integrand, integrator){
  increments <- diff(integrator |> as.vector())

  #Gets every points except the last - not needed
  summand <- integrand[-length(integrand)]

  res <- c(0, cumsum(summand * increments))
  attr(res, "times") <- attr(integrand, "times")
  return(res)
}

path1 <- ito_sum_path(integrand, integrator)
path1 <- as.data.frame(path1) |> mutate(times = attr(path1, "times"))

ggplot(path1, aes(x = times, y = path1)) +
  geom_line()


#...just read solution from here on