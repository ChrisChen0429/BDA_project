data {
  int<lower=1> N;
  int<lower=1> D;
  int<lower=1> S;
  int<lower=1> city_n[N];
  int<lower=1, upper=S> state[N];
  matrix[N, D] X;
  int<lower=0> y[N];
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
  y ~ binomial_logit(city_n, alpha_s[state] + X * beta);
} generated quantities {
  int<lower=0> y_rep[N];
  for (i in 1:N){
    y_rep[i] = binomial_rng(city_n[i], 
    inv_logit(alpha_s[state[i]] + X[i, :] * beta));
  }
}
