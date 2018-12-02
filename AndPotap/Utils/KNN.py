# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Import packages
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
import numpy as np  # scientific computing
import time  # to report time
import multiprocessing  # map reduce
from functools import partial  # function compatibility for map reduce
# ================================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Construct KNN class
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


class KNN:

    def __init__(self, x, y, k_neighb=5, metric='l2', split=0.7, k=5, seed=2453):
        self.x = x
        self.y = y
        self.k_neigh = k_neighb
        self.metric = metric
        self.split = split
        self.k = k
        self.seed = seed
        self.x_train = x
        self.y_train = y
        self.x_test = x
        self.y_test = y
        self.y_hat = np.zeros(0)
        self.fold_accuracy = np.zeros(k)
        self.pool = multiprocessing.Pool()
        self.n = x.shape[0]
        self.d = x.shape[1]
        self.n_train = x.shape[0]
        self.n_test = x.shape[0]
        self.train_ind = [i for i in range(x.shape[0])]
        self.ind_iterable = [i for i in range(x.shape[0])]
        self.threshold = 0.5

    def sampling(self):
        """
        Divides the data into train and test sets at random.
        """
        int_list = [i for i in range(self.n)]
        self.n_train = int(np.floor(self.n * self.split))
        self.train_ind = np.random.choice(a=int_list,
                                          size=self.n_train,
                                          replace=False)

        # Fill in values for training and testing
        self.x_train = self.x[self.train_ind, :]
        self.y_train = self.y[self.train_ind]

        mask = np.ones(self.n, np.bool)
        mask[self.train_ind] = 0
        self.x_test = self.x[mask, :]
        self.y_test = self.y[mask]
        self.n_test = self.x_test.shape[0]

        self.y_hat = np.zeros((self.n_test, self.k))

        # Fill in the iterables
        self.ind_iterable = [i for i in range(self.n_test)]

    def introduce_test(self, x_test):
        """
        Allows the user to introduce a test set independently
        :param x_test: np.array | complete test set
        """
        self.x_test = x_test
        self.n_test = x_test.shape[0]
        self.ind_iterable = [i for i in range(self.n_test)]

        self.y_hat = np.zeros((self.n_test, self.k))

    @staticmethod
    def compute_l1_dist(j, x_train, x_test, y_train, k_neigh, threshold):
        """
        Computes the l1 distance between the train set and
        the new point. It is static for paralellization purposes
        :param j: int | current test observation being evaluated
        :param x_train: np.array | complete train set
        :param x_test: np.array | complete test set
        :param y_train: np.array | complete train labels
        :param k_neigh: int | number of neighbors to consider
        :param threshold: np.float | boundary threshold
        :return: int | classification for the given test point
        """
        dist = np.abs(x_test[j, :] - x_train)  # verify correct dimensions
        select = np.argsort(np.sum(dist, axis=1))[0:k_neigh]
        output = np.mean(y_train[select])
        return 1 if output >= threshold else 0

    def predict_test_fold_l1(self, k):
        """
        Makes predictions for the entire test set on fold number k
        :param k: int | current fold
        """
        f = partial(self.compute_l1_dist,
                    x_train=self.x_train,
                    x_test=self.x_test,
                    y_train=self.y_train,
                    k_neigh=self.k_neigh,
                    threshold=self.threshold)
        zz = self.pool.map(func=f, iterable=self.ind_iterable)
        for j in range(self.n_test):
            self.y_hat[j, k] = zz[j]

    def calculate_accuracy_l1(self):
        """
        Calculates the accuracy for each fold
        """
        for k in range(self.k):
            t0 = time.time()
            np.random.seed(self.seed)
            self.sampling()
            self.predict_test_fold_l1(k)
            self.fold_accuracy[k] = np.mean(self.y_hat[:, k] == self.y_test)
            print('Fold {} took : {:6.1f} sec'.format(k, time.time() - t0))

    @staticmethod
    def compute_l2_dist(j, x_train, x_test, y_train, k_neigh, threshold):
        """
        Computes the l2 distance between the train set and
        the new point. It is static for paralellization purposes
        :param j: int | current test observation being evaluated
        :param x_train: np.array | complete train set
        :param x_test: np.array | complete test set
        :param y_train: np.array | complete train labels
        :param k_neigh: int | number of neighbors to consider
        :param threshold: np.float | boundary threshold
        :return: int | classification for the given test point
        """
        dist = (x_test[j, :] - x_train) ** 2  # verify correct dimensions
        select = np.argsort(np.sqrt(np.sum(dist, axis=1)))[0:k_neigh]
        output = np.mean(y_train[select])
        return 1 if output >= threshold else 0

    def predict_test_fold_l2(self, k):
        """
        Makes predictions for the entire test set on fold number k
        :param k: int | current fold
        """
        f = partial(self.compute_l2_dist,
                    x_train=self.x_train,
                    x_test=self.x_test,
                    y_train=self.y_train,
                    k_neigh=self.k_neigh,
                    threshold=self.threshold)
        zz = self.pool.map(func=f, iterable=self.ind_iterable)
        for j in range(self.n_test):
            self.y_hat[j, k] = zz[j]

    def calculate_accuracy_l2(self):
        """
        Calculates the accuracy for each fold
        """
        for k in range(self.k):
            t0 = time.time()
            np.random.seed(self.seed)
            self.sampling()
            self.predict_test_fold_l2(k)
            self.fold_accuracy[k] = np.mean(self.y_hat[:, k] == self.y_test)
            print('Fold {} took : {:6.1f} sec'.format(k, time.time() - t0))

    @staticmethod
    def compute_linf_dist(j, x_train, x_test, y_train, k_neigh, threshold):
        """
        Computes the linf distance between the train set and
        the new point. It is static for paralellization purposes
        :param j: int | current test observation being evaluated
        :param x_train: np.array | complete train set
        :param x_test: np.array | complete test set
        :param y_train: np.array | complete train labels
        :param k_neigh: int | number of neighbors to consider
        :param threshold: np.float | boundary threshold
        :return: int | classification for the given test point
        """
        dist = np.abs(x_test[j, :] - x_train)  # verify correct dimensions
        select = np.argsort(np.sqrt(np.max(dist, axis=1)))[0:k_neigh]
        output = np.mean(y_train[select])
        return 1 if output >= threshold else 0

    def predict_test_fold_linf(self, k):
        """
        Makes predictions for the entire test set on fold number k
        :param k: int | current fold
        """
        f = partial(self.compute_linf_dist,
                    x_train=self.x_train,
                    x_test=self.x_test,
                    y_train=self.y_train,
                    k_neigh=self.k_neigh,
                    threshold=self.threshold)
        zz = self.pool.map(func=f, iterable=self.ind_iterable)
        for j in range(self.n_test):
            self.y_hat[j, k] = zz[j]

    def calculate_accuracy_linf(self):
        """
        Calculates the accuracy for each fold
        """
        for k in range(self.k):
            t0 = time.time()
            np.random.seed(self.seed)
            self.sampling()
            self.predict_test_fold_linf(k)
            self.fold_accuracy[k] = np.mean(self.y_hat[:, k] == self.y_test)
            print('Fold {} took : {:6.1f} sec'.format(k, time.time() - t0))

    def calculate_accuracy(self):
        if self.metric == 'l2':
            self.calculate_accuracy_l2()
        elif self.metric == 'l1':
            self.calculate_accuracy_l1()
        elif self.metric == 'linf':
            self.calculate_accuracy_linf()
        else:
            print('Metric not found')

# ================================================================================
