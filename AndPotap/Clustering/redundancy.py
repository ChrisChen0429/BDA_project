# ===========================================================================
# Notes
# ===========================================================================
"""
(*) This script finds a lower dimensional embedding of the data set
    to understand the redundancy found in the data
(*) Should date time variables be encoded as integers and then measure the
    distance
"""
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Import packages
# ===========================================================================
import numpy as np
import pandas as pd
from sklearn.decomposition import KernelPCA
from sklearn.decomposition import PCA
import time
import matplotlib.pyplot as plt
# import joblib as jb
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Determine files
# ===========================================================================
# file_input = './AndPotap/DBs/core_sample.txt'
file_input = './AndPotap/DBs/core.txt'
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Load files
# ===========================================================================
df = pd.read_csv(filepath_or_buffer=file_input, sep='|')
# jb.parallel_backend(n_jobs=-1)
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Select relevant columns
# ===========================================================================
selected_columns = [
    'age',
    'appraisal_value',
    'client_income',
    'risk_index',
    'ratio',
    'lender_score',
    'asset_market_value',
    'credit_score',
    'effective_pay',
    'factor_employed'
]

# Subset
df_selected = df[selected_columns]

# Generate data matrix
x = df_selected.values

# Normalize the data
x = (x - np.mean(x, axis=0)) / np.std(x, axis=0)
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Extract information with PCA
# ===========================================================================
t0 = time.time()
pca = PCA(n_components=10).fit(x)
# pca = PCA(n_components=9).fit(x)

# noinspection PyUnresolvedReferences
s_pca = pca.singular_values_
print('\nKernel PCA took: {:6.1f} sec'.format(time.time() - t0))

total_pca = np.sum(s_pca)
ss_pca = np.cumsum(s_pca) / total_pca
dim_80_pca = len(ss_pca[ss_pca < 0.8])
print('A total of {} dimensions represent 80% of '
      'the data'.format(dim_80_pca))
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Extract the information from Kernel PCA
# ===========================================================================
# t0 = time.time()
# kpca = KernelPCA(n_components=10,
#                  kernel='rbf',
#                  n_jobs=-1).fit(x)
#
# # noinspection PyUnresolvedReferences
# s_kpca = kpca.lambdas_
# print('\nKernel PCA took: {:6.1f} sec'.format(time.time() - t0))
#
# total_kpca = np.sum(s_kpca)
# ss_kpca = np.cumsum(s_kpca) / total_kpca
# dim_80_kpca = len(ss_kpca[ss_kpca < 0.8])
# print('A total of {} dimensions represent 80% of '
#       'the data'.format(dim_80_kpca))
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Plot components
# ===========================================================================
plt.figure()
plt.title('PCA eigenvalues')
plt.plot(s_pca, color='blue', label='PCA')
plt.legend()
plt.show()
#
# plt.figure()
# plt.title('KPCA eigenvalues')
# plt.plot(s_kpca, color='red', label='KPCA')
# plt.legend()
# plt.show()
# ===========================================================================
