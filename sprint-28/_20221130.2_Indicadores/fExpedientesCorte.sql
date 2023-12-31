--SELECT * FROM [Indicadores].[fExpedientesCorte] ('20090101', '20220731', '1, 2, ') ORDER BY excExcTipCodigo

ALTER FUNCTION [Indicadores].[fExpedientesCorte]
( @fDesde DATE
, @fHasta DATE
, @tipoExpediente VARCHAR(50)
)
RETURNS TABLE
AS
RETURN(

WITH T AS(
	SELECT DISTINCT(value) 
	FROM dbo.Split(@tipoExpediente, ',') 
	WHERE [value] IS NOT NULL)

SELECT E.excNumExp, E.excExcTipCodigo
FROM dbo.expedientesCorte AS E 
LEFT JOIN T
ON T.value = ISNULL(E.excExcTipCodigo, '')
WHERE E.excFechaGeneracionOT >=@fDesde AND  E.excFechaGeneracionOT <@fHasta 
AND (@tipoExpediente IS NULL  OR T.value IS NOT NULL)
)
GO
