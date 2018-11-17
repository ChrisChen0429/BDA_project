data {
  int<lower=1> Z;
  int<lower=1> C;
  int<lower=1, upper=C> cc[Z];
  int<lower=0> N_z[Z];
  int<lower=0> y[Z];
} parameters {
  vector<lower=0>[C] alpha;
  vector<lower=0>[C] beta;
  vector<lower=0, upper=1>[Z] theta;
} model {
  alpha ~ gamma(2, 100);
  beta ~ gamma(25, 100);
  theta ~ beta(alpha[cc], beta[cc]);
  y ~ binomial(N_z, theta);
} generated quantities {
  int y_rep[Z];
  for (j in 1:Z){
    y_rep[j] = binomial_rng(N_z[j], theta[j]);
  }
}
