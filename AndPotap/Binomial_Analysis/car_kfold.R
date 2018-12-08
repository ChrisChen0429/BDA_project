###################################################################
## Import Packages
###################################################################
library(rstan)
options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)
knitr::opts_chunk$set(echo = TRUE)

###################################################################
## Set the parameters
###################################################################
# file <-  './AndPotap/DBs/city_st.txt'
# file_adjacency <-  './AndPotap/DBs/A.txt'
# file_model <- './AndPotap/Binomial_Analysis/selected/car_train.stan'
# source('./AndPotap/Utils/processing.R')

## Files VM
file <-  './BDA_project/data/city_st.txt'
file_model <- './BDA_project/Models/car_train.stan'
file_adjacency <-  './BDA_project/data/A.txt'
source('./BDA_project/Models/processing.R')

SEED = 1234
pct = 1
# pct = 0.1
# pct = 0.01

# CHAINS = 1
# ITER = 20
CHAINS = 8
ITER = 2000
pct_train = 0.8
comp_sm <- stan_model(file_model)

SEEDS = c(81989843, 42, 123, 193724, 37462)

###################################################################
## Load the data
###################################################################
## Load the data
data <- read_delim(file = file, delim = '|')
A <- read_csv(file = file_adjacency, col_names = FALSE)

# Sample the data
data = sample_data(data = data, pct = pct, SEED = SEED)

## Selecting the relevant columns for the analysis
inputs <- data %>% dplyr::select(
  state,
  city,
  client_income,
  # mar_2_inc,
  appraisal_value,
  app_2_inc,
  # asset_market_value,
  mar_2_app,
  sex_F,
  age,
  risk_index,
  employed_30,
  condition_U,
  city_n,
  ID_state,
  y)
summary(inputs)


###################################################################
## Perform k-fold CV
###################################################################
## Metrics for City
rmse_model = rep(NA, times = length(SEEDS))
rmse_baseline = rep(NA, times = length(SEEDS))

## Metrics for State
rmse_model_state = rep(NA, times = length(SEEDS))
rmse_baseline_state = rep(NA, times = length(SEEDS))

for (j in 1:length(SEEDS)){
  data_stan = STAN_train_car(inputs=inputs, 
                             W = A,
                             pct_train = pct_train,
                             SEED_TRAIN = SEEDS[j])
  
  sm = sampling(comp_sm, data=data_stan, iter=ITER, chains=CHAINS)
  
  sample = data_stan$sample
  y_test = inputs$y[-sample]
  rmse_model[j] = eval_model(sm = sm, y_test = y_test)
  rmse_baseline[j] = rmse(y_hat = rep(0, times = length(y_test)), 
                          y_test = inputs$y[-sample])
  
  output_state = eval_model_state(sm = sm, 
                                  y_test = y_test,
                                  inputs = inputs,
                                  sample = sample)
  rmse_model_state[j] = output_state$rmse_state
  rmse_baseline_state[j] = output_state$rmse_baseline
}

cat('\nResults for baseline')
cat('\nBaseline mean RMSE: ', mean(rmse_baseline))
cat('\nBaseline sd RMSE: ', sd(rmse_baseline))

cat('\nState Baseline mean RMSE: ', mean(rmse_baseline_state))
cat('\nState Baseline sd RMSE: ', sd(rmse_baseline_state))

cat('\nNow the results for the model')
cat('\nModel mean RMSE: ', mean(rmse_model))
cat('Model sd RMSE: ', sd(rmse_model))

cat('\nState Model mean RMSE: ', mean(rmse_model_state))
cat('State Model sd RMSE: ', sd(rmse_model_state))
