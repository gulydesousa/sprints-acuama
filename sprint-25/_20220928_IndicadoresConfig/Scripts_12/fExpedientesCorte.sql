
--SELECT * FROM [Indicadores].[fExpedientesCorte] ('20200101', '20220731')

CREATE FUNCTION [Indicadores].[fExpedientesCorte]
( @fDesde DATE
, @fHasta DATE
)
RETURNS TABLE
AS
RETURN(
SELECT excNumExp 
FROM dbo.expedientesCorte 
WHERE excFechaCorte IS NOT NULL  
  AND excfechacierreExp IS NOT NULL
  AND excfechacierreExp >=@fDesde AND excfechacierreExp <@fHasta 
  AND excFechaCorte >=@fDesde AND  excFechaCorte <@fHasta
)
GO
