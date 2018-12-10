data {
  int<lower=1> N_train;
  int<lower=1> N_test;
  int<lower=1> D;
  int<lower=0> city_n_train[N_train];
  int<lower=0> city_n_test[N_test];
  matrix[N_train, D] X_train;
  matrix[N_test, D] X_test;
  int<lower=0> y_train[N_train];
} parameters {
  real alpha;
  vector[D] beta;
  real<lower=0, upper=1> theta;
} model {
  alpha ~ normal(0, 5);
  beta ~ normal(0, 5);
  theta ~ beta(1, 9);
  for (n in 1:N_train) {
    if (y_train[n] == 0) {
      target += log_sum_exp(bernoulli_lpmf(1 | theta),
                bernoulli_lpmf(0 | theta)
              + binomial_logit_lpmf(y_train[n] | city_n_train[n], 
                                    alpha + X_train[n, ] * beta));
    }
    else{
      target += bernoulli_lpmf(0 | theta)
              + binomial_logit_lpmf(y_train[n] | city_n_train[n], 
                                   alpha + X_train[n, ] * beta);
    }
  }
} generated quantities{
  int<lower=0> y_rep_train[N_train];
  int<lower=0> y_rep_test[N_test];
  real<lower =0,upper=1> zero_train[N_train];
  real<lower =0,upper=1> zero_test[N_test];
  for (i in 1:N_train){
    zero_train[i] = uniform_rng(0,1);
    if (zero_train[i] < theta){
      y_rep_train[i] = 0;
      }
    else{
      y_rep_train[i] = binomial_rng(city_n_train[i], 
                       inv_logit(alpha + X_train[i,] * beta));
      }
  }
  for (i in 1:N_test){
    zero_test[i] = uniform_rng(0,1);
    if (zero_test[i] < theta){
      y_rep_test[i] = 0;
      }
    else{
      y_rep_test[i] = binomial_rng(city_n_test[i], 
                       inv_logit(alpha + X_test[i,] * beta));
      }
  }
}
