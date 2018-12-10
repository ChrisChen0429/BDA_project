functions {
  real sparse_iar_lpdf(vector phi, 
                        real tau, 
                        int[,] W_sparse, 
                        vector D_sparse, 
                        vector lambda, 
                        int S,
                        int W_n) {
      row_vector[S] phit_D; // phi' * D
      row_vector[S] phit_W; // phi' * W
      vector[S] ldet_terms;
    
      phit_D = (phi .* D_sparse)';
      phit_W = rep_row_vector(0, S);
      for (i in 1:W_n) {
        phit_W[W_sparse[i, 1]] = phit_W[W_sparse[i, 1]] + phi[W_sparse[i, 2]];
        phit_W[W_sparse[i, 2]] = phit_W[W_sparse[i, 2]] + phi[W_sparse[i, 1]];
      }
    
      return 0.5 * ((S-1) * log(tau)
                    - tau * (phit_D * phi - (phit_W * phi)));
  }
} data {
  int<lower = 1> N_train;               // number of record of train set
  int<lower = 1> N_test;                // number of record of test set
  int<lower = 1> D;                     // number of non-geo parameter
  int<lower = 1> S;                     // number of state
  int<lower=1> city_n_train[N_train];   // number of record for city k in 
  int<lower=1> city_n_test[N_test];     // number of record for city k in
  int<lower=1> state_train[N_train];    // state indicator for train set
  int<lower=1> state_test[N_test];      // state indicator for test set
  matrix[N_train, D] X_train;           // raw design matrix for train set
  matrix[N_test, D] X_test;             // raw design matrix for train set
  int<lower = 0> y_train[N_train];      // response for train set
  matrix<lower = 0, upper = 1>[S, S] W; // adjacency matrix
  int W_n;                              // number of adjacent region pairs
} transformed data {
  int W_sparse[W_n, 2];   // adjacency pairs
  vector[S] D_sparse;     // diagonal of D (number of neigbors for each site)
  vector[S] lambda;       // eigenvalues of invsqrtD * W * invsqrtD
  { // generate sparse representation for W
  int counter;
  counter = 1;
  // loop over upper triangular part of W to identify neighbor pairs
    for (i in 1:(S - 1)) {
      for (j in (i + 1):S) {
        if (W[i, j] == 1) {
          W_sparse[counter, 1] = i;
          W_sparse[counter, 2] = j;
          counter = counter + 1;
        }
      }
    }
  }
  for (i in 1:S) D_sparse[i] = sum(W[i]);
  {
    vector[S] invsqrtD;  
    for (i in 1:S) {
      invsqrtD[i] = 1 / sqrt(D_sparse[i]);
    }
    lambda = eigenvalues_sym(quad_form(W, diag_matrix(invsqrtD)));
  }
} parameters {
  vector[D] beta;                   
  vector[S] phi_unscaled;
  real<lower = 0> tau;
  real<lower=0, upper=1> theta;                  // probability of draw a zero
  real alpha;
} transformed parameters {
  vector[S] phi;                                 // brute force centering
  phi = phi_unscaled - mean(phi_unscaled);
} model {
  tau ~ gamma(2, 2);
  phi_unscaled ~ sparse_iar(tau, W_sparse, D_sparse, lambda, S, W_n);
  beta ~ normal(0, 5);
  alpha ~ normal(0, 5); 
  y_train ~ binomial_logit(city_n_train, 
  alpha + phi[state_train] + X_train * beta);
} generated quantities {
  int<lower=0> y_rep_train[N_train];
  int<lower=0> y_rep_test[N_test];
  for (i in 1:N_train){
    y_rep_train[i] = binomial_rng(city_n_train[i], 
    inv_logit(alpha + phi[state_train[i]] + X_train[i, :] * beta));
  }
  for (i in 1:N_test){
    y_rep_test[i] = binomial_rng(city_n_test[i], 
    inv_logit(alpha + phi[state_test[i]] + X_test[i, :] * beta));
  }
}
