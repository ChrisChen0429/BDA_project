data {
  int<lower=0> N;
  vector[N] age;
  vector[N] 
  int<lower=0, upper=1> y[N];
} parameters {
  real alpha;
  real beta1;
  real beta2;
} model {
  for (i in 1:N)
    y[i] ~ bernoulli_logit(alpha + dot_product(beta, x[i]));
}
