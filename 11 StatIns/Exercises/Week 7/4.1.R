###################################
########## Practical 4.1 ##########
###################################
library(glmnet)
data(norauto, package = "CASdatasets")

#Model claims (NbClaim) using a Poisson regression with
#Covariates: (Male, Young, DistLimit, GeoRegion)


#########
### a ###
#########

poisson_glm <- glm(
  formula = NbClaim ~ Male + Young + DistLimit + GeoRegion,
  offset = log(Expo),  #On log scale so offset needs log
  family = poisson,
  data = norauto
)
coef(poisson_glm)

#########
### b ###
#########

# glmnet has no formula interface: build the design matrix (dummies) by hand
X <- model.matrix(NbClaim ~ Male + Young + DistLimit + GeoRegion, norauto)[, -1]
y <- norauto$NbClaim

poisson_ridge <- glmnet(
  x = X, y = y,
  family = "poisson",
  offset = log(norauto$Expo),  #On log scale so offset needs log
  alpha = 0
)
plot(poisson_ridge, xvar = "lambda", label = TRUE)


#########
### c ###
#########
poisson_lasso <- glmnet(
  x = X, y = y,
  family = "poisson",
  offset = log(norauto$Expo), #On log scale so offset needs log
  alpha = 1
)
plot(poisson_lasso, xvar = "lambda", label = TRUE)


#########
### d ###
#########

# Choose lambda by cross-validation
set.seed(1)
cv_ridge <- cv.glmnet(
  x = X, y = y,
  family = "poisson",
  offset = log(norauto$Expo),
  alpha = 0
)
plot(cv_ridge)

set.seed(1)
cv_lasso <- cv.glmnet(
  x = X, y = y,
  family = "poisson",
  offset = log(norauto$Expo),
  alpha = 1
)
plot(cv_lasso)


cbind(
  glm       = coef(poisson_glm),
  ridge_min = as.vector(coef(cv_ridge, s = "lambda.min")),
  lasso_min = as.vector(coef(cv_lasso, s = "lambda.min")),
  ridge_1se = as.vector(coef(cv_ridge, s = "lambda.1se")),
  lasso_1se = as.vector(coef(cv_lasso, s = "lambda.1se"))
)

#Yes, your code fits the exercise, and the result is what you should expect here. The lasso isn't doing anything wrong.

# Why nothing is exactly zero at lambda.min: the lasso only zeroes a coefficient when λ is large enough to outweigh that covariate's contribution to the likelihood. The data has 184k policies and only 12 coefficients, and every covariate carries real signal (look at the GLM estimates). So cross-validation finds that almost any penalty hurts the out-of-sample deviance, and it picks a tiny λ:

# lambda.min	Non-zero coefficients
# Ridge	9.7e-4	12 (ridge never sets any to zero)
# Lasso	2.3e-5	12
# Lasso, lambda.1se	3.2e-3	5
# At λ ≈ 2e-5 the penalty is basically zero, so the lasso gives back the GLM coefficients. Ridge at its lambda.min is also close to the GLM.

# Where the lasso's sparsity does show up:

# Coefficient path plot from (c): as log(λ) increases, coefficients hit exactly zero one at a time. That's the lasso behaviour the exercise wants you to see.
# lambda.1se: this is the largest λ whose CV deviance is within one standard error of the minimum. There, 7 of the 12 coefficients are exactly zero. You can see this with print(cv_lasso), as in the table above.
# For your write-up of (d): with lots of data and few covariates, regularisation adds almost nothing. The CV-optimal penalty is close to zero, so ridge and lasso both end up close to the MLE. Shrinkage and variable selection matter when the number of parameters is large compared to the information in the data.

# One thing to check: the exercise says "offset Expo", but the code uses log(Expo). That's correct for a log link, because it makes the expected claim count proportional to exposure. It's worth confirming that your course's solutions mean the same thing.