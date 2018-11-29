// baseline model: city level
functions {
   /*
   * Alternative to poisson_log_rng() that 
   * avoids potential numerical problems during warmup
   */
   int poisson_log_safe_rng(real eta) {
     real pois_rate = exp(eta);
     if (pois_rate >= exp(20.79))
       return -9;
     return poisson_rng(pois_rate);
   }
}
data {
  int<lower = 1> n;                     // number of record
  int<lower = 1> p;                     // number of non-geo parameter
  matrix[n, p] X;                       // raw data matrix
  int<lower = 0> y[n];                  // response
  vector[n] number;               // number of record for city k
}

parameters {
  vector[p] beta;
}
model {
  beta ~ cauchy(0,1);
  y ~ poisson_log(log(number) + X * beta );
}
generated quantities{
  int<lower =0> y_rep[n];
  for (i in 1:n){
    y_rep[i] = poisson_log_rng(log(number[i]) + X[i,] * beta);
  }
}

