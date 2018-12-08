## Import Libraries
library(tidyverse)
library(rstan)
options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)

## Define Functions

sample_data <- function(data, pct, SEED){
  set.seed(seed = SEED)
  sample_size = round(pct * nrow(data))
  sample <- sample(x = nrow(data), size = sample_size, replace = F)
  return(data[sample, ])
}

rmse <- function(y_hat, y_test){
  return(sqrt(mean((y_hat - y_test) ** 2)))
}

eval_model <- function(sm, y_test){
  sims = rstan::extract(sm)
  y_hat <- apply(X = sims$y_rep_test, MARGIN = 2, FUN = mean)
  return(rmse(y_hat = y_hat, y_test = y_test))
}

eval_model_state <- function(sm, y_test, inputs, sample){
  sims = rstan::extract(sm)
  y_hat <- apply(X = sims$y_rep_test, MARGIN = 2, FUN = mean)
  
  test_df = data.frame(ID_state = inputs$ID_state[-sample],
                       state = inputs$state[-sample],
                       y_test = y_test,
                       y_hat = y_hat)
  test_df <- test_df %>% 
    group_by(state) %>% 
    summarize(y_sum_test = sum(y_test),
              y_sum_hat = sum(y_hat)) %>% 
    arrange(desc(y_sum_test)) %>% 
    ungroup()
  
  rmse_baseline = sqrt(mean((test_df$y_sum_test) ** 2))
  
  output = list(rmse_state = rmse(y_hat = test_df$y_sum_hat, 
                                  y_test = test_df$y_sum_test),
                rmse_baseline = rmse_baseline)
  return(output)
}

state_rep <- function(sims, inputs){
  B = dim(sims$y_rep)[1]
  state_rep = data.frame(t(sims$y_rep))
  state_rep$ID_state = inputs$ID_state
  state_rep <- state_rep %>% 
    group_by(ID_state) %>% 
    summarize_all(sum) %>%
    ungroup()
  y_state_rep <- t(state_rep)
  y_state_rep <- y_state_rep[2:B, ]
  return(y_state_rep)
}

STAN_ind <- function(inputs) {
  
  ## Allocate train
  y = inputs$y
  
  ## Inputs for STAN
  X = inputs %>% dplyr::select(-y,-city, -state)
  
  D = ncol(X)
  N = nrow(X)
  
  data_stan = list(N = N,
                   D = D,
                   X = X,
                   y = y)
  
  return(data_stan)
}

STAN_city <- function(inputs) {
  
  ## Allocate train
  y = inputs$y
  
  ## Inputs for STAN
  X = inputs %>% dplyr::select(-y, -city_n, -ID_state, -city, -state)
  
  D = ncol(X)
  N = nrow(X)
  city_n = inputs$city_n
  S = length(unique(inputs$state))
  state = inputs$ID_state
  
  data_stan = list(N = N,
                   D = D,
                   S = S,
                   city_n = city_n,
                   state = state,
                   X = X,
                   y = y)
  
  return(data_stan)
}

STAN_train_city <- function(inputs, pct_train, SEED_TRAIN) {
  
  ## Train / Test split
  set.seed(seed = SEED_TRAIN)
  pct_train = pct_train
  sample_size = round(pct_train * nrow(inputs))
  sample <- sample(x = nrow(inputs), size = sample_size, replace = F)
  
  ## Allocate train
  y = inputs$y
  
  inputs_train = inputs[sample, ]
  y_train = y[sample]
  
  ## Allocate test
  inputs_test = inputs[-sample, ]
  y_test = y[-sample]
  
  ## Inputs for STAN
  X_train = inputs_train %>% dplyr::select(-y, 
                                           -city_n, 
                                           -ID_state, 
                                           -city, 
                                           -state)
  
  X_test = inputs_test %>% dplyr::select(-y, 
                                         -city_n, 
                                         -ID_state, 
                                         -city, 
                                         -state)
  D = ncol(X_train)
  N_train = nrow(X_train)
  N_test = nrow(X_test)
  city_n_train = inputs$city_n[sample]
  city_n_test = inputs$city_n[-sample]
  state_train = inputs$ID_state[sample]
  state_test = inputs$ID_state[-sample]
  S = length(unique(data$state))
  
  data_stan_train = list(N_train=N_train,
                         N_test=N_test,
                         city_n_train=city_n_train,
                         city_n_test=city_n_test,
                         S=S,
                         state_train=state_train,
                         state_test=state_test,
                         D=D,
                         X_train=X_train,
                         X_test=X_test,
                         y_train=y_train,
                         sample=sample)
  return(data_stan_train)
}

STAN_car <- function(inputs, W) {
  
  ## Allocate train
  y = inputs$y
  
  ## Inputs for STAN
  X = inputs %>% dplyr::select(-y, -city_n, -ID_state, -city, -state)
  
  D = ncol(X)
  N = nrow(X)
  city_n = inputs$city_n
  S = length(unique(inputs$state))
  state = inputs$ID_state
  
  W_n = as.integer(sum(W) / 2)
  
  data_stan = list(N = N,
                   D = D,
                   S = S,
                   city_n = city_n,
                   state = state,
                   W = W,
                   W_n = W_n,
                   X = X,
                   y = y)
  
  return(data_stan)
}

STAN_train_car <- function(inputs, W, pct_train, SEED_TRAIN) {
  
  ## Train / Test split
  set.seed(seed = SEED_TRAIN)
  pct_train = pct_train
  sample_size = round(pct_train * nrow(inputs))
  sample <- sample(x = nrow(inputs), size = sample_size, replace = F)
  
  ## Allocate train
  y = inputs$y
  
  inputs_train = inputs[sample, ]
  y_train = y[sample]
  
  ## Allocate test
  inputs_test = inputs[-sample, ]
  y_test = y[-sample]
  
  ## Inputs for STAN
  X_train = inputs_train %>% dplyr::select(-y, 
                                           -city_n, 
                                           -ID_state, 
                                           -city, 
                                           -state)
  
  X_test = inputs_test %>% dplyr::select(-y, 
                                         -city_n, 
                                         -ID_state, 
                                         -city, 
                                         -state)
  D = ncol(X_train)
  N_train = nrow(X_train)
  N_test = nrow(X_test)
  city_n_train = inputs$city_n[sample]
  city_n_test = inputs$city_n[-sample]
  state_train = inputs$ID_state[sample]
  state_test = inputs$ID_state[-sample]
  S = length(unique(data$state))
  
  W_n = as.integer(sum(W) / 2)
  
  data_stan_train = list(N_train=N_train,
                         N_test=N_test,
                         city_n_train=city_n_train,
                         city_n_test=city_n_test,
                         S=S,
                         state_train=state_train,
                         state_test=state_test,
                         D=D,
                         X_train=X_train,
                         X_test=X_test,
                         y_train=y_train,
                         W=W,
                         W_n=W_n,
                         sample=sample)
  return(data_stan_train)
}

plot_ppcs <- function(sm, sims, inputs, legend='y_rep'){
  T_rep <- apply(X = sims$y_rep, MARGIN = 1, FUN = sum)
  T_rep_2 <- apply(X = sims$y_rep, MARGIN = 1, FUN = max)
  y_rep <- as.matrix(sm, pars = legend)
  y_state_rep <- state_rep(sims = sims, inputs = inputs)
  
  T_obs <- sum(inputs$y)
  T_obs_2 <- max(inputs$y)
  
  df_state = inputs %>% 
    group_by(ID_state) %>% 
    summarize(y_state = sum(y))
  
  df = data.frame(T_rep=T_rep)
  g_1 <- ggplot(df, aes(x=T_rep)) +
    geom_histogram(fill='lightblue',
                   color='black') +
    geom_vline(xintercept = T_obs, color = 'red') +
    ylab('') +
    xlab('Defaults') +
    ggtitle('Total Defaults in Mexico')
  
  df = data.frame(T_rep=T_rep_2)
  g_2 <- ggplot(df, aes(x=T_rep)) +
    geom_histogram(fill='lightblue',
                   color='black') +
    geom_vline(xintercept = T_obs_2, color = 'red') +
    ylab('') +
    xlab('Defaults') +
    ggtitle('Highest City Default')
  
  g_overlay <- ppc_dens_overlay(y = inputs$y, yrep = y_rep[1:200, ])
  g_overlay <- g_overlay  + xlim(1, 15) + ggtitle('City Overlay')
  
  g_overlay_state <- ppc_dens_overlay(y = df_state$y_state, 
                                      yrep = y_state_rep[400:600, ])
  g_overlay_state <-  g_overlay_state + ggtitle('State Overlay')
  
  gridExtra::grid.arrange(g_2, g_1, g_overlay, g_overlay_state,
                          layout_matrix=rbind(c(1, 2), c(3, 4)))
}

plot_states <- function(y_state_rep, df_state){
  T_rep <- y_state_rep[,18]
  T_obs <- df_state$y_state[18]
  df = data.frame(T_rep=T_rep)
  g1 <- ggplot(df, aes(x=T_rep)) +
    geom_histogram(fill='lightblue',
                   color='black',
                   bins = 20) +
    geom_vline(xintercept = T_obs, color = 'red') 
  
  T_rep <- y_state_rep[,10]
  T_obs <- df_state$y_state[10]
  df = data.frame(T_rep=T_rep)
  g2 <- ggplot(df, aes(x=T_rep)) +
    geom_histogram(fill='lightblue',
                   color='black',
                   bins = 20) +
    geom_vline(xintercept = T_obs, color = 'red')
  
  T_rep <- y_state_rep[,20]
  T_obs <- df_state$y_state[20]
  df = data.frame(T_rep=T_rep)
  g3 <- ggplot(df, aes(x=T_rep)) +
    geom_histogram(fill='lightblue',
                   color='black',
                   bins = 20) +
    geom_vline(xintercept = T_obs, color = 'red')
  
  T_rep <- y_state_rep[,3]
  T_obs <- df_state$y_state[3]
  df = data.frame(T_rep=T_rep)
  g4 <- ggplot(df, aes(x=T_rep)) +
    geom_histogram(fill='lightblue',
                   color='black',
                   bins = 20) +
    geom_vline(xintercept = T_obs, color = 'red')
  
  T_rep <- y_state_rep[,17]
  T_obs <- df_state$y_state[17]
  df = data.frame(T_rep=T_rep)
  g5 <- ggplot(df, aes(x=T_rep)) +
    geom_histogram(fill='lightblue',
                   color='black',
                   bins = 20) +
    geom_vline(xintercept = T_obs, color = 'red')
  
  T_rep <- y_state_rep[,7]
  T_obs <- df_state$y_state[7]
  df = data.frame(T_rep=T_rep)
  g6 <- ggplot(df, aes(x=T_rep)) +
    geom_histogram(fill='lightblue',
                   color='black',
                   bins = 20) +
    geom_vline(xintercept = T_obs, color = 'red')
  
  T_rep <- y_state_rep[,25]
  T_obs <- df_state$y_state[25]
  df = data.frame(T_rep=T_rep)
  g7 <- ggplot(df, aes(x=T_rep)) +
    geom_histogram(fill='lightblue',
                   color='black',
                   bins = 20) +
    geom_vline(xintercept = T_obs, color = 'red')
  
  T_rep <- y_state_rep[,2]
  T_obs <- df_state$y_state[2]
  df = data.frame(T_rep=T_rep)
  g8 <- ggplot(df, aes(x=T_rep)) +
    geom_histogram(fill='lightblue',
                   color='black',
                   bins = 20) +
    geom_vline(xintercept = T_obs, color = 'red')
  
  T_rep <- y_state_rep[,1]
  T_obs <- df_state$y_state[1]
  df = data.frame(T_rep=T_rep)
  g9 <- ggplot(df, aes(x=T_rep)) +
    geom_histogram(fill='lightblue',
                   color='black',
                   bins = 20) +
    geom_vline(xintercept = T_obs, color = 'red')
  
  gridExtra::grid.arrange(g1, g2, g3, g4, g5, g6, g7, g8, g9,
                          layout_matrix=rbind(c(1, 2, 3), 
                                              c(4, 5, 6),
                                              c(7, 8, 9)))
}

# create_adjancency <- function(path, data){
#   N = length(unique(data$state))
#   A <- matrix(0,ncol = N,nrow = N)
#   colnames(A) = (unique(data$state))[order(unique(data$state))]
#   rownames(A) = (unique(data$state))[order(unique(data$state))]
#   A['NUEVO LEON',c('ZACATECAS','SAN LUIS POTOSI','TAMAULIPAS','COAHUILA DE ZARAGOZA')] = 1
#   A[c('ZACATECAS','SAN LUIS POTOSI','TAMAULIPAS','COAHUILA DE ZARAGOZA'),'NUEVO LEON'] = 1
#   A['VERACRUZ LLAVE',c('TAMAULIPAS','SAN LUIS POTOSI','HIDALGO','PUEBLA','OAXACA','CHIAPAS','TABASCO')] = 1
#   A[c('TAMAULIPAS','SAN LUIS POTOSI','HIDALGO','PUEBLA','OAXACA','CHIAPAS','TABASCO'),'VERACRUZ LLAVE'] = 1
#   A['GUANAJUATO',c('MICHOACAN DE OCAMPO','JALISCO','SAN LUIS POTOSI','ZACATECAS','QUERETARO DE ARTEAGA')] = 1
#   A[c('MICHOACAN DE OCAMPO','JALISCO','SAN LUIS POTOSI','ZACATECAS','QUERETARO DE ARTEAGA'),'GUANAJUATO'] = 1
#   A['NAYARIT',c('SINALOA','DURANGO','ZACATECAS','JALISCO')] = 1
#   A[c('SINALOA','DURANGO','ZACATECAS','JALISCO'),'NAYARIT'] = 1
#   A['JALISCO',c('NAYARIT','ZACATECAS','COLIMA','MICHOACAN DE OCAMPO','GUANAJUATO','AGUASCALIENTES')] = 1
#   A[c('NAYARIT','ZACATECAS','COLIMA','MICHOACAN DE OCAMPO','GUANAJUATO','AGUASCALIENTES'),'JALISCO'] = 1
#   A['DISTRITO FEDERAL',c('ESTADO DE MEXICO','MORELOS')] = 1
#   A[c('ESTADO DE MEXICO','MORELOS'),'DISTRITO FEDERAL'] = 1
#   A['MORELOS',c('GUERRERO','PUEBLA','ESTADO DE MEXICO')] = 1
#   A[c('GUERRERO','PUEBLA','ESTADO DE MEXICO'),'MORELOS'] = 1
#   A['MICHOACAN DE OCAMPO',c('COAHUILA DE ZARAGOZA','ESTADO DE MEXICO','JALISCO','GUANAJUATO','GUERRERO','QUERETARO DE ARTEAGA')] = 1
#   A[c('COAHUILA DE ZARAGOZA','JALISCO','ESTADO DE MEXICO','GUANAJUATO','GUERRERO','QUERETARO DE ARTEAGA'),'MICHOACAN DE OCAMPO'] = 1
#   A['ESTADO DE MEXICO',c('HIDALGO','QUERETARO DE ARTEAGA','MICHOACAN DE OCAMPO','GUERRERO','PUEBLA','TLAXCALA','MORELOS')] = 1
#   A[c('HIDALGO','QUERETARO DE ARTEAGA','MICHOACAN DE OCAMPO','GUERRERO','PUEBLA','TLAXCALA','MORELOS'), 'ESTADO DE MEXICO'] = 1
#   A['HIDALGO',c('ESTADO DE MEXICO','QUERETARO DE ARTEAGA','SAN LUIS POTOSI','VERACRUZ LLAVE','PUEBLA','TLAXCALA')] = 1
#   A[c('ESTADO DE MEXICO','QUERETARO DE ARTEAGA','SAN LUIS POTOSI','VERACRUZ LLAVE','PUEBLA','TLAXCALA'),'HIDALGO'] = 1
#   A['ZACATECAS',c('JALISCO','NAYARIT','DURANGO','COAHUILA DE ZARAGOZA','NUEVO LEON','TAMAULIPAS','SAN LUIS POTOSI','AGUASCALIENTES')] = 1
#   A[c('JALISCO','NAYARIT','DURANGO','COAHUILA DE ZARAGOZA','NUEVO LEON','TAMAULIPAS','SAN LUIS POTOSI','AGUASCALIENTES'),'ZACATECAS'] = 1
#   A['GUERRERO',c('MICHOACAN DE OCAMPO','PUEBLA','ESTADO DE MEXICO','MORELOS')] = 1
#   A[c('MICHOACAN DE OCAMPO','PUEBLA','ESTADO DE MEXICO','MORELOS'),'GUERRERO'] = 1
#   A['DURANGO',c('CHIHUAHUA','COAHUILA DE ZARAGOZA','ZACATECAS','NAYARIT','SINALOA')] = 1
#   A[c('CHIHUAHUA','COAHUILA DE ZARAGOZA','ZACATECAS','NAYARIT','SINALOA'),'DURANGO'] = 1
#   A['CHIHUAHUA',c('DURANGO','SINALOA','COAHUILA DE ZARAGOZA','SONORA')] = 1
#   A[c('DURANGO','SINALOA','COAHUILA DE ZARAGOZA','SONORA'),'CHIHUAHUA'] = 1
#   A['CHIAPAS',c('OAXACA','VERACRUZ LLAVE','TABASCO','CAMPECHE')] = 1
#   A[c('OAXACA','VERACRUZ LLAVE','TABASCO','CAMPECHE'),'CHIAPAS'] = 1
#   A['COLIMA',c('JALISCO','MICHOACAN DE OCAMPO')] = 1
#   A[c('JALISCO','MICHOACAN DE OCAMPO'),'COLIMA'] = 1　
#   A['COAHUILA DE ZARAGOZA',c('NUEVO LEON','ZACATECAS','DURANGO','CHIHUAHUA','SAN LUIS POTOSI')] = 1
#   A[c('NUEVO LEON','ZACATECAS','DURANGO','CHIHUAHUA','SAN LUIS POTOSI'),'COAHUILA DE ZARAGOZA'] = 1
#   A['SAN LUIS POTOSI',c('TABASCO','NUEVO LEON','COAHUILA DE ZARAGOZA','ZACATECAS','JALISCO','GUANAJUATO','QUERETARO DE ARTEAGA','HIDALGO','VERACRUZ LLAVE')] = 1
#   A[c('TABASCO','NUEVO LEON','COAHUILA DE ZARAGOZA','ZACATECAS','JALISCO','GUANAJUATO','QUERETARO DE ARTEAGA','HIDALGO','VERACRUZ LLAVE'),'SAN LUIS POTOSI'] = 1
#   A['CAMPECHE',c('TABASCO','QUINTANA ROO','YUCATAN')] = 1
#   A[c('TABASCO','QUINTANA ROO','YUCATAN'),'CAMPECHE'] = 1
#   A['BAJA CALIFORNIA SUR',c('BAJA CALIFORNIA','SONORA','SINALOA')] = 1
#   A[c('BAJA CALIFORNIA','SONORA','SINALOA'),'BAJA CALIFORNIA SUR'] = 1
#   A['BAJA CALIFORNIA',c('BAJA CALIFORNIA SUR','SONORA')] = 1
#   A[c('BAJA CALIFORNIA SUR','SONORA'),'BAJA CALIFORNIA'] = 1
#   A['AGUASCALIENTES',c('ZACATECAS','JALISCO')] = 1
#   A[c('ZACATECAS','JALISCO'),'AGUASCALIENTES'] = 1
#   A['YUCATAN',c('CAMPECHE','QUINTANA ROO')] = 1
#   A[c('CAMPECHE','QUINTANA ROO'),'YUCATAN'] = 1
#   A['TAMAULIPAS',c('NUEVO LEON','SAN LUIS POTOSI','VERACRUZ LLAVE')] = 1
#   A[c('NUEVO LEON','SAN LUIS POTOSI','VERACRUZ LLAVE'),'TAMAULIPAS'] = 1
#   A['TABASCO',c('CAMPECHE','CHIAPAS','VERACRUZ LLAVE')] = 1
#   A[c('CAMPECHE','CHIAPAS','VERACRUZ LLAVE'),'TABASCO'] = 1
#   A['SONORA',c('BAJA CALIFORNIA','BAJA CALIFORNIA SUR','SINALOA','CHIHUAHUA')] = 1
#   A[c('BAJA CALIFORNIA','BAJA CALIFORNIA SUR','SINALOA','CHIHUAHUA'),'SONORA'] = 1
#   A['SINALOA',c('SONORA','CHIHUAHUA','DURANGO','NAYARIT')] = 1
#   A[c('SONORA','CHIHUAHUA','DURANGO','NAYARIT'),'SINALOA'] = 1
#   A['QUINTANA ROO',c('YUCATAN','CAMPECHE')] = 1
#   A[c('YUCATAN','CAMPECHE'),'QUINTANA ROO'] =1
#   A['QUERETARO DE ARTEAGA',c('SAN LUIS POTOSI','HIDALGO','ESTADO DE MEXICO','GUANAJUATO','MICHOACAN DE OCAMPO')] = 1
#   A[c('SAN LUIS POTOSI','HIDALGO','ESTADO DE MEXICO','GUANAJUATO','MICHOACAN DE OCAMPO'),'QUERETARO DE ARTEAGA'] = 1
#   A['PUEBLA',c('ESTADO DE MEXICO','MORELOS','TLAXCALA','GUERRERO','OAXACA','VERACRUZ LLAVE','HIDALGO')] = 1
#   A[c('ESTADO DE MEXICO','MORELOS','TLAXCALA','GUERRERO','OAXACA','VERACRUZ LLAVE','HIDALGO'),'PUEBLA'] = 1
#   A['TLAXCALA',c('ESTADO DE MEXICO','HIDALGO','PUEBLA')] = 1
#   A[c('ESTADO DE MEXICO','HIDALGO','PUEBLA'),'TLAXCALA'] = 1
#   A['OAXACA',c('GUERRERO','PUEBLA','VERACRUZ LLAVE','CHIAPAS')] = 1
#   A[c('GUERRERO','PUEBLA','VERACRUZ LLAVE','CHIAPAS'),'OAXACA'] =1
#   write.table(A, file=path, sep = ',', col.names = F, row.names = F)
# }
