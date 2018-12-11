data {
  int<lower=1> N_train;
  int<lower=1> N_test;
  int<lower=1> D;
  int<lower=1> S;
  int<lower=1> city_n_train[N_train];
  int<lower=1> city_n_test[N_test];
  int<lower=1, upper=S> state_train[N_train];
  int<lower=1, upper=S> state_test[N_test];
  matrix[N_train, D] X_train;
  matrix[N_test, D] X_test;
  int<lower=0> y_train[N_train];
} parameters {
  real alpha;
  vector[D] beta;
  vector[S] alpha_s_raw;
  vector<lower=0>[S] sigma_alpha_s;
} transformed parameters {
  vector[S] alpha_s;
  vector[S] ones = rep_vector(1, S);
  alpha_s = alpha * ones + alpha_s_raw .* sigma_alpha_s;
} model {
  alpha ~ normal(0, 5);
  beta ~ normal(0, 5);
  sigma_alpha_s ~ lognormal(1, 1);
  alpha_s_raw ~ std_normal();
  y_train ~ binomial_logit(city_n_train, 
  alpha_s[state_train] + X_train * beta);
} generated quantities {
  int<lower=0> y_rep_train[N_train];
  int<lower=0> y_rep_test[N_test];
  for (i in 1:N_train){
    y_rep_train[i] = binomial_rng(city_n_train[i], 
    inv_logit(alpha_s[state_train[i]] + X_train[i, :] * beta));
  }
  for (i in 1:N_test){
    y_rep_test[i] = binomial_rng(city_n_test[i], 
    inv_logit(alpha_s[state_test[i]] + X_test[i, :] * beta));
  }
}
