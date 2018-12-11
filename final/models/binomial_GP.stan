data {
  int<lower=0> N;
  int<lower=0> city_n[N];
  int<lower=0> D;
  vector[D] X[N];
  int<lower=0> y[N];
} transformed data {
real delta = 1e-9;  
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
  y ~ binomial_logit(city_n, a + f[1:N]);
} generated quantities {
  int<lower=0> y_rep[N];
  for (i in 1:N) {
    yrep[i] = binomial_rng(city_n[i], inv_logit(a + f[i]));
    }
}
