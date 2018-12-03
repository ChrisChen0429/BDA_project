data {
  int<lower=0> N_train;
  int<lower=0> N_test;
  int<lower=0> State_N_train[N_train];
  int<lower=0> State_N_test[N_test];
  int<lower=0> D;
  matrix[N_train, D] X_train;
  matrix[N_test, D] X_test;
  int<lower=0> y_train[N_train];
} parameters {
  real alpha;
  vector[D] beta;
} model {
  alpha ~ normal(0, 5);
  beta ~ normal(0, 5);
  y_train ~ poisson(to_vector(State_N_train) .* exp(alpha + X_train * beta));
} generated quantities {
  int<lower=0> yrep_test[N_test];
  for (i in 1:N_test) {
    yrep_test[i] = poisson_rng(State_N_test[i] * exp(alpha + X_test[i, :] * beta));
  }
}
