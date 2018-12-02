# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Imports
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
import numpy as np
import multiprocessing
from functools import partial
# ================================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Notes
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
"""
(*)     Should I exclude one feature out of the complete list? The most
        recent one used?
"""
# ================================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Construct DecTree class
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


class DecTree:

    def __init__(self, x, y, max_depth, parallel=False,
                 min_obs=2, split=0.7, k=5, seed=42):
        self.x = x
        self.y = y
        self.max_depth = max_depth
        self.min_obs = min_obs
        self.parallel = parallel
        self.feature_list = [j for j in range(x.shape[1])]
        self.x_train = np.array(1)
        self.y_train = np.array(1)
        self.x_test = np.array(1)
        self.y_test = np.array(1)
        self.n = x.shape[0]
        self.d = x.shape[1]
        self.split = split
        self.k = k
        self.y_hat = np.array(1)
        self.train_ind = []
        self.n_train = x.shape[0]
        self.n_test = x.shape[0]
        self.seed = seed
        self.train_size = 0
        self.pool = multiprocessing.Pool()
        self.root = {}
        self.fold_accuracy = 0
        self.ind_iterable = [i for i in range(x.shape[0])]  # important for parallelization

    def non_random(self):
        """
        For debugging purposes, fill-in the train data as all the data
        """
        self.x_train = self.x
        self.y_train = self.y
        self.x_test = self.x
        self.y_test = self.y
        self.train_ind = [i for i in range(self.n)]

    def sampling(self):
        """
        Divides the data intro train and test sets at random.
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
        self.y_hat = np.zeros((self.n_test, self.k))
        self.train_ind = [i for i in range(self.n_train)]

        # Fill in the iterables and sets
        self.n_test = self.x_test.shape[0]
        self.ind_iterable = [i for i in range(self.n_test)]

    def deviance(self, obs):
        """
        Computes the 2 category deviance for a set of observations
        in the training set.
        :param obs: np.array | observations in the current cell in numpy index
        :return: np.float | deviance in that current cell
        """
        if len(obs) == 0:
            return 0
        prop = np.mean(self.y_train[obs])
        if np.isclose(prop, 0):
            return 0
        elif np.isclose(prop, 1):
            return 0
        else:
            return -prop * np.log(prop) - (1 - prop) * np.log(1 - prop)

    def best_split(self, feature, ind_list):
        """
        Finds the best midpoint split in the observations indicated by
        ind_list along column feature
        :param feature: int | feature (column) being analyzed
        :param ind_list: int list | list of indices in the cell
        :return: (np.float, np.float) | (threshold, deviance) pairs
        """
        # Compute the midpoints
        n_m = len(ind_list)
        points = self.x_train[ind_list, feature]
        points = np.sort(points)
        midpoint_splits = np.zeros(n_m - 1)  # midpoints are one less
        midpoint_avg = np.zeros(n_m - 1)
        for i in range(n_m - 1):
            midpoint_splits[i] = 0.5 * (points[i] + points[i+1])

        i = 0
        for midpoint in midpoint_splits:
            left = np.array(ind_list)
            right = np.array(ind_list)
            left_in = np.where(self.x_train[ind_list, feature] < midpoint)[0]
            right_in = np.where(self.x_train[ind_list, feature] >= midpoint)[0]
            left = left[left_in]
            right = right[right_in]

            left_n = len(left)
            left_impurity = self.deviance(obs=left)

            right_n = len(right)
            right_impurity = self.deviance(obs=right)

            midpoint_avg[i] = left_n * left_impurity + right_n * right_impurity
            i += 1

        minimizer = np.argmin(midpoint_avg)
        return midpoint_splits[minimizer], midpoint_avg[minimizer]

    def get_split(self, ind_list, feature, value):
        """
        Splits the list of indices given by the given value. It returns
        two lists for further splitting.
        :param ind_list: int list | current indices being examined
        :param feature: int | feature under examination
        :param value: np.float | threshold value
        :return: tuple int list | left and right subseting based on the value
        """
        left = np.array(ind_list)
        right = np.array(ind_list)
        left_in = np.where(self.x_train[ind_list, feature] < value)[0]
        right_in = np.where(self.x_train[ind_list, feature] >= value)[0]
        left = list(left[left_in])
        right = list(right[right_in])
        return left, right

    @staticmethod
    def best_split_pool(feature, ind_list, x_train, y_train):
        """
        Finds the best midpoint split in the observations indicated by
        ind_list along column feature. It is static since it is used
        in the paralellization procedure
        :param feature: int | feature (column) being analyzed
        :param ind_list: int list | list of indices in the cell
        :param x_train: np.array | training data x
        :param y_train: np.array | training labels y
        :return: (np.float, np.float) | (threshold, deviance) pairs
        """

        def deviance(obs, y_t):
            """
            Computes the 2 category deviance for a set of observations
            in the training set.
            :param y_t: np.array | training labels y
            :param obs: np.array | observations in the current cell in numpy index
            :return: np.float | deviance in that current cell
            """
            if len(obs) == 0:
                return 0
            prop = np.mean(y_t[obs])
            if np.isclose(prop, 0):
                return 0
            elif np.isclose(prop, 1):
                return 0
            else:
                return -prop * np.log(prop) - (1 - prop) * np.log(1 - prop)

        # Compute the midpoints
        n_m = len(ind_list)
        points = x_train[ind_list, feature]
        points = np.sort(points)
        midpoint_splits = np.zeros(n_m - 1)  # midpoints are one less
        midpoint_avg = np.zeros(n_m - 1)
        for i in range(n_m - 1):
            midpoint_splits[i] = 0.5 * (points[i] + points[i+1])

        i = 0
        for midpoint in midpoint_splits:
            left = np.array(ind_list)
            right = np.array(ind_list)
            left_in = np.where(x_train[ind_list, feature] < midpoint)[0]
            right_in = np.where(x_train[ind_list, feature] >= midpoint)[0]
            left = left[left_in]
            right = right[right_in]

            left_n = len(left)
            left_impurity = deviance(obs=left, y_t=y_train)

            right_n = len(right)
            right_impurity = deviance(obs=right, y_t=y_train)

            midpoint_avg[i] = left_n * left_impurity + right_n * right_impurity
            i += 1

        minimizer = np.argmin(midpoint_avg)
        return midpoint_splits[minimizer], midpoint_avg[minimizer]

    def select_best_split_parallel(self, ind_list):
        """
        Runs a parallelized routine in order to find the best splitting feature
        for the given list of observations
        :param ind_list: int list | list of observations being analyzed
        :return: dict | keys and values for the splitting node
        """
        f = partial(self.best_split_pool,
                    x_train=self.x_train,
                    y_train=self.y_train,
                    ind_list=ind_list)
        zz = self.pool.map(func=f, iterable=self.feature_list)

        z = np.zeros(self.d)
        for j in range(self.d):
            z[j] = zz[j][1]

        best_feature = np.argmin(z)
        split = self.get_split(ind_list=ind_list,
                               feature=best_feature,
                               value=zz[best_feature][0])
        return {"f": best_feature,
                "v": zz[best_feature][0],
                "split": split}

    def select_best_split(self, ind_list):
        """
        Iterates through all the features to find the best splitting one
        :param ind_list: int list | list of observations being analyzed
        :return: dict | keys and values for the splitting node
        """
        z = np.zeros((self.d, 2))
        for j in range(self.d):
            tup = self.best_split(feature=j, ind_list=ind_list)
            z[j, 0] = tup[0]
            z[j, 1] = tup[1]

        best_feature = np.argmin(z[:, 1])
        split = self.get_split(ind_list=ind_list,
                               feature=best_feature,
                               value=z[best_feature, 0])
        return {"f": best_feature,
                "v": z[best_feature, 0],
                "split": split}

    def get_best_split(self, ind_list):
        """
        Select paralellization procedure if required
        """
        if self.parallel:
            output = self.select_best_split_parallel(ind_list=ind_list)
            return output
        else:
            output = self.select_best_split(ind_list=ind_list)
            return output

    def create_nodes(self, node, depth):
        """
        Analyzes the current split given by the node and determines
        whether to follow creating children nodes or to take a majority
        vote
        :param node: dict | current branch being analyzed
        :param depth: int | depth of the current node
        :return: dict | decision
        """
        left, right = node["split"]
        del node['split']
        if not left or not right:
            node['r'] = self.to_terminal(left + right)
            node['l'] = self.to_terminal(left + right)
            return

        # Check max depth
        if depth >= self.max_depth:
            node['l'] = self.to_terminal(left)
            node['r'] = self.to_terminal(right)
            return

        # Add left child node
        if len(left) <= self.min_obs:
            node['l'] = self.to_terminal(left)
        else:
            node['l'] = self.get_best_split(left)
            self.create_nodes(node=node['l'], depth=depth + 1)

        # Add right child node
        if len(right) <= self.min_obs:
            node['r'] = self.to_terminal(left)
        else:
            node['r'] = self.get_best_split(right)
            self.create_nodes(node=node['r'], depth=depth + 1)

    def build_tree(self):
        """
        Builds the dictionary tree by recursively calling the two
        most relevant functions. The split identifier and
        the dictionary augmenting.
        """
        root = self.get_best_split(self.train_ind)
        self.create_nodes(node=root, depth=1)
        self.root = root

    def to_terminal(self, ind_list):
        """
        Computes the majority vote in a group of observations
        :param ind_list: int list | list of indices in the current cell
        :return: int | majority vote
        """
        votes = np.mean(self.y_train[ind_list])
        return 1 if votes >= 0.5 else 0

    @staticmethod
    def predict(x_new, node):
        """
        Generate a prediction for a given x_new. Note that the function
        is static in order to multiprocess the procedure.
        Below is the same function but added to include a single
        query for the map reduce algorithm
        :param node: dict | the dictionary created with the data set
        :param x_new: np.array | a given new observation
        :return: int | classification value
        """
        def sub_predict(sub_node, sub_x_new):
            """
            Generate a prediction for a given x_new. Note that the function
            is static in order to multiprocess the procedure
            :param sub_node: dict | the dictionary created with the data set
            :param sub_x_new: np.array | a given new observation
            :return: int | classification value
            """
            # Go to the left of the tree
            if sub_x_new[sub_node['f']] < sub_node['v']:
                if isinstance(sub_node['l'], dict):
                    return sub_predict(sub_node['l'], sub_x_new)
                else:
                    return sub_node['l']
            # Go to the right of the three
            else:
                if isinstance(sub_node['r'], dict):
                    return sub_predict(sub_node['r'], sub_x_new)
                else:
                    return sub_node['r']

        # Go to the left of the tree
        if x_new[node['f']] < node['v']:
            if isinstance(node['l'], dict):
                return sub_predict(node['l'], x_new)
            else:
                return node['l']
        # Go to the right of the three
        else:
            if isinstance(node['r'], dict):
                return sub_predict(node['r'], x_new)
            else:
                return node['r']

    def predict_test(self, x_test):
        """
        Computes the labels of the test set given based on the
        tree computed with the train data
        :param x_test: np.array |
        :return: np.array | test set predicted labels
        """
        f = partial(self.predict,
                    node=self.root)
        zz = self.pool.map(func=f, iterable=x_test)
        return np.array(zz)

    def obtain_predictions(self):
        """
        Fills-in the predictions
        """
        self.y_hat = self.predict_test(x_test=self.x_test)

    def calculate_accuracy(self):
        """
        Calculate the accuracy of the algorithm
        """
        np.random.seed(self.seed)
        self.sampling()
        # self.non_random()
        self.build_tree()
        self.obtain_predictions()
        output = np.sum(self.y_test == self.y_hat) / self.n_test
        self.fold_accuracy = output

    # def __getstate__(self):
    #     self_dict = self.__dict__.copy()
    #     del self_dict['pool']
    #     return self_dict
    #
    # def __setstate__(self, state):
    #     self.__dict__.update(state)

# ================================================================================
