# ===========================================================================
# Notes
# ===========================================================================
"""
(*) This script explores the contents of the DBs given by the client
(*) Beware! This file writes an output
(*) Also make sure that your working directory is properly set
"""
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Imports
# ===========================================================================
import os
import numpy as np
import pandas as pd
import time
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Files
# ===========================================================================
os.chdir('/Users/andpotap/Documents/Columbia/BS/BDA_project')
file_input = './AndPotap/DBs/core.txt'
file_output = './AndPotap/DBs/city.txt'
file_output_st = './AndPotap/DBs/city_st.txt'
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Open DBs
# ===========================================================================
t0 = time.time()
data_all = pd.read_csv(file_input, sep='|')
print('It takes: {:6.1f} sec to load the data'.format(time.time() - t0))
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Select only relevant columns for the analysis
# ===========================================================================
selected_columns = ['mortgage_id',
                    'state',
                    'county',
                    'city',
                    'zip',
                    'age',
                    'asset_market_value',
                    'mar_2_app',
                    'appraisal_value',
                    'app_2_inc',
                    'client_income',
                    'mar_2_inc',
                    'sex_F',
                    'condition_U',
                    'risk_index',
                    'effective_pay',
                    'factor_employed',
                    'bank_2_home',
                    'ratio',
                    'vendor_Y',
                    'employed_30',
                    'antiquity_20',
                    'credit_score',
                    'lender_score',
                    'y',
                    'months_wo_pay']
data = data_all[selected_columns]
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Aggregate the data
# ===========================================================================


def log_mean(x):
    # return np.mean(np.log(x))
    return np.log(np.mean(x))


agg_dict = {
    'client_income': log_mean,
    'asset_market_value': log_mean,
    'appraisal_value': log_mean,
    'age': np.mean,
    'mar_2_app': np.mean,
    'app_2_inc': np.mean,
    'mar_2_inc': np.mean,
    'sex_F': np.mean,
    'condition_U': np.mean,
    'risk_index': np.mean,
    'effective_pay': np.mean,
    'factor_employed': np.mean,
    'bank_2_home': np.mean,
    'ratio': np.mean,
    'vendor_Y': np.mean,
    'employed_30': np.mean,
    'antiquity_20': np.mean,
    'credit_score': np.mean,
    'lender_score': np.mean,
    'months_wo_pay': np.sum,
    'y': np.sum
}
df = data.groupby(by=['city', 'state']).agg(agg_dict)
df = df.reset_index()

city_df = data.groupby(by=['city', 'state']).agg({'y': np.ma.count})
city_df = city_df.reset_index()
city_df = city_df.rename(columns={'y': 'city_n'})

agg_dict_state = {
    'client_income': log_mean,
    'asset_market_value': log_mean,
    'appraisal_value': log_mean,
    'age': np.mean,
    'sex_F': np.mean,
    'condition_U': np.mean,
    'risk_index': np.mean,
    'ratio': np.mean,
    'vendor_Y': np.mean,
    'employed_30': np.mean,
    'lender_score': np.mean,
    'y': np.ma.count
}

rename_dict_state = {
    'client_income': 'income_state',
    'asset_market_value': 'market_state',
    'appraisal_value': 'appraisal_state',
    'age': 'age_state',
    'sex_F': 'sex_state',
    'condition_U': 'new_state',
    'risk_index': 'risk_state',
    'ratio': 'ratio_state',
    'vendor_Y': 'vendor_state',
    'employed_30': 'employed_state',
    'lender_score': 'lender_state',
    'y': 'state_n',
    'index': 'ID_state'
}

state_df = data.groupby(by=['state']).agg(agg_dict_state)
state_df = state_df.reset_index()
state_df = state_df.reset_index()
state_df = state_df.rename(columns=rename_dict_state)

city_df = pd.merge(left=city_df,
                   right=state_df,
                   how='inner',
                   on='state')

df = pd.merge(left=df,
              right=city_df,
              how='inner',
              on=['city', 'state'])
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Compute new columns
# ===========================================================================
df.loc[:, 'theta_emp'] = df['y'] / df['city_n']
df.loc[:, 'ID_state'] = df.loc[:, 'ID_state'] + 1
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Standardize the inputs
# ===========================================================================
st_columns = [
    'age',
    'client_income',
    'appraisal_value',
    'asset_market_value',
    'mar_2_app',
    'app_2_inc',
    'mar_2_inc',
    'sex_F',
    'condition_U',
    'risk_index',
    'effective_pay',
    'factor_employed',
    'bank_2_home',
    'ratio',
    'vendor_Y',
    'employed_30',
    'antiquity_20',
    'credit_score',
    'lender_score',
]
df_st = df.copy()
df_st[st_columns] = df_st[st_columns].transform(lambda x:
                                                (x - x.mean()) / x.std())
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Order the columns
# ===========================================================================
ordered_columns = [
    'ID_state',
    'state',
    'state_n',
    'city',
    'city_n',
    'age',
    'client_income',
    'appraisal_value',
    'asset_market_value',
    'mar_2_app',
    'app_2_inc',
    'mar_2_inc',
    'sex_F',
    'condition_U',
    'risk_index',
    'effective_pay',
    'factor_employed',
    'bank_2_home',
    'ratio',
    'vendor_Y',
    'employed_30',
    'antiquity_20',
    'credit_score',
    'lender_score',
    'theta_emp',
    'months_wo_pay',
    'y'
]
df = df[ordered_columns]
df_st = df_st[ordered_columns]
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Output the file
# ===========================================================================
df.to_csv(file_output, sep='|', index=False)
df_st.to_csv(file_output_st, sep='|', index=False)
# ===========================================================================
