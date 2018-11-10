data {
  int<lower=0> M;
  int<lower=0> N[M];
  int<lower=0> y[M];
} parameters {
  real alpha;
  real beta;
  vector<lower=0, upper=1>[M] theta;
} model {
  alpha ~ gamma(2, 2);
  beta ~ gamma(2, 2);
  theta ~ beta(alpha, beta);
  for (j in 1:M){
   y[j] ~ poisson(N[j] * theta[j]);  
  }
} generated quantities {
  int y_rep[M];
  for (j in 1:M){
    y_rep[j] = poisson_rng(N[j] * theta[j]);
  }
}
