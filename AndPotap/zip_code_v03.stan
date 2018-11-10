data {
  int<lower=2> K;
  int<lower=0> M;
  int<lower=0> N[M];
  int<lower=0> y[M];
  vector<lower=0>[K] a0;
  int<lower=1, upper=K> z[M];
} parameters {
  simplex[K] phi;
  real alpha;
  real beta;
  vector<lower=0, upper=1>[K] theta;
} model {
  alpha ~ gamma(2, 2);
  beta ~ gamma(2, 2);
  phi ~ dirichlet(a0);
  theta ~ beta(alpha, beta);
  for (j in 1:M){
    z[j] ~ categorical(phi);
    y[j] ~ poisson(N[j] * theta[z[j]]);
  }
} generated quantities {
  int<lower=1, upper=K> z_rep[M];
  for (j in 1:M){
    z_rep[j] = categorical_rng(phi);
  }
}
