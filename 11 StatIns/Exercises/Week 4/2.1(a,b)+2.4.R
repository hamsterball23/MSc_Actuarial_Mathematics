library(ggplot2)
library(dplyr)
library(tibble)
library(scales)

###################################
########## Practical 2.1 ##########
###################################

###############
#####  a  #####
###############
set.seed(2026)
stdNormSim <- rnorm(1000)


#Parzen-Rosenblatt density estimator
#Epanechnikov kernel from exercise 2.1
bandwidths <- c(0.1, 0.3, 0.5, 0.7, 1.0)

EpanechnikovKernel <- function(x) { ifelse(abs(x) <= 1, (1-x**2)*3/4, 0) }
vEpanechnikovKernel <- Vectorize(EpanechnikovKernel)

ParzenRosenblattDensityEstimator <- function(x, vec, bandwidth){
  n <- length(vec)
  return(
    sum(vEpanechnikovKernel((x-vec)/bandwidth))/(n*bandwidth)
  )
}
# vectorize over x so geom_function (which passes a vector of x-values) works
vParzenRosenblattDensityEstimator <- Vectorize(ParzenRosenblattDensityEstimator, "x")

# build the estimated density for each bandwidth on a common grid, stratified
xGrid <- seq(-4, 4, length.out = 301)
densityDf <- do.call(rbind, lapply(bandwidths, function(h) {
  data.frame(
    x = xGrid,
    density = vParzenRosenblattDensityEstimator(xGrid, stdNormSim, h),
    bandwidth = factor(h)
  )
}))

ggplot(densityDf, aes(x = x, y = density, color = bandwidth)) +
  geom_histogram(data = data.frame(x = stdNormSim), aes(x = x, y = after_stat(density)),
                  inherit.aes = FALSE, binwidth = 0.1, alpha = 0.15, boundary = 0) +
  geom_line() +
  geom_function(fun = dnorm, color = "black", linetype = "dashed", inherit.aes = FALSE) +
  facet_wrap(~ bandwidth, labeller = label_both) +
  labs(title = "Parzen-Rosenblatt density estimate vs. standard normal",
       subtitle = "Dashed black line = dnorm(x); faint bars = data histogram",
       x = "x", y = "density") +
  theme(legend.position = "none")

###############
#####  b  #####
###############
set.seed(2026)
X1 <- runif(1000)
X2 <- runif(1000, 1, 2)
p <- rbinom(1000, 1, 0.8)
YSim <- p*X1 + (1-p)*X2


xGridY <- seq(0, 2, length.out = 301)
densityDfY <- do.call(rbind, lapply(bandwidths, function(h){
  data.frame(
    x = xGridY,
    density = vParzenRosenblattDensityEstimator(xGridY, YSim, h),
    bandwidth = factor(h)
  )
}))

#Density must be the following step function
densY <- function(x) {
  ifelse(0<=x && x<=2, 1, 0)* (ifelse(0<=x && x<=1, 1, 0)*0.6 + 0.2)
}
vdensY <- Vectorize(densY)


ggplot(densityDfY, aes(x = x, y = density, color = bandwidth)) +
  geom_histogram(data = data.frame(x = YSim), aes(x = x, y = after_stat(density)),
                  inherit.aes = FALSE, binwidth = 0.1, alpha = 0.15, boundary = 0) +
  geom_line() +
  geom_function(fun = vdensY, color = "black", linetype = "dashed", inherit.aes = FALSE) +
  facet_wrap(~ bandwidth, labeller = label_both) +
  labs(title = "Parzen-Rosenblatt density estimate vs. true density",
       subtitle = "Dashed black line = densityY(x); faint bars = data histogram",
       x = "x", y = "density") +
  theme(legend.position = "none")


###################################
########## Practical 2.4 ##########
###################################
data(brvehins1a, package = "CASdatasets")

#####  a  #####
M <- 200000
data <- brvehins1a |>
  select(SumInsAvg, ClaimAmountTotColl) |>
  filter(ClaimAmountTotColl > 0, ClaimAmountTotColl < M)
summary(data)


#####  b  #####
X <- data$SumInsAvg
ecdfX <- ecdf(X)

XUniform <- ecdfX(X)

#Plot
ggplot() +
  geom_function(fun = ecdfX, color = "#2a78d6", linewidth = 0.8) +
  scale_x_continuous(labels = comma, limits = c(0, max(X))) +
  labs(
    title = "Empirical distribution function of SumInsAvg",
    subtitle = bquote(F[X]^(n) * "(·),  n = " * .(comma(nrow(data)))),
    x = "SumInsAvg",
    y = "Prob."
  ) +
  theme(panel.grid.minor = element_blank())


#####  c  #####
n <- nrow(data)

hn <- 3*n**(-1/5)/log(log(n))

xGrid <- seq(0, M, 100)

Y <- data$ClaimAmountTotColl

# Emperical distribution function of Y - F_Y^(n) ( * )
ecdfY <- ecdf(Y)


# Conditional emperical distribution function of Y - F_Y^(n) ( * | 0.7)
GaussianKernel <- Vectorize(function(x) {exp(-x**2/2)/sqrt(2*pi)})
cecdfY <- Vectorize(function(t, x = 0.7){
  denom <- sum(GaussianKernel((x-XUniform)/hn))
  num <- sum(ifelse(Y <= t, 1, 0) * GaussianKernel((x-XUniform)/hn))
  return (num/denom)
}, "t")

# Plot
plot_base <- ggplot() +
  scale_x_continuous(labels = comma, limits = c(0, M)) +
  geom_function(aes(color = "Conditional | X = 0.7"), fun = cecdfY,
                linewidth = 0.9, n = length(xGrid)) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = c(0.78, 0.25),
    legend.background = element_rect(fill = "white", color = NA)
  )

plot_base +
  geom_function(aes(color = "Unconditional"), fun = ecdfY,
                linetype = "dashed", linewidth = 0.8, n = length(xGrid)) +
  scale_color_manual(values = c("Unconditional" = "#2a78d6",
                                 "Conditional | X = 0.7" = "#eb6834")) +
  labs(
    title = "Conditional vs. unconditional distribution of ClaimAmountTotColl",
    subtitle = bquote(F[Y]^(n) * "(·)  (dashed)  vs.  " *
                       F[Y]^(n) * "(· | X = 0.7)  (solid),  n = " *
                       .(comma(n)) * ",  " * h[n] * " = " * .(round(hn, 4))),
    x = "ClaimAmountTotColl",
    y = "Prob.",
    color = NULL
  )


##### d #####
## Xs have been transformed by their distribution function, so they should be uniformly distributed on (0,1)
# Then f_X(x) = 1 on (0,1), so f_X(0.7) = 1 -- this is what makes sigma(t|0.7) computable
# without ever estimating f_X.

# Theorem 2.4: sqrt(n*hn) * (F^(n)(t|x) - F(t|x)) -> N(0, sigma^2(t|x)), with
#   sigma^2(t|x) = R(K) * F(t|x) * (1 - F(t|x)) / f_X(x)
# where R(K) = integral of K(u)^2 du is the kernel's roughness.
RK <- integrate(function(u) GaussianKernel(u)**2, -Inf, Inf)$value  # = 1/(2*sqrt(pi))
fX_0.7 <- 1  # density of Uniform(0,1) at any interior point, in particular x = 0.7

# F(t|0.7) itself is unknown, so plug in its estimator cecdfY(t) -- sigma is a
# function of F(t|0.7), not a single number.
sigma_hat <- function(Ft) sqrt(RK * Ft * (1 - Ft) / fX_0.7)

z <- qnorm(0.975)
naiveLower <- function(Ft) pmax(0, Ft - z * sigma_hat(Ft) / sqrt(n * hn))
naiveUpper <- function(Ft) pmin(1, Ft + z * sigma_hat(Ft) / sqrt(n * hn))

# cecdfY() re-scans all n observations for every t it's called on, so evaluate it
# ONCE on the grid and reuse the vector below, instead of recomputing it once per
# bound/band (this is what made the original version "very slow").
cecdfGrid <- cecdfY(xGrid)

naiveBandDf <- data.frame(
  x = xGrid,
  lower = naiveLower(cecdfGrid),
  upper = naiveUpper(cecdfGrid)
)

# Theorem 2.8: sqrt(n*hn / (RK/fX_0.7)) * sup_t |F^(n)(t|0.7) - F(t|0.7)| -> sup_u |B(u)|
# (a time-changed Brownian bridge, via the substitution u = F(t|0.7)), whose 95%
# quantile is the Kolmogorov constant 1.36. Unlike the naive band, this does NOT
# depend on t/cecdfY(t) -- solving for the sup gives one constant half-width that
# applies uniformly across the whole path.
pathwiseWidth <- 1.36 * sqrt(RK / fX_0.7) / sqrt(n * hn)

pathwiseLower <- function(Ft) pmax(0, Ft - pathwiseWidth)
pathwiseUpper <- function(Ft) pmin(1, Ft + pathwiseWidth)

pathwiseBandDf <- data.frame(x = xGrid, lower = pathwiseLower(cecdfGrid), upper = pathwiseUpper(cecdfGrid))

plot_base +
  geom_ribbon(data = naiveBandDf, aes(x = x, ymin = lower, ymax = upper, fill = "95% naive (pointwise)"),
              inherit.aes = FALSE, alpha = 0.25, color = NA) +
  geom_ribbon(data = pathwiseBandDf, aes(x = x, ymin = lower, ymax = upper, fill = "95% pathwise"),
              inherit.aes = FALSE, alpha = 0.25, color = NA) +
  scale_color_manual(values = c("Unconditional" = "#2a78d6",
                                 "Conditional | X = 0.7" = "#eb6834")) +
  scale_fill_manual(values = c("95% naive (pointwise)" = "#eb6834",
                                "95% pathwise" = "#1baf7a")) +
  labs(
    title = "Naive (pointwise) vs. pathwise 95% confidence bands",
    subtitle = bquote(F[Y]^(n) * "(· | X = 0.7)  with 95% bands,  n = " *
                       .(comma(n)) * ",  " * h[n] * " = " * .(round(hn, 4))),
    x = "ClaimAmountTotColl",
    y = "Prob.",
    color = NULL,
    fill = NULL
  )
