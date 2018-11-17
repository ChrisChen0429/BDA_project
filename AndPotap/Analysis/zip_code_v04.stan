data {
  int<lower=1> Z;
  int<lower=1> C;
  int<lower=1, upper=C> cc[Z];
  int<lower=0> N_z[Z];
  int<lower=0> y[Z];
} parameters {
  real<lower=0> alpha_a0;
  real<lower=0> alpha_b0;
  real<lower=0> beta_a0;
  real<lower=0> beta_b0;
  vector<lower=0>[C] alpha;
  vector<lower=0>[C] beta;
  vector<lower=0, upper=1>[Z] theta;
} model {
  alpha_a0 ~ gamma(0.5, 10);
  alpha_b0 ~ gamma(10, 1);
  beta_a0 ~  gamma(2, 1);
  beta_b0 ~ gamma(10, 1);
  alpha ~ gamma(alpha_a0, alpha_b0);
  beta ~ gamma(beta_a0, beta_b0);
  theta ~ beta(alpha[cc], beta[cc]);
  y ~ binomial(N_z, theta);
} generated quantities {
  int y_rep[Z];
  for (j in 1:Z){
    y_rep[j] = binomial_rng(N_z[j], theta[j]);
  }
}
