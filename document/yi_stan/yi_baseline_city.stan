// baseline model: city level

functions {
/*
* Alternative to poisson_log_rng() that 
* avoids potential numerical problems during warmup
*/
   int poisson_log_safe_rng(real eta) {
     real pois_rate = exp(eta);
     if (pois_rate >= exp(20.79))
       return -9;
     return poisson_rng(pois_rate);
   }
}


data {
  int<lower = 1> N_train;                     // number of record
  int<lower = 1> N_test;                     // number of record
  int<lower = 1> D;                     // number of non-geo parameter
  matrix[N_train, D] X_train;                       // raw data matrix
  int<lower = 0> y_train[N_train];                  // response
  vector[N_train] n_city_train;               // number of record for city k
  vector[N_test] n_city_test;
  matrix[N_test, D] X_test;                       // raw data matrix
  
}

parameters {
  vector[D] beta;
  real a;
}
model {
  beta ~ normal(0,5);
  a ~ normal(0,5);
  y_train ~ poisson_log(log(n_city_train) + a + X_train * beta );
}
generated quantities{
  int y_rep[N_train];
  int y_rep_cv[N_test];
  for (i in 1:N_train){
    y_rep[i] = poisson_log_safe_rng(log(n_city_train[i]) + a + X_train[i,] * beta);
  }
  for (i in 1:N_test){
    y_rep_cv[i] = poisson_log_safe_rng(log(n_city_test[i]) +  a +X_test[i,] * beta);
  }
}

