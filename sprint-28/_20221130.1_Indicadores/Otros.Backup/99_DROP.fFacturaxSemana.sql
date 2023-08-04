
/*
DECLARE @fDesde DATE='20220101';
DECLARE @fHasta DATE = '20220301';
DECLARE @cnsDesde INT = NULL;
DECLARE @cnsHasta INT = NULL;
DECLARE @srvCod INT = NULL;
DECLARE @incilec VARCHAR(MAX) = '10, 11, 12, 14 ';

SELECT * FROM Indicadores.fFacturaxSemana (@fDesde, @fHasta, @cnsDesde, @cnsHasta, @srvCod, @incilec);

*/

CREATE FUNCTION [Indicadores].[fFacturaxSemana] 
( @fDesde DATE
, @fHasta DATE
, @cnsDesde INT = NULL
, @cnsHasta INT = NULL
, @srvCod INT = NULL
, @incilec VARCHAR(MAX) = NULL)
RETURNS TABLE 

AS
RETURN(

WITH IL (inlCod) AS (

SELECT DISTINCT(value) FROM dbo.Split(@incilec, ',')

), CNS AS(
SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, F.facNumero,
	   F.facLecActFec,
	   facConsumoFactura = ISNULL(F.facConsumoFactura, 0), 
	   SEMANA	= (DATEDIFF(DAY, @fDesde, facLecActFec)/7)+1,
	   inlCod	= I.inlCod
FROM dbo.facturas AS F
LEFT JOIN IL AS I 
ON I.inlCod = ISNULL(F.facInsInlCod, '')

WHERE F.facFechaRectif IS NULL
AND F.facLecActFec >= @fDesde 
AND F.facLecActFec < @fHasta
AND (@cnsDesde IS NULL OR  ISNULL(F.facConsumoFactura, 0) >= @cnsDesde)
AND (@cnsHasta IS NULL OR  ISNULL(F.facConsumoFactura, 0) <= @cnsDesde)
AND (@incilec IS NULL OR I.inlCod IS NOT NULL)

), FL AS(
SELECT F.*
--RN=1: Para quedarnos con una ocurrencia por factura y servicio
, RN= ROW_NUMBER() OVER (PARTITION  BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion ORDER BY FL.fclNumLinea)
, fclTrfSvCod = ISNULL(FL.fclTrfSvCod, 0)
FROM CNS AS F
LEFT JOIN dbo.faclin AS FL
ON F.facCod = FL.fclFacCod
AND F.facPerCod = FL.fclFacPerCod
AND F.facCtrCod = FL.fclFacCtrCod
AND F.facVersion = FL.fclFacVersion
AND FL.fclTrfSvCod = ISNULL(@srvCod, 0))

SELECT SEMANA
	 , VALOR = COUNT(facConsumoFactura)
FROM FL
WHERE RN=1
AND (@srvCod IS NULL OR fclTrfSvCod = @srvCod)
GROUP BY SEMANA
)
GO


