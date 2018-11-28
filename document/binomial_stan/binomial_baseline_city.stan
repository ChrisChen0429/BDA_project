// baseline model: city level
data {
  int<lower = 1> n;               // number of record
  int<lower = 1> p;               // number of non-geo parameter
  matrix[n, p] X;                 // raw data matrix
  int y[n];                       // response
  int<lower=1> number[n];         // number of record for city n
}
parameters {
  // regression coefficient vector
  // real alpha;
  vector[p] beta;
}
transformed parameters {
  vector[n] eta;
  eta = X*beta;
}
model {
  // alpha ~ normal(0, 5);
  beta ~ normal(0, 5);
  y ~ binomial_logit(number, eta);
}
generated quantities{
  int<lower =0> y_rep[n];
  for (i in 1:n){
    y_rep[i] = binomial_rng(number[i], inv_logit(eta[i]));
  }
}
