SELECT * FROM parametros WHERE pgsclave='SEPARADOR_CSV';


IF(NOT EXISTS (SELECT * FROM parametros WHERE pgsclave='SEPARADOR_CSV'))

INSERT INTO parametros 
OUTPUT INSERTED.*
VALUES(
'SEPARADOR_CSV',
'Separador para los ficheros CSV',
2, 
';',
0,
1, 
1)
