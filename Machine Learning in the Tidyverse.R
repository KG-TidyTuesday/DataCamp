# Machine Learning in the Tidyverse
################################################################################################
# Chapter 1: Foundations of Tidy Machine Learning 
################################################################################################ 
# Create the unnested dataframe called gap_unnnested
gap_unnested <- gap_nested %>% 
  unnest()
  
# Confirm that your data was not modified  
identical(gapminder, gap_unnested)

# Extract the data of Algeria
algeria_df <- gap_nested$data[[1]]

# Calculate the minimum of the population vector
min(algeria_df$population)

# Calculate the maximum of the population vector
max(algeria_df$population)

# Calculate the mean of the population vector
mean(algeria_df$population)

########################################################################################

# Calculate the mean population for each country
pop_nested <- gap_nested %>%
  mutate(mean_pop = map(.x = gap_nested$data, ~mean(.x$population)))

# Take a look at pop_nested
head(pop_nested)

# Extract the mean_pop value by using unnest
pop_mean <- pop_nested %>% 
  unnest(mean_pop)

# Take a look at pop_mean
head(pop_mean)

####################################################################################
# Chapter 2: Exploring coefficients across models
####################################################################################
# Build a linear model for each country
gap_models <- gap_nested %>%
    mutate(model = map(data, ~lm(formula = life_expectancy~year, data = .x)))
    
# Extract the model for Algeria    
algeria_model <- gap_models$model[[1]]

# View the summary for the Algeria model
summary(algeria_model)

########################################################################################

library(broom)

# Extract the coefficients of the algeria_model as a dataframe
tidy(algeria_model)

# Extract the statistics of the algeria_model as a dataframe
glance(algeria_model)

###########################################################################################

# Build the augmented dataframe
algeria_fitted <- augment(algeria_model)

# Compare the predicted values with the actual values of life expectancy
algeria_fitted %>% 
  ggplot(aes(x = year)) +
  geom_point(aes(y = life_expectancy)) + 
  geom_line(aes(y = .fitted), color = "red")

##################################################################################

# Extract the coefficient statistics of each model into nested dataframes
model_coef_nested <- gap_models %>% 
    mutate(coef = map(model, ~tidy(.x)))
    
# Simplify the coef dataframes for each model    
model_coef <- model_coef_nested %>%
    unnest(coef)

# Plot a histogram of the coefficient estimates for year         
model_coef %>% 
  filter(term == "year") %>% 
  ggplot(aes(x = estimate)) +
  geom_histogram()

######################################################################################

# Extract the fit statistics of each model into dataframes
model_perf_nested <- gap_models %>% 
    mutate(fit = map(model, ~glance(.x)))

# Simplify the fit dataframes for each model    
model_perf <- model_perf_nested %>% 
    unnest(fit)
    
# Look at the first six rows of model_perf
head(model_perf)

#################################################################################

# Plot a histogram of rsquared for the 77 models    
model_perf %>% 
  ggplot(aes(x = r.squared)) + 
 geom_histogram()  
  
# Extract the 4 best fitting models
best_fit <- model_perf %>% 
  top_n(n = 4, wt = r.squared)

# Extract the 4 models with the worst fit
worst_fit <- model_perf %>% 
  top_n(n = 4, wt = -r.squared)

#################################################################################

best_augmented <- best_fit %>% 
  # Build the augmented dataframe for each country model
  mutate(augmented = map(model, ~augment(.x))) %>% 
  # Expand the augmented dataframes
 unnest(augmented)

worst_augmented <- worst_fit %>% 
  # Build the augmented dataframe for each country model
  mutate(augmented = map(model, ~augment(.x))) %>% 
  # Expand the augmented dataframes
   unnest(augmented)

# Compare the predicted values with the actual values of life expectancy 
# for the top 4 worst fitting models
worst_augmented %>% 
  ggplot(aes(x = year)) +
  geom_point(aes(y = ___)) + 
  geom_line(aes(y = ___), color = "red") +
  facet_wrap(~country, scales = "free_y")

# Compare the predicted values with the actual values of life expectancy 
# for the top 4 worst fitting models
worst_augmented %>% 
  ggplot(aes(x = year)) +
  geom_point(aes(y = life_expectancy)) + 
  geom_line(aes(y = .fitted), color = "red") +
  facet_wrap(~country, scales = "free_y")


# Build a linear model for each country using all features
gap_fullmodel <- gap_nested %>% 
  mutate(model = map(data, ~lm(formula = life_expectancy ~ ., data = .x)))

fullmodel_perf <- gap_fullmodel %>% 
  # Extract the fit statistics of each model into dataframes
  mutate(fit = map(model, ~ glance(.x))) %>% 
  # Simplify the fit dataframes for each model
  unnest(fit)
  
# View the performance for the four countries with the worst fitting 
# four simple models you looked at before
fullmodel_perf %>% 
  filter(country %in% worst_fit$country) %>% 
  select(country, adj.r.squared)

#####################################################################################################
# Chapter 3: Training, test and validation splits
#####################################################################################################

set.seed(42)

# Prepare the initial split object
gap_split <- initial_split(gampminder, prop = 0.75)

# Extract the training dataframe
training_data <- training(gap_split)

# Extract the testing dataframe
testing_data <- testing(gap_split)

# Calculate the dimensions of both training_data and testing_data
dim(training_data)
dim(testing_data)

set.seed(42)

# Prepare the dataframe containing the cross validation partitions
cv_split <- vfold_cv(training_data, v = 5)

cv_data <- cv_split %>% 
  mutate(
    # Extract the train dataframe for each split
    train = map(splits, ~training(.x)), 
    # Extract the validate dataframe for each split
    validate = map(splits, ~testing(.x))
  )

# Use head() to preview cv_data
head(cv_data)


###############################################################################
# Build a model using the train data for each fold of the cross validation
cv_models_lm <- cv_data %>% 
  mutate(model = map(train, ~lm(formula = life_expectancy~., data = .x)))

cv_prep_lm <- cv_models_lm %>% 
  mutate(
    # Extract the recorded life expectancy for the records in the validate dataframes
    validate_actual = map(validate, ~.x$life_expectancy),
    # Predict life expectancy for each validate set using its corresponding model
    validate_predicted = map2(.x = model, .y = validate, ~predict(.x, .y))
  )


##################################################################################

library(Metrics)
# Calculate the mean absolute error for each validate fold       
cv_eval_lm <- cv_prep_lm %>% 
  mutate(validate_mae = map2_dbl(validate_actual, validate_predicted, ~mae(actual = .x, predicted = .y)))

# Print the validate_mae column
cv_eval_lm$validate_mae

# Calculate the mean of validate_mae column
mean(cv_eval_lm$validate_mae)

################################################################################################################
library(ranger)

# Build a random forest model for each fold
cv_models_rf <- cv_data %>% 
  mutate(model = map(train, ~ranger(formula = life_expectancy~., data = .x,
                                    num.trees = 100, seed = 42)))

# Generate predictions using the random forest model
cv_prep_rf <- cv_models_rf %>% 
  mutate(validate_predicted = map2(.x =model, .y = validate, ~predict(.x, .y)$predictions))


#####################################################################################################

library(ranger)

# Calculate validate MAE for each fold
cv_eval_rf <- cv_prep_rf %>% 
  mutate(validate_mae = map2_dbl(validate_actual, validate_predicted , ~mae(actual = .x, predicted = .y)))

# Print the validate_mae column
cv_eval_rf$validate_mae


# Calculate the mean of validate_mae column
mean(cv_eval_rf$validate_mae)



# Prepare for tuning your cross validation folds by varying mtry
cv_tune <- cv_data %>% 
  crossing(mtry = 2:5) 

# Build a model for each fold & mtry combination
cv_model_tunerf <- cv_tune %>% 
  mutate(model = map2(.x = train, .y = mtry, ~ranger(formula = life_expectancy~., 
                                           data = .x, mtry = .y, 
                                           num.trees = 100, seed = 42)))
##########################################################################################################

# Generate validate predictions for each model
cv_prep_tunerf <- cv_model_tunerf %>% 
  mutate(validate_predicted = map2(.x = model, .y = validate, ~predict(.x, .y)$predictions))

# Calculate validate MAE for each fold and mtry combination
cv_eval_tunerf <- cv_prep_tunerf %>% 
  mutate(validate_mae = map2_dbl(.x = validate_actual, .y = validate_predicted, ~mae(actual = .x, predicted = .y)))

# Calculate the mean validate_mae for each mtry used  
cv_eval_tunerf %>% 
  group_by(mtry) %>% 
  summarise(mean_mae = mean(validate_mae))

# Build the model using all training data and the best performing parameter
best_model <- ranger(formula = life_expectancy~., data = training_data,
                     mtry = 4, num.trees = 100, seed = 42)

# Prepare the test_actual vector
test_actual <- testing_data$life_expectancy

# Predict life_expectancy for the testing_data
test_predicted <- predict(best_model, testing_data)$predictions

# Calculate the test MAE
mae(test_actual, test_predicted)


cv_prep_lr <- cv_models_lr %>% 
  mutate(
    # Prepare binary vector of actual Attrition values in validate
    validate_actual = map(validate, ~.x$Attrition == "Yes"),
    # Prepare binary vector of predicted Attrition values for validate
    validate_predicted = map2(.x = model , .y = validate, ~predict(.x, .y, type = "response") >  0.5)
  )



#############################################################################################
# Chapter 4: Logstic Regression Models
###########################################################################################

set.seed(42)

# Prepare the initial split object
data_split <- initial_split(attrition, prop = 00.75)

# Extract the training dataframe
training_data <- training(data_split)

# Extract the testing dataframe
testing_data <- testing(data_split)



set.seed(42)
cv_split <- vfold_cv(training_data, v = 5)

cv_data <- cv_split %>% 
  mutate(
    # Extract the train dataframe for each split
    train = map(splits, ~training(.x)),
    # Extract the validate dataframe for each split
    validate = map(splits, ~testing(.x))
  )



# Extract the first model and validate 
model <- cv_models_lr$model[[1]]
validate <- cv_models_lr$validate[[1]]

# Prepare binary vector of actual Attrition values in validate
validate_actual <- validate$Attrition == "Yes"

# Predict the probabilities for the observations in validate
validate_prob <- predict(model, validate, type = "response")

# Prepare binary vector of predicted Attrition values for validate
validate_predicted <- validate_prob > 0.5


library(Metrics)

# Compare the actual & predicted performance visually using a table
table(validate_actual, validate_predicted)

# Calculate the accuracy
accuracy(validate_actual, validate_predicted)

# Calculate the precision
precision(validate_actual, validate_predicted)

# Calculate the recall
recall(validate_actual, validate_predicted)


# Calculate the validate recall for each cross validation fold
cv_perf_recall <- cv_prep_lr %>% 
  mutate(validate_recall = map2_dbl(.x = validate_actual, .y = validate_predicted,
                                    ~recall(actual = .x, predicted = .y)))

# Print the validate_recall column
cv_perf_recall$validate_recall

# Calculate the average of the validate_recall column
mean(cv_perf_recall$validate_recall)

###########################################################################################
# Evaluate the random forest model
###########################################################################################

library(ranger)

# Prepare for tuning your cross validation folds by varying mtry
cv_tune <- cv_data %>%
  crossing(mtry = c(2, 4, 8, 16)) 

# Build a cross validation model for each fold & mtry combination
cv_models_rf <- cv_tune %>% 
  mutate(model = map2(train, mtry, ~ranger(formula = Attrition~., 
                                           data = .x, mtry = .y,
                                           num.trees = 100, seed = 42)))


cv_prep_rf <- cv_models_rf %>% 
  mutate(
    # Prepare binary vector of actual Attrition values in validate
    validate_actual = map(validate, ~.x$Attrition == "Yes"),
    # Prepare binary vector of predicted Attrition values for validate
    validate_predicted = map2(.x = model, .y = validate, ~predict(.x, .y, type = "response")$predictions == "Yes")
  )

# Calculate the validate recall for each cross validation fold
cv_perf_recall <- cv_prep_rf %>% 
  mutate(recall = map2_dbl(.x = validate_actual, .y = validate_predicted, ~recall(actual = .x, predicted = .y)))

# Calculate the mean recall for each mtry used  
cv_perf_recall %>% 
  group_by(mtry) %>% 
  summarise(mean_recall = mean(recall))


# Build the logistic regression model using all training data
best_model <- glm(formula = Attrition ~., 
                  data = training_data, family = "binomial")


# Prepare binary vector of actual Attrition values for testing_data
test_actual <- testing_data$Attrition == "Yes"

# Prepare binary vector of predicted Attrition values for testing_data
test_predicted <- predict(best_model, testing_data, type = "response") > 0.5


# Compare the actual & predicted performance visually using a table
table(test_actual,test_predicted )
# Calculate the test accuracy
accuracy(test_actual,test_predicted )

# Calculate the test precision
precision(test_actual,test_predicted )

# Calculate the test recall
recall(test_actual,test_predicted )



