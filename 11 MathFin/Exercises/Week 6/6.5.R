#########################
########## 6.5 ##########
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
integrand_maker <- function(fun, deltaT, a = 0, b = 1)
{
  nGrid <- (b - a) / deltaT

  if (abs(nGrid - round(nGrid)) > 1e-8)
  {
    stop("deltaT should divide b - a evenly")
  }

  # Integrand evaluated on the same grid as the Brownian motion: t_0 = a, ..., t_n = b
  times <- seq(a, b, by = deltaT)

  return(fun(times))
}

# Cumulative sum along each path (row) of a matrix
rowCumsum <- function(m)
{
  t(apply(m, 1, cumsum))
}

W_maker <- function(t, N, deltaT, seed = 2026){
  #Using left-endpoint sums

  #Creating integrand in fine grid
  integrand_sin <- integrand_maker(function(t) sin(t), deltaT, a = 0, b = t)
  integrand_cos <- integrand_maker(function(t) cos(t), deltaT, a = 0, b = t)

  #Create integrator in fine grid
  integrator_B1 <- DiscreteBrownianMotionGenerator(deltaT, N, a = 0, b = t, seed = seed)
  integrator_B2 <- DiscreteBrownianMotionGenerator(deltaT, N, a = 0, b = t, seed = seed+1)

  #Make integrator increments path by path (N x nGrid): column j is B_{t_j} - B_{t_{j-1}}
  increments_B1 <- integrator_B1[, -1, drop = FALSE] - integrator_B1[, -ncol(integrator_B1), drop = FALSE]
  increments_B2 <- integrator_B2[, -1, drop = FALSE] - integrator_B2[, -ncol(integrator_B2), drop = FALSE]

  #Left endpoints: drop the last grid point
  summand_sin <- integrand_sin[-length(integrand_sin)]
  summand_cos <- integrand_cos[-length(integrand_cos)]

  #Multiply column j of the increments by f(t_{j-1}), then cumulate along each path
  res_W2 <- cbind(0, rowCumsum(sweep(increments_B1, 2, summand_sin, "*") + sweep(increments_B2, 2, summand_cos, "*")))
  res_W3 <- cbind(0, rowCumsum(sweep(increments_B1, 2, summand_cos, "*") + sweep(increments_B2, 2, summand_sin, "*")))

  colnames(res_W2) <- colnames(res_W3) <- attr(integrator_B1, "times")

  return(list(W2 = res_W2, W3 = res_W3))
}

plot_paths <- function(paths, title)
{
  as.data.frame(paths) |>
    mutate(path = factor(row_number())) |>
    pivot_longer(-path, names_to = "t", values_to = "value") |>
    mutate(t = as.numeric(t)) |>
    ggplot(aes(x = t, y = value, colour = path)) +
    geom_line() +
    labs(title = title, x = "t", y = NULL) +
    theme_minimal()
}

W_n5 <- W_maker(t = 1, N = 5, deltaT = 0.01, seed = 2026)
plot_paths(W_n5$W2, expression(W^{(2)}))
plot_paths(W_n5$W3, expression(W^{(3)}))

#########
### b ###
#########
W_n10000 <- W_maker(t = 1, N = 10000, deltaT = 0.01, seed = 2026)
plot_histograms <- function(paths, title, xlab, sd = 1)
{
  # Only the endpoint W_1 (last column), not every time point
  data.frame(value = paths[, ncol(paths)]) |>
    ggplot(aes(x = value)) +
    geom_histogram(aes(y = after_stat(density)), bins = 100) +
    geom_function(fun = dnorm, args = list(sd = sd), linetype = "dashed", color = "red") +
    labs(title = title, x = xlab, y = "Density")
}

plot_histograms(
  W_n10000$W2,
  title = expression(W[1]^{(2)} * " vs. standard normal density"),
  xlab = expression(W[1]^{(2)})
)
plot_histograms(
  W_n10000$W3,
  title = expression(W[1]^{(3)} * " vs. standard normal density"),
  xlab = expression(W[1]^{(3)})
)

#########
### c ###
#########
M_maker <- function(t, N, deltaT, seed = 2026){
  #Using left-endpoint sums

  #Creating integrand in fine grid
  integrand_exp <- integrand_maker(function(t) exp(t), deltaT, a = 0, b = t)

  #Create integrator in fine grid
  integrator_B <- DiscreteBrownianMotionGenerator(deltaT, N, a = 0, b = t, seed = seed)

  #Make integrator increments path by path (N x nGrid): column j is B_{t_j} - B_{t_{j-1}}
  increments_B <- integrator_B[, -1, drop = FALSE] - integrator_B[, -ncol(integrator_B), drop = FALSE]
  
  #Left endpoints: drop the last grid point
  summand_exp <- integrand_exp[-length(integrand_exp)]

  #Multiply column j of the increments by f(t_{j-1}), then cumulate along each path
  res_M <- cbind(0, rowCumsum(sweep(increments_B, 2, summand_exp, "*")))

  colnames(res_M) <- attr(integrator_B, "times")

  return(res_M)
}

M_n5 <- M_maker(t = 1, N = 5, deltaT = 0.01, seed = 2026)

plot_paths(M_n5, title = expression(M[1]))

#########
### d ###
#########

M_n10000 <- M_maker(t = 1, N = 10000, deltaT = 0.01, seed = 1234)

M_n10000_endpoints <- M_n10000[,ncol(M_n10000)]

M_n10000_endpoints |> mean() #-0.002557727
M_n10000_endpoints |> var() #3.155208

#Theoretical variance (use quadratic variation below)
(exp(2) - 1)/ 2 #3.194528

#M_1 is a martingale because int_0^1 e^2s ds = (1/2)(e^2 - 1)


#########
### e ###
#########
M_tilde_maker <- function(t, N, deltaT, seed = 2026){
  #Computes e^t B_t - int_0^t e^s B_s ds, using a left-endpoint Riemann sum for the ds-integral

  #Creating integrands in fine grid
  integrand_exp <- integrand_maker(function(t) exp(t), deltaT, a = 0, b = t)
  integrand_B <- DiscreteBrownianMotionGenerator(deltaT, N, a = 0, b = t, seed = seed)

  #Left endpoints: drop the last grid point (last column for the N x (nGrid + 1) matrix B)
  summand_exp <- integrand_exp[-length(integrand_exp)]
  summand_B <- integrand_B[, -ncol(integrand_B), drop = FALSE]

  # Increments in integrator is just deltaT
  riemann_sum <- cbind(0, deltaT * rowCumsum(sweep(summand_B, 2, summand_exp, "*")))

  #e^t B_t at every grid point: multiply column j of B by e^{t_j}
  res_M <- sweep(integrand_B, 2, integrand_exp, "*") - riemann_sum

  colnames(res_M) <- attr(integrand_B, "times")

  return(res_M)
}

# Same seed as in (d), so both use the same Brownian paths (needed for the comparison in (f))
M_tilde_n10000 <- M_tilde_maker(t = 1, N = 10000, deltaT = 0.01, seed = 1234)

M_tilde_n10000_endpoints <- M_tilde_n10000[, ncol(M_tilde_n10000)]

M_tilde_n10000_endpoints |> mean() #0.00722269
M_tilde_n10000_endpoints |> var() #3.247352

#########
### f ###
#########
# Same Brownian paths in (d) and (e), so the difference is pure discretisation error
mean(abs(M_n10000_endpoints - M_tilde_n10000_endpoints)) #0.01773356

# The error shrinks as the grid gets finer
sapply(c(0.1, 0.01, 0.001), function(dt)
{
  M_end <- M_maker(t = 1, N = 10000, deltaT = dt, seed = 1234)
  M_tilde_end <- M_tilde_maker(t = 1, N = 10000, deltaT = dt, seed = 1234)
  mean(abs(M_end[, ncol(M_end)] - M_tilde_end[, ncol(M_tilde_end)]))
})
#[1] 0.172226047 0.017733563 0.001784666
#This is linear in deltaT


#########
### g ###
#########

rowSums(t(diff(t(W_n5$W2))) * t(diff(t(W_n5$W3))))
#[1] 0.7656961 0.5249181 0.5945954 0.7719772 0.8175905

#d<W2,W3>_s = sin(s)cos(s) d<B1>_s + cos(s)sin(s) d<B2>_s (cross terms vanish since <B1,B2> = 0)
#<W2,W3>_t = int_0^t 2sin(s)cos(s) ds = int_0^t sin(2s) ds = (1 - cos(2t))/2
(1 - cos(2))/2 #0.7080734

#########
### h ###
#########
# M_1 ~ N(0, (e^2 - 1)/2) by the Ito isometry (Problem 6.4)
plot_histograms(
  M_n10000,
  title = expression(M[1] * " vs. N(0, (" * e^2 - 1 * ")/2) density"),
  xlab = expression(M[1]),
  sd = sqrt((exp(2) - 1) / 2)
)

