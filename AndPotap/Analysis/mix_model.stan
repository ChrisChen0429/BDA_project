data {
  int<lower=0> Total;
  int<lower=0> M;
  int<lower=0> D;
  int<lower=1, upper=M> ind_m[Total];
  int<lower=1, upper=D> ind_d[Total];
  int<lower=0> N_m[M];
  int<lower=0> N_d[D];
  int<lower=0> y_m[M];
  int<lower=0> y_d[D];
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
  for (m in 1:M){
   y_m[m] ~ poisson(N_m[m] * theta_m[m]);  
  }
  for (d in 1:D){
   y_d[d] ~ poisson(N_d[d] * theta_d[d]);  
  }
  for (t in 1:Total){
    y[t] ~ poisson(N[t] * (theta_m[ind_m[t]] + theta_d[ind_d[t]]));
  }
}
