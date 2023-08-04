/*
DECLARE @fDesde DATE='20220101';
DECLARE @fHasta DATE = '20220301';
DECLARE @cnsDesde INT = 10;
DECLARE @cnsHasta INT = 15;


SELECT * FROM Indicadores.fFacturasRangoCnsxSemana (@fDesde, @fHasta, @cnsDesde, @cnsHasta);
*/

CREATE FUNCTION [Indicadores].[fFacturasRangoCnsxSemana] 
( @fDesde DATE
, @fHasta DATE
, @cnsDesde INT = NULL
, @cnsHasta INT = NULL)
RETURNS TABLE 

AS
RETURN(

WITH FACS AS(
SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, F.facNumero,
	   F.facLecActFec,
	   facConsumoFactura = ISNULL(F.facConsumoFactura, 0), 
	   SEMANA	= (DATEDIFF(DAY, @fDesde, facLecActFec)/7)+1
FROM dbo.facturas AS F
WHERE (F.facFechaRectif IS NULL OR F.facFechaRectif>=@fHasta)
  AND (F.facLecActFec >= @fDesde AND F.facLecActFec < @fHasta)
  AND (@cnsDesde IS NULL OR  ISNULL(F.facConsumoFactura, 0) >= @cnsDesde)
  AND (@cnsHasta IS NULL OR  ISNULL(F.facConsumoFactura, 0) <= @cnsHasta)

)
SELECT SEMANA
	 , VALOR = COUNT(facCod)
FROM FACS
GROUP BY SEMANA
)
GO


