SELECT * FROM parametros WHERE pgsclave='RUTA_CARGA_OT_INSPECC';

IF(NOT EXISTS (SELECT * FROM parametros WHERE pgsclave='RUTA_CARGA_OT_INSPECC'))

INSERT INTO parametros 
OUTPUT INSERTED.*
VALUES(
'RUTA_CARGA_OT_INSPECC',
'Directorio de carga masiva de OT de inspecciones',
2, 
'__cargaOT_INSPECCIONES__',
0,
1, 
1)
