# Solutions for week 4 in StatIns 

## Exercise 1

# a.

library(tidyverse)
set.seed(2026)
n <- 1000
X <- rnorm(n, 0, 1)

# use the density function in R for kernel estimation
# adjust bandwidth by changing bw (default bw = 0.2221)
kern_norm <- density(X, kernel = "epanechnikov", bw = 0.3)

# generate data frames for plotting
kern_df <- data.frame(x = kern_norm$x, y = kern_norm$y, type = "Epanechnikov KDE")
true_density_df <- data.frame(x = kern_norm$x, y = dnorm(kern_norm$x), type = "True Density")
mle_density_df <- data.frame(x = kern_norm$x, y = dnorm(kern_norm$x, mean = mean(X), sd = sd(X)), type = "MLE Density")
combined_df <- rbind(kern_df, true_density_df, mle_density_df)

# plot with legend
ggplot(combined_df, aes(x = x, y = y, color = type)) +
  geom_line(size = 1, aes(linetype = type)) +
  labs(
    title = "Epanechnikov Kernel Density vs True and MLE (Normal Distribution)",
    x = "Value", y = "Density", color = "Density Type"
  ) +
  theme_minimal() +
  scale_color_manual(values = c("Epanechnikov KDE" = "black", "True Density" = "red", "MLE Density" = "blue"))


# zoom into specific region
ggplot(combined_df, aes(x = x, y = y, color = type)) +
  geom_line(size = 1, aes(linetype = type)) +
  labs(
    title = "Zoomed Epanechnikov Kernel Density vs True and MLE",
    x = "Value", y = "Density", color = "Density Type"
  ) +
  coord_cartesian(xlim = c(2, 2.6), ylim = c(0, 0.1)) +
  theme_minimal() +
  scale_color_manual(values = c("Epanechnikov KDE" = "black", "True Density" = "red", "MLE Density" = "blue"))


# b.

set.seed(2026)
n <- 1000
p <- rbinom(n, 1, 0.8)
X1 <- runif(n)
X2 <- runif(n, min = 1, max = 2)
Y <- p * X1 + (1 - p) * X2

# define true density function for mixture distribution
Y_dens <- function(x) {
  y <- numeric(length(x))
  y[x > 0 & x < 1] <- 0.8
  y[x > 1 & x < 2] <- 0.2
  return(y)
}

# estimate density using Epanechnikov kernel
kern_jump <- density(Y, kernel = "epanechnikov")

kern_df <- data.frame(x = kern_jump$x, y = kern_jump$y, type = "Epanechnikov KDE")
true_density_df <- data.frame(x = kern_jump$x, y = Y_dens(kern_jump$x), type = "True Density")
combined_df <- rbind(kern_df, true_density_df)

# plot with legend
ggplot(combined_df, aes(x = x, y = y, color = type)) +
  geom_line(size = 1, aes(linetype = type)) +
  labs(
    title = "Epanechnikov KDE vs True Density (Mixture Distribution)",
    x = "Value", y = "Density", color = "Density Type"
  ) +
  theme_minimal() +
  scale_color_manual(values = c("Epanechnikov KDE" = "black", "True Density" = "red"))

## Exercise 4

library(tidyverse)
library(CASdatasets)

## a.

data(brvehins1a)
upper_claim_limit <- 200000

auto_brazil <- brvehins1a %>% 
  select(SumInsAvg, ClaimAmountTotColl) %>%
  filter(ClaimAmountTotColl  != 0, 
         ClaimAmountTotColl < upper_claim_limit) %>%
  arrange(SumInsAvg) 

X <- auto_brazil$SumInsAvg
Y <- auto_brazil$ClaimAmountTotColl

## b.

emp_df <- function(t, data) {
  sum(data <= t) / length(data)
}

X_uniform <- unlist(lapply(sort(X), FUN = function(t) emp_df(t, data = X)))

uni_frame <- data.frame("X_u" = X_uniform)
ggplot(uni_frame, aes(x = X_u)) +
  geom_histogram(bins = 50, colour = "white") + theme_bw()

## c.

cond_emp_df <- function(t, covariate, response, x, bandwidth){
  sum(1 * (response <= t)*dnorm((x-covariate)/bandwidth)) / sum(dnorm((x-covariate)/bandwidth))
}

n <- length(X)
h <- 3*n^(-1/5)/log(log(n))
t_grid <- seq(from = 0, to = upper_claim_limit, by = 100)

F_unconditional <- rep(0, length(t))
F_x <- rep(0, length(t))

for (i in 1:length(t_grid)){
  F_unconditional[i] <- emp_df(t = t_grid[i], data = Y)
  F_x[i] <- cond_emp_df(t = t_grid[i], covariate = X_uniform, response = Y, x = 0.7, bandwidth = h) 
}

plot_frame_cecdf_0 <- tibble("t" = t_grid, "F_uncon" = F_unconditional, "F_x" =  F_x)

ggplot(plot_frame_cecdf_0, aes(t_grid)) + 
  geom_line(aes(y = F_uncon, colour = "F")) +
  geom_line(aes(y = F_x, colour = "F_x")) +
  ylab("ecdf") + theme_bw()

## d.

plot_frame_cecdf <- plot_frame_cecdf_0 %>%
  mutate("F_x_lower" = F_x - qnorm(0.975)*sqrt(((1/(2*sqrt(pi)))*F_x*(1-F_x)/(h*n))), 
         "F_x_upper" = F_x + qnorm(0.975)*sqrt(((1/(2*sqrt(pi)))*F_x*(1-F_x)/(h*n))),
         "F_X_Kol_Lower" = F_x - 1.36*sqrt(1/(2*sqrt(pi)))/sqrt(n*h),
         "F_X_Kol_Upper" = F_x + 1.36*sqrt(1/(2*sqrt(pi)))/sqrt(n*h))

ggplot(plot_frame_cecdf, aes(t_grid)) + 
  geom_line(aes(y = F_x, colour = "F_x")) +
  geom_line(aes(y = F_x_lower, colour = "F_x_lower"), linetype = "dashed") + 
  geom_line(aes(y = F_x_upper, colour = "F_x_upper"), linetype = "dashed") +
  geom_line(aes(y = F_X_Kol_Upper, colour = "F_X_Kol_Upper"), linetype = "dashed") +
  geom_line(aes(y = F_X_Kol_Lower, colour = "F_X_Kol_Lower"), linetype = "dashed") +
  theme_bw()
