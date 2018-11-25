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
import numpy as np
import pandas as pd
import time
from AndPotap.Utils.eda import one_col_summary
from AndPotap.Utils.regular import clean_vendor
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Files
# ===========================================================================
file_input = './AndPotap/DBs/core_raw.txt'
file_y = './AndPotap/DBs/core_y.txt'
file_path = './AndPotap/DBs/core.txt'
file_path_sample = './AndPotap/DBs/core_sample.txt'
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Open DBs
# ===========================================================================
t0 = time.time()
data = pd.read_csv(file_input, sep='|')
print('It takes: {:6.1f} sec to load the data'.format(time.time() - t0))
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Output list of columns to excel
# ===========================================================================
# pd.DataFrame(data.columns).to_excel('./DBs/column_list.xlsx',
#                                     header=False,
#                                     index=False)
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Explore columns contents
# ===========================================================================
# col = 'Nombre'
# column = 'idpoliticasValidacion'

# df = one_col_summary(data=data, column=column, col=col)

# for colu in list(data.columns):
#     df = one_col_summary(data=data, column=colu, col=col)
#     print(df)
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Select columns to include and rename them
# ===========================================================================
selected_columns = ['Nombre',
                    'fecha_firma_credito',
                    'colonia_domicilio',
                    'ciudad_domicilio',
                    'entidad_federativa',
                    'codigo_postal',
                    'Genero',
                    'numero_credito',
                    'factor_pago_roa',
                    'importe_original_credito_porcion_banco_pesos',
                    'importe_original_credito_porcion_infonavit_pesos',
                    'importe_original_porcion_banco_vsm',
                    'importe_original_porcion_infonavit_vsm',
                    'tasa_interes',
                    'antiguedad_empleo_titular',
                    'ingresos_cliente_registrado_infonavit',
                    'relacion_pago',
                    'calificacion_infonavit',
                    'nombre_vendedor',
                    'valor_compra_venta',
                    'colonia_compra',
                    'ciudad_compra',
                    'codigo_postal_compra',
                    'entidad_federativa_compra',
                    'valor_avaluo',
                    'nueva_usada',
                    'indice_riesgo',
                    'tipo_credito',
                    'antiguedad_laboral',
                    'nombre_empresa',
                    'edad',
                    'calificacion_buro',
                    'Monto_credito_original_total_pesos']
data_sub = data[selected_columns]
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Rename the columns
# ===========================================================================
renaming_dict = {'Nombre': 'mortgage_product',
                 'colonia_domicilio': 'county',
                 'ciudad_domicilio': 'city',
                 'entidad_federativa': 'state',
                 'codigo_postal': 'zip',
                 'Genero': 'sex',
                 'numero_credito': 'mortgage_id',
                 'fecha_firma_credito': 'date_signed',
                 'factor_pago_roa': 'factor_employed',
                 'importe_original_credito_porcion_banco_pesos': 'bank_total',
                 'importe_original_credito_porcion_infonavit_pesos': 'home_total',
                 'importe_original_porcion_banco_vsm': 'bank_monthly',
                 'importe_original_porcion_infonavit_vsm': 'home_monthly',
                 'tasa_interes': 'interest_rate',
                 'antiguedad_empleo_titular': 'months_employed',
                 'ingresos_cliente_registrado_infonavit': 'client_income',
                 'relacion_pago': 'ratio',
                 'calificacion_infonavit': 'lender_score',
                 'nombre_vendedor': 'vendor_name',
                 'valor_compra_venta': 'asset_market_value',
                 'colonia_compra': 'county_asset',
                 'ciudad_compra': 'city_asset',
                 'codigo_postal_compra': 'zip_asset',
                 'entidad_federativa_compra': 'state_asset',
                 'valor_avaluo': 'asset_value',
                 'nueva_usada': 'new_used',
                 'indice_riesgo': 'risk_index',
                 'tipo_credito': 'credit_type',
                 'antiguedad_laboral': 'labor_antiquity',
                 'nombre_empresa': 'employer_name',
                 'edad': 'age',
                 'calificacion_buro': 'credit_score',
                 'Monto_credito_original_total_pesos': 'appraisal_value'}
# Rename the data set
data_sub = data_sub.rename(columns=renaming_dict)

# Verify that all columns that are selected are renamed
c = set(selected_columns).difference(set(renaming_dict))
print('\nThe number of missing columns to rename is {}'.format(len(c)))
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Explore certain columns
# ===========================================================================
# column = 'sex'
# column = 'asset_age'
column = 'new_used'
col = 'mortgage_id'

df = one_col_summary(data=data_sub, column=column, col=col)
print(df)
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Incorporate dummy columns
# ===========================================================================
data_sub['sex'] = data_sub['sex'].astype('category')
sex_encoding = {1.0: 'M', 2.0: 'F'}
data_sub['sex'] = data_sub['sex'].replace(sex_encoding)
aux = pd.get_dummies(data=data_sub[['sex', 'new_used']],
                     prefix=['sex', 'condition'],
                     columns=['sex', 'new_used'])
aux = aux.drop('sex_M', axis=1)
aux = aux.drop('condition_N', axis=1)
data_sub = pd.merge(left=data_sub,
                    right=aux,
                    how='inner',
                    left_index=True,
                    right_index=True)
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Load the y label data
# ===========================================================================
data_y = pd.read_csv(file_y, sep='|')
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Combine the data sets
# ===========================================================================
data_sub = pd.merge(left=data_sub, right=data_y, how='inner',
                    on='mortgage_id')
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Convert to proper data types
# ===========================================================================
cols_2_int = {'mortgage_id': 'int64',
              'age': 'int64',
              'zip': 'int64',
              'zip_asset': 'int64',
              'credit_score': 'int64'}
data_sub = data_sub.astype(cols_2_int)
data_sub['date_signed'] = pd.to_datetime(data_sub['date_signed'],
                                         format='%Y%m%d')
data_sub['date_start'] = pd.to_datetime(data_sub['date_start'])
data_sub['last_date_pay'] = pd.to_datetime(data_sub['last_date_pay'])
data_sub['days_pay'] = data_sub['last_date_pay'] - data_sub['date_start']
data_sub['days_pay'] = data_sub['days_pay'].dt.days
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Provisional dummy variable for Investors
# ===========================================================================
# data_sub.loc[:, 'inv_city'] = 0
# mask = data_sub['city'] != data_sub['city_asset']
# data_sub.loc[mask, 'inv_city'] = 1
#
# data_sub.loc[:, 'inv_state'] = 0
# mask = data_sub['state'] != data_sub['state_asset']
# data_sub.loc[mask, 'inv_state'] = 1
#
# data_sub.loc[:, 'inv_county'] = 0
# mask = data_sub['county'] != data_sub['county_asset']
# data_sub.loc[mask, 'inv_county'] = 1
#
# data_sub.loc[:, 'inv_zip'] = 0
# mask = data_sub['zip'] != data_sub['zip_asset']
# data_sub.loc[mask, 'inv_zip'] = 1
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Add threshold dummies
# ===========================================================================
data_sub.loc[:, 'employed_30'] = 0
mask = data_sub['months_employed'] < 30
data_sub.loc[mask, 'employed_30'] = 1

data_sub.loc[:, 'antiquity_20'] = 0
mask = data_sub['labor_antiquity'] < 20
data_sub.loc[mask, 'antiquity_20'] = 1
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Clean the vendor's name
# ===========================================================================
data_sub.loc[:, 'vendor_Y'] = clean_vendor(vendor=data_sub['vendor_name'])
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Add ratios
# ===========================================================================
data_sub.loc[:, 'mar_2_inc'] = (data_sub['asset_market_value'] /
                                (data_sub['client_income'] * 10000))

data_sub.loc[:, 'app_2_inc'] = (data_sub['appraisal_value'] /
                                (data_sub['client_income'] * 10000))

data_sub.loc[:, 'mar_2_val'] = (data_sub['asset_market_value'] /
                                data_sub['asset_value'])

data_sub.loc[:, 'bank_2_home'] = (data_sub['bank_total'] /
                                  data_sub['home_total'])

data_sub.loc[:, 'mar_2_app'] = (data_sub['asset_market_value'] /
                                data_sub['appraisal_value'])
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Order columns
# ===========================================================================
ordered_columns = ['mortgage_id',
                   'state',
                   'county',
                   'city',
                   'zip',
                   'vendor_name',
                   'employer_name',
                   'age',
                   'sex',
                   'asset_market_value',
                   'mar_2_app',
                   'appraisal_value',
                   'app_2_inc',
                   'client_income',
                   'mar_2_inc',
                   'sex_F',
                   'condition_U',
                   'y',
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
                   'mar_2_val',
                   'bank_total',
                   'home_total',
                   'bank_monthly',
                   'home_monthly',
                   'days_pay',
                   'days_wo_pay',
                   'months_wo_pay',
                   'date_start',
                   'date_finish',
                   'last_date_pay',
                   'origin',
                   'new_used',
                   'labor_antiquity',
                   'credit_type',
                   'asset_value',
                   'months_employed',
                   'state_asset',
                   'county_asset',
                   'city_asset',
                   'zip_asset',
                   'mortgage_product',
                   'date_signed',
                   'interest_rate']

# Verify that all columns that are selected are ordered
c = set(data_sub.columns).difference(set(ordered_columns))
print('\nThe number missing columns to order are {}'.format(len(c)))

# Order the columns
data_sub = data_sub[ordered_columns]
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Output the cleaned data set
# ===========================================================================
data_sub.to_csv(file_path, sep='|', index=False)
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Sample a small amount of the data set
# ===========================================================================
n = data_sub.shape[0]
per = 0.01
m = round(n * per)
np.random.seed(seed=12372763)
selected_rows = np.random.choice(a=n, size=m, replace=False)
data_sample = data_sub.iloc[selected_rows, :]
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# ===========================================================================
# Output the random sample extract
# ===========================================================================
data_sample.to_csv(file_path_sample, index=False)
# data_sample.to_csv(file_path_sample, sep='|', index=False)
# ===========================================================================
