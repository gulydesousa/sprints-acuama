SELECT * FROM parametros 
WHERE pgsclave IN ('OBTENER_CABECERA', 'FAC.APERTURA')

--SELECT *
UPDATE P SET pgsvalor='2.0'
FROM parametros AS P WHERE pgsclave='FAC.APERTURA'


--SELECT *
UPDATE P SET pgsvalor='OFF'
FROM parametros AS P WHERE pgsclave='OBTENER_CABECERA'


SELECT * FROM parametros 
WHERE pgsclave IN ('OBTENER_CABECERA', 'FAC.APERTURA')