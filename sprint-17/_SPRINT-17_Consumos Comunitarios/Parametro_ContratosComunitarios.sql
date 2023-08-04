--SELECT * FROM parametros WHERE pgsclave LIKE '%COM%'
--DELETE FROM parametros WHERE pgsclave='VERSION_CNS_COMUNITARIOS'
--SELECT * FROM parametros WHERE pgsclave='VERSION_CNS_COMUNITARIOS'


INSERT INTO dbo.parametros VALUES(
  'VERSION_CNS_COMUNITARIOS'
, 'Sprint#17 abril-2022: Para condicionar la ejecución de Tasks_Facturas_AplicarConsumosComunitarios  (1.0.0=Version Inicial, 2.0.0:Cambios en DESCONTAR)'
, 5
, '2.0.0'
, 0
, 1
, 0  )
