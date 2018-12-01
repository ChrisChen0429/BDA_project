data {
  int <lower=0> N;
  int <lower=0> D;
  int<lower=0> S;
  int<lower=0> state[N];
  matrix[N, D] X;
  int <lower=0, upper=1> y[N];
} parameters {
  real alpha;
  vector[D] beta;
  vector[D] beta_s_raw[S];
  vector[S] alpha_s_raw;
  vector<lower=0>[S] sigma_s_alpha;
  vector<lower=0>[S] sigma_s_beta;
} transformed parameters {
  vector[S] alpha_s;
  vector[D] beta[S];
  for (s in 1:S){
    alpha_s[s] = alpha + alpha_s_raw[s] * sigma_s_alpha[s];
    for (d in 1:D) {
      beta_s[s, d] = beta[d] + beta_s_raw[s, d] * sigma_s_beta[s];
    }
  }
} model {
  alpha ~ normal(0, 5);
  beta ~ normal(0, 5);
  sigma_s_alpha ~ lognormal(0, 1);
  sigma_s_beta ~ lognormal(0, 1);
  alpha_s_raw ~ std_normal();
  beta_s_raw ~ std_normal();
  y ~ bernoulli_logit(alpha_s[state] + X * beta[state]);
} generated quantities {
  int<lower=0, upper=1> y_rep[N];
  vector[S] theta_s;
  for (i in 1:N){
   y_rep[i] = bernoulli_logit_rng(alpha_s[state[i]] + X[i, ] * beta[state[i]]); 
  }
  theta_s = inv_logit(alpha_s);
}
