## Imports
library(rstan)
library(tidyverse)
library(ggplot2)
library(gridExtra)
library(bayesplot)
options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)

## Set file paths & percentage trigger
file <-  './AndPotap/DBs/core.txt'
model2_file <- './AndPotap/mix_model_v01.stan'
output_file2 <- './AndPotap/mix.txt'

# pct = 1
pct = 0.1
# pct = 0.01

## Load the data
data <- read_delim(file = file, delim = '|')

# Sample the data
set.seed(seed = 42)
sample_size = round(pct * nrow(data))
sample <- sample(x = nrow(data), size = sample_size, replace = F)
data = data[sample, ]

# Change column format
data$postal_code = factor(data$postal_code)

## Generate the needed summaries
# Vendors
vendor_summary = data %>% 
  group_by(vendor_name) %>% 
  summarize(mort_no = n(), 
            y_sum = sum(y), 
            income_bar = mean(client_income), 
            factor_bar = mean(factor_employed),
            lender_bar = mean(lender_score),
            risk_bar = mean(risk_index),
            ratio_bar = mean(ratio),
            asset_val = mean(asset_market_value)) %>% 
  mutate(theta_emp = y_sum / mort_no) %>% 
  arrange(desc(mort_no)) %>% ungroup()

vendor_summary$ID_vendor = seq.int(nrow(vendor_summary))

N_d = vendor_summary$mort_no
y_d = vendor_summary$y_sum
D = nrow(vendor_summary)

# Zip codes
zip_summary = data %>% 
  group_by(postal_code, city, state) %>% 
  summarize(mort_no = n(), 
            y_sum = sum(y), 
            income_bar = mean(client_income), 
            factor_bar = mean(factor_employed),
            lender_bar = mean(lender_score),
            risk_bar = mean(risk_index),
            ratio_bar = mean(ratio),
            asset_val = mean(asset_market_value)) %>% 
  mutate(theta_emp = y_sum / mort_no) %>% 
  arrange(desc(mort_no)) %>% ungroup()

zip_summary$ID_zip = seq.int(nrow(zip_summary))

N_m = zip_summary$mort_no
y_m = zip_summary$y_sum
M = nrow(zip_summary)

# Both
mix_summary = data %>% 
  group_by(postal_code, vendor_name) %>% 
  summarize(mort_no = n(), 
            y_sum = sum(y), 
            income_bar = mean(client_income), 
            factor_bar = mean(factor_employed),
            lender_bar = mean(lender_score),
            risk_bar = mean(risk_index),
            ratio_bar = mean(ratio),
            asset_val = mean(asset_market_value)) %>% 
  mutate(theta_emp = y_sum / mort_no) %>% 
  arrange(desc(mort_no)) %>% ungroup()

mix_summary <- mix_summary %>% 
  inner_join(y = zip_summary[, c('postal_code', 'ID_zip')], by = 'postal_code') %>% 
  inner_join(y = vendor_summary[, c('vendor_name', 'ID_vendor')], by = 'vendor_name')

# mix_summary[, c('postal_code', 'vendor_name', 'ID_zip', 'ID_vendor')]

ind_d = mix_summary$ID_vendor
ind_m = mix_summary$ID_zip
N = mix_summary$mort_no
Total = nrow(mix_summary)
y = mix_summary$y_sum

## Compile the STAN models
sm.join <- stan_model(model2_file)

## Fit the second model specification
inputs = list(M=M, D=D, N_m=N_m, N_d=N_d, y_m=y_m, y_d=y_d, N=N, y=y)
model.fit2 = sampling(sm.join, data=inputs)

## Print the results
print(model.fit2, digits=2, pars = c('alpha_m', 'beta_m', 'alpha_d', 'beta_d'))

## Output the results
sims2 = rstan::extract(model.fit2)

theta_d = apply(X = sims2$theta_d, MARGIN = 2, FUN = median)
vendor_summary$theta_d = theta_d

theta_m = apply(X = sims2$theta_m, MARGIN = 2, FUN = median)
zip_summary$theta_m = theta_m

# Merge back into the complete data base
mix_summary <- mix_summary %>% 
  inner_join(y = zip_summary[, c('postal_code', 'theta_m')], by = 'postal_code') %>% 
  inner_join(y = vendor_summary[, c('vendor_name', 'theta_d')], by = 'vendor_name')

write_csv(x = mix_summary, path = output_file2)
