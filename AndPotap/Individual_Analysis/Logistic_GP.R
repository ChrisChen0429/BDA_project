#### Notes
# This file runs the Logistic Gaussian Process

## Imports  ######################################################
library(rstan)
library(tidyverse)
library(ggplot2)
library(arm)
library(bayesplot)
options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)
knitr::opts_chunk$set(echo = TRUE)
##################################################################

#### Files  ######################################################
file <-  './data/core.txt'
# file_model_logistic <- './Models/logistic_gp_v01.stan'
file_model <- './Models/logistic_gp_multi_v02.stan'
# file_model <- './AndPotap/Individual_Analysis/Models/logistic_gp_multi_v02.stan'
##################################################################

##################################################################
## Load the data
data <- read_delim(file = file, delim = '|')

# Sample the data
# pct = 1
# pct = 0.1
pct = 0.01
set.seed(seed = 42)
sample_size = round(pct * nrow(data))
sample <- sample(x = nrow(data), size = sample_size, replace = F)
data = data[sample, ]

## Selecting the relevant columns for the analysis
data_sub <- data %>% dplyr::select(
  state,
  city,
  county,
  zip,
  asset_market_value,
  mar_2_app,
  appraisal_value,
  app_2_inc,
  client_income,
  mar_2_inc,
  age,
  sex_F,
  condition_U,
  y,
  y2)
summary(data_sub)


## Group data by state and define the IDs
state_summary <- data_sub %>% 
  dplyr::select(state) %>% 
  group_by(state) %>% 
  summarize(n_state = n()) %>% 
  arrange(desc(n_state)) %>% 
  ungroup()

state_summary$ID_state = seq.int(nrow(state_summary))

## Group data by city and define the IDs
city_summary <- data_sub %>% 
  dplyr::select(city) %>% 
  group_by(city) %>% 
  summarize(n_city = n()) %>% 
  arrange(desc(n_city)) %>% 
  ungroup()

city_summary$ID_city = seq.int(nrow(city_summary))

## Merge back into data
data_sub <- data_sub %>% 
  inner_join(y = state_summary[, c('state', 'ID_state')], by = 'state') %>%
  inner_join(y = city_summary[, c('city', 'ID_city')], by = 'city')
##################################################################

##################################################################
## Rescaling
inputs <- data_sub %>%
  mutate(
    income_st = (log(client_income) - mean(log(client_income))) 
    / sd(log(client_income)),
    appraisal_st = (log(appraisal_value) - mean(log(appraisal_value))) 
    / sd(log(appraisal_value)),
    market_st = (log(asset_market_value) - mean(log(asset_market_value))) 
    / sd(log(asset_market_value)),
    mar_2_inc_st = (mar_2_inc - mean(mar_2_inc)) / sd(mar_2_inc),
    app_2_inc_st = (app_2_inc - mean(app_2_inc)) / sd(app_2_inc),
    mar_2_app_st = (mar_2_app - mean(mar_2_app)) / sd(mar_2_app),
    age_st = (age - mean(age)) / sd(age)
  ) %>% 
  dplyr::select(
    income_st,
    mar_2_inc_st,
    appraisal_st,
    # app_2_inc_st,
    # mar_2_app_st,
    # market_st,
    age_st,
    y,
    y2
  )

## Train / Test split
set.seed(seed = 81989843)
pct_train = 0.9
sample_size = round(pct_train * nrow(inputs))
sample <- sample(x = nrow(inputs), size = sample_size, replace = F)

## Allocate train
y = inputs$y

inputs_train = inputs[sample, ]
y_train = y[sample]

## Allocate test
inputs_test = inputs[-sample, ]
y_test = y[-sample]

## Create inputs for STAN
data_stan_train <- list(N=nrow(inputs_train), 
                        D=ncol(inputs_train), 
                        X=inputs_train, 
                        y=y_train)

## Inputs for STAN
X_train = inputs_train %>% dplyr::select(-y, -y2)
X_test = inputs_test %>% dplyr::select(-y, -y2)
D = ncol(X_train)
N = nrow(X_train)
N1 = nrow(X_train)
N2 = nrow(X_test)

data_stan_train = list(N1=N1, 
                       N2=N2, 
                       D=D, 
                       x1=X_train, 
                       x2=X_test, 
                       z1=y_train)
##################################################################

##################################################################
## Compile the model
comp_sm <- stan_model(file_model_logistic)
##################################################################

##################################################################
## Run the model
sm.logistic_v01 = sampling(comp_sm, 
                           data=data_stan_train, 
                           iter=2000, 
                           chains=4)
##################################################################

##################################################################
## Print the results
print(sm.logistic_v01,
      pars = c('alpha', 'rho'),
      digits = 2, 
      probs = c(0.025, 0.5, 0.975))
##################################################################

##################################################################
## Extract the results
sims <- rstan::extract(sm.logistic_v01)
proba_hat = apply(X = sims$z2, MARGIN = 2, FUN = mean)
##################################################################

##################################################################
## Compute the test accuracy
threshold = 0.1
##################################################################

##################################################################
## Baseline calcs
y_hat_baseline <- rep(0, times = length(y_test))
accuracy_base = sum(y_hat_baseline == y_test) / length(y_test)
cat('\nBaseline accuracy: ', accuracy_base * 100)
##################################################################

##################################################################
## Prediction calcs
y_hat = rep(0, times = length(y_test))
y_hat[proba_hat > threshold] = 1

accuracy = sum(y_hat == y_test) / length(y_test)

cat('\nLogistic accuracy: ', accuracy * 100)
cat('\nConfusion table\n')
print(table(y_test, y_hat))

## Predict at the state level
test_df = data.frame(ID_state = data_sub$ID_state[-sample],
                     state = data_sub$state[-sample],
                     y_test = y_test,
                     y_hat = y_hat)
test_df <- test_df %>% 
  group_by(state) %>% 
  summarize(y_sum_test = sum(y_test),
            y_sum_hat = sum(y_hat)) %>% 
  arrange(desc(y_sum_test)) %>% 
  ungroup()

accuracy_baseline = mean(abs(test_df$y_sum_test) ** 2)
accuracy = mean(abs(test_df$y_sum_hat - test_df$y_sum_test) ** 2)

cat('\nBaseline MSE: ', accuracy_baseline * 100)
cat('\nLogistic MSE: ', accuracy * 100)
##################################################################

##################################################################
## Predict at the city level
test_df = data.frame(ID_city = data_sub$ID_city[-sample],
                     city = data_sub$city[-sample],
                     y_test = y_test,
                     y_hat = y_hat)
test_df <- test_df %>% 
  group_by(city) %>% 
  summarize(y_sum_test = sum(y_test),
            y_sum_hat = sum(y_hat)) %>% 
  arrange(desc(y_sum_test)) %>% 
  ungroup()

accuracy_baseline = mean(abs(test_df$y_sum_test) ** 2)
accuracy = mean(abs(test_df$y_sum_hat - test_df$y_sum_test) ** 2)

cat('\nBaseline MSE: ', accuracy_baseline * 100)
cat('\nLogistic MSE: ', accuracy * 100)
##################################################################
