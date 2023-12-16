--SELECT * FROM parametros WHERE pgsclave like 'OT%' ORDER BY pgsclave

INSERT INTO parametros
VALUES('OT_PDTE_REALIZAR', 'Para habilitar la opción Pendiente Realizar', 2, 'OFF', 0, 1, 0)


SELECT * 
--Update P SET pgsvalor='ON'
FROM parametros AS P WHERE pgsclave='OT_PDTE_REALIZAR'
