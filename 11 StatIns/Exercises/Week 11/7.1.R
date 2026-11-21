###################################
########## Practical 7.1 ##########
###################################

library(splines)
library(ggplot2)

sim_data <- function(n, K, seed, par_Z = c(2, 0.5), par_C = c(2.5, 0.5)){
  set.seed(seed)
  Z <- rlnorm(n, meanlog = par_Z[1], sdlog = par_Z[2])
  C <- rlnorm(n, meanlog = par_C[1], sdlog = par_C[2])
  delta <- Z <= C
  W <- pmin(Z, C)
  return(
    data.frame(
      W = W,
      delta = delta
    )
  )
}

PoissonRegressionMethod <- function(data, K, df_spline){

  # 0 = t_0 < t_1 < ... < t_{K-1} < t_K = Inf, with t_i the i/(K+1) quantile of W
  t_grid <- c(0, quantile(data$W, probs = (1:(K-1))/(K+1), names = FALSE), Inf)

  # O(k): number of events (delta = 1) with W in [t_{k-1}, t_k)
  O <- sapply(1:K,
      function(k){
        sum(data$delta & data$W >= t_grid[k] & data$W < t_grid[k+1])
      }
    )
  # E(k): total time at risk in [t_{k-1}, t_k) = sum_i (t_k ∧ W_i - t_{k-1} ∧ W_i)
  E <- sapply(1:K,
    function(k){
      sum(pmin(t_grid[k+1], data$W) - pmin(t_grid[k], data$W))
    }
  )

  pois_df <- data.frame(
    O = O,
    E = E,
    interval = cut(t_grid[1:K], t_grid, right = FALSE),
    t = t_grid[1:K]   # left endpoint t_{k-1} of each interval (t_K = Inf can't go in a spline)
  )

  #--- Fit with one value at each interval
  fit <- glm(O ~ 0 + interval + offset(log(E)), family = poisson, data = pois_df)

  lambda_hat <- exp(coef(fit))


  #--- Fit using splines
  fit_s <- glm(O ~ ns(t, df = df_spline) + offset(log(E)), family = poisson, data = pois_df)

  # λ̂(t): predict with exposure 1, so the offset log(1) = 0 drops out
  lambda_hat_est_spline <- predict(fit_s, newdata = transform(pois_df, E = 1), type = "response")


  return(
    structure(
      list(
        fit = fit,
        lambda_hat = lambda_hat,
        fit_s = fit_s,
        lambda_hat_est_spline = lambda_hat_est_spline,
        data = data, O = O, E = E, t_grid = t_grid,
        pois_df = pois_df
      ),
      class = "PoissonRegressionMethod"
    )
  )
}


# S3 method: plot(obj) dispatches here for objects of class "PoissonRegressionMethod".
# true_par = c(meanlog, sdlog) adds the true log-normal hazard of Z as a reference.
plot.PoissonRegressionMethod <- function(x, true_par = NULL, ...){
  K <- length(x$lambda_hat)
  t_max <- max(x$data$W)

  # piecewise constant: repeat last value at t_max so the final step is drawn
  step_df <- data.frame(t = c(x$t_grid[1:K], t_max), lambda = c(x$lambda_hat, x$lambda_hat[K]))
  spline_df <- data.frame(t = x$pois_df$t, lambda = x$lambda_hat_est_spline)

  p <- ggplot() +
    geom_step(data = step_df, aes(t, lambda, colour = "Piecewise constant")) +
    geom_line(data = spline_df, aes(t, lambda, colour = "Natural spline")) +
    geom_point(data = spline_df, aes(t, lambda, colour = "Natural spline")) +
    labs(x = "t", y = expression(hat(lambda)(t)), colour = NULL) +
    theme_minimal() +
    theme(legend.position = "top")

  if (!is.null(true_par)) {
    t_seq <- seq(0, t_max, length.out = 500)
    true_df <- data.frame(t = t_seq,
      lambda = dlnorm(t_seq, true_par[1], true_par[2]) /
               plnorm(t_seq, true_par[1], true_par[2], lower.tail = FALSE))
    p <- p + geom_line(data = true_df, aes(t, lambda, colour = "True hazard"), linetype = "dashed")
  }
  p
}

#########
### a ###
#########

sim_a <- sim_data(n = 5000, K = 15, seed = 2026)
res_a <- PoissonRegressionMethod(sim_a, K = 15, df_spline = 5)
plot(res_a, true_par = c(2, 0.5))


#########
### b ###
#########
data("cancer", package = "survival")

data_b <- data.frame(W = cancer$time, delta = as.numeric(cancer$status == 2))
Ks <- c(2,5,7,10,12,15)
results <- vector("list", length = length(Ks))
plots <- vector("list", length = length(Ks))

for (i in seq_along(Ks)){
  k <- Ks[i]
  results[[i]] <- PoissonRegressionMethod(data_b, K = k, df_spline = min(5, k-2))
  plots[[i]] <- plot(results[[i]]) + ggtitle(paste("K =", k))
}

for (p in plots){
  print(p)
}

#small K gives a coarse step function. As K grows, the steps follow 
# the data more closely, but each one is noisier because fewer deaths 
# fall in each interval. The spline stays fairly stable across K once 
# K is well above its degrees of freedom. In this data the hazard rises 
# from about 0.0013 to about 0.0035 per day over the follow-up period.
