--SELECT * FROM dbo.vPerzonaFechas

CREATE VIEW dbo.vPerzonaFechas
AS

WITH PZ AS(
SELECT Z.przcodper
, Z.przcodzon
, Z.przfPeriodoD
, Z.przfPeriodoH
, NumMeses = DATEDIFF(MONTH, Z.przfPeriodoD, Z.przfPeriodoH)+1
, RN = ROW_NUMBER() OVER(PARTITION BY przcodper, DATEDIFF(MONTH, Z.przfPeriodoD, Z.przfPeriodoH) ORDER BY Z.przfPeriodoD, Z.przfPeriodoH)
--DR<>1 : ¿Existen diferentes fechas en perzona? 
--, DR = DENSE_RANK() OVER(PARTITION BY przcodper, DATEDIFF(MONTH, Z.przfPeriodoD, Z.przfPeriodoH) ORDER BY Z.przfPeriodoD, Z.przfPeriodoH)
FROM dbo.perzona AS Z
WHERE COALESCE(Z.przfPeriodoD, Z.przfPeriodoH) IS NOT NULL)

SELECT przcodper, przcodzon, przfPeriodoD, przfPeriodoH, NumMeses, pertipo, RN
FROM PZ 
INNER JOIN periodos AS P
ON  P.percod= PZ.przcodper


GO