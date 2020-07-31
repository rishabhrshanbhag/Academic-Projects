library(tidyverse)
library(caret)
library(modelr)
library(mlbench)
library(olsrr)
library(ggpubr)
library(purrr)
library(corrplot)
library(kernlab)
library(xgboost)
set.seed(1)

heart_data <- read_csv("../Data/heart.csv")
heart_data <- heart_data %>%
  mutate(
    cp = as_factor(cp),
    exang = as_factor(exang)
  )

# # Choosing the right variables
fit1 <- lm(target ~ age + sex + cp +  trestbps + chol + fbs + thalach + restecg + exang + oldpeak + slope + ca, data=heart_data)
k <- ols_step_best_subset(fit1)
plot(k)
# 
# # Age is not a good parameter
# 
# fit2 <- lm(target ~ cp + trestbps + chol + fbs + thalach, data=heart_data)
# k <- ols_step_best_subset(fit2)
# plot(k)
# 
# # cp + thalach + trestbps are best parameters
# 
#Adding oldpeak
fit3 <- lm(target ~ cp + exang + thalach + oldpeak, data=heart_data)
k <-  ols_step_best_subset(fit3)
plot(k)

formula <- "target ~ cp + exang + thalach + oldpeak"
# Making Corelation Matrix
heart_corr <- cor(heart_data)
corrplot(heart_corr)

heart_part <- resample_partition(heart_data, c(train = 0.8,
                                               test = 0.2))
heart_train <- as_tibble(heart_part$train)
heart_test <- as_tibble(heart_part$test)

# fit_f <- lm(target ~ cp + trestbps + thalach + oldpeak, data=heart_train)
fit_f <- lm(formula, data=heart_train)

p1 <- heart_train %>% add_residuals(fit_f) %>%
  ggplot(aes(x=cp, y=resid)) + geom_boxplot()
p2 <- heart_train %>% add_residuals(fit_f) %>%
  ggplot(aes(x=exang, y=resid)) + geom_boxplot()
p3 <- heart_train %>% add_residuals(fit_f) %>%
  ggplot(aes(x=thalach, y=resid)) + geom_point()
p4 <- heart_train %>% add_residuals(fit_f) %>%
  ggplot(aes(x=oldpeak, y=resid)) + geom_point()
ggarrange(p1, p2, p3, p4, ncol = 2,nrow = 2)

rmse(fit_f2, heart_part$test)
rmse(fit_f2, heart_part$train)

set.seed(1)
heart_cv <- crossv_kfold(heart_data, 5)

heart_cv <- heart_cv %>%
  mutate(fit = map(train,
                   ~ lm(target ~  cp + slope + ca + thal,
                        data = .)))
heart_cv

heart_cv <- heart_cv %>%
  mutate(rmse_train = map2_dbl(fit, train, ~ rmse(.x, .y)),
         rmse_test = map2_dbl(fit, test, ~ rmse(.x, .y)))

mean(heart_cv$rmse_train)
mean(heart_cv$rmse_test)

distPred <- predict(fit_f, heart_test)
actuals_preds <- as_tibble(cbind(actuals=heart_test$target, predicteds=distPred))
actuals_preds <- actuals_preds %>%
  mutate(predicted2 = ifelse(predicteds > 0.5, 1, 0))
confusionMatrix(as.factor(actuals_preds$predicted2), as.factor(actuals_preds$actuals))

# Model Training
#LSVM
heart_train <- heart_train %>%
  mutate(
    target = as_factor(target)
  )
lssvm_model <- lssvm(target ~ cp + exang + thalach + oldpeak + ca + slope + thal, data=heart_train, )

distPred <- predict(lssvm_model, heart_test)

confusionMatrix(as.factor(distPred), as_factor(heart_test$target))

#XG Boost
xgboostdata <- heart_train %>%
  select(cp, exang, thalach, oldpeak)

xgboostdata <- data.matrix(xgboostdata)

bstSparse <- xgboost(data = xgboostdata, label = heart_train$target, max_depth = 2, eta = 1, nthread = 2, nrounds = 2, objective = "binary:logistic")
  