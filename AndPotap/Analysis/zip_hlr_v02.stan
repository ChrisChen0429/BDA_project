data {
  int<lower=1> N;
  int<lower=1> D;
  int<lower=1> Z;
  int<lower=1> S;
  int<lower=1> ss;
  int<lower=1> zz;
  matrix[N, D] X;
  int<lower=0, upper=1> y[N];
} parameters {
  real beta;
  vector[S] beta_s;
  vector[Z] beta_z;
} model {
  beta ~ normal(0, 100);
  
  y ~ bernoulli_logit(X * beta + alpha);
}
