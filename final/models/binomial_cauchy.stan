data {
  int<lower=1> N;
  int<lower=1> D;
  int<lower=0> city_n[N];
  matrix[N, D] X;
  int<lower=0> y[N];
} parameters {
  real alpha;
  vector[D] beta;
} model {
  alpha ~ cauchy(0, 1);
  beta ~ cauchy(0, 1);
  y ~ binomial_logit(city_n, alpha + X * beta);
} generated quantities {
  int<lower=0> y_rep [N];
  for (i in 1:N){
    y_rep[i] = binomial_rng(city_n[i], 
    inv_logit(alpha + X[i, :] * beta));
  }
}
