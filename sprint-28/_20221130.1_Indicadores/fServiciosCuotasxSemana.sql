/*
DECLARE @fDesde DATE='20220101';
DECLARE @fHasta DATE = '20220301';
DECLARE @srvCod AS VARCHAR(25) = '1,23'
DECLARE @incilec VARCHAR(MAX) = '10, 11, 12, 14 ';

SELECT * FROM [Indicadores].[fServiciosCuotasxSemana] (@fDesde, @fHasta, @srvCod);

*/

CREATE FUNCTION [Indicadores].[fServiciosCuotasxSemana] 
( @fDesde DATE
, @fHasta DATE
, @srvCod AS VARCHAR(25))
RETURNS TABLE 


AS
RETURN(

WITH SVC(svcCod) AS(
--Servicios que buscamos
SELECT [value] FROM dbo.Split(@srvCod, ',')

), FACS AS(

SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion,
	   SEMANA	= (DATEDIFF(DAY, @fDesde, facFecha)/7)+1	 
FROM dbo.facturas AS F
WHERE (F.facFechaRectif IS NULL OR F.facFechaRectif>=@fHasta)
  AND (F.facFecha IS NOT NULL AND F.facFecha>= @fDesde AND F.facFecha < @fHasta) 

), FL AS(
SELECT F.*
, FL.fclTrfSvCod 
--RN=1: Para quedarnos con una ocurrencia por factura y servicio
, RN= ROW_NUMBER() OVER (PARTITION  BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, FL.fclTrfSvCod ORDER BY FL.fclNumLinea)
FROM FACS AS F
INNER JOIN  dbo.faclin AS FL
ON F.facCod = FL.fclFacCod
AND F.facPerCod = FL.fclFacPerCod
AND F.facCtrCod = FL.fclFacCtrCod
AND F.facVersion = FL.fclFacVersion
AND (FL.fclFecLiq IS NULL OR FL.fclFecLiq>=@fHasta)
INNER JOIN SVC AS S
ON S.svcCod = FL.fclTrfSvCod)

SELECT SEMANA
 , VALOR = COUNT(fclTrfSvCod) 
FROM FL
WHERE RN=1
GROUP BY SEMANA

)
GO


