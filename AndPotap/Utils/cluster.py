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
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Construct the functions
# ===========================================================================


def k_means_addition(k, df, selected_columns, seed):
    x = df[selected_columns].values
    x = (x - np.mean(x, axis=0)) / np.std(x, axis=0)
    df_out = df['mortgage_id'].copy()
    df_out = pd.DataFrame(df_out)

    # Peform k means
    kmeans = KMeans(n_clusters=k,
                    random_state=seed).fit(x)

    # Add the clusters
    name = 'cluster_' + str(k)
    df_out[name] = kmeans.labels_

    return df_out, kmeans.cluster_centers_

# ===========================================================================
