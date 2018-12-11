data {
  int<lower=0> N_train;
  int<lower=0> N_test;
  int<lower=0> city_n_train[N_train];
  int<lower=0> city_n_test[N_test];
  int<lower=0> D;
  vector[D] X_train[N_train];
  vector[D] X_test[N_test];
  int<lower=0> y_train[N_train];
} transformed data {
  real delta = 1e-9;
  int<lower=0> N = N_train + N_test;
  vector[D] X[N];
  for (i in 1:N_train) X[i, ] = X_train[i, ];
  for (i in 1:N_test) X[N_train + i, ] = X_test[i, ];
} parameters {
  real a;
  real<lower=0> alpha;
  real<lower=0> rho;
  vector[N] eta;
} transformed parameters {
  vector[N] f;
  {
    matrix[N, N] L_K;
    matrix[N, N] Ker = cov_exp_quad(X, alpha, rho);
    
    for (n in 1:N) {
      Ker[n, n] = Ker[n, n] + delta;
    }
    
    L_K = cholesky_decompose(Ker);
    f = L_K * eta;
  }
} model { 
  a ~ std_normal();
  alpha ~ std_normal();
  rho ~ inv_gamma(7, 7);
  eta ~ std_normal();
  y_train ~ binomial_logit(city_n_train, a + f[1:N_train]);
} generated quantities {
  int<lower=0> y_rep_train[N_train];
  int<lower=0> y_rep_test[N_test];
  for (i in 1:N_train) {
    y_rep_train[i] = binomial_rng(city_n_train[i], 
    inv_logit(a + f[i]));
    }
  for (i in 1:N_test) {
    y_rep_test[i] = binomial_rng(city_n_test[i], 
    inv_logit(a + f[N_train + i]));
  }
}
