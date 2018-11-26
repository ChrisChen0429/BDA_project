data {
  int<lower=0> N;
  int<lower=0> D;
  matrix[N, D] X;
  int<lower=0> Ns[N];
  int<lower=0> y[N];
} parameters {
  real alpha;
  vector[D] beta;
} transformed parameters {
  vector[N] theta;
  theta = inv_logit(alpha + X * beta);
} model {
  alpha ~ normal(0, 5);
  beta ~ normal(0, 3);
  y ~ binomial_logit(Ns, alpha + X * beta);
} generated quantities {
  int<lower=0> y_rep[N];
  for (i in 1:N){
    y_rep[i] = binomial_rng(Ns[i], inv_logit(alpha + X[i, ] * beta));
  }
}
