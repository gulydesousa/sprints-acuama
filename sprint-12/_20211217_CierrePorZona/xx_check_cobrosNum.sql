--SELECT C.* , V.cbnNumero
----UPDATE C SET C.cbnNumero=V.cbnNumero
--FROM dbo.cobrosNum AS C
--LEFT JOIN dbo.vCobrosNumerador AS V
--ON C.cbnScd = V.scdcod AND C.cbnPpag = V.ppagCod
--WHERE V.cbnNumero <> C.cbnNumero


--SELECT COUNT(1) FROM cobros where cobfecreg> '20220103'


SELECT V.* , C.cbnNumero
----UPDATE C SET C.cbnNumero=V.cbnNumero
FROM dbo.vCobrosNumerador AS V
LEFT JOIN dbo.cobrosNum AS C
ON C.cbnScd = V.scdcod AND C.cbnPpag = V.ppagCod
WHERE C.cbnNumero IS NULL OR V.cbnNumero <> C.cbnNumero