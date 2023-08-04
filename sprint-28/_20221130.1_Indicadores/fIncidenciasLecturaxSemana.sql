
/*
DECLARE @fDesde DATE='20220101';
DECLARE @fHasta DATE = '20220301';
--DECLARE @incilec VARCHAR(MAX) = NULL;	--Trae todas 
--DECLARE @incilec VARCHAR(MAX) = '';	--Trae todas 
--DECLARE @incilec VARCHAR(MAX) = ',';	--Sin incidencia de lectura
DECLARE @incilec VARCHAR(MAX) = '10,14, 11';	--Con incidencia de lectura

SELECT * FROM Indicadores.fIncidenciasLecturaxSemana (@fDesde, @fHasta, @incilec);
*/


CREATE FUNCTION [Indicadores].[fIncidenciasLecturaxSemana] 
( @fDesde DATE
, @fHasta DATE
, @incilec VARCHAR(MAX) = NULL)
RETURNS TABLE 

AS
RETURN(

WITH IL (inlCod) AS (

SELECT DISTINCT(value) FROM dbo.Split(@incilec, ',')

), FACS AS(
SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, F.facNumero,
	   F.facLecActFec, 
	   SEMANA	= (DATEDIFF(DAY, @fDesde, facLecActFec)/7)+1,
	   F.facInsInlCod
FROM dbo.facturas AS F
LEFT JOIN IL AS I 
ON I.inlCod = ISNULL(F.facInsInlCod, '')

WHERE (F.facFechaRectif IS NULL OR F.facFechaRectif>=@fHasta)
  AND (F.facLecActFec >= @fDesde AND F.facLecActFec < @fHasta)
  AND (@incilec IS NULL OR @incilec = '' OR I.inlCod IS NOT NULL))

SELECT SEMANA
	 , VALOR = COUNT(facCod)
FROM FACS
GROUP BY SEMANA

)
GO

