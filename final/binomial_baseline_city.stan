// baseline model: city level
data {
  int<lower=1> N_train;                 // number of record, train
  int<lower=1> N_test;                  // number of record, test
  int<lower=1> D;                       // number of covariates
  matrix[N_train, D] X_train;           // train data
  matrix[N_test, D] X_test;             // test data
  int<lower=1> n_city_train[N_train];   // number of record for city n, train
  int<lower=1> n_city_test[N_test];     // number of record for city n, test
  int<lower=0> y_train[N_train];        // y train
}
parameters {
  real a;                               // include intercept
  vector[D] beta;                       // regression coefficient vector
}
transformed parameters {
  vector[N_train] eta;
  eta = a + X_train*beta;               // probability in binomial regression
}
model {
  a ~ cauchy(0, 10);                    // Cauchy prior
  beta ~ cauchy(0, 2.5);                // Cauchy prior
  y_train ~ binomial_logit(n_city_train, eta);  // binomial model
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
