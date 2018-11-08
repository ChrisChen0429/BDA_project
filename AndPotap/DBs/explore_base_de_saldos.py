# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Notes
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
"""
(*) This script outputs the y-labels needed for the analysis.
    It:
        * reads the data bases
        * subsets for the relevant columns only (the ones that contain
            the number of delayed days and months
        * merges the two data bases into one
        * displays a summary table with the % of delayed contracts
        * renames the columns
        * outputs into a txt file
"""
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Imports
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
import os
import numpy as np
import pandas as pd
from AndPotap.Utils.eda import one_col_summary
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Open DBs
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
path = '/Users/andpotap/Documents/Columbia/BS/Risk-Managment'
os.chdir(path)
file_it = './DBs/BASE DE SALDOS FHIPO IT PESOS AGOSTO-18.xlsx.txt'
file_s = './DBs/BASE DE SALDOS FHIPO SOCIAL PESOS_AGOSTO-18.xlsx.txt'

data_it = pd.read_table(file_it)
data_s = pd.read_table(file_s)
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Total number of mortages per data base
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
count_it = np.count_nonzero(data_it['numcred'].unique())
print('\nIn Saldos IT we have: {} mortgages'.format(count_it))

count_s = np.count_nonzero(data_s['numcred'].unique())
print('\nIn Saldos Social we have: {} mortgages'.format(count_s))
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Subset the data into the columns that we care
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
selected_columns = ['numcred', 'omisos', 'dias_mora', 'num_pag_ef']
data_it = data_it[selected_columns]
data_it['origin'] = 'IT'
data_s = data_s[selected_columns]
data_s['origin'] = 'SOCIAL'
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Merge the data base into a single one
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
data = pd.concat([data_s, data_it], ignore_index=True)

count_all = np.count_nonzero(data['numcred'].unique())
print('\nIn total we have: {} UNIQUE mortgages'.format(count_all))
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Compute the percentage of moratory
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
df_omisos = one_col_summary(data=data, column='omisos', col='origin')
print('\nBelow is a summary that displays the percentage of delayed mort')
print(df_omisos.head())
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Rename the columns
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
renaming_dict = {'numcred': 'mortgage_id',
                 'omisos': 'months_wo',
                 'dias_mora': 'days_wo',
                 'num_pag_ef': 'total_w'}
data = data.rename(columns=renaming_dict)
data['y'] = 0
data.loc[data['months_wo'] >= 1, 'y'] = 1
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Output the file
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
file_path = './DBs/core_y.txt'
data.to_csv(file_path, sep='|', index=False)
# ===========================================================================
