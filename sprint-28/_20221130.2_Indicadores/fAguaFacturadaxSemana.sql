
/*

DECLARE @fDesde DATE='20220201';
DECLARE @fHasta DATE = '20220301';
DECLARE @usos VARCHAR(100) = '1';
SELECT *, SUM(VALOR) OVER() FROM [Indicadores].[fAguaFacturadaxSemana] (@fDesde, @fHasta, @usos)

SELECT [VALOR] = SUM(VALOR) FROM Indicadores.fAguaFacturadaxSemana ('20220701', '20220801', '1')
*/

ALTER FUNCTION Indicadores.fAguaFacturadaxSemana 
( @fDesde DATE
, @fHasta DATE
, @usos VARCHAR(100) = NULL)
RETURNS TABLE 

AS
RETURN(


WITH U AS(
SELECT DISTINCT(value) FROM dbo.Split(@usos, ',')

), FACS AS(
SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion
, F.facNumero
, F.facConsumoFactura
, usoCod = U.value
, SEMANA = (DATEDIFF(DAY, @fDesde, facLecActFec)/7)+1
, RN = ROW_NUMBER() OVER(PARTITION BY  F.facCod, F.facPerCod, F.facCtrCod, F.facVersion ORDER BY FL.fclNumLinea)
FROM dbo.facturas AS F
INNER JOIN dbo.contratos AS C
ON  C.ctrcod = F.facCtrCod
AND C.ctrversion = F.facCtrVersion
INNER JOIN dbo.faclin AS FL
ON F.facCod = FL.fclFacCod
AND F.facPerCod = FL.fclFacPerCod
AND F.facCtrCod = FL.fclFacCtrCod
AND F.facVersion = FL.fclFacVersion
AND FL.fclFecLiq IS NULL 
AND FL.fclTrfSvCod = 1
AND (F.facFechaRectif IS NULL OR F.facFechaRectif >= @fHasta)
AND F.facLecActFec >= @fDesde 
AND F.facLecActFec < @fHasta
LEFT JOIN U 
ON C.ctrUsoCod = U.value)

SELECT SEMANA
	 , VALOR = SUM(facConsumoFactura) 
FROM FACS
WHERE RN=1
AND (@usos IS NULL OR usoCod IS NOT NULL )
GROUP BY SEMANA
)

GO
