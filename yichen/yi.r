library(knitr);library(arm);library(ggplot2)
library(MASS);library(tidyr);library(dplyr)
library(extraDistr);library(gridExtra)
library(rstan);library(bayesplot);library(loo)
library(shinystan);library(readr)
options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)
knitr::opts_chunk$set(echo = TRUE)


########## city level analysis
file <-  '../data/core.txt'
data <- read_delim(file = file, delim = '|')

# Sample the data
pct = 1
# pct = 0.1
# pct = 0.01
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

## Group data by state and define the IDs
state_summary <- data_sub %>% 
  dplyr::select(state, 
                client_income, 
                appraisal_value,
                asset_market_value) %>% 
  group_by(state) %>% 
  summarize(n_state = n(),
            income_mean_state = mean(client_income),
            appraisal_mean_state = mean(appraisal_value),
            market_mean_state = mean(asset_market_value)) %>% 
  arrange(desc(n_state)) %>% 
  ungroup()
state_summary$ID_state = seq.int(nrow(state_summary))


## Group data by city and define the IDs
city_summary <- data_sub %>% 
  dplyr::select(city, state,
                client_income,
                appraisal_value,
                asset_market_value,
                mar_2_inc,
                mar_2_app,
                app_2_inc,
                age,
                y,
                y2) %>% 
  group_by(city, state) %>% 
  summarize(n_city = n(),
            income_mean_city = mean(client_income),
            appraisal_mean_city = mean(appraisal_value),
            market_mean_city = mean(asset_market_value),
            
            mar_2_inc_mean_city = mean(mar_2_inc),
            mar_2_app_mean_city = mean(mar_2_app),
            app_2_inc_mean_city = mean(app_2_inc),
            
            age_mean_city = mean(age),
            sum_y = sum(y),
            sum_y2 = sum(y2)) %>% 
  arrange(desc(n_city)) %>% 
  ungroup()


## Merge back into data
city_summary <- city_summary %>% 
  inner_join(y = state_summary[c('ID_state', 'state')], by = 'state')



N = length(unique(data$state))
A <- matrix(0,ncol = N,nrow = N)
colnames(A) = unique(data$state)
rownames(A) = unique(data$state)
A['NUEVO LEON',c('ZACATECAS','SAN LUIS POTOSI','TAMAULIPAS','COAHUILA DE ZARAGOZA')] = 1
A[c('ZACATECAS','SAN LUIS POTOSI','TAMAULIPAS','COAHUILA DE ZARAGOZA'),'NUEVO LEON'] = 1
A['VERACRUZ LLAVE',c('TAMAULIPAS','SAN LUIS POTOSI','HIDALGO','PUEBLA','OAXACA','CHIAPAS','TABASCO')] = 1
A[c('TAMAULIPAS','SAN LUIS POTOSI','HIDALGO','PUEBLA','OAXACA','CHIAPAS','TABASCO'),'VERACRUZ LLAVE'] = 1
A['GUANAJUATO',c('MICHOACAN DE OCAMPO','JALISCO','SAN LUIS POTOSI','ZACATECAS','QUERETARO DE ARTEAGA')] = 1
A[c('MICHOACAN DE OCAMPO','JALISCO','SAN LUIS POTOSI','ZACATECAS','QUERETARO DE ARTEAGA'),'GUANAJUATO'] = 1
A['NAYARIT',c('SINALOA','DURANGO','ZACATECAS','JALISCO')] = 1
A[c('SINALOA','DURANGO','ZACATECAS','JALISCO'),'NAYARIT'] = 1
A['JALISCO',c('NAYARIT','ZACATECAS','COLIMA','MICHOACAN DE OCAMPO','GUANAJUATO','AGUASCALIENTES')] = 1
A[c('NAYARIT','ZACATECAS','COLIMA','MICHOACAN DE OCAMPO','GUANAJUATO','AGUASCALIENTES'),'JALISCO'] = 1
A['DISTRITO FEDERAL',c('ESTADO DE MEXICO','MORELOS')] = 1
A[c('ESTADO DE MEXICO','MORELOS'),'DISTRITO FEDERAL'] = 1
A['MORELOS',c('GUERRERO','PUEBLA','ESTADO DE MEXICO')] = 1
A[c('GUERRERO','PUEBLA','ESTADO DE MEXICO'),'MORELOS'] = 1
A['MICHOACAN DE OCAMPO',c('COAHUILA DE ZARAGOZA','ESTADO DE MEXICO','JALISCO','GUANAJUATO','GUERRERO','QUERETARO DE ARTEAGA')] = 1
A[c('COAHUILA DE ZARAGOZA','JALISCO','ESTADO DE MEXICO','GUANAJUATO','GUERRERO','QUERETARO DE ARTEAGA'),'MICHOACAN DE OCAMPO'] = 1
A['ESTADO DE MEXICO',c('HIDALGO','QUERETARO DE ARTEAGA','MICHOACAN DE OCAMPO','GUERRERO','PUEBLA','TLAXCALA','MORELOS')] = 1
A[c('HIDALGO','QUERETARO DE ARTEAGA','MICHOACAN DE OCAMPO','GUERRERO','PUEBLA','TLAXCALA','MORELOS'), 'ESTADO DE MEXICO'] = 1
A['HIDALGO',c('ESTADO DE MEXICO','QUERETARO DE ARTEAGA','SAN LUIS POTOSI','VERACRUZ LLAVE','PUEBLA','TLAXCALA')] = 1
A[c('ESTADO DE MEXICO','QUERETARO DE ARTEAGA','SAN LUIS POTOSI','VERACRUZ LLAVE','PUEBLA','TLAXCALA'),'HIDALGO'] = 1
A['ZACATECAS',c('JALISCO','NAYARIT','DURANGO','COAHUILA DE ZARAGOZA','NUEVO LEON','TAMAULIPAS','SAN LUIS POTOSI','AGUASCALIENTES')] = 1
A[c('JALISCO','NAYARIT','DURANGO','COAHUILA DE ZARAGOZA','NUEVO LEON','TAMAULIPAS','SAN LUIS POTOSI','AGUASCALIENTES'),'ZACATECAS'] = 1
A['GUERRERO',c('MICHOACAN DE OCAMPO','PUEBLA','ESTADO DE MEXICO','MORELOS')] = 1
A[c('MICHOACAN DE OCAMPO','PUEBLA','ESTADO DE MEXICO','MORELOS'),'GUERRERO'] = 1
A['DURANGO',c('CHIHUAHUA','COAHUILA DE ZARAGOZA','ZACATECAS','NAYARIT','SINALOA')] = 1
A[c('CHIHUAHUA','COAHUILA DE ZARAGOZA','ZACATECAS','NAYARIT','SINALOA'),'DURANGO'] = 1
A['CHIHUAHUA',c('DURANGO','SINALOA','COAHUILA DE ZARAGOZA','SONORA')] = 1
A[c('DURANGO','SINALOA','COAHUILA DE ZARAGOZA','SONORA'),'CHIHUAHUA'] = 1
A['CHIAPAS',c('OAXACA','VERACRUZ LLAVE','TABASCO','CAMPECHE')] = 1
A[c('OAXACA','VERACRUZ LLAVE','TABASCO','CAMPECHE'),'CHIAPAS'] = 1
A['COLIMA',c('JALISCO','MICHOACAN DE OCAMPO')] = 1
A[c('JALISCO','MICHOACAN DE OCAMPO'),'COLIMA'] = 1　
A['COAHUILA DE ZARAGOZA',c('NUEVO LEON','ZACATECAS','DURANGO','CHIHUAHUA','SAN LUIS POTOSI')] = 1
A[c('NUEVO LEON','ZACATECAS','DURANGO','CHIHUAHUA','SAN LUIS POTOSI'),'COAHUILA DE ZARAGOZA'] = 1
A['SAN LUIS POTOSI',c('TABASCO','NUEVO LEON','COAHUILA DE ZARAGOZA','ZACATECAS','JALISCO','GUANAJUATO','QUERETARO DE ARTEAGA','HIDALGO','VERACRUZ LLAVE')] = 1
A[c('TABASCO','NUEVO LEON','COAHUILA DE ZARAGOZA','ZACATECAS','JALISCO','GUANAJUATO','QUERETARO DE ARTEAGA','HIDALGO','VERACRUZ LLAVE'),'SAN LUIS POTOSI'] = 1
A['CAMPECHE',c('TABASCO','QUINTANA ROO','YUCATAN')] = 1
A[c('TABASCO','QUINTANA ROO','YUCATAN'),'CAMPECHE'] = 1
A['BAJA CALIFORNIA SUR',c('BAJA CALIFORNIA','SONORA','SINALOA')] = 1
A[c('BAJA CALIFORNIA','SONORA','SINALOA'),'BAJA CALIFORNIA SUR'] = 1
A['BAJA CALIFORNIA',c('BAJA CALIFORNIA SUR','SONORA')] = 1
A[c('BAJA CALIFORNIA SUR','SONORA'),'BAJA CALIFORNIA'] = 1
A['AGUASCALIENTES',c('ZACATECAS','JALISCO')] = 1
A[c('ZACATECAS','JALISCO'),'AGUASCALIENTES'] = 1
A['YUCATAN',c('CAMPECHE','QUINTANA ROO')] = 1
A[c('CAMPECHE','QUINTANA ROO'),'YUCATAN'] = 1
A['TAMAULIPAS',c('NUEVO LEON','SAN LUIS POTOSI','VERACRUZ LLAVE')] = 1
A[c('NUEVO LEON','SAN LUIS POTOSI','VERACRUZ LLAVE'),'TAMAULIPAS'] = 1
A['TABASCO',c('CAMPECHE','CHIAPAS','VERACRUZ LLAVE')] = 1
A[c('CAMPECHE','CHIAPAS','VERACRUZ LLAVE'),'TABASCO'] = 1
A['SONORA',c('BAJA CALIFORNIA','BAJA CALIFORNIA SUR','SINALOA','CHIHUAHUA')] = 1
A[c('BAJA CALIFORNIA','BAJA CALIFORNIA SUR','SINALOA','CHIHUAHUA'),'SONORA'] = 1
A['SINALOA',c('SONORA','CHIHUAHUA','DURANGO','NAYARIT')] = 1
A[c('SONORA','CHIHUAHUA','DURANGO','NAYARIT'),'SINALOA'] = 1
A['QUINTANA ROO',c('YUCATAN','CAMPECHE')] = 1
A[c('YUCATAN','CAMPECHE'),'QUINTANA ROO'] =1
A['QUERETARO DE ARTEAGA',c('SAN LUIS POTOSI','HIDALGO','ESTADO DE MEXICO','GUANAJUATO','MICHOACAN DE OCAMPO')] = 1
A[c('SAN LUIS POTOSI','HIDALGO','ESTADO DE MEXICO','GUANAJUATO','MICHOACAN DE OCAMPO'),'QUERETARO DE ARTEAGA'] = 1
A['PUEBLA',c('ESTADO DE MEXICO','MORELOS','TLAXCALA','GUERRERO','OAXACA','VERACRUZ LLAVE','HIDALGO')] = 1
A[c('ESTADO DE MEXICO','MORELOS','TLAXCALA','GUERRERO','OAXACA','VERACRUZ LLAVE','HIDALGO'),'PUEBLA'] = 1
A['TLAXCALA',c('ESTADO DE MEXICO','HIDALGO','PUEBLA')] = 1
A[c('ESTADO DE MEXICO','HIDALGO','PUEBLA'),'TLAXCALA'] = 1
A['OAXACA',c('GUERRERO','PUEBLA','VERACRUZ LLAVE','CHIAPAS')] = 1
A[c('GUERRERO','PUEBLA','VERACRUZ LLAVE','CHIAPAS'),'OAXACA'] =1




## Rescaling
inputs <- city_summary %>%
  mutate(
    market_state_city = (log(market_mean_city) - mean(log(market_mean_city))) /
      sd(log(market_mean_city)),
    
    income_state_city = (log(appraisal_mean_city) - mean(log(appraisal_mean_city))) /
      sd(log(appraisal_mean_city)),
    
    appraisal_state_city = (log(appraisal_mean_city) -
                              mean(log(appraisal_mean_city))) /
      sd(log(appraisal_mean_city)),
    
    mar_2_inc_city = (mar_2_inc_mean_city - mean(mar_2_inc_mean_city)) / sd(mar_2_inc_mean_city),
    
    app_2_inc_city = (app_2_inc_mean_city - mean(app_2_inc_mean_city)) / sd(app_2_inc_mean_city),
    
    mar_2_app_city = (mar_2_app_mean_city - mean(mar_2_app_mean_city)) / sd(mar_2_app_mean_city),
    
    age_city = (age_mean_city - mean(age_mean_city)) / sd(age_mean_city)) %>% 
  dplyr::select(
    market_state_city,
    income_state_city,
    appraisal_state_city,
    mar_2_inc_city,
    app_2_inc_city,
    mar_2_app_city,
    age_city,
    ID_state,
    n_city,
    sum_y,
    sum_y2
  )
## simulate the fake data
library(matlib)
set.seed(1234)
S = length(unique(data_sub$state))
n_city_train = inputs$n_city
X_train = inputs %>% dplyr::select(-ID_state,-n_city,-sum_y, -sum_y2)
N_train = nrow(X_train)
D = ncol(X_train)
state_train = inputs$ID_state
tau <- rgamma(n=1,shape = 2,rate = 2)
D <- diag(colSums(A))
W <- A
B <- Inverse(D) %*% W
sigma <-  tau * D %*% (diag(32) - B)
theta <- runif(n=1,min = 0,max = 1)
phi <- mvrnorm(n=1, mu = rep(0,32), Sigma = sigma )
beta <- rcauchy(n=7,location = 0,scale = 2.5)
alpha <- 0.1
y <- c()
for (i in (1:N_train)){
  zero_d <- runif(n=1,min = 0,max = 1)
  if (zero_d < theta){
    new_y <- 0
  }else{
    prob <- invlogit(alpha + phi[state_train[i]] + sum(X_train[i,] * beta))
    new_y <-rbinom(n=1,size = n_city_train[i],prob = prob)   
  }  
  y <- c(y,new_y)
}
D = ncol(X_train)
fake_data = list(S=S,N_train=N_train, D=D,
                 state_train = state_train,
                 X_train=X_train, W = A,W_n = sum(A) / 2,
                 n_city_train = n_city_train, 
                 y = y)

## fit the model with the fake data
fake_fit <- stan('model2_full.stan', data=fake_data,seed=1234)

## test the recoverage
sim_fake <- rstan::extract(fake_fit)
true_phi <- phi
posterior_phi <- as.matrix(sim_fake, pars = c('phi'))
true_beta <- beta
posterior_beta <- as.matrix(sim_fake, pars = c('beta'))
true_alpha_tau_theta <- c(alpha,tau,theta)
posterior_alpha_tau_theta <- as.matrix(sim_fake, pars = c('alpha','tau','theta'))

mcmc_recover_hist(posterior_phi, true = true_phi)
mcmc_recover_hist(posterior_beta, true = true_beta)
mcmc_recover_hist(posterior_alpha_tau_theta, true = true_alpha_tau_theta)





## Train / Test split
set.seed(1234)
model2 = stan_model('Model2.stan')

splited_inputs <- split(inputs, sample(rep(1:5, 176)))

for (i in 1:5){
  a <- c(1,2,3,4,5)[-i]
  inputs_test = splited_inputs[[i]]
  inputs_train = rbind(splited_inputs[[a[1]]] ,splited_inputs[[a[2]]],splited_inputs[[a[3]]],splited_inputs[[a[4]]]) 
  
  y_train = inputs_train$sum_y
  y_test = inputs_test$sum_y
  
  ## Inputs for STAN
  n_city_train = inputs_train$n_city
  n_city_test = inputs_test$n_city
  
  
  X_train = inputs_train %>% dplyr::select(-ID_state,-n_city,-sum_y, -sum_y2)
  X_test = inputs_test %>% dplyr::select(-ID_state,-n_city,-sum_y, -sum_y2)
  
  N_train = nrow(X_train)
  N_test = nrow(X_test)
  
  D = ncol(X_train)
  S = length(unique(data_sub$state))
  state_train = inputs_train$ID_state
  state_test = inputs_test$ID_state
  
  model2_data = list(S=S,N_train=N_train, N_test=N_test, D=D,
                     state_train = state_train,state_test = state_test,
                     X_train=X_train, X_test=X_test,W = A,W_n = sum(A) / 2,
                     n_city_train = n_city_train, 
                     n_city_test = n_city_test,
                     y = y_train)
  fit2 <- sampling(model2, data=model2_data,seed=1234)
  name = paste('model2_cv',as.character(i),'.rds',sep = "")
  saveRDS(fit2, file = name)
}


MSE <- c()
for (i in 1:5){
  name = paste('model2_cv',as.character(i),'.rds',sep = "")
  fit1 <- readRDS(file = name)
  sims <- rstan::extract(fit1)
  y_hat <- apply(X = sims$y_rep_cv, MARGIN = 2, FUN = median)  
  
  test_df = data.frame(ID_state = inputs_test$ID_state,
                       y_test = y_test,
                       y_hat = y_hat)
  
  test_df <- test_df %>% 
    summarize(y_sum_test = sum(y_test),
              y_sum_hat = sum(y_hat)) %>% 
    arrange(desc(y_sum_test)) %>% 
    ungroup()
  
  mse_baseline = mean((test_df$y_sum_test) ** 2)
  mse = mean((test_df$y_sum_hat - test_df$y_sum_test) ** 2)
  MSE <- c(MSE,mse)
}
average_MSE <- mean(MSE)
SD_MSE <- sd(MSE)



## Allocate train
y_train = inputs$sum_y

## Inputs for STAN
n_city_train = inputs$n_city
X_train = inputs %>% dplyr::select(-ID_state,-n_city,-sum_y, -sum_y2)

N_train = nrow(X_train)
D = ncol(X_train)
S = length(unique(data_sub$state))
state_train = inputs$ID_state
model2_data = list(S=S,N_train=N_train, D=D,
                   state_train = state_train,
                   X_train=X_train, W = A,W_n = sum(A) / 2,
                   n_city_train = n_city_train, 
                   y = y_train)
model2_full = stan_model('model2_full.stan')
fit2 <- sampling(model2_full, data=model2_data,seed=1234)
saveRDS(fit2, file = "model2_full.rds")
fit2 <- readRDS(file = "model2_full.rds")
library(shinystan)
ss_mod = as.shinystan(fit2)
launch_shinystan(ss_mod)




########## individual level analysis
# Sample the data
pct = 1
# pct = 0.1
# pct = 0.01
set.seed(seed = 42)
sample_size = round(pct * nrow(data))
sample <- sample(x = nrow(data), size = sample_size, replace = F)
data = data[sample, ]
## Selecting the relevant columns for the analysis
data_sub <- data %>% dplyr::select(
  state,
  asset_market_value,
  mar_2_app,
  appraisal_value,
  app_2_inc,
  client_income,
  mar_2_inc,
  age,
  y)

state = as.vector(data$state)
unique_s = unique(state)
for (i in 1:32){
  s = as.character(unique_s[i])
  state[state==s] = as.numeric(i)
}
state = as.numeric(state)

y <- data_sub$y
X <- data_sub %>% dplyr::select(-state,-y)
X <- scale(X)

individual_data = list(S=32,N=length(y), D=ncol(X),
                   state = state,
                   X=X, W = A,W_n = sum(A) / 2,
                   y = y)
individual = stan('model2_individual.stan', data=individual_data,seed=1234)
saveRDS(individual, file = "individual_fit")
print(individual, pars = c('alpha','beta','phi','theta','lp__'),probs=0.01)
ss_mod = as.shinystan(individual)
launch_shinystan(ss_mod)

fit <- model2_full
posterior <- as.matrix(fit)

plot_title <- ggtitle("Posterior distributions",
                      "with medians and 80% intervals")
mcmc_intervals(posterior,
           pars = c("phi[1]","phi[2]","phi[3]","phi[4]","phi[5]",
                    "phi[6]","phi[7]","phi[8]","phi[9]","phi[10]",
                    "phi[11]","phi[12]","phi[13]","phi[14]","phi[15]",
                    "phi[16]","phi[17]","phi[18]","phi[19]","phi[20]",
                    "phi[21]","phi[22]","phi[23]","phi[24]","phi[25]",
                    "phi[26]","phi[27]","phi[28]","phi[29]","phi[30]",
                    "phi[31]","phi[32]"),
           prob = 0.95) + plot_title
