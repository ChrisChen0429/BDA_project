// baseline model: city level
data {
  int<lower = 1> n;                 // number of record
  int<lower = 1> p;                 // number of non-geo parameter
  matrix[n, p] X;                   // raw data matrix
  int y[n];                         // response
}
parameters {
  // regression coefficient vector
  real alpha;
  vector[p] beta;
}
transformed parameters {
  vector[n] eta;
  eta = alpha + X*beta;
}
model {
  alpha ~ normal(0, 5);
  beta ~ normal(0, 5);
  y ~ binomial_logit(n, eta);
}
generated quantities{
  int<lower =0> y_rep[n];
  for (i in 1:n){
    y_rep[i] = binomial_rng(n, inv_logit(eta[i]));
  }
}
