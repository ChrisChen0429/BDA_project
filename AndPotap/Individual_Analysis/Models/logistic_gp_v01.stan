data {
  int<lower=1> N;
  real X[N];
  int<lower=0, upper=1> y[N];
} transformed data {
  real delta = 1e-9;
} parameters {
  real<lower=0> rho;
  real<lower=0> alpha;
  real a;
  vector[N] eta;
} model {
  vector[N] f;
  {
    matrix[N, N] L_K;
    matrix[N, N] K = cov_exp_quad(X, alpha, rho);
    
    // diagonal elements
    for (n in 1:N)
      K[n, n] = K[n, n] + delta;
    
    L_K = cholesky_decompose(K);
    f = L_K * eta;
  }
  rho ~ inv_gamma(5, 5);
  alpha ~ std_normal();
  a ~ normal(0, 5);
  eta ~ std_normal();
  y ~ bernoulli_logit(a + f);
}
