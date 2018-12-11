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
  alpha ~ normal(0, 5);
  beta ~ normal(0, 5);
  y ~ poisson_log(log(to_vector(city_n)) + alpha + X * beta);
} generated quantities {
  int<lower=0> y_rep [N];
  for (i in 1:N){
    y_rep[i] = poisson_log_rng(log(city_n[i]) + alpha + X[i, :] * beta);
  }
}
