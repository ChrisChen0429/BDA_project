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

###################################################################
## Set the parameters
###################################################################
## Files Local
# file <-  './AndPotap/DBs/core.txt'
# file_model <- './AndPotap/Binomial_Analysis/Selected/logistic.stan'
# file_output <- './AndPotap/Binomial_Analysis/Selected/sims_logistic_local.rds'
# source('./AndPotap/Utils/processing.R')

## Files VM
file <-  './BDA_project/data/core.txt'
file_model <- './BDA_project/Models/logistic.stan'
file_output <- './BDA_project/Models/sims_logistic_all.rds'
source('./BDA_project/Models/processing.R')

# CHAINS = 1
# ITER = 20
CHAINS = 4
ITER = 2000

pct = 1
# pct = 0.1
# pct = 0.01
SEED = 1234

comp_sm <- stan_model(file_model)

###################################################################
## Load the data
###################################################################
## Load the data
data <- read_delim(file = file, delim = '|')

# Sample the data
data = sample_data(data = data, pct = pct, SEED = SEED)

## Selecting the relevant columns for the analysis
inputs_logistic <- data %>% 
  dplyr::select(state, city, 
                client_income, 
                ratio, 
                sex_F, 
                age, 
                condition_U, 
                factor_employed, 
                risk_index, 
                effective_pay, 
                y)

###################################################################
## Run the model
###################################################################
data_stan_log = STAN_ind(inputs = inputs_logistic)

sm = sampling(comp_sm, data=data_stan_log, iter=ITER, chains=CHAINS)

## Save the Model
saveRDS(sm, file = file_output)

## Load the Model
sm2 <- readRDS(file = file_output)

print(sm2,
      pars = c('alpha', 'beta'),
      digits = 2, 
      probs = c(0.025, 0.5, 0.975))

###################################################################
## Perform PPCs
###################################################################
