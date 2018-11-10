data {
  int<lower=0> N;
  int<lower=0> M;
  row_vector[M] x[N];
  int<lower=0, upper=1> y[N];
} parameters {
  real alpha;
  vector[M] beta;
} model {
  for (i in 1:N)
    y[i] ~ bernoulli_logit(alpha + dot_product(beta, x[i]));
}
