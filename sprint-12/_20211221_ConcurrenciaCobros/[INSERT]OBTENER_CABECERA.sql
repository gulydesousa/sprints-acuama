--SELECT * FROM parametros
INSERT INTO dbo.parametros VALUES('OBTENER_CABECERA', 'Asignar OFF para evitar problemas de concurrencia (Manuales/Remesa) en Cobros_Select cuando FAC.APERTURA = 2.0', 2, 'ON', 0, 1, 0);

SELECT * 
--UPDATE P SET pgsvalor='OFF'
FROM parametros AS P WHERE pgsclave='OBTENER_CABECERA'


--DELETE P FROM parametros AS P WHERE pgsclave='OBTENER_CABECERA'



SELECT * 
--UPDATE P SET pgsvalor='ON'
FROM parametros AS P WHERE pgsclave IN('OBTENER_CABECERA', 'FAC.APERTURA')