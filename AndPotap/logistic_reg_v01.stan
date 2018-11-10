data {
  int<lower=0> N;
  int<lower=0> D;
  matrix[N, D] X;
  int<lower=0, upper=1> y[N];
} parameters {
  real alpha;
  vector[D] beta;
} model {
  alpha ~ normal(0, 5);
  beta ~ normal(0, 5);
  y ~ bernoulli_logit(X * beta + alpha);
}
