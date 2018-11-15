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
# Files
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
os.chdir('/Users/andpotap/Documents/Columbia/BS/BDA_project')
file_it = './AndPotap/DBs/' \
          'BASE DE SALDOS FHIPO IT PESOS AGOSTO-18.xlsx.txt'
file_s = './AndPotap/DBs/' \
         'BASE DE SALDOS FHIPO SOCIAL PESOS_AGOSTO-18.xlsx.txt'
file_path = './AndPotap/DBS/core_y.txt'
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Open DBs
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
data_it = pd.read_table(file_it)
data_s = pd.read_table(file_s)
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Total number of mortgages per data base
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
count_it = np.count_nonzero(data_it['numcred'].unique())
print('\nIn Saldos IT we have: {} mortgages'.format(count_it))

count_s = np.count_nonzero(data_s['numcred'].unique())
print('\nIn Saldos Social we have: {} mortgages'.format(count_s))
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Compute the percentage of moratory
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# column = 'empresa'  # only displays a one
# column = 'fec_ori'  # include to validate
# column = 'vecimto'  # inclue to compute terms
# column = 'tasa_int'  # all are 12
# column = 'f_ult_pago'
# column = 'omisos'
# column = 'estatus'  # displays only one value
# df_view = one_col_summary(data=data_s, column=column, col='moneda')
# print(df_view)
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Subset the data into the columns that we care
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
selected_columns = ['numcred',
                    'omisos',
                    'dias_mora',
                    'num_pag_ef',
                    'fec_ori',
                    'vecimto',
                    'f_ult_pago']
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
print('\nHEAD summary that displays the percentage of delayed mort')
print(df_omisos.head())
# See that I actually got this line
# 157      20180801      20

# There are some errors
#           numcred  omisos  dias_mora   ...     vecimto  f_ult_pago  origin
# 3264    615051202       5        150   ...    20451130           0  SOCIAL
# 7007   1116158954       2         60   ...    20370930           0  SOCIAL
# 25379  3116091906       8        240   ...    20411130           0  SOCIAL
# 26969   916161743       0          0   ...    20480930           0      IT
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Rename the columns
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
renaming_dict = {'numcred': 'mortgage_id',
                 'omisos': 'months_wo_pay',
                 'dias_mora': 'days_wo_pay',
                 'num_pag_ef': 'effective_pay',
                 'fec_ori': 'date_start',
                 'vecimto': 'data_finish',
                 'f_ult_pago': 'last_date_pay'}
data = data.rename(columns=renaming_dict)
data['y'] = 0
data.loc[data['months_wo_pay'] >= 1, 'y'] = 1
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Output the file
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
data.to_csv(file_path, sep='|', index=False)
# ===========================================================================
