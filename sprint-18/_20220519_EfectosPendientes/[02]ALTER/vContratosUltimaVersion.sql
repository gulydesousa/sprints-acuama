--SELECT * FROM vContratosUltimaVersion WHERE ctrzoncod=3

ALTER VIEW vContratosUltimaVersion
AS
WITH CTR AS(
SELECT ctrCod
, ctrVersion
, ctrComunitario
, ctrCalculoComunitario
, ctrBaja
, ctrzoncod
, ctrCCC
, RN= ROW_NUMBER() OVER (PARTITION BY ctrCod ORDER BY ctrVersion DESC)
FROM dbo.Contratos

), HIJOS AS(
SELECT ctrComunitario
	 , numHijosComunitarios = COUNT(ctrCod) 
	 , numHijosDescontar = SUM(IIF(ctrCalculoComunitario = 1, 1, 0))
	 , numHijosRepartir = SUM(IIF(ctrCalculoComunitario = 2, 1, 0))
FROM CTR
WHERE RN=1
AND ctrComunitario IS NOT NULL
AND ctrbaja = 0
GROUP BY ctrComunitario)

SELECT C.ctrCod
, C.ctrVersion
, C.ctrComunitario 
, C.ctrCalculoComunitario
, calculoComunitario = CASE WHEN C.ctrCalculoComunitario IS NULL THEN NULL
						WHEN C.ctrCalculoComunitario= 1 THEN 'Descontar' 
						WHEN C.ctrCalculoComunitario= 2 THEN 'Repartir' 
						ELSE 'No-Definido' END
, numHijosComunitarios = ISNULL(H.numHijosComunitarios, 0)
, numHijosDescontar
, numHijosRepartir
, ctrzoncod
, C.ctrBaja
, C.ctrCCC
FROM CTR AS C
LEFT JOIN HIJOS AS H
ON C.ctrcod = H.ctrComunitario
WHERE RN=1;
GO