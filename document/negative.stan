// baseline model: city level
functions {
   int neg_binomial_2_log_safe_rng(real eta, real phi) {
     real gamma_rate = gamma_rng(phi, phi / exp(eta));
     if (gamma_rate >= exp(20.79))
       return -9;     
     return poisson_rng(gamma_rate);
   }
}

data {
  int<lower=1> N_train;               // number of record, train
  int<lower=1> N_test;                // number of record, test
  int<lower=1> D;                     // number of covariates
  matrix[N_train, D] X_train;           // train data
  matrix[N_test, D] X_test;             // test data
  vector[N_train] n_city_train;   // number of record for city n, train
  vector[N_test] n_city_test;     // number of record for city n, test
  int<lower=0> y_train[N_train];      // y train
}
parameters {
  // regression coefficient vector
  real a; // include intercept
  vector[D] beta;
  real<lower=0> phi;
}
transformed parameters {
  vector[N_train] eta;
  eta = a + X_train*beta;
}
model {
  a ~ normal(0, 5);
  beta ~ normal(0, 5);
  phi ~ normal(0,5);
  y_train ~ neg_binomial_2_log(log(n_city_train) + eta,phi);
}
generated quantities{
  int y_rep[N_train];
  int y_rep_cv[N_test];
  for (i in 1:N_train){
    y_rep[i] = neg_binomial_2_log_safe_rng(log(n_city_train[i])+ eta[i],phi);
  }
  for (i in 1:N_test){
    y_rep_cv[i] = neg_binomial_2_log_safe_rng(log(n_city_test[i])+ eta[i],phi);
  }
}