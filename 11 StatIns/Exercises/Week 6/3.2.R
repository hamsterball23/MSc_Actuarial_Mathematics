###################################
########## Practical 3.2 ##########
###################################
library(ggplot2)
library(tidyr)
library(dplyr)
library(CASdatasets)

data(beaonre, package = "CASdatasets")

OrderStatisitics <- beaonre$ClaimCost |> sort()

#########
### a ###
#########
HillEstimator <- function(k, vec)
{
  n <- length(vec)
  mean(log(vec[seq(n-k+1, n, by = 1)]/vec[n-k]))
}

plot_data <- data.frame(
    k = seq(1, length(OrderStatisitics) - 1, by = 1)
  ) |> 
  rowwise() |> 
  mutate(
    HillEst = HillEstimator(k, OrderStatisitics)
  )

ggplot(plot_data, aes(x = k, y = HillEst)) +
  geom_line(size = 0.3) +
  geom_vline(xintercept = (length(plot_data$HillEst)+1)/5, linetype = "dashed", color = "blue", alpha = 0.3) +
  geom_hline(yintercept = 1.7, linetype = "dashed", color = "red", alpha = 0.5) +
  labs(
    x = "k",
    y = "Hill estimator, gamma_{n,k}",
    title = "Hill estimator as function of k"
  ) 

#It looks like that there is a stable region around k = n/5, or where gamma is 1,7


#########
### b ###
#########

SingleBootstrapHillEstimator <- function(OrderStat, SampleSize = 300, kFractionOfN = 1/5)
{
  SampleOrderStat <- sample(OrderStat, SampleSize, replace = TRUE) |> sort()

  HillEstimator(SampleSize * kFractionOfN, SampleOrderStat)
}

GetGammaEstBootstrap <- function(OrderStatisitics, NRepetitions, GammaEst = NA_real_, SampleSize = 300, kFractionOfN = 1/5, seed = 2026)
{
  singleSampler <- function() {SingleBootstrapHillEstimator(OrderStatisitics, SampleSize = SampleSize, kFractionOfN = kFractionOfN)}
  
  set.seed(seed)
  HillEst <- replicate(NRepetitions, singleSampler())

  if (is.na(GammaEst)){
    GammaEst <- mean(HillEst)
  }

  ggplot(data.frame(HillEst = HillEst), aes(x = HillEst)) +
    geom_histogram(aes(y = ..density..), bins = round(sqrt(NRepetitions)) ) +
    geom_function(fun = function(x) dnorm(x = x, mean = GammaEst, sd = GammaEst/sqrt(SampleSize * kFractionOfN)))
}

GetGammaEstBootstrap(
  OrderStatisitics, 
  GammaEst = 1.7, #Taken from a)
  NRepetitions = 1000, 
  SampleSize = 300
)


GetGammaEstBootstrap(
  OrderStatisitics, 
  GammaEst = NA_real_, #Takes it from the sample
  NRepetitions = 100000, 
  SampleSize = 300
)
