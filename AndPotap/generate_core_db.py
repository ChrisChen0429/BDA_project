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
# from Utils.eda import one_col_summary
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
                 'codigo_postal': 'postal_code',
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
                 'antiguedad_laboral': 'months_employed',
                 'nombre_empresa': 'employer_name',
                 'edad': 'age',
                 'plazo_propuesto': 'contract_length',
                 'calificacion_buro': 'credit_score',
                 'estado_civil_acreditado': 'married',
                 'Calculado_edad': 'asset_age',
                 'Monto_credito_original_total_pesos': 'contract_value'}
data_sub = data_sub.rename(columns=renaming_dict)
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
