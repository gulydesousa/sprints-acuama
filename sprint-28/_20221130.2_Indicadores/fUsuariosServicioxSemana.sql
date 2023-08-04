/*
DECLARE @fDesde DATE='20220101';
DECLARE @fHasta DATE = '20220301';
DECLARE @srvCod AS SMALLINT = 1;

SELECT *, SUM(VALOR) OVER () FROM [Indicadores].[fUsuariosServicioxSemana] (@fDesde, @fHasta, @srvCod);
*/


CREATE FUNCTION [Indicadores].[fUsuariosServicioxSemana] 
( @fDesde DATE
, @fHasta DATE
, @srvCod AS INT)
RETURNS TABLE 


AS
RETURN(

WITH FACS AS(
SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion,
	   SEMANA	= (DATEDIFF(DAY, @fDesde, facFecha)/7)+1	 
FROM dbo.facturas AS F
WHERE (F.facFechaRectif IS NULL OR F.facFechaRectif>=@fHasta)
  AND (F.facFecha IS NOT NULL AND F.facFecha>= @fDesde AND F.facFecha < @fHasta) 

), FL AS(
SELECT F.*
, FL.fclTrfSvCod 
, fclUnidades = IIF(FL.fclFacPerCod='000001', 0,  FL.fclUnidades)

--FACTURAS que tienen el servicio @srvCod + UNIDADES  que tienen el servicio T.Fijo Cdad. (Agua/Alcantarillado)
, Usuarios = CASE WHEN FL.fclTrfSvCod=@srvCod THEN 1
				  WHEN FL.fclFacPerCod<>'000001' THEN ISNULL(FL.fclUnidades, 0)
				  ELSE 0 END
--RN=1: Para quedarnos con una ocurrencia por factura y servicio
, RN= ROW_NUMBER() OVER (PARTITION  BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, FL.fclTrfSvCod ORDER BY FL.fclNumLinea)
FROM FACS AS F
INNER JOIN  dbo.faclin AS FL
ON F.facCod = FL.fclFacCod
AND F.facPerCod = FL.fclFacPerCod
AND F.facCtrCod = FL.fclFacCtrCod
AND F.facVersion = FL.fclFacVersion
AND (FL.fclFecLiq IS NULL OR FL.fclFecLiq>=@fHasta)
AND (FL.fclTrfSvCod=@srvCod OR FL.fclTrfSvCod = (CASE @srvCod WHEN 1 THEN 23 WHEN 3 THEN 24 ELSE 0 END))

)

SELECT SEMANA 
, VALOR = SUM(Usuarios)
FROM FL
WHERE RN=1
GROUP BY SEMANA

)
GO


