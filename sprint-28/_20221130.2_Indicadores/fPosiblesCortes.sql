
--SELECT * FROM [Indicadores].[fPosiblesCortes] ('20220101', '20230131')

ALTER FUNCTION [Indicadores].[fPosiblesCortes]
( @fDesde DATE
, @fHasta DATE
)
RETURNS TABLE
AS
RETURN(

SELECT E.excNumExp, E.excFechaReg
FROM dbo.expedientesCorte AS E 
WHERE E.excfechacierreExp IS NULL
  --AND E.excFechaCorte IS NULL   
  AND E.excFechaReg >=@fDesde 
  AND E.excFechaReg < @fHasta


)
GO
