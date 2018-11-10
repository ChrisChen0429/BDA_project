data {
  int<lower=0> Total;
  int<lower=0> M;
  int<lower=0> D;
  int<lower=1, upper=M> ind_m[Total];
  int<lower=1, upper=D> ind_d[Total];
  int<lower=0> N[Total];
  int<lower=0> y[Total];
} parameters {
  real alpha_m;
  real beta_m;
  real alpha_d;
  real beta_d;
  vector<lower=0, upper=1>[M] theta_m;
  vector<lower=0, upper=1>[D] theta_d;
} model {
  alpha_m ~ gamma(2, 2);
  beta_m ~ gamma(2, 2);
  alpha_d ~ gamma(2, 2);
  beta_d ~ gamma(2, 2);
  theta_m ~ beta(alpha_m, beta_m);
  theta_d ~ beta(alpha_d, beta_d);
  for (t in 1:Total){
    y[t] ~ poisson(N[t] * (theta_m[ind_m[t]] + theta_d[ind_d[t]]));
  }
}
