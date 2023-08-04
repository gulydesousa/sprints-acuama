--SELECT * FROM dbo.vCobrosNumerador

ALTER VIEW dbo.vCobrosNumerador
AS

WITH T AS (
SELECT P.ppagCod
	 , S.scdcod 
FROM dbo.ppagos AS P 
CROSS JOIN dbo.sociedades AS S

), C AS(
SELECT cobScd
	 , cobPpag
	 , ISNULL(MAX(cobNum), 0) AS NUM
FROM dbo.cobros
GROUP BY cobScd, cobPpag)

SELECT T.scdcod
	 , T.ppagCod
	 , ISNULL(C.NUM, 0) AS cbnNumero
FROM T
LEFT JOIN C
ON T.ppagCod=C.cobPpag
AND T.scdcod = C.cobScd;

GO