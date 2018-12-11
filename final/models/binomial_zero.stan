data {
  int<lower=1> N;
  int<lower=1> D;
  int<lower=0> city_n[N];
  matrix[N, D] X;
  int<lower=0> y[N];
} parameters {
  real alpha;
  vector[D] beta;
  real<lower=0, upper=1> theta;
} model {
  alpha ~ normal(0, 5);
  beta ~ normal(0, 5);
  theta ~ beta(150, 1000);
  for (n in 1:N) {
    if (y[n] == 0) {
      target += log_sum_exp(bernoulli_lpmf(1 | theta),
                bernoulli_lpmf(0 | theta)
              + binomial_logit_lpmf(y[n] | city_n[n], alpha + X[n, ] * beta));
    }
    else{
      target += bernoulli_lpmf(0 | theta)
              + binomial_logit_lpmf(y[n] | city_n[n], alpha + X[n, ] * beta);
    }
  }
} generated quantities{
  int<lower=0> y_rep[N];
  real<lower =0,upper=1> zero[N];
  for (i in 1:N){
    zero[i] = uniform_rng(0,1);
    if (zero[i] < theta){
      y_rep[i] = 0;
      }
    else{
      y_rep[i] = binomial_rng(city_n[i], inv_logit(alpha + X[i,] * beta));
      }
  }
}
