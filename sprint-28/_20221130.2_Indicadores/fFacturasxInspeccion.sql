/*
DECLARE @fDesde DATE='20220101';
DECLARE @fHasta DATE = '20220201';
--DECLARE @tInspecciones VARCHAR(250) = NULL;
DECLARE @tInspecciones VARCHAR(250) = '1,4,5';

SELECT * FROM Indicadores.fFacturasxInspeccion (@fDesde, @fHasta, @tInspecciones)
*/

ALTER FUNCTION [Indicadores].[fFacturasxInspeccion]
( @fDesde DATE
, @fHasta DATE
, @tInspecciones VARCHAR(250) = NULL)
RETURNS TABLE 

AS
RETURN(


--Inspecciones para filtrar
WITH I (facInspeccion) AS (
SELECT DISTINCT(value) FROM dbo.Split(@tInspecciones, ',')

--Facturas no rectificadas por fecha de inspección
), FACS AS(
SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion
	 , facInspeccion = ISNULL(F.facInspeccion, '')
FROM dbo.facturas AS F 
WHERE  F.facLecInspectorFec >= @fDesde 
   AND F.facLecInspectorFec < @fHasta
   AND (F.facFechaRectif IS NULL OR F.facFechaRectif >=@fHasta))

SELECT  F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, F.facInspeccion
FROM FACS AS F 
LEFT JOIN I
ON I.facInspeccion = F.facInspeccion
WHERE (@tInspecciones IS NULL OR @tInspecciones = '' OR I.facInspeccion IS NOT NULL)
  
)
GO


