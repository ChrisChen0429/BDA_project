data {
  int<lower=0> N_train;
  int<lower=0> N_test;
  int<lower=0> S;
  int<lower=0> State_train[N_train];
  int<lower=0> State_test[N_test];
  int<lower=0> State_N_train[N_train];
  int<lower=0> State_N_test[N_test];
  int<lower=0> D;
  matrix[N_train, D] X_train;
  matrix[N_test, D] X_test;
  int<lower=0> y_train[N_train];
} parameters {
  real alpha;
  vector[S] alpha_s_raw;
  vector<lower=0>[S] sigma_s;
  vector[D] beta;
} transformed parameters {
  vector[S] alpha_s;
  vector[S] ones = rep_vector(1, S);
  alpha_s = alpha * ones + alpha_s_raw .* sigma_s;
} model {
  alpha ~ normal(0, 5);
  alpha_s_raw ~ std_normal();
  sigma_s ~ lognormal(0, 1);
  beta ~ normal(0, 5);
  y_train ~ binomial_logit(State_N_train, 
  alpha_s[State_train] + X_train * beta);
} generated quantities {
  int<lower=0> yrep_test[N_test];
  for (i in 1:N_test) {
    yrep_test[i] = binomial_rng(State_N_test[i], 
    inv_logit(alpha_s[State_test[i]] + X_test[i, :] * beta));
  }
}
