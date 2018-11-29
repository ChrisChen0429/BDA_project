data {
  int<lower = 1> s;               // number of state
  int<lower = 1> n;               // number of record
  int<lower = 1> p;               // number of non-geo parameter
  matrix[n, p] X;                 // raw data matrix
  int<lower = 0> y[n];            // response
  int<lower=1> state[n];          // state indicator
  int<lower=1> number[n];
}
parameters {
  real alpha;
  real alpha_s[s];
  matrix[s,p] beta;               // betas are different for different states
  //matrix[s,p] a;
}
model {
  alpha ~ normal(0,5);
  alpha_s ~ normal(alpha,5);
  //for (i in 1:s){a[i,] ~ normal(alpha_s[i], 5);}
  for (i in 1:s){beta[i,] ~ normal(alpha_s[i], 5);}
  for (i in 1:n){y[i] ~ binomial_logit(number[i], X[i,]*beta[state[i],]');}
}
generated quantities{
  int<lower =0> y_rep[n];
  for (i in 1:n){
    y_rep[i] = binomial_rng(number[i], inv_logit(X[i,]*beta[state[i],]'));
  }
}

