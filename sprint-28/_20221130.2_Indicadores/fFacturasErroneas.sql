--SELECT * FROM [Indicadores].[fFacturasErroneas] ('20220101', '20220131')

ALTER FUNCTION [Indicadores].[fFacturasErroneas]
( @fDesde DATE
, @fHasta DATE
)
RETURNS TABLE
AS

RETURN(

SELECT DISTINCT facCod, facPerCod, facCtrCod
--SELECT facCod, facPerCod, facCtrCod, facVersion, facSerCod
FROM dbo.facturas AS F
WHERE F.facSerCod IN(SELECT sersercodrelac FROM dbo.series AS S WHERE S.sersercodrelac IS NOT NULL)
AND (F.facFecha >= @fDesde AND F.facfecha <@fHasta)
)
GO


