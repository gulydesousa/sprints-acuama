INSERT INTO parametros VALUES ('NOTIFICACIONES_REGISTRO', 'Tipo de registro asignado a notificaciones enviadas por email', 2, '12', 0, 1, 1 )

--SELECT * FROM registroEntradasTipo
SELECT *  
--UPDATE P SET pgsValor=12
FROM parametros AS P WHERE pgsclave='NOTIFICACIONES_REGISTRO'