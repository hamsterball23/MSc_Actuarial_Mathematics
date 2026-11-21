# Solutions for week 10 in StatIns

# Practical exercise 1

library(CASdatasets)
library(tidyverse)

# load data
data(austri1autoBI7895)
incremental_paid_triangle <- austri1autoBI7895$paid

# preliminaries
I <-length(incremental_paid_triangle[,1])
J <- I - 1
cumulative_paid_triangle <- t(apply(incremental_paid_triangle, 1, cumsum))
# the 1 means that we apply cumsum (cumulative sum) over the rows only

## a.

# compute the chain-ladder estimators
f_CL <- rep(0, J)
for (j in 0:(J-1)){
  f_CL[j+1] <- sum(cumulative_paid_triangle[(1:(I-j-1)),j+2])/sum(cumulative_paid_triangle[(1:(I-j-1)),j+1])
}

diagonal_elements <- (apply(cumulative_paid_triangle, 1, max, na.rm=TRUE))
kappa_inverse <- c(1,cumprod(rev(f_CL)))         # product of \hat{f}
C_CL <- diagonal_elements[(I-J):I]*kappa_inverse # ultimate
R_CL <- C_CL-diagonal_elements                   # reserves

C_CL
R_CL

## b.

# expo is the number of exposed vehicles, infl is the inflation indices

claims_df <- tibble("C_CL" = C_CL,
                    "diag" = diagonal_elements,
                    "kappa" = (1/kappa_inverse),
                    "expo" = (austri1autoBI7895$expo)[6:length(austri1autoBI7895$expo)],
                    "inflation" = (austri1autoBI7895$infl)[,1],
                    "I" = 1:18)

set.seed(2026)
# here we implement Bornhuetter-Ferguson
claims_df %>% mutate("prior" = case_when(kappa > 0.8 ~ NA, kappa < 0.8 ~ 0.37*expo)) %>%
  mutate("C_BF" = case_when(is.na(prior) ~ C_CL, !is.na(prior) ~ kappa*C_CL + (1-kappa)*prior)) %>%
  mutate("CL_BF_diff" = C_CL - C_BF)

# c.

triangle <- cumulative_paid_triangle
s_sq <- rep(0, J)
for (j in 0:(J-2)){
  denominator_j <- (I-j-1)-1
  sum_indecies <- 1:(I-j-1)
  s_sq[j+1] <- (1/denominator_j)*sum((triangle[sum_indecies,j+1])*((triangle[sum_indecies,j+2]/triangle[sum_indecies,j+1] - f_CL[j+1])^2))
}

# see the definition at the bottom of page 212
s_sq[J] <- min(s_sq[J-2], (s_sq[J-1])^(2)/s_sq[J-2])

# conditional variance as in (5.7) of the notes
sum_vec_var <- (rev(kappa_inverse[-1]))*s_sq/(f_CL^2)
Mack_var <- (claims_df$C_CL)[-1]*cumsum(rev(sum_vec_var))
sqrt(Mack_var)

# squared bias 
triangle_col_sum <- rowSums(t(cumulative_paid_triangle), na.rm = TRUE)[-I]
sum_vec_bias <- (s_sq/(f_CL^2))/triangle_col_sum

Mack_sq_b <- (((claims_df$C_CL)[-1])^(2))*cumsum(rev(sum_vec_bias))

# compare standard deviation with output from existing software.
round(sqrt(Mack_var + Mack_sq_b), digits = 1)
ChainLadder::MackChainLadder(Triangle = cumulative_paid_triangle, est.sigma = "Mack")

# Practical exercise 2

# load data
data(usmedclaim)
incremental_triangle <- usmedclaim[,-c(1,2)]

# preliminaries
incremental_triangle[,1]
I <- length(incremental_triangle[,1])
J <- length(incremental_triangle[1,]) - 1
# note that this is not a usual triangle, since 36 = I > J + 1 = 13
cumulative_triangle <- t(apply(incremental_triangle, 1, cumsum))

# calculate the Chain-Ladder factors
f_CL <- rep(0, J)
for (j in 0:(J-1)){
  f_CL[j+1] <- sum(cumulative_triangle[(1:(I-j-1)),j+2])/sum(cumulative_triangle[(1:(I-j-1)),j+1])
}

# we now make the extrapolation, see page 216
tail_df <- data_frame("dev_p" = 1:J, "log_f" = log(f_CL))

ggplot(tail_df, aes(x=dev_p, y = log_f)) +
  geom_point() + ylim(0,0.009) + xlim(7, 12) +
  geom_vline(xintercept = 7, color = "red") +
  geom_smooth(method='lm') + theme_bw()

ggplot(tail_df, aes(x=dev_p, y = log_f)) +
  geom_point() + ylim(0,0.009) + xlim(8, 12) +
  geom_vline(xintercept = 8, color = "red") +
  geom_smooth(method='lm') + theme_bw()

dev_period <- 8:J
exp_tail_model <- lm((tail_df %>% filter(dev_p >= 8))$log_f ~ dev_period)

# optimal a and b using least squares
a_star <- coef(exp_tail_model)["(Intercept)"]
b_star <- coef(exp_tail_model)["dev_period"]

# we choose 100 as a high threshold
f_star_init <- exp(a_star + c(J:(J + 100)) * b_star)
f_star <- f_star_init[1:(min(which(f_star_init < 1))-1)]

# use the approximation on page 217
tau_hat <- prod(f_star)
tau_hat_arithmetic <- exp(-0.5*(a_star+J*b_star)*((a_star/b_star) + J))

# compute the ultimates
diagonal_elements <- (apply(cumulative_triangle, 1, max, na.rm=TRUE))
kappa_inverse <- c(1,cumprod(rev(f_CL)))         # product of \hat{f}
C_CL <- diagonal_elements[(I-J):I]*kappa_inverse # ultimate


claims_df <- data_frame("C_CL" = C_CL,
                        "diag" = diagonal_elements[(I-J):I]  ,
                        "kappa" = (1/kappa_inverse),
                        "I" = (I-J):I)
claims_df %>% 
  mutate("C_CL_plus" = C_CL*tau_hat) %>%
  mutate("tail_diff" = C_CL_plus- C_CL)

# C_CL_plus is the CL with extrapolation

