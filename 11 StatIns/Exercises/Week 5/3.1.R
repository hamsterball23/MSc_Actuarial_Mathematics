###################################
########## Practical 3.1 ##########
###################################
library(dplyr)
library(tidyr)
library(ggplot2)
library(tibble)

FDistBurr <- function(x, beta = 1, eta = 2, theta = 1)
{
  1 - (1 + (x/theta)^eta)^(-beta)
}

FSurvInvBurr <- function(u, beta = 1, eta = 2, theta = 1)
{
  theta * (u^(-1/beta) - 1)^(1/eta)
}

set.seed(2025)
SampUni <- runif(1000)
SampleBurr <- FSurvInvBurr(SampUni)

###########################
############ a ############
###########################
OrderStatistics <- sort(SampleBurr)

HillEstimator <- function(k, n, vec)
{
  mean(log(vec[seq(n-k+1, n, by = 1)]/vec[n-k]))
}

###########################
############ b ############
###########################
plot_data <- data.frame(
    k = 1:999
  ) |> 
  rowwise() |>
  mutate(
    HillEst = HillEstimator(k, n = length(OrderStatistics), vec = OrderStatistics)
  )

ggplot(plot_data |> filter(k <= 500), aes(x = k, y = HillEst)) +
  geom_point(size = 0.5) +
  geom_line() +
  geom_hline(yintercept = 0.5, color = "blue")

#Maybe lets try where k = 200
k_chosen <- 200
HillEstimator(k_chosen, length(OrderStatistics), OrderStatistics) # 0.5243
#is varying about until the bias term blows up the estimate

#We remember that the Burr distribution had tail index 1/(eta*beta) = 0.5, which is close 

#Lets try a normal distributed value
set.seed(2026)
SampleNorm <- rnorm(1000)
OrderStatNorm <- SampleNorm[SampleNorm > 0] |> sort()


plot_data_norm <- data.frame(
    k = 1:(length(OrderStatNorm)-1)
  ) |>
  rowwise() |>
  mutate(
    HillEst = HillEstimator(k, n = length(OrderStatNorm), OrderStatNorm)
  )

ggplot(plot_data_norm |> filter(k <= 500), aes(x = k, y = HillEst)) +
  geom_point(size = 1) +
  geom_line()

#There seems only to be a bias term - would set the hill estimate to zero?

#This is true because the normal distribution is in the Gumbel domian of attraction with tail index 0

###########################
############ c ############
###########################
emp_mean_excess <- function(u, vec) {
  excesses <- vec[vec > u] - u
  if (length(excesses) == 0) return(NA)
  return(mean(excesses))
}

plot_data_emp_mean_excess <- tibble(
    u = seq(0, quantile(SampleBurr, 0.99), length.out = 200),
    e_Burr = sapply(u, emp_mean_excess, vec = SampleBurr),
    e_Norm = sapply(u, emp_mean_excess, vec = SampleNorm)
  ) |> pivot_longer(
    cols = c(e_Burr, e_Norm),
    values_to = "value",
    names_to = "color"
  )

ggplot(plot_data_emp_mean_excess, aes(x = u, y = value, color = color)) +
  geom_line() +
  geom_function(fun = function(x) {(pi/2 - atan(x))*(1+x**2)}, linetype = "dashed") +
  geom_function(fun = function(x) {ifelse(x < 2.5, NA,1/x)}, linetype = "dashed")

###########################
############ d ############
###########################
#We use Weissmann estimator
Weissman <- function(p, k, vec){
  n <- length(vec)
  ((1-p)*n/k)**(-HillEstimator(k,n,vec))*vec[n-k]
}

#Use approximation log(tilde(Q)/Q - 1) = log(tilde(Q)) - log(Q)
WeissmanCI <- function(p, k, vec, alpha = 0.05) {
  n <- length(vec)
  q <- Weissman(p, k, vec)
  h <- qnorm(1 - alpha/2) * HillEstimator(k, n, vec) * log(k / (n * (1 - p))) / sqrt(k)
  c(lowerCI = q * exp(-h), estimate = q, upperCI = q * exp(h))
}

results_d <- tibble(
    p = c(0.90, 0.99, 0.9999)
  ) |> 
  rowwise() |>
  mutate(
    TrueQ =  FSurvInvBurr(1-p)
  ) |>
  mutate(
    WeissmannQ = Weissman(p = p, k = k_chosen, vec = OrderStatistics)
  ) |>
  mutate(
    WeissmannCI = list(WeissmanCI(p = p, k_chosen, vec = OrderStatistics, alpha = 0.05))
  ) |>
  ungroup() |>
  unnest_wider(WeissmannCI) |> select(-estimate)

(results_d)

###########################
############ e ############
###########################
results_e <- results_d |> 
  rowwise() |>
  mutate(
    EmpQ = quantile(OrderStatistics, p, type = 1)
  )

(results_e)
