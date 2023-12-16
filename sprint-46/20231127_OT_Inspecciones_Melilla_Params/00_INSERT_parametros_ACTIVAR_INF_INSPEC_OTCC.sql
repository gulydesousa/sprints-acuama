SELECT * FROM parametros WHERE pgsclave='ACTIVAR_INF_INSPEC_OTCC';

IF(NOT EXISTS (SELECT * FROM parametros WHERE pgsclave='ACTIVAR_INF_INSPEC_OTCC'))

INSERT INTO parametros 
OUTPUT INSERTED.*
VALUES(
'ACTIVAR_INF_INSPEC_OTCC',
'Habilita los tipos OT con anomalía y sin anomalía en emisión de notificaciones',
2, 
'False',
0,
1, 
0)
