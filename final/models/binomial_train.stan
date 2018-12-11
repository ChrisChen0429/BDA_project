data {
  int<lower=1> N_train;
  int<lower=1> N_test;
  int<lower=1> D;
  int<lower=0> city_n_train[N_train];
  int<lower=0> city_n_test[N_test];
  matrix[N_train, D] X_train;
  matrix[N_test, D] X_test;
  int<lower=0> y_train[N_train];
} parameters {
  real alpha;
  vector[D] beta;
} model {
  alpha ~ normal(0, 5);
  beta ~ normal(0, 5);
  y_train ~ binomial_logit(city_n_train, alpha + X_train * beta);
} generated quantities {
  int<lower=0> y_rep_train [N_train];
  int<lower=0> y_rep_test [N_test];
  for (i in 1:N_train){
    y_rep_train[i] = binomial_rng(city_n_train[i], 
    inv_logit(alpha + X_train[i, :] * beta));
  }
  for (i in 1:N_test){
    y_rep_test[i] = binomial_rng(city_n_test[i], 
    inv_logit(alpha + X_test[i, :] * beta));
  }
}
