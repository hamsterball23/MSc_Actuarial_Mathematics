###################################
########## Practical 7.2 ##########
###################################

sim_data <- function(gamma_z, gamma_c, n, seed){
  set.seed(seed)
  Uz <- runif(n)
  Uc <- runif(n)
  Z <- 1/(Uz**gamma_z)
  C <- 1/(Uc**gamma_c)
  delta <- Z<=C
  W <- pmin(Z, C)
  return(
    data.frame(
      delta = delta,
      W = W
    )
  )
}

sim_data_burr <- function(gamma_z, gamma_c, n, seed, beta = 1, theta = 1){
  set.seed(seed)
  Uz <- runif(n)
  Uc <- runif(n)
  Z <- (Uz**(-1/beta)-1)**gamma_z*theta  # P(Z>x) = (1+(x/theta)^(1/gamma_z))^(-beta), EVI = gamma_z/beta
  C <- (Uc**(-1/beta)-1)**gamma_c*theta
  delta <- Z <= C
  W <- pmin(Z, C)
  return(
    data.frame(
      delta = delta,
      W = W
    )
  )
}

hill_estimator <- function(vec, k){
  n <- length(vec)

  if (k > n) stop("k > n in Hill Estimator")
  
  order_vec <- sort(vec)

  return(
    mean( log( order_vec[seq(n-k+1, n, by =1)] / order_vec[n-k] ) )
  )
}

hill_estimator_censored <- function(df, k){
  n <- length(df$W)
  n_delta <- length(df$delta)

  if (k > n) stop("k > n in Hill Estimator")
  if (n != n_delta) stop("Given W vector and delta vector does not have equal length")
  
  sort_df <- df[order(df$W),]

  order_vec_W <- sort_df$W  
  order_vec_delta <- sort_df$delta

  Hill_est <- mean( log( order_vec_W[seq(n-k+1, n, by =1)] / order_vec_W[n-k] ) )
  p_est <- mean( order_vec_delta[seq(n_delta-k+1, n_delta)])

  return(Hill_est/p_est)
}

library(ggplot2)

# Hill plot: usual Hill estimator for W and censored Hill estimator for Z,
# for all k = 1, ..., k_max at once (vectorised via cumulative sums).
# If gamma_z and gamma_c are given, the true values are drawn as reference lines:
#   gamma_z                              (target of the censored estimator)
#   gamma_w = gamma_z*gamma_c/(gamma_z+gamma_c)  (target of the usual estimator on W)
hill_plot <- function(df, k_max = length(df$W) - 1, gamma_z = NULL, gamma_c = NULL,
                      ylim = NULL, main = "Hill plot", log_k = TRUE)
{
  ord <- order(df$W, decreasing = TRUE)   # W_{n,n} >= W_{n-1,n} >= ...
  logW <- log(df$W[ord])
  delta <- df$delta[ord]
  k <- seq_len(k_max)

  hill <- cumsum(logW)[k] / k - logW[k + 1]   # gamma_hat_{n,k}
  p_hat <- cumsum(delta)[k] / k               # p_hat_{n,k}
  hill_c <- hill / p_hat                       # censored Hill (Inf if p_hat = 0)

  cols <- c("Hill (W)" = "steelblue", "Censored Hill" = "firebrick")
  plot_df <- data.frame(
    k = rep(k, 2),
    gamma_hat = c(hill, hill_c),
    estimator = factor(rep(names(cols), each = k_max), levels = names(cols))
  )

  p <- ggplot(plot_df, aes(x = k, y = gamma_hat, colour = estimator)) +
    geom_line() +
    scale_colour_manual(values = cols) +
    labs(x = "k", y = expression(hat(gamma)), colour = NULL, title = main) +
    theme_minimal() +
    theme(legend.position = "top", axis.title.y = element_text(angle = 0, vjust = 0.5))

  # true values as dashed lines, in the colour of the estimator that targets them
  if (!is.null(gamma_z)) {
    p <- p + geom_hline(yintercept = gamma_z, colour = cols[["Censored Hill"]], linetype = "dashed")
    if (!is.null(gamma_c)) {
      gamma_w <- gamma_z * gamma_c / (gamma_z + gamma_c)
      p <- p + geom_hline(yintercept = gamma_w, colour = cols[["Hill (W)"]], linetype = "dashed")
    }
  }
  if (log_k) p <- p + scale_x_log10()
  if (!is.null(ylim)) p <- p + coord_cartesian(ylim = ylim)  # zooms without dropping data

  p
}


#########
### a ###
#########

sim_a <- sim_data(
  gamma_z = 0.5,
  gamma_c = 2,
  n = 10**5,
  seed = 2026
)

hill_plot(sim_a, gamma_z = 0.5, gamma_c = 2)

hill_estimator(sim_a$W, 10**4) #0.3978 close to true 0.4 = 2*0.5 / (2+0.5)
hill_estimator_censored(sim_a, 10**4) #0.4972 close to true 0.5
#Hill on W estimates gamma_W < gamma_Z, i.e. it underestimates the tail of Z. Dividing by p_hat
#(~0.8 = share uncensored) corrects this. Both curves are noisy for small k and stable for k >~ 500.



#########
### b ###
#########

sim_b <- sim_data(
  gamma_z = 2,
  gamma_c = 0.5,
  n = 10**5,
  seed = 2027
)

hill_plot(sim_b, gamma_z = 2, gamma_c = 0.5)

hill_estimator(sim_b$W, 10**4) #0.404, gamma_W = 0.4 is unchanged (formula is symmetric in gz, gc)
hill_estimator_censored(sim_b, 10**4) #2.03 close to true 2

#Heavy censoring: only ~20% uncensored (p = 0.5/2.5), so Hill on W is far below gamma_Z and the
#censored estimator divides by ~0.2, which amplifies the noise ~5x -> much more variable Hill plot.

#########
### c ###
#########

sim_c <- sim_data_burr(
  gamma_z = 0.5,
  gamma_c = 2,
  n = 10**5,
  seed = 2028
)

#Same EVIs as in (a): gamma_Z = 0.5, gamma_C = 2, gamma_W = 0.4
hill_plot(sim_c, gamma_z = 0.5, gamma_c = 2)
#Zoom (coord_cartesian keeps the log k-axis and doesn't drop data)
hill_plot(sim_c, gamma_z = 0.5, gamma_c = 2) + coord_cartesian(xlim = c(10, 10**4), ylim = c(0, 1))

#Unlike the Pareto case, Burr is only asymptotically Pareto, so both estimators get biased upwards
#for large k (censored: 0.50 at k=1000, 0.57 at k=10^4, 0.66 at k=2*10^4). Stable for k ~ 200-2000.

hill_estimator(sim_c$W, 500) #0.4051 close to gamma_W = 0.4
hill_estimator_censored(sim_c, 500) #0.4905 close to gamma_Z = 0.5
