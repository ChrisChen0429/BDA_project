functions {
  real sparse_iar_lpdf(vector phi, real tau,
    int[,] W_sparse, vector D_sparse, vector lambda, int n, int W_n) {
      row_vector[n] phit_D; // phi' * D
      row_vector[n] phit_W; // phi' * W
      vector[n] ldet_terms;
    
      phit_D = (phi .* D_sparse)';
      phit_W = rep_row_vector(0, n);
      for (i in 1:W_n) {
        phit_W[W_sparse[i, 1]] = phit_W[W_sparse[i, 1]] + phi[W_sparse[i, 2]];
        phit_W[W_sparse[i, 2]] = phit_W[W_sparse[i, 2]] + phi[W_sparse[i, 1]];
      }
    
      return 0.5 * ((n-1) * log(tau)
                    - tau * (phit_D * phi - (phit_W * phi)));
  }
  
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
  int<lower = 1> n;                     // number of state
  int<lower = 1> k;                     // number of record
  int<lower = 1> p;                     // number of non-geo parameter
  matrix[k, p] X;                       // raw data matrix
  int<lower = 0> y[k];                  // response
  int<lower=1> state[k];                // state indicator
  matrix<lower = 0, upper = 1>[n, n] W; // adjacency matrix
  int W_n;                              // number of adjacent region pairs
  int<lower=1> number[k];               // number of record for city k
}
transformed data {
  int W_sparse[W_n, 2];   // adjacency pairs
  vector[n] D_sparse;     // diagonal of D (number of neigbors for each site)
  vector[n] lambda;       // eigenvalues of invsqrtD * W * invsqrtD
  
  { // generate sparse representation for W
  int counter;
  counter = 1;
  // loop over upper triangular part of W to identify neighbor pairs
    for (i in 1:(n - 1)) {
      for (j in (i + 1):n) {
        if (W[i, j] == 1) {
          W_sparse[counter, 1] = i;
          W_sparse[counter, 2] = j;
          counter = counter + 1;
        }
      }
    }
  }
  for (i in 1:n) D_sparse[i] = sum(W[i]);
  {
    vector[n] invsqrtD;  
    for (i in 1:n) {
      invsqrtD[i] = 1 / sqrt(D_sparse[i]);
    }
    lambda = eigenvalues_sym(quad_form(W, diag_matrix(invsqrtD)));
  }
}
parameters {
  matrix[n,p] beta;
  vector[n] phi_unscaled;
  real<lower = 0> tau;
  real<lower=0, upper=1> theta;                  // probability of draw a zero
}
transformed parameters {
  vector[n] phi;                                 // brute force centering
  phi = phi_unscaled - mean(phi_unscaled);
}
model {
  tau ~ gamma(2, 2);
  phi_unscaled ~ sparse_iar(tau, W_sparse, D_sparse, lambda, n, W_n);
  for (i in 1:n){beta[i,] ~ normal(phi[i], 5);}
  for (j in 1:k){
    if (y[j] == 0){
      target += log_sum_exp(bernoulli_lpmf(1 | theta),bernoulli_lpmf(0 | theta) + poisson_log_lpmf(y[j] | X[j,] * beta[state[j],]'));}
    else{
      target += bernoulli_lpmf(0 | theta) + poisson_log_lpmf(y[j] | log(number[j]) + X[j,] * beta[state[j],]');
    }
  }
}
generated quantities{
  int y_rep[k];
  real<lower =0,upper=1> zero[k];
  for (i in 1:k){
    zero[i] = uniform_rng(0,1);
    if (zero[i] < theta){y_rep[i] = 0;}
    else{y_rep[i] = poisson_log_safe_rng(log(number[i]) +X[i,] * beta[state[i],]');}
  }
}


