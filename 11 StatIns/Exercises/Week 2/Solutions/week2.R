# Solutions for week 2 in StatIns

## Practical Exercise 1.2

# to install the CASdatasets package (it is not on CRAN, so the usual install.packages command does not work)
# you may need to install the 'remotes' package first
remotes::install_github("dutangc/CASdatasets")

library(CASdatasets)
library(tidyverse)
data(frecomfire)

## (a)

ggplot(data = frecomfire) + 
  geom_histogram(mapping = aes(x = ClaimCost2007), bins = 100, colour = "white") + 
  theme_bw()

# remove largest observations
ggplot(data = frecomfire[frecomfire$ClaimCost2007 < 10^4,]) + 
  geom_histogram(mapping = aes(x = ClaimCost2007), bins = 100, colour = "white") +
  theme_bw()

nrow(frecomfire[frecomfire$ClaimCost2007 < 10^4,])
nrow(frecomfire)

## (b)

CC <- frecomfire$ClaimCost2007
n <- nrow(frecomfire)
var(CC) + c(-1, 1) * qnorm(0.975) * sqrt(mean((CC - mean(CC))^4) - var(CC)^2)/sqrt(n)
var(CC)

## (c)

u <- 5000
emp_ME <- sum(CC[CC > u])/length(CC[CC > u]) - u
emp_ME2 <- sum((CC[CC > u] - u)^2)/length(CC[CC > u])
emp_df <- length(CC[CC <= u])/n

emp_ME + c(-1, 1) * qnorm(0.975) * sqrt(emp_ME2 - emp_ME^2)/sqrt(n*(1 - emp_df))
emp_ME

## (d)

t <- 2000
emp_df <- length(CC[CC <= t])/n
(emp_Lambda <- -log(1 - emp_df))
emp_Lambda + c(-1, 1) * qnorm(0.975) * sqrt(emp_df)/sqrt(n*(1 - emp_df))


