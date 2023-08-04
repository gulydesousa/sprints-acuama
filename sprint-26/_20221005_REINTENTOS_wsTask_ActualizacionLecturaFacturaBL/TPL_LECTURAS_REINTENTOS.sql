SELECT * 
--UPDATE P SET pgsvalor=2, pgsclave='TPL_LECTURAS_REINTENTOS'
FROM dbo.parametros AS P WHERE pgsclave='TPL_LECTURAS_REINTENTOS'

--INSERT INTO parametros VALUES('TPL_LECTURAS_REINTENTOS', 'Si > 0 se habilitan los reintentos en la actualización de lecturas por tarea', 1, 3, 0, 1, 0)