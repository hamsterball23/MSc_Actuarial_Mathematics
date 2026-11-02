###################################
########## Practical 5.2 ##########
###################################
library(ggplot2)
library(tidyverse)
data("usmedclaim", package = "CASdatasets")

#We index with j from 1 to J instead of from 0 to J'

source("11 StatIns/Exercises/Week 10/MackChainLadderMethod.R")

#----- Fit CL model -----
#usmedclaim is clearly incremental - negative values
MackCLFit <- MackChainLadderMethod(usmedclaim |> select(-members, -month))
fs <- MackCLFit$f[-length(MackCLFit$f)]

J <- ncol(usmedclaim |> select(-members, -month))

#----- Plot and choose treshold j_0 ----
plot_data <- data.frame(
  j = 0:(length(fs)-1),
  f = fs
)

# Thresholds for the zoomed panel and the lm-fit panel
j_zoom <- 2
j_0 <- 7

# Stack one copy of the data per panel, each with its own subset of j
panels <- c(
  "All factors",
  paste0("j >= ", j_zoom),
  paste0("j >= ", j_0, " with lm fit")
)
plot_data_panels <- bind_rows(
  plot_data |> mutate(panel = panels[1]),
  plot_data |> filter(j >= j_zoom) |> mutate(panel = panels[2]),
  plot_data |> filter(j >= j_0) |> mutate(panel = panels[3])
) |> mutate(panel = factor(panel, levels = panels))

plot_data_panels |>
  ggplot(aes(x = j, y = log(f))) +
  geom_point() +
  geom_line() +
  geom_smooth(
    data = filter(plot_data_panels, panel == panels[3]),
    method = "lm", formula = y ~ x, se = FALSE
  ) +
  facet_wrap(~panel, scales = "free")

#A j_0 at 7 seems adequate - a lower j0 gives a bad linear fit
# and a higher one would be very few datapoints for a linear fit


lmDecay <- lm(log(f) ~ j, plot_data |> filter(j >= j_0))
a_star <- coef(lmDecay)["(Intercept)"]
b_star <- coef(lmDecay)["j"]

#Tail factors
n <- 20
tail_factors <- pmax(
  exp(a_star + b_star * seq(J-1, J-1 + n)),
  1
)
tail_factors

#Using the approximation then the cumulative tail factor can be estimated:
cum_tail_factor_approx <- exp(-0.5*(a_star + (J-1) * b_star)*(a_star / b_star + J))
(cum_tail_factor_approx)

#Alternatively use cumprod
cum_tail_factor <- prod(tail_factors)
(cum_tail_factor)

#Ultimates:
#Without tail development factor
TotalUltimates_wo_tail_factor <- MackCLFit$TotalUltimate
TotalUltimates_w_tail_factor <- MackCLFit$TotalUltimate * cum_tail_factor
difference <- TotalUltimates_w_tail_factor - TotalUltimates_wo_tail_factor
rel_difference <- (cum_tail_factor - 1) / cum_tail_factor

(TotalUltimates_wo_tail_factor)
(TotalUltimates_w_tail_factor)
(difference)
(rel_difference)
#A 0.1 % increase!