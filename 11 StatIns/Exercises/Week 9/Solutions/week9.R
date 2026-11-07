# Solutions for week 9 in StatIns

# Practical exercise 3

# Load necessary libraries
library(rpart)        # For the regression tree
library(randomForest) # For random forest
library(gbm)          # For gradient boosting model

# Set the random seed
set.seed(2026)

## a.

# Generate the data
n <- 1000
eta <- function(x) 0.3 +2*dnorm(x,mean = 0.2,sd = 0.05) 
X <- runif(n, 0, 1)
S <- rank(X)/(n+1)
Y <-(1-S)^{-eta(X)} + 20*(X> 0.75)

# this is what the exercise asks for, but it creates some crazy results
#S <- runif(n, 0, 1)
#Y <- S^(-eta(X)) + 20 * (X > 0.75)

# Convert to data frame
data <- data.frame(X = X, Y = Y)

# here you can vary the max depth
tree_model <- rpart(Y ~ X, data = data, 
                    control = rpart.control(cp = 0, maxdepth = 2))

# Plot the regression tree
plot(tree_model, margin = 0.1)
text(tree_model, use.n = TRUE, cex = 0.8)
title("Single Regression Tree (Deeper)")
x_grid <- seq(-2.5, 2.5, length.out = 1000)
# Generate predictions from the tree model
y_pred_tree <- predict(tree_model, newdata = data.frame(x = x_grid))

plot(x_grid, y_pred_tree)
plot(X, Y)

## b.

rf_model <- randomForest(Y ~ X, data = data, ntree = 400, maxnodes = 15)

y_pred_rf <- predict(rf_model, newdata = data.frame(x = x_grid))


plot(X, Y, pch = 16, col = "blue", 
     main = "Single Tree and Random Forest Regression",
     xlab = "X", ylab = "Y")
lines(x_grid, y_pred_tree, col = "green", lwd = 2, lty = 2)
lines(x_grid, y_pred_rf, col = "red", lwd = 2)
legend("topright", legend = c("Data", "Tree Prediction", "RF Prediction"), 
       col = c("blue", "green", "red"), pch = c(16, NA, NA), lty = c(NA, 2, 1), lwd = c(NA, 2, 2))

## c.

# default is 'gaussian' distribution which is the squared error loss function
gbm_model <- gbm(Y ~ X, data = data, n.trees = 400, shrinkage = 0.1, interaction.depth = 4)

y_pred_gbm <- predict(gbm_model, newdata = data.frame(x = x_grid))

plot(X, Y, pch = 16, col = "blue", 
     main = "Single Tree and Random Forest Regression",
     xlab = "X", ylab = "Y")
lines(x_grid, y_pred_gbm, col = "red", lwd = 2)
legend("topright", legend = c("Data", "GBM prediction"), 
       col = c("blue", "red"), pch = c(16, NA, NA), lty = c(NA, 2, 1), lwd = c(NA, 2, 2))

# very close to the random forest predictions

# Practical exercise 4

# Load the required package
library(splines)
library(tidyverse)
library(magrittr)
set.seed(2026)

## a.

n <- 1000
X <- runif(n, -2.5, 2.5)
Y <- sin(2 * X) + rnorm(n, sd=0.2)
Z <- sin(2 * X) + rnorm(n, sd=0.2) + 2.2*(X < 0)*cos(2*X)

knots_chosen <- c(-1.25, 0, 1.25)

# first investigate for the Y's
model1 <- lm(Y ~ bs(X, degree = 1, knots = knots_chosen, Boundary.knots = c(-2.5,2.5)))
model2 <- lm(Y ~ bs(X, degree = 2, knots = knots_chosen, Boundary.knots = c(-2.5,2.5)))
model3 <- lm(Y ~ bs(X, degree = 3, knots = knots_chosen, Boundary.knots = c(-2.5,2.5)))
model4 <- lm(Y ~ bs(X, degree = 4, knots = knots_chosen, Boundary.knots = c(-2.5,2.5)))

#Divide the X's into 3 4 regions
X_segments <- data.frame("X" = X) %>%
  mutate("Segment_1" = 1*(X <= knots_chosen[1])) %>%
  mutate("Segment_2" = 1*(X > knots_chosen[1] & X <= knots_chosen[2])) %>%
  mutate("Segment_3" = 1*(X > knots_chosen[2] & X <= knots_chosen[3])) %>%
  mutate("Segment_4" = 1*(X > knots_chosen[3]))


X_segments %>% view()

Y_segmented <- X_segments %>% 
  mutate("Y" = Y) %>%
  select(-X)

model0 <- lm(Y ~ ., data = Y_segmented)
model0

x_sequence <- seq(-2.5, 2.5, length.out = n)
x_sequence_segments <- data.frame("X" = x_sequence) %>%
  mutate("Segment_1" = 1*(x_sequence <= knots_chosen[1])) %>%
  mutate("Segment_2" = 1*(x_sequence > knots_chosen[1] & x_sequence <= knots_chosen[2])) %>%
  mutate("Segment_3" = 1*(x_sequence > knots_chosen[2] & x_sequence <= knots_chosen[3])) %>%
  mutate("Segment_4" = 1*(x_sequence > knots_chosen[3]))

model_0_pred <- predict(model0, x_sequence_segments)

base_frame <- data.frame("X" = X, 
                         "Y" = Y, 
                         "x_seq" = x_sequence)

model_0_plot_frame <- base_frame %>%
  mutate("Y_predicted" = model_0_pred,
         "Order" = "0")

ggplot(data = model_0_plot_frame) + 
  geom_point(aes(x = X, y = Y)) + 
  geom_line(aes(x = x_seq, y = Y_predicted), color = "red") +
  geom_vline(xintercept = knots_chosen, linetype = "dashed") + 
  ggtitle("Piecewise constant Spline (Order 0) fitted to simulated data") +
  theme_bw()


all_models_plot_frame <-
  model_0_plot_frame %>%
  rbind(
    base_frame %>%
      mutate("Y_predicted" = predict(model1, x_sequence_segments),
             "Order" = "1"),
    base_frame %>%
      mutate("Y_predicted" = predict(model2, x_sequence_segments),
             "Order" = "2"),
    base_frame %>%
      mutate("Y_predicted" = predict(model3, x_sequence_segments),
             "Order" = "3"))

ggplot(data = all_models_plot_frame) + 
  geom_point(aes(x = X, y = Y)) + 
  geom_line(aes(x = x_seq, y = Y_predicted), color = "red", size = 1) +
  geom_vline(xintercept = knots_chosen, linetype = "dashed") + 
  ggtitle("Piecewise constant Spline (Order 0, 1, 2, 3) fitted to simulated data") + 
  facet_wrap(vars(Order)) + theme_bw()

# now for the Z's
model1 <- lm(Z ~ bs(X, degree = 1, knots = knots_chosen, Boundary.knots = c(-2.5,2.5)))
model2 <- lm(Z ~ bs(X, degree = 2, knots = knots_chosen, Boundary.knots = c(-2.5,2.5)))
model3 <- lm(Z ~ bs(X, degree = 3, knots = knots_chosen, Boundary.knots = c(-2.5,2.5)))
model4 <- lm(Z ~ bs(X, degree = 4, knots = knots_chosen, Boundary.knots = c(-2.5,2.5)))

#Divide the X's into 3 4 regions
Z_segmented <- X_segments %>% 
  mutate("Z" = Z) %>%
  select(-X)

model0 <- lm(Z ~ ., data = Z_segmented)

model_0_pred <- predict(model0, x_sequence_segments)

base_frame <- data.frame("X" = X, 
                         "Z" = Z, 
                         "x_seq" = x_sequence)

model_0_plot_frame <- base_frame %>%
  mutate("Z_predicted" = model_0_pred,
         "Order" = "0")

ggplot(data = model_0_plot_frame) + 
  geom_point(aes(x = X, y = Z)) + 
  geom_line(aes(x = x_seq, y = Z_predicted), color = "red") +
  geom_vline(xintercept = knots_chosen, linetype = "dashed") + 
  ggtitle("Piecewise constant Spline (Order 0) fitted to simulated data") +
  theme_bw()


all_models_plot_frame <-
  model_0_plot_frame %>%
  rbind(
    base_frame %>%
      mutate("Z_predicted" = predict(model1, x_sequence_segments),
             "Order" = "1"),
    base_frame %>%
      mutate("Z_predicted" = predict(model2, x_sequence_segments),
             "Order" = "2"),
    base_frame %>%
      mutate("Z_predicted" = predict(model3, x_sequence_segments),
             "Order" = "3"))

ggplot(data = all_models_plot_frame) + 
  geom_point(aes(x = X, y = Z)) + 
  geom_line(aes(x = x_seq, y = Z_predicted), color = "red", size = 1) +
  geom_vline(xintercept = knots_chosen, linetype = "dashed") + 
  ggtitle("Piecewise constant Spline (Order 0, 1, 2, 3) fitted to simulated data") + 
  facet_wrap(vars(Order)) + theme_bw()


## b.

set.seed(2026)
n <- 100
Nsim <- 100
pmax <- 15

df_with_train_test_error_joint <- data.frame("N" = NA, "p"  = NA, "Train_Y" = NA , "Test_Y" = NA, "Train_Z" = NA , "Test_Z" = NA )
for(i in 1:Nsim){
  X <- runif(n, -2.5, 2.5)
  Y <- sin(2 * X) + rnorm(n, sd=0.2) 
  Z <- sin(2 * X) + rnorm(n, sd=0.2) + 2.2*(X < 0)*cos(2*X)
  train_indices <- sample(seq_len(n), size =  n/2)
  train_x <- X[train_indices]
  test_x  <- X[-train_indices]
  train_y <- Y[train_indices]
  test_y  <- Y[-train_indices]
  train_z <- Z[train_indices]
  test_z  <- Z[-train_indices]
  
  for(p in 1:pmax){
    ft   <- lm(train_y ~ bs(train_x, degree = p, knots = knots_chosen, Boundary.knots = c(-2.5,2.5)))
    ft_z <- lm(train_z ~ bs(train_x, degree = p, knots = knots_chosen, Boundary.knots = c(-2.5,2.5)))
    df_with_train_test_error_joint %<>% 
      rbind( data.frame("N" = i, 
                        "p" = p , 
                        "Train_Y" = sum((ft$residuals)^2), 
                        "Test_Y" = sum((test_y - predict(ft, newdata = data.frame(train_x = test_x, train_y = test_y)))^2), 
                        "Train_Z" = sum((ft_z$residuals)^2), 
                        "Test_Z" = sum((test_z - predict(ft_z, newdata = data.frame(train_x = test_x, train_z = test_z)))^2)))
  }
}

max(df_with_train_test_error_joint$Test_Y[-1]) # 1 is NA

df_with_train_test_error_joint %<>% drop_na() 

mean_curves <- df_with_train_test_error_joint %>%
  group_by(p) %>%
  summarise("Mean_test_Y" = mean(Test_Y), "Mean_train_Y" = mean(Train_Y), "Mean_test_Z" = mean(Test_Z), "Mean_train_Z" = mean(Train_Z))

# in the following, blue is training error and red is test error

p1 <- ggplot(df_with_train_test_error_joint, aes(x = p)) + 
  geom_line(aes(y = Train_Z, group = N), stat="identity", alpha = 0.4, color = "#85c1e9") + 
  geom_line(aes(y = Test_Z, group = N) , stat="identity", alpha = 0.4, color = "#f1948a") + xlim(3,10) +ylim(2,30) +# ylim(2,30) +
  geom_line(data = mean_curves, aes(x = p, y = Mean_test_Y), color ="#e74c3c", size = 1.5) +
  geom_line(data = mean_curves, aes(x = p, y = Mean_train_Y), color = "#3498db", size = 1.5) + ylab("Train vs test error") + ggtitle("Training vs test error: Z = sin(2X) + N(0, 0.2^{2}) + 2.2*(X < 0)*cos(2X)") +
  geom_vline(xintercept = 6, linetype = "dashed") ## for degrees higher than 6 the test error starts to increase

p2 <- ggplot(df_with_train_test_error_joint, aes(x = p)) + 
  geom_line(aes(y = Train_Y, group = N), stat="identity", alpha = 0.4, color = "#85c1e9") + 
  geom_line(aes(y = Test_Y, group = N) , stat="identity", alpha = 0.4, color = "#f1948a") + xlim(3,10) + ylim(2,8) + # ylim(2,8) +
  geom_line(data = mean_curves, aes(x = p, y = Mean_test_Z), color ="#e74c3c", size = 1.5) +
  geom_line(data = mean_curves, aes(x = p, y = Mean_train_Z), color = "#3498db", size = 1.5) + ylab("Train vs test error") + ggtitle("Training vs test error: Y = sin(2X) + N(0, 0.2^{2})") +
  geom_vline(xintercept = 6, linetype = "dashed") ## for degrees higher than 6 the test error starts to increase

gridExtra::grid.arrange(p2, p1)
