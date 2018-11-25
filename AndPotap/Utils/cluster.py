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


def rank_in_cluster(df, name, ranks_name, x, centers, label):
    mask_np = np.where(df[name] == label)[0]
    mask_pd = df[name] == label
    center = centers[label]

    y = x[mask_np]

    diff = np.sum((y - center) ** 2, axis=1)
    tmp = diff.argsort()
    ranks = np.empty_like(tmp)
    ranks[tmp] = np.arange(len(diff))
    ranks = ranks + 1

    df.loc[mask_pd, ranks_name] = ranks

    return df


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

    # Add ranks
    ranks_name = 'ranks_' + str(k)
    df_out.loc[:, ranks_name] = 0

    for label in range(k):
        df_out = rank_in_cluster(df=df_out,
                                 name=name,
                                 ranks_name=ranks_name,
                                 x=x,
                                 centers=kmeans.cluster_centers_,
                                 label=label)

    # De-normalize the clusters
    clusters = (kmeans.cluster_centers_ * sigma) + mu

    return df_out, clusters

# ===========================================================================
