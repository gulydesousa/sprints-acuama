
SELECT  *
FROM dbo.vCobrosNumerador AS v
LEFT JOIN dbo.cobrosNum AS c
ON C.cbnScd = V.scdcod AND C.cbnPpag = V.ppagCod
--WHERE c.cbnScd IS NULL 
 --OR V.cbnNumero <> C.cbnNumero

SELECT  *
FROM dbo.vCobrosNumerador AS v
LEFT JOIN dbo.cobrosNum AS c
ON C.cbnScd = V.scdcod AND C.cbnPpag = V.ppagCod
WHERE c.cbnScd IS NULL OR V.cbnNumero <> C.cbnNumero

--INSERT INTO dbo.cobrosNum
--SELECT  V.*
--FROM dbo.vCobrosNumerador AS v
--LEFT JOIN dbo.cobrosNum AS c
--ON C.cbnScd = V.scdcod AND C.cbnPpag = V.ppagCod
--WHERE c.cbnScd IS NULL 


SELECT  V.*
--UPDATE C SET C.cbnNumero=V.cbnNumero
FROM dbo.vCobrosNumerador AS v
LEFT JOIN dbo.cobrosNum AS c
ON C.cbnScd = V.scdcod AND C.cbnPpag = V.ppagCod
WHERE V.cbnNumero <> C.cbnNumero

