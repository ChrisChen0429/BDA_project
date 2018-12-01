// baseline model: city level
data {
  int<lower=1> N_train;               // number of record, train
  int<lower=1> N_test;                // number of record, test
  int<lower=1> D;                     // number of covariates
  matrix[N_train, D] X_train;           // train data
  matrix[N_test, D] X_test;             // test data
  int<lower=1> n_city_train[N_train];   // number of record for city n, train
  int<lower=1> n_city_test[N_test];     // number of record for city n, test
  int<lower=0> y_train[N_train];      // y train
}
parameters {
  // regression coefficient vector
  real a; // include intercept
  vector[D] beta;
}
transformed parameters {
  vector[N_train] eta;
  eta = a + X_train*beta;
}
model {
  a ~ normal(0, 5);
  beta ~ normal(0, 5);
  y_train ~ binomial_logit(n_city_train, eta);
}
generated quantities{
  int<lower =0> y_rep[N_train];
  int<lower =0> y_rep_cv[N_test];
  for (i in 1:N_train){
    y_rep[i] = binomial_rng(n_city_train[i], inv_logit(eta[i]));
  }
  for (i in 1:N_test){
    y_rep_cv[i] = binomial_rng(n_city_test[i], inv_logit(eta[i]));
  }
}
