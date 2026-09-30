# Solutions for week 3 in StatIns

## Practical Exercise 3

## (a)

library(tidyverse)

df <- function(z) {
  1 - exp(-z/2)
}

emp_df <- function(z) {
  length(Z[Z <= z])/length(Z)
}

set.seed(2026)
n <- 1000             # adjust sample size here
Z <- rexp(n, 1/2)

upper_bound <- function(z) {
  emp_df(z) + qnorm(0.975) * sqrt(df(z)*(1 - df(z)))/sqrt(n)
}

lower_bound <- function(z) {
  emp_df(z) - qnorm(0.975) * sqrt(df(z)*(1 - df(z)))/sqrt(n)
}

ggplot() +
  geom_function(fun = Vectorize(emp_df), xlim = c(0, 10)) +
  geom_function(fun = Vectorize(upper_bound), colour = "blue", xlim = c(0, 10)) +
  geom_function(fun = Vectorize(lower_bound), colour = "red", xlim = c(0, 10)) +
  theme_bw() + xlab("t") + ylab("Empirical df")

## (b)

install.packages("e1071")
library(e1071)
set.seed(2026)

# setting up values
n_seq  <- c(10, 100, 1000)
z_seq  <- seq(0.01, 10, length.out = 1000)
lambda <- 0.5

D10   <- rep(NA,1000)
D100  <- rep(NA,1000)
D1000 <- rep(NA,1000)
supB  <- rep(NA,1000)

F_z <- pexp(z_seq,rate=lambda)
# creating loop to obtain 1000 (it says 100 in the exercise, but we do 1000 instead) realizations of D_n
for (i in 1:1000){
  # cimulating the random variables
  X10   <- rexp(n_seq[1], rate=lambda)
  X100  <- rexp(n_seq[2], rate=lambda)
  X1000 <- rexp(n_seq[3], rate=lambda)
  
  # calculating the empirical distribution function
  F10   <- ecdf(X10)
  F100  <- ecdf(X100)
  F1000 <- ecdf(X1000)
  
  # calculating D_n
  D10[i]   <- max(abs(F10(z_seq)   - F_z))
  D100[i]  <- max(abs(F100(z_seq)  - F_z))
  D1000[i] <- max(abs(F1000(z_seq) - F_z))
  
  # calculating sup |B(t)|
  Br_bridge <- rbridge(end = 1, frequency = 1000) # simulating a brownian bridge
  supB[i]   <- max(abs(Br_bridge))
}
#-----------------Plotting with base R-----------------

par(mfrow=(c(2 , 2))) # plot in a 2x2 grid
hist(sqrt(10)   * D10)
hist(sqrt(100)  * D100)
hist(sqrt(1000) * D1000)
hist(supB)

#-----------------Plotting with ggplot-----------------
library(tidyverse)
data <- data.frame(
  Value = c(sqrt(10)   * D10, 
            sqrt(100)  * D100, 
            sqrt(1000) * D1000, 
            supB),
  Group = factor(rep(c("D10", "D100", "D1000", "supB"),
                     times = c(length(D10), length(D100), length(D1000), length(supB))))
)

# plot histograms using ggplot2 with facets
ggplot(data, aes(x = Value)) +
  geom_histogram( bins = 50, fill = "lightblue", color = "black", aes(y = ..density..)) + 
  facet_wrap(~ Group, ncol = 2) +  # Create a 2x2 grid of histograms
  labs(title = "Histograms of Scaled D10, D100, D1000, and supB",
       x = "Value", y = "Frequency") +
  theme_minimal()
