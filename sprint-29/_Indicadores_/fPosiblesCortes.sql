
--SELECT * FROM [Indicadores].[fPosiblesCortes] ('20220101', '20230131', '100,200') ORDER BY excExcTipCodigo

ALTER FUNCTION [Indicadores].[fPosiblesCortes]
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

SELECT E.excNumExp, E.excFechaReg, E.excExcTipCodigo
FROM dbo.expedientesCorte AS E 
LEFT JOIN T
ON T.value = ISNULL(E.excExcTipCodigo, '')
WHERE E.excfechacierreExp IS NULL
  AND E.excFechaReg >=@fDesde 
  AND E.excFechaReg < @fHasta
  AND (@tipoExpediente IS NULL OR T.value IS NOT NULL)

)
GO
