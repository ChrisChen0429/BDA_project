data {
  int<lower=1> Z;
  int<lower=1> N_z[Z];
  int<lower=0> y[Z];
} parameters {
  real beta;
  real<lower=0> sigma;
  vector[Z] beta_z_raw;
} transformed parameters {
  vector[Z] beta_z;
  beta_z = beta + beta_z_raw * sigma;
} model {
  beta ~ normal(0, 100);
  sigma ~ lognormal(0, 10);
  beta_z_raw ~ std_normal(); 
  y ~ binomial_logit(N_z, beta_z);
} generated quantities {
  vector[Z] theta;
  theta = inv_logit(beta_z);
}
