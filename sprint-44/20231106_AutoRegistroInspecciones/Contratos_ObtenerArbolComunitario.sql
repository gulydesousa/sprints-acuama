/*
DECLARE @codZona AS INT = 3;
DECLARE @raiz AS INT = 25848;
EXEC dbo.Contratos_ObtenerArbolComunitario @codZona, @raiz
*/
CREATE PROCEDURE [dbo].[Contratos_ObtenerArbolComunitario]
  @codZona AS VARCHAR(4)
, @raiz AS INT = NULL
AS
SET NOCOUNT ON;

SELECT *
INTO #CTR
FROM dbo.vContratosUltimaVersion AS V
WHERE V.ctrzoncod=@codZona;


WITH CTE AS(
SELECT C.ctrCod
	 , C.ctrComunitario
	 , C.calculoComunitario
	 , nivel = 0
	 , raiz  = C.ctrCod
FROM #CTR AS C
WHERE C.numHijosComunitarios>0
AND( 
(@raiz IS NULL AND C.ctrComunitario IS NULL)
OR 
(@raiz IS NOT NULL AND C.ctrCod = @raiz))


UNION ALL 
SELECT C.ctrCod
	 , C.ctrComunitario
	 , C.calculoComunitario
	 , nivel = nivel + 1 
	 , raiz =  T.raiz 
FROM #CTR AS C
INNER JOIN CTE AS T
ON C.ctrComunitario = T.ctrCod)


SELECT * 
FROM CTE
ORDER BY nivel, ctrCod;

IF OBJECT_ID('tempdb..#CTR') IS NOT NULL DROP TABLE #CTR;   

GO