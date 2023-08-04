
--INSERT INTO dbo.parametros VALUES('DOMICBANC', 'Hablilita la domiciliacion bancaria desde Sistema/Oficina online/Solicitudes', 2, 'ON',0 ,1, 0)

SELECT * 
--UPDATE P SET pgsValor='ON'
FROM parametros AS P WHERE pgsclave='DOMICBANC'