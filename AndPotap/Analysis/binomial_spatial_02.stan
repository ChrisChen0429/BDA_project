data {
  int<lower=0> N;
  int<lower=0> Ns[N];
  int<lower=0> y[N];
} parameters {
  vector<lower=0, upper=1>[N] theta;
} model {
  theta ~ beta(1, 1);
  y ~ binomial(Ns, theta);
} generated quantities {
  int<lower=0> y_rep[N];
  for (i in 1:N){
    y_rep[i] = binomial_rng(Ns[i], theta[i]);
  }
}
