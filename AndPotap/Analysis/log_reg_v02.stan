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
  beta ~ normal(0, 3);
  y ~ bernoulli_logit(X * beta + alpha);
} generated quantities {
  int<lower=0, upper=1> y_rep[N];
  for (i in 1:N){
    y_rep[i] = bernoulli_logit_rng(X[i, ] * beta + alpha);
  }
}
