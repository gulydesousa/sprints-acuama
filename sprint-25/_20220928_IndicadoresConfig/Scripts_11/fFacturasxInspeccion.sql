/*
DECLARE @fDesde DATE='20220101';
DECLARE @fHasta DATE = '20220201';
DECLARE @tInspecciones VARCHAR(250) = ',';

SELECT * FROM Indicadores.fFacturasxInspeccion (@fDesde, @fHasta, @tInspecciones)


*/

CREATE FUNCTION Indicadores.fFacturasxInspeccion
( @fDesde DATE
, @fHasta DATE
, @tInspecciones VARCHAR(250) = NULL)
RETURNS TABLE 

AS
RETURN(
WITH I (facInspeccion) AS (
SELECT DISTINCT(value) FROM dbo.Split(@tInspecciones, ',')
)
SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, F.facInspeccion
FROM dbo.facturas AS F 
LEFT JOIN I
ON I.facInspeccion = ISNULL(F.facInspeccion, '')
WHERE (@tInspecciones IS NULL OR @tInspecciones = '' OR I.facInspeccion IS NOT NULL)
  AND F.facLecInspectorFec >= @fDesde 
  AND F.facLecInspectorFec < @fHasta
  
)
GO
