###################################################################
## Import Packages
###################################################################
library(rstan)
library(tidyverse)
library(ggplot2)
library(arm)
library(bayesplot)
options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)
knitr::opts_chunk$set(echo = TRUE)
# source('./AndPotap/Utils/processing.R')
source('./BDA_project/Models/processing.R')

###################################################################
## Set the parameters
###################################################################
## Files Local
# file <-  './AndPotap/DBs/city_st.txt'
# file_model <- './AndPotap/Binomial_Analysis/Selected/binomial_GP.stan'
# file_output <- './AndPotap/Binomial_Analysis/Selected/sims_GP_local.rds'

## Files VM
file <-  './BDA_project/data/city_st.txt'
file_model <- './BDA_project/Models/binomial_GP.stan'
file_output <- './BDA_project/Models/sims_GP_all.rds'

SEED = 1234
# CHAINS = 1
# ITER = 20
CHAINS = 4
ITER = 2000
pct_train = 0.8
pct = 1
# pct = 0.1
# pct = 0.01
comp_sm <- stan_model(file_model)

###################################################################
## Load the data
###################################################################
## Load the data
data <- read_delim(file = file, delim = '|')

# Sample the data
data = sample_data(data = data, pct = pct, SEED = SEED)

## Selecting the relevant columns for the analysis
inputs <- data %>% dplyr::select(
  state,
  city,
  # client_income,
  # mar_2_inc,
  appraisal_value,
  app_2_inc,
  # asset_market_value,
  mar_2_app,
  # sex_F,
  # age,
  # risk_index,
  employed_30,
  condition_U,
  city_n,
  ID_state,
  y)
summary(inputs)

###################################################################
## Run the model
###################################################################
data_stan = STAN_city(inputs=inputs)

sm = sampling(comp_sm, data=data_stan, iter=ITER, chains=CHAINS)

## Save the Model
saveRDS(sm, file = file_output)

## Load the Model
sm2 <- readRDS(file = file_output)

print(sm2,
      pars = c('alpha', 'rho', 'a'),
      digits = 2, 
      probs = c(0.025, 0.5, 0.975))

###################################################################
## Perform PPCs
###################################################################
