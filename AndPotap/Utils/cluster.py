# ===========================================================================
# Notes
# ===========================================================================
"""
(*) The current file contains a bunch of functions to perform clustering
"""
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Import packages
# ===========================================================================
import numpy as np
import pandas as pd
from sklearn.cluster import KMeans
np.set_printoptions(precision=2,
                    formatter={'all': lambda x: '%4.2f' % x})
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Construct the functions
# ===========================================================================


def k_means_addition(k, df, selected_columns, seed):
    # Create data matrix
    x = df[selected_columns].values
    mu = np.mean(x, axis=0)
    sigma = np.std(x, axis=0)
    x = (x - mu) / sigma
    df_out = df['mortgage_id'].copy()
    df_out = pd.DataFrame(df_out)

    # Perform k means
    kmeans = KMeans(n_clusters=k,
                    random_state=seed).fit(x)

    # Add the clusters
    name = 'cluster_' + str(k)
    df_out[name] = kmeans.labels_

    # De-normalize the clusters
    clusters = (kmeans.cluster_centers_ * sigma) + mu

    return df_out, clusters

# ===========================================================================
