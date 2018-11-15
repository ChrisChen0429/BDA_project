# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Notes
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
"""
(*) This script explores the contents of the DBs given by the client
(*) Beware! This file writes an output
(*) Also make sure that your working directory is properly set
"""
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Imports
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
import numpy as np
import pandas as pd
# from AndPotap.Utils.eda import one_col_summary
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Open DBs
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
data = pd.read_excel('./AndPotap/DBs/Base de originacion FHIPO.xlsx')
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Output list of columns to excel
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# pd.DataFrame(data.columns).to_excel('./DBs/column_list.xlsx',
#                                     header=False,
#                                     index=False)
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Explore columns contents
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# col = 'Nombre'
# column = 'idpoliticasValidacion'

# df = one_col_summary(data=data, column=column, col=col)

# for colu in list(data.columns):
#     df = one_col_summary(data=data, column=colu, col=col)
#     print(df)
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Select columns to include and rename them
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
selected_columns = ['Nombre',
                    'colonia_domicilio',
                    'ciudad_domicilio',
                    'entidad_federativa',
                    'codigo_postal',
                    'Genero',
                    'numero_credito',
                    'fecha_firma_credito',
                    'factor_pago_roa',
                    'factor_pago_rea',
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
                    'plazo_propuesto',
                    'calificacion_buro',
                    'estado_civil_acreditado',
                    'Calculado_edad',
                    'Monto_credito_original_total_pesos']
data_sub = data[selected_columns]
renaming_dict = {'Nombre': 'mortgage_product',
                 'colonia_domicilio': 'county',
                 'ciudad_domicilio': 'city',
                 'entidad_federativa': 'state',
                 'codigo_postal': 'zip',
                 'Genero': 'sex',
                 'numero_credito': 'mortgage_id',
                 'fecha_firma_credito': 'date_signed',
                 'factor_pago_roa': 'factor_employed',
                 'factor_pago_rea': 'factor_unemployed',
                 'tasa_interes': 'interest_rate',
                 'antiguedad_empleo_titular': 'months_employed',
                 'ingresos_cliente_registrado_infonavit': 'client_income',
                 'relacion_pago': 'ratio',
                 'calificacion_infonavit': 'lender_score',
                 'nombre_vendedor': 'vendor_name',
                 'valor_compra_venta': 'asset_value',
                 'colonia_compra': 'county_asset',
                 'ciudad_compra': 'city_asset',
                 'codigo_postal_compra': 'postal_code_asset',
                 'entidad_federativa_compra': 'state_asset',
                 'valor_avaluo': 'asset_market_value',
                 'nueva_usada': 'new_used',
                 'indice_riesgo': 'risk_index',
                 'tipo_credito': 'credit_type',
                 'antiguedad_laboral': 'labor_antiquity',
                 'nombre_empresa': 'employer_name',
                 'edad': 'age',
                 'plazo_propuesto': 'contract_length',
                 'calificacion_buro': 'credit_score',
                 'estado_civil_acreditado': 'married',
                 'Calculado_edad': 'asset_age',
                 'Monto_credito_original_total_pesos': 'appraisal_value'}
data_sub = data_sub.rename(columns=renaming_dict)
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Explore certain columns
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# col = 'mortgage_id'
# column = 'sex'
# column = 'asset_age'

# df = one_col_summary(data=data_sub, column=column, col=col)
# print(df)
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Incorporate dummy columns
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
data_sub['sex'] = data_sub['sex'].astype('category')
sex_encoding = {1.0: 'M', 2.0: 'F'}
data_sub['sex'] = data_sub['sex'].replace(sex_encoding)
aux = pd.get_dummies(data=data_sub[['sex', 'new_used']],
                     prefix=['sex', 'condition'],
                     columns=['sex', 'new_used'])
data_sub = pd.merge(left=data_sub,
                    right=aux,
                    how='inner',
                    left_index=True,
                    right_index=True)
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Order columns
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ordered_columns = ['mortgage_id',
                   'state',
                   'county',
                   'city',
                   'zip',
                   'vendor_name',
                   'employer_name',
                   'age',
                   'sex',
                   'new_used',
                   'appraisal_value',
                   'client_income',
                   'risk_index',
                   'ratio',
                   'lender_score',
                   'asset_market_value',
                   'credit_score',
                   'asset_age',
                   'labor_antiquity',
                   'sex_F',
                   'sex_M',
                   'condition_N',
                   'condition_U',
                   'factor_employed',
                   'factor_unemployed',
                   'months_employed',
                   'credit_type',
                   'asset_value',
                   'months_employed',
                   'state_asset',
                   'county_asset',
                   'city_asset',
                   'postal_code_asset',
                   'contract_length',
                   'married',
                   'mortgage_product',
                   'date_signed',
                   'interest_rate']
data_sub = data_sub[ordered_columns]
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Load the y label data
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
file_y = './AndPotap/DBs/core_y.txt'
data_y = pd.read_csv(file_y, sep='|')
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Combine the data sets
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
data_sub = pd.merge(left=data_sub, right=data_y, how='inner',
                    on='mortgage_id')
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Convert to proper data types
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cols_2_int = {'mortgage_id': 'int64',
              'age': 'int64',
              'zip': 'int64'}
data_sub = data_sub.astype(cols_2_int)
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Output the cleaned data set
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
file_path = './AndPotap/DBs/core.txt'
data_sub.to_csv(file_path, sep='|')
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Sample a small amount of the data set
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
n = data_sub.shape[0]
per = 0.1
m = round(n * per)
np.random.seed(seed=12372763)
selected_rows = np.random.choice(a=n, size=m, replace=False)
data_sample = data_sub.iloc[selected_rows, :]
# ===========================================================================
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Output the random sample extract
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
file_path_sample = './AndPotap/DBs/core_sample.txt'
data_sample.to_csv(file_path_sample, sep='|')
# ===========================================================================
