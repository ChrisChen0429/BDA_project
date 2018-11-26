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
}
data {
  int<lower = 1> s;                     // number of state
  int<lower = 1> n;                     // number of record
  int<lower = 1> p;                     // number of non-geo parameter
  matrix[n, p] X;                       // raw data matrix
  int<lower = 0> y[n];                  // response
  int<lower=1> state[n];                // state indicator
  matrix<lower = 0, upper = 1>[s, s] W; // adjacency matrix
  int W_n;                              // number of adjacent region pairs
}
transformed data {
  int W_sparse[W_n, 2];   // adjacency pairs
  vector[s] D_sparse;     // diagonal of D (number of neigbors for each site)
  vector[s] lambda;       // eigenvalues of invsqrtD * W * invsqrtD
  
  { // generate sparse representation for W
  int counter;
  counter = 1;
  // loop over upper triangular part of W to identify neighbor pairs
    for (i in 1:(s - 1)) {
      for (j in (i + 1):s) {
        if (W[i, j] == 1) {
          W_sparse[counter, 1] = i;
          W_sparse[counter, 2] = j;
          counter = counter + 1;
        }
      }
    }
  }
  for (i in 1:s) D_sparse[i] = sum(W[i]);
  {
    vector[s] invsqrtD;  
    for (i in 1:s) {
      invsqrtD[i] = 1 / sqrt(D_sparse[i]);
    }
    lambda = eigenvalues_sym(quad_form(W, diag_matrix(invsqrtD)));
  }
}
parameters {
  matrix[s,p] beta;    // betas are different for different states
  vector[s] phi_unscaled;
  real<lower = 0> tau;
}
transformed parameters {
  vector[s] phi; // brute force centering
  phi = phi_unscaled - mean(phi_unscaled);
}
model {
  tau ~ gamma(2, 2);
  phi_unscaled ~ sparse_iar(tau, W_sparse, D_sparse, lambda, n, W_n);
  for (i in 1:s){beta[i,] ~ normal(phi[i], 5);}
  for (i in 1:n){y[i] ~ poisson_log(X[i,] * beta[state[i],]');}
}
generated quantities{
  int<lower =0> y_rep[n];
  for (i in 1:n){y_rep[i] = poisson_log_rng(X[i,] * beta[state[i],]');
  }
}

