## Import packages
library(rstan)
library(tidyverse)
library(ggplot2)
library(arm)
library(bayesplot)
options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)
knitr::opts_chunk$set(echo = TRUE)

#####################################################################
# file <-  './data/core.txt'
# file_model <- './AndPotap/Binomial_Analysis/Models/binomial_GP.stan'
file <-  './BDA_project/data/core.txt'
file_model <- './BDA_project/Models/binomial_GP.stan'
pct = 1
# pct = 0.1
# pct = 0.01

CHAINS = 8
ITER = 2000
#####################################################################

data <- read_delim(file = file, delim = '|')

# Sample the data
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

## Create geographical 
geo <- data_sub %>% 
  group_by(city, state) %>% 
  summarize(market_mean = mean(asset_market_value),
            appraisal_mean = mean(appraisal_value),
            income_mean = mean(client_income),
            mar_2_inc_mean = mean(mar_2_inc),
            app_2_inc_mean = mean(app_2_inc),
            mar_2_app_mean = mean(mar_2_app),
            age_mean = mean(age),
            y_sum = sum(y),
            N_state = n()) %>% 
  ungroup()


## Group data by state and define the IDs
state_summary <- data_sub %>% 
  dplyr::select(state, 
                client_income, 
                appraisal_value,
                asset_market_value) %>% 
  group_by(state) %>% 
  summarize(N_state = n(),
            income_mean_state = mean(client_income),
            appraisal_mean_state = mean(appraisal_value),
            market_mean_state = mean(asset_market_value)) %>% 
  arrange(desc(N_state)) %>% 
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
geo <- geo %>% 
  inner_join(y = state_summary[, c('state', 'ID_state')], by = 'state')


## Rescaling
inputs <- geo %>%
  mutate(
    
    income_st = (log(income_mean) - mean(log(income_mean))) /
      sd(log(income_mean)),
    
    appraisal_st = (log(appraisal_mean) - mean(log(appraisal_mean))) /
      sd(log(appraisal_mean)),
    
    market_st = (log(market_mean) - mean(log(market_mean))) /
      sd(log(market_mean)),
    
    mar_2_inc_st = (mar_2_inc_mean - mean(mar_2_inc_mean)) / sd(mar_2_inc_mean),
    app_2_inc_st = (app_2_inc_mean - mean(app_2_inc_mean)) / sd(app_2_inc_mean),
    mar_2_app_st = (mar_2_app_mean - mean(mar_2_app_mean)) / sd(mar_2_app_mean),
    age_st = (age_mean - mean(age_mean)) / sd(age_mean)
  ) %>% 
  dplyr::select(
    income_st,
    # mar_2_inc_st,
    appraisal_st,
    app_2_inc_st,
    # mar_2_app_st,
    # market_st,
    age_st,
    N_state,
    y_sum
  )

## Train / Test split
set.seed(seed = 81989843)
pct_train = 0.9
sample_size = round(pct_train * nrow(inputs))
sample <- sample(x = nrow(inputs), size = sample_size, replace = F)

## Allocate train
y = inputs$y_sum

inputs_train = inputs[sample, ]
y_train = y[sample]

## Allocate test
inputs_test = inputs[-sample, ]
y_test = y[-sample]

## Inputs for STAN
X_train = inputs_train %>% dplyr::select(-y_sum, -N_state)
X_test = inputs_test %>% dplyr::select(-y_sum, -N_state)
D = ncol(X_train)
N_train = nrow(X_train)
N_test = nrow(X_test)
State_N_train = inputs$N_state[sample]
State_N_test = inputs$N_state[-sample]

data_stan_train = list(N_train=N_train,
                       N_test=N_test,
                       D=D,
                       State_N_train=State_N_train,
                       State_N_test=State_N_test,
                       X_train=X_train,
                       X_test=X_test,
                       y_train=y_train)

comp_sm <- stan_model(file_model)


# sm.logistic_v01 = sampling(comp_sm, data=data_stan_train, iter=100, chains=1)
sm.logistic_v01 = sampling(comp_sm, data=data_stan_train, 
                           iter=ITER, 
                           chains=CHAINS)


print(sm.logistic_v01,
      pars = c('alpha', 'rho', 'a'),
      digits = 2, 
      probs = c(0.025, 0.5, 0.975))


sims <- rstan::extract(sm.logistic_v01)
y_hat <- apply(X = sims$yrep_test, MARGIN = 2, FUN = mean)


## Baseline
y_hat_baseline <- rep(0, times = length(y_test))

RMSE_baseline = sqrt(mean((y_hat_baseline - y_test) ** 2))
RMSE = sqrt(mean((y_hat - y_test) ** 2))

## Prints
cat('\nBaseline RMSE: ', RMSE_baseline * 100)
cat('\nBinomial GP RMSE: ', RMSE * 100)

test_df = data.frame(ID_state = geo$ID_state[-sample],
                     state = geo$state[-sample],
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
cat('\nBinomial MSE: ', accuracy * 100)
