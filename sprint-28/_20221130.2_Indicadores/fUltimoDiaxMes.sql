--SELECT * FROM [Indicadores].[fUltimoDiaxMes]  ('20211001', '20221101')


CREATE FUNCTION [Indicadores].[fUltimoDiaxMes] 
( @fDesde DATE, @fHasta DATE)
RETURNS TABLE
RETURN(
WITH dateCTE
AS
(
    SELECT DATEADD(DAY, -1, DATEADD(M, 1, @fDesde)) EndOFMonth
  
    UNION ALL 
    SELECT DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1, EndOFMonth)))
    FROM dateCTE
    WHERE DATEADD(DAY, 1, EndOFMonth) < @fHasta

)
SELECT *
FROM dateCTE
)