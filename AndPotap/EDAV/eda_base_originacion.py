# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Notes
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
"""
(*) This script explores the contents of the DBs given by the client
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
# Read off selected columns
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# selected = ['Nombre', 'id_portafolio', 'periodo', 'intTipoCompra',
#        'idpoliticasValidacion', 'archivo_cesion', 'numero_seguridad_social',
#        'nombre_cliente', 'calle_numero', 'colonia_domicilio',
#        'ciudad_domicilio', 'entidad_federativa', 'codigo_postal',
#        'lada_cliente', 'telefono_cliente', 'rfc_cliente', 'Genero',
#        'numero_credito'
#     'Monto_credito_original_total_pesos',
#             'importe_original_credito_porcion_banco_pesos',
#             'importe_original_credito_porcion_infonavit_pesos',
#             'importe_original_porcion_banco_vsm',
#             'importe_original_porcion_infonavit_vsm']
selected = ['Monto_credito_original_total_pesos',
            'importe_original_credito_porcion_banco_pesos',
            'importe_original_credito_porcion_infonavit_pesos',
            'importe_original_porcion_banco_vsm',
            'importe_original_porcion_infonavit_vsm']
# mask = data['importe_original_credito_porcion_banco_pesos'] = 0
mask = data[selected[-1]] > 0
data.loc[1, selected]
# ===========================================================================
