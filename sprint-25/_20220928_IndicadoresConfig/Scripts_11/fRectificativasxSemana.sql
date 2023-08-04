/*
DECLARE @fDesde DATE='20210101';
DECLARE @fHasta DATE = '20210201';
DECLARE @RectificaCns BIT = 1;

SELECT * FROM Indicadores.fRectificativasxSemana (@fDesde, @fHasta, @RectificaCns)
*/

CREATE FUNCTION Indicadores.fRectificativasxSemana 
( @fDesde DATE
, @fHasta DATE
, @RectificaCns BIT = NULL)

RETURNS TABLE 

AS
RETURN(

WITH FAC AS(
SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, F.facNumero, F.facFecha, F.facSerCod, 
	   F.facLecActFec,
	   facConsumoFactura= ISNULL(F.facConsumoFactura, 0), 
	   SEMANA = (DATEDIFF(DAY, @fDesde, facLecActFec)/7)+1
FROM dbo.facturas AS F
WHERE F.facLecActFec >= @fDesde 
  AND F.facLecActFec < @fHasta
  AND F.facFechaRectif IS NULL
  AND F.facFecha IS NOT NULL

), FAC0 AS(
SELECT  F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, F.facNumero, F.facConsumoFactura
, facVersion_Rectificada = F0.facVersion, facNumero_Rectificada = F0.facNumero, facConsumo_Rectificada = ISNULL(F0.facConsumoFactura, 0)
, F.SEMANA
--RN= 1: Por garantizar que hay una sola rectificativa por factura
, RN = ROW_NUMBER() OVER(PARTITION BY  F0.facCod, F0.facPerCod, F0.facCtrCod ORDER BY F0.facVersion DESC)
FROM FAC AS F
INNER JOIN facturas AS F0 
ON  F.facCod = F0.facCod
AND F.facPerCod = F0.facPerCod
AND F.facCtrCod = F0.facCtrCod
AND F0.facFechaRectif IS NOT NULL
AND F0.facFechaRectif = F.facFecha
AND F0.facSerieRectif = F.facSerCod
AND F0.facNumeroRectif = F.facNumero
)

SELECT SEMANA
	 , VALOR = COUNT(facConsumoFactura)
FROM FAC0
WHERE RN=1 
AND ( (@RectificaCns IS NULL) 
   OR (@RectificaCns=1 AND facConsumoFactura<>facConsumo_Rectificada) 
   OR (@RectificaCns=0 AND facConsumoFactura=facConsumo_Rectificada))
GROUP BY SEMANA
) 

GO
