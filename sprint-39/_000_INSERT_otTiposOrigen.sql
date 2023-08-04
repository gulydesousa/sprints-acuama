
INSERT INTO dbo.otTiposOrigen(ottoCodigo, ottoOrigen, ottoDescripcion, ottoFechaInicio)
SELECT O.ottcod, 'ANY', O.ottdes, pgsvalor 
FROM dbo.ottipos AS O
LEFT JOIN dbo.parametros AS P
ON P.pgsclave='FECHA_INICIO_EXPLOTACION'

INSERT INTO dbo.otTiposOrigen(ottoCodigo, ottoOrigen, ottoDescripcion, ottoFechaInicio)
SELECT pgsvalor, 'CCMASIVO', 'C.C. Masivo', GETDATE()
FROM parametros WHERE pgsclave LIKE 'OT_TIPO_CC';


INSERT INTO dbo.otTiposOrigen(ottoCodigo, ottoOrigen, ottoDescripcion, ottoFechaInicio)
SELECT pgsvalor, 'CCCONTRATO', 'C.C. Contrato', GETDATE()
FROM parametros WHERE pgsclave LIKE 'OT_TIPO_CC';

INSERT INTO dbo.otTiposOrigen(ottoCodigo, ottoOrigen, ottoDescripcion, ottoFechaInicio)
SELECT pgsvalor, 'CCCSV', 'C.C. Masivo por CSV', GETDATE()
FROM parametros WHERE pgsclave LIKE 'OT_TIPO_CC';



UPDATE T SET ottoDescripcion='OT C.Contador'
FROM otTiposOrigen AS T WHERE ottoCodigo=1 AND ottoOrigen='ANY' AND ottoDescripcion='ALTA/INSTALACION CONTADOR'

SELECT * FROM dbo.otTiposOrigen