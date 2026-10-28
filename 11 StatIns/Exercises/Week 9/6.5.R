###################################
########## Practical 6.5 ##########
###################################
library(tidyverse)
library(rpart)
library(mgcv)

sim_data <- function(n, seed = 2026)
{
  set.seed(seed)
  X <- matrix(rnorm(n * 5), ncol = 5, dimnames = list(NULL, paste0("X", 1:5)))
  epsilon <- rnorm(n)
  Y <- 2 + X[, "X1"] + 2 * sin(X[, "X2"]) + X[, "X3"]^2 + epsilon

  return(
    data.frame(X, Y = Y)
  )
}

#########
### a ###
#########
data_sim <- sim_data(3000, seed = 2026)

#########
### b ###
#########

# 70/30 train/test split
set.seed(2025)
train_idx <- sample(nrow(data_sim), size = 0.7 * nrow(data_sim))
train <- data_sim[train_idx, ]
test  <- data_sim[-train_idx, ]

# The three base models, as functions so they can be refitted on each CV fold
fit_lm   <- function(data) lm(Y ~ X1 + X2 + X3 + X4 + X5, data = data)
fit_tree <- function(data) rpart(Y ~ X1 + X2 + X3 + X4 + X5, data = data)
fit_gam  <- function(data) gam(Y ~ s(X1) + s(X2) + s(X3) + s(X4) + s(X5), data = data)

base_fitters <- list(lm = fit_lm, tree = fit_tree, gam = fit_gam)

# Fit each base model on the full training set
base_fits <- map(base_fitters, \(fit) fit(train))

#########
### c ###
#########

# Assign each training observation to one of K = 5 folds
K <- 5
folds <- sample(rep(1:K, length.out = nrow(train)))

# Out-of-fold predictions: for fold k, fit on the other folds and predict fold k
oof_pred <- matrix(NA, nrow(train), length(base_fitters),
                   dimnames = list(NULL, names(base_fitters)))

for (k in 1:K){
  in_fold <- folds == k
  for (m in names(base_fitters)){
    fit_k <- base_fitters[[m]](train[!in_fold, ])
    oof_pred[in_fold, m] <- predict(fit_k, newdata = train[in_fold, ])
  }
}

# Constrained least squares: minimise sum (Y - P w)^2 over w >= 0, sum(w) = 1.
# Parametrise w = softmax(theta), so the constraints hold automatically and we
# can use an unconstrained optimiser.
softmax <- function(theta) exp(theta) / sum(exp(theta))

stack_loss <- function(theta, P, y) mean((y - P %*% softmax(theta))^2)

opt <- optim(rep(0, ncol(oof_pred)), stack_loss, P = oof_pred, y = train$Y,
             method = "BFGS")
weights <- setNames(softmax(opt$par), colnames(oof_pred))
round(weights, 4)

# Conclusion (c):
# The weights are lm ~ 0.001, tree ~ 0.002, gam ~ 0.997. (Softmax can't reach exactly 0,
# so the tiny weights are effectively 0.)
# This makes sense: the true regression function is additive, 2 + x1 + 2 sin(x2) + x3^2,
# so the GAM is correctly specified. The lm misses sin and the square, and the tree is
# piecewise constant. Neither adds information the GAM doesn't already have.

#########
### d ###
#########

# Test-set predictions of the base models (fitted on all of train) and the stack
predict_base <- function(data) sapply(base_fits, \(fit) predict(fit, newdata = data))
predict_stack <- function(data) as.vector(predict_base(data) %*% weights)

test_preds <- data.frame(predict_base(test), stack = predict_stack(test))

# Test MSE per predictor
test_mse <- test_preds |>
  summarise(across(everything(), \(p) mean((test$Y - p)^2))) |>
  pivot_longer(everything(), names_to = "model", values_to = "mse") |>
  arrange(mse)
test_mse

ggplot(test_mse, aes(reorder(model, mse), mse)) +
  geom_col() +
  geom_hline(yintercept = 1, linetype = "dashed") + # Var(epsilon) = irreducible error
  labs(title = "Test MSE of base models and stacked predictor",
       x = NULL, y = "Test MSE")

# Permutation importance of the stack: shuffle one covariate in the test set,
# and record the increase in test MSE. Averaged over B shuffles.
B <- 20
mse_stack <- mean((test$Y - predict_stack(test))^2)

perm_importance <- map_dfr(paste0("X", 1:5), \(v) {
  increase <- map_dbl(1:B, \(b) {
    test_perm <- test
    test_perm[[v]] <- sample(test_perm[[v]])
    mean((test$Y - predict_stack(test_perm))^2) - mse_stack
  })
  tibble(variable = v, importance = mean(increase), sd = sd(increase))
}) |>
  mutate(relative = importance / sum(importance))
perm_importance

ggplot(perm_importance, aes(variable, importance)) +
  geom_col() +
  geom_errorbar(aes(ymin = importance - sd, ymax = importance + sd), width = 0.2) +
  labs(title = "Permutation importance of the stacked predictor",
       x = NULL, y = "Increase in test MSE")

# Conclusion (d):
# Test MSE: gam 0.995, stack 0.996, tree 2.43, lm 3.43. The stack is essentially the
# GAM, and both are at the irreducible error Var(epsilon) = 1.
# Here stacking can't beat its best component, because one component is already
# (almost) the true model. It just picks out that component automatically.
# Permutation importance (increase in test MSE): X3 ~ 4.1, X2 ~ 3.4, X1 ~ 1.9, while
# X4 and X5 are ~ 0.000 and 0.002 (within noise of 0). As shares of the total, that is
# X3 44%, X2 36%, X1 20%, and X4, X5 < 0.03%. So X4 and X5 have no importance, as expected.
# The ordering matches the true variance contributions:
# Var(X3^2) = 2, Var(2 sin(X2)) = 2(1 - e^-2) ~ 1.73, Var(X1) = 1.
# Permuting X_j removes its signal and adds an independent copy, which roughly doubles
# that variance contribution: ~4, ~3.5 and ~2.
