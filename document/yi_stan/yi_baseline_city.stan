// baseline model: city level
data {
  int<lower = 1> n;                     // number of record
  int<lower = 1> p;                     // number of non-geo parameter
  matrix[n, p] X;                       // raw data matrix
  int<lower = 0> y[n];                  // response
}

parameters {
  vector[p] beta;
}
model {
  beta ~ cauchy(0,1);
  y ~ poisson_log(X * beta );
}
generated quantities{
  int<lower =0> y_rep[n];
  for (i in 1:n){
    y_rep[i] = poisson_log_rng(X[i,] * beta);
  }
}

