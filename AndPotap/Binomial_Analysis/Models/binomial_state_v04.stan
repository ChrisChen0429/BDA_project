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
  vector<lower=0>[S] sigma_s_alpha;
  vector[D] beta;
  vector[D] beta_s_raw[S];
  vector<lower=0>[S] sigma_s_beta;
} transformed parameters {
  vector[S] alpha_s;
  vector[D] beta_s[S];
  vector[S] ones = rep_vector(1, S);
  alpha_s = alpha * ones + alpha_s_raw .* sigma_s_alpha;
  for (s in 1:S) {
    for (d in 1:D) {
     beta_s[s, d] = beta[d] + beta_s_raw[s, d] * sigma_s_beta[s]; 
    }
  }
} model {
  alpha ~ normal(0, 5);
  alpha_s_raw ~ std_normal();
  sigma_s_alpha ~ lognormal(0, 1);
  sigma_s_beta ~ lognormal(0, 1);
  beta ~ normal(0, 5);
  for (s in 1:S) beta_s_raw[s] ~ std_normal();
  {
    vector[N_train] X_train_beta_s;
    for (i in 1:N_train){
      X_train_beta_s[i] = X_train[i, ] * beta_s[State_train[i]];
    }
    y_train ~ binomial_logit(State_N_train, 
    alpha_s[State_train] + X_train_beta_s);
  }
} generated quantities {
  int<lower=0> yrep_test[N_test];
  for (i in 1:N_test) {
    yrep_test[i] = binomial_rng(State_N_test[i], 
    inv_logit(alpha_s[State_test[i]] + X_test[i, :] * beta_s[State_test[i], ]));
  }
}
