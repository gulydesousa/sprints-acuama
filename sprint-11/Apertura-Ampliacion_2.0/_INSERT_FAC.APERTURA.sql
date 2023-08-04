--SELECT * FROM parametros
INSERT INTO dbo.parametros VALUES('FAC.APERTURA', 'Versión de la apertura de facturación (nueva versión: 2.0)', 2, '1.0', 0, 1, 0);

SELECT * 
--UPDATE P SET pgsvalor='1.0'
FROM parametros AS P WHERE pgsclave='FAC.APERTURA'


