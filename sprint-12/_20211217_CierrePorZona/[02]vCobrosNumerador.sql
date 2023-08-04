--SELECT * FROM dbo.vCobrosNumerador

CREATE VIEW dbo.vCobrosNumerador
AS

WITH T AS (
SELECT P.ppagCod, scdcod 
FROM ppagos AS P CROSS JOIN sociedades AS S
), C AS(
SELECT cobScd, cobPpag, ISNULL(MAX(cobNum), 0) AS NUM
FROM cobros
GROUP BY cobScd, cobPpag)

SELECT T.scdcod, T.ppagCod, ISNULL(C.NUM, 0) AS cbnNumero
FROM T
LEFT JOIN C
ON T.ppagCod=C.cobPpag
AND T.scdcod = C.cobScd;

GO