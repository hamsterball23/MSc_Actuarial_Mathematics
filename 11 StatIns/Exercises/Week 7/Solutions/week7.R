# Solutions for week 7 in StatIns

# Practical exercise 1

library(CASdatasets)
library(glmnet)
library(dplyr)

data(norauto)
auto_df <- as.data.frame(norauto)

## a. 

# Call the standard glm() function. We remove the intercept for intepretability.
norway_glm <- glm(NbClaim ~ Male + Young + DistLimit + GeoRegion + offset(log(Expo)),
  family = poisson(link = "log"),
  data   = norauto
)

# Call summary on the model to asses fitted coefficients, std error, P-values etc.
summary(norway_glm)

# OUTPUT: We see that GeoRegionMedium+ appears to be the least significant factor level.

## b. 

# Define model matrix, response and offset
norway_covariates <- model.matrix(NbClaim ~ Male + Young + DistLimit + GeoRegion, data = norauto)[, -1]
norway_response <- norauto$NbClaim
norway_offset <- log(norauto$Expo)

# Fit a Poisson model with ridge regularization (which is specified with alpha = 0)
norway_ridge <- glmnet(norway_covariates,
  norway_response,
  family = "poisson",
  alpha = 0,
  offset = norway_offset,
  intercept = TRUE
)

coef(norway_ridge) %>% as.matrix() # we now have a ton of models each corresponding to a different choice of shrinkage parameter lambda
coef(norway_ridge) %>%
  as.matrix() %>%
  rownames() # we check that the variables correspond to those of the glm call

# We plot the fit
variable_df <- data.frame("label" = names(coefficients(norway_glm))[-1]) # We call this to have the covariates number in the terminal while looking at the plot
plot(norway_ridge, xvar = "lambda", label = TRUE) # The top line shows the number of variables included. You can see that it remains 12 for all log-lambda, and thus no variable exclusion is performed by the ridge.

## c.

# Fit a Poisson model with ridge regularization (which is specified with alpha = 1)
norway_lasso <- glmnet(norway_covariates,
  norway_response,
  family = "poisson",
  alpha = 1,
  offset = norway_offset,
  intercept = TRUE
)

coef(norway_lasso) %>% as.matrix() # we now have a ton of models each corresponding to a different choice of shrinkage parameter lambda
coef(norway_lasso) %>%
  as.matrix() %>%
  rownames() # we check that the variables correspond to those of the glm call

# We plot the fit
variable_df
plot(norway_lasso, xvar = "lambda", label = TRUE) # In this plot we see that sparsity that the lasso induces, which effectively is performing the variables selection.

# Compare with the ridge
par(mfrow = c(2, 1))
plot(norway_ridge, xvar = "lambda", label = TRUE)
plot(norway_lasso, xvar = "lambda", label = TRUE) # Beware the different x-axis!!

## d.

# first perform CV for ridge

# Perform cross-validation to select λ for ridge regression
cv_norway_ridge <- cv.glmnet(norway_covariates,
  norway_response,
  family = "poisson",
  alpha = 0,
  offset = norway_offset,
  intercept = TRUE
) # The default number of folds in this cross-validation is 10

cv_deviance_optimal_lambda_ridge <- cv_norway_ridge$lambda.min # Extract the optimal lambda. For the possion glm family, the default is the deviance loss and not the mean squarred error.

par(mfrow = c(1, 1))
plot(cv_norway_ridge) # Plot the deviance as a function of log-lambda

# Refit the ridge model using the optimal lambda
cv_norway_ridge_optimal <- glmnet(norway_covariates,
  norway_response,
  family = "poisson",
  alpha = 0,
  lambda = cv_deviance_optimal_lambda_ridge,
  offset = norway_offset,
  intercept = TRUE
)

ridge_cv_coefs <- coef(cv_norway_ridge_optimal)
colnames(ridge_cv_coefs) <- "ridge"

# Compare with the glm coefficients
ridge_cv_coefs %>%
  cbind("glm" = norway_glm$coefficients %>%
    as.vector())

# now perform CV for Lasso GLM

cv_norway_lasso <- cv.glmnet(norway_covariates,
  norway_response,
  family    = "poisson",
  alpha     = 1,
  offset    = norway_offset,
  intercept = TRUE
) # The default number of folds in this cross-validation is 10


cv_deviance_optimal_lambda_lasso <- cv_norway_lasso$lambda.min # Extract the optimal lambda. For the possion glm family, the default is the deviance loss and not the mean squarred error.

par(mfrow = c(1, 1))
plot(cv_norway_lasso) # Plot the deviance as a function of log-lambda in the lasso case

# Refit the lasso model using the optimal lambda
cv_norway_lasso_optimal <- glmnet(norway_covariates,
  norway_response,
  family    = "poisson",
  alpha     = 1,
  lambda    = cv_deviance_optimal_lambda_lasso,
  offset    = norway_offset,
  intercept = TRUE
)

lasso_cv_coefs <- coef(cv_norway_lasso_optimal)
colnames(lasso_cv_coefs) <- "lasso"

# Compare with glm with ridge cross validation and lasso cross validation.
cbind(
  "glm" = norway_glm$coefficients %>%
    as.vector(),
  ridge_cv_coefs,
  lasso_cv_coefs
)
