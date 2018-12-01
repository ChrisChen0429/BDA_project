data {
  int<lower=0> N;
  int<lower=0> D;
  matrix[N, D] X;
  int<lower=0, upper=1> y[N];
} transformed data {
  matrix[N, D] Q;
  matrix[D, D] R;
  matrix[D, D] R_inv;
  Q = qr_Q(X)[, 1:D] * sqrt(N - 1);
  R = qr_R(X)[1:D, ] / sqrt(N - 1);
  R_inv = inverse(R);
} parameters {
  real alpha;
  vector[D] theta;
} model {
  alpha ~ normal(0, 5);
  theta ~ normal(0, 5);
  y ~ bernoulli_logit(alpha + Q * theta);
} generated quantities {
  int<lower=0, upper=1> y_rep[N];
  vector[D] beta;
  for (i in 1:N){
    y_rep[i] = bernoulli_logit_rng(alpha + Q[i, :] * theta);
  }
  beta = R_inv * theta;
}
