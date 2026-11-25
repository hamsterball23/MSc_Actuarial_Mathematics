###################################
########## Practical 7.3 ##########
###################################

#########
### a ###
#########

# Exponential 
# The hazard rate of an exponential is clearly the lambda parameter (1 / mean)
# which is a constant because, P(X>x)=exp(-lambda*t)=exp(-int_0^t lambda dt)
haz_exp <- function(x, lambda)(lambda)

# Weibull
# Note the survival function S of a Weibull distribution is given by
# S(t) = exp(-(t/lambda)^k)
# The recognize int_0^t lambda(s) ds = (t/lambda)^k sp by Fundamental Law of Calculus
# we have lambda(t) = k (t/lambda)^{k-1} * 1/lambda = (k/lambda) * (t/lambda)^{k-1}
haz_wei <- function(x, lambda, k) {(k/lambda)*(x/lambda)^(k-1)}

#########
### b ###
#########

LogRankTest <- function(
  repetitions,
  n_each,
  A_sampler,
  B_sampler,
  seed,
  alpha = 0.05
){
  LogRankTestStatistics <- vector("numeric", repetitions)

  set.seed(seed)
  for (i in 1:repetitions){
    #Not observed
    Z_A <- A_sampler(n_each)
    Z_B <- B_sampler(n_each)
    C_A <- A_sampler(n_each)
    C_B <- B_sampler(n_each)

    #Observable quantities
    W_A <- pmin(Z_A, C_A)
    W_B <- pmin(Z_B, C_B)
    delta_A <- (Z_A <= C_A)
    delta_B <- (Z_B <= C_B)

    total_sample <- c(W_A, W_B)

    #Unique times (a.s. merely all times, because continuous distributions)
    times <- sort(unique(total_sample))

    #Quantities used

    Y_A <- sapply(times, function(t) sum(W_A >= t))
    Y_B <- sapply(times, function(t) sum(W_B >= t))
    Y <- Y_A + Y_B

    d_A <- sapply(times, function(t) sum(delta_A*(W_A == t)))
    d_B <- sapply(times, function(t) sum(delta_B*(W_B == t)))
    d <- d_A + d_B

    #Parameters of the hypergeometric distributions
    E_A <- d * (Y_A / Y)
    v_A <- ifelse(Y > 1, d * ( (Y_A*Y_B)/(Y**2) ) * ( (Y - d)/(Y - 1) ), 0)

    #Not used but is the distributional quantities
    # E_B <- d*(Y_B / Y)
    # v_B = d * ( (Y_B*Y_A)/(Y**2) ) * ( (Y - d)/(Y - 1) )

    U_LR <- sum(d_A - E_A)
    V_LR <- sum(v_A)

    LogRankTestStatistics[i] <- U_LR / sqrt(V_LR)
  }

  rejects_idx <- (abs(LogRankTestStatistics) > qnorm(1-alpha /2))

  accept <- LogRankTestStatistics[!rejects_idx]
  reject <- LogRankTestStatistics[rejects_idx]

  no_accepts <- sum(!rejects_idx)
  no_rejects <- sum(rejects_idx)

  rejection_frequency <- no_rejects / repetitions

  return(
    list(
      LogRankTestStatistics = LogRankTestStatistics,
      rejection_frequency = rejection_frequency,
      accepted_values = accept,
      no_accepts = no_accepts,
      rejected_values = reject,
      no_rejects = no_rejects
    )
  )
}

#########
### i ###
#########
experiment_i <- LogRankTest(
  repetitions = 500,
  n_each = 1000, 
  A_sampler = function(n) {rexp(n, rate = 2)},
  B_sampler = function(n) {rexp(n, rate = 2)},
  seed = 2026,
  alpha = 0.05
)
experiment_i$rejection_frequency #0.032 (16/500), which is close to expected of 0.05

##########
### ii ###
##########

hazards_for_population_B <- c(2.1, 2.2, 2.3, 2.4)
emp_rejection_freqs <- rep(NA_real_, length.out = length(hazards_for_population_B))
names(emp_rejection_freqs) <- hazards_for_population_B |> as.character()

seed <- 2027
for (i in seq_along(hazards_for_population_B)){
  hazB <- hazards_for_population_B[i]

  emp_rejection_freqs[i] <- LogRankTest(
    repetitions = 500,
    n_each = 1000, 
    A_sampler = function(n) {rexp(n, rate = 2)},
    B_sampler = function(n) {rexp(n, rate = hazB)},
    seed = seed,
    alpha = 0.05
  )$rejection_frequency
  seed <- seed + 1
}

(emp_rejection_freqs)
#   2.1   2.2   2.3   2.4 
# 0.112 0.280 0.614 0.786 

#Clearly small differences leads to fewer emperical rejections, compared
#to bigger differences. Makes sense from a sampling point of view, but 
#still one would expect that investigating small differences would be hard/impossible

###########
### iii ###
###########
experiment_iii <- LogRankTest(
  repetitions = 500,
  n_each = 1000, 
  A_sampler = function(n) {rexp(n, rate = 0.17)},
  B_sampler = function(n) {rweibull(n, shape = 2, scale = 5)},
  seed = 2031,
  alpha = 0.05
)

experiment_iii$rejection_frequency #0.52, which is very close to spot on

#One would, if one did not know the generating distribution, would not with 
#statistical significance reject the hypothesis that the hazard rates are equal
#at every t, even though the hazards rate are different by design!

#The log rank test works best when the two distributions are proportional hazards
#The difference between the hazard rate for exponential and Weibull is clearly non-linear/not proportional

library(ggplot2)
ggplot() +
  geom_function(fun = function(x){haz_exp(x, 0.17)}, aes(color = "Exponential")) +
  geom_function(fun = function(x){haz_wei(x, k=2, lambda = 5)}, aes(color = "Weibull")) +
  xlim(c(0,qexp(0.99, rate = 0.17))) +
  labs(
    x = "Time",
    y = expression(lambda),
    color = "Distribution",
    title = "Hazard rates for Exponential and Weibull"
  )
