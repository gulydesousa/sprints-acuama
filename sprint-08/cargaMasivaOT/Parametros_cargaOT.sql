--SELECT * FROM parametros WHERE pgsclave='RUTADOCUMENTOS'
--SELECT * FROM dbo.parametros WHERE pgsclave IN ('OT_SERIE_CC', 'OT_SOLICITUD_CC' , 'OT_TIPO_CC', 'OT_IMPUTACION_CC', 'OT_ALMACEN_CC')
--SELECT * FROM [ottipos]

INSERT INTO dbo.parametros VALUES('RUTA_CARGAMASIVA_OT', 'Directorio de carga masiva OTs', 2, '__cargaOT__', 0, 1, 0)

UPDATE P SET pgsvalor=1 FROM dbo.parametros AS P WHERE pgsclave = 'OT_TIPO_CC'

