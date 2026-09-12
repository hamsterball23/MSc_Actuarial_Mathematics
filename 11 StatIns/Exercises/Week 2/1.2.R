### Practical Exercises 1.2
install.packages(
  "CASdatasets", 
  repos = "http://dutangc.perso.math.cnrs.fr/RRepository/pub/", 
  type="source"
)
library(CASdatasets)
library(ggplot2)

data("frecomfire", package = "CASdatasets")
vec <- frecomfire$ClaimCost2007

# -------------------- a) --------------------
ggplot(data = frecomfire, aes(x=ClaimCost2007)) + 
  geom_histogram(bins = 80)

# -------------------- b) --------------------
mu <- mean(vec)
mu2 <- mean((vec - mu)^2)
mu4 <- mean((vec - mu)^4)

#Proposition 1.1 says that the variance has a confidence interval with
#mean equal to mu2 and Standard error equal to sqrt( (mu4 - (mu2)**2) / n )
n <- length(vec)
mu2 + c(-1,1) * qnorm(0.975) * sqrt( (mu4 - (mu2)**2) / n )
# (15,530,916, 68,003,653)

# -------------------- c) --------------------
meanExcessFunc <- function(u, vec)
{
  sum(vec[vec > u]) / sum(vec > u) - u
  ## Alternatively mean(vec[vec>u]-u)
}

# second moment of the excess, e_F^(2)(u) = E[(Z-u)^2 | Z>u]
meanExcessFunc2 <- function(u, vec)
{
  mean((vec[vec > u] - u)^2)
}

FhatFunc <- function(t, vec)
{
  return (mean(vec <= t))
}

#Theorem 1.11 says that the mean excess function has a confidence interval with
#mean equal to e_n(u) and Standard error equal to
#sqrt( (e_F^(2)(u) - e_F(u)^2) / ((1 - F(u)) * n) )
u <- 5000
Fhat_u <- FhatFunc(u, vec)
en_u   <- meanExcessFunc(u, vec)
eF2_u  <- meanExcessFunc2(u, vec)

en_u + c(-1,1) * qnorm(0.975) * sqrt( (eF2_u - en_u^2) / ((1 - Fhat_u) * n) )
# (6984.121, 10076.741)

# -------------------- d) --------------------
cumHazardFunc <- function(t, vec)
{
  n <- length(vec)
  return ( log(n) - log(sum(vec > t)) )
}

t <- 2000
cumHaz_t <- cumHazardFunc(t, vec)
Fhat_t <- FhatFunc(t, vec)

#Theorem 1.12 says that the cumulative hazard function has a confidence interval with
# mean equl to cumHaz(t) and Standard error equal to
#sqrt( (F(t)) / (n * (1-F(t)) )

cumHaz_t + c(-1,1) * qnorm(0.975) * sqrt( Fhat_t / (n * (1 - Fhat_t)) )
# (1.492237, 1.568299)