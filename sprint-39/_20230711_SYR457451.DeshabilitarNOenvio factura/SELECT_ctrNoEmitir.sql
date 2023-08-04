--Aqui SYR_457451 quedan las que tenían no ctrNoEmitir=1

SELECT C.ctrcod, c.ctrversion, C.ctrNoEmision 
INTO SYR_457451
FROM vContratosUltimaVersion AS V
INNER JOIN contratos as c
ON C.ctrcod= V.ctrCod
AND C.ctrversion = V.ctrVersion
AND C.ctrNoEmision=1