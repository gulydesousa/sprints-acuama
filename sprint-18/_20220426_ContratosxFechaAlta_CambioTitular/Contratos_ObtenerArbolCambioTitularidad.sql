/*
DECLARE @fechaDesde DATE	= NULL
DECLARE @fechaHasta DATE	= NULL

EXEC dbo.Contratos_ObtenerArbolCambioTitularidad
*/

CREATE PROCEDURE dbo.Contratos_ObtenerArbolCambioTitularidad
  @fechaDesde DATE	= NULL
, @fechaHasta DATE	= NULL
AS 
IF(@fechaHasta IS NOT NULL)
SET @fechaHasta = DATEADD(DAY, 1, @fechaHasta);


WITH CTRS AS(
--Contratos
SELECT C.ctrCod
, C.ctrversion
, C.ctrNuevo
, C.ctrinmcod
, C.ctrTitNom
, C.ctrbaja
, C.ctrfecanu
, RN = ROW_NUMBER() OVER(PARTITION BY C.ctrCod ORDER BY C.ctrversion DESC) 
, ctrfecini = CAST(MIN(C.ctrfecini) OVER(PARTITION BY C.ctrCod) AS DATE)
FROM dbo.contratos AS C 
WHERE C.ctrfecini IS NOT NULL

)
--Ultima version
SELECT C.ctrCod
, C.ctrversion
, C.ctrNuevo
, C.ctrfecini
, C.ctrinmcod
, C.ctrTitNom
, C.ctrbaja
, C.ctrfecanu
INTO #CTR
FROM CTRS AS C
WHERE RN=1;

--Contratos por cambio de titular
SELECT DISTINCT ctrNuevo 
INTO #CTIT
FROM #CTR 
WHERE ctrNuevo IS NOT NULL;


WITH  CTE AS(
SELECT C.ctrCod
, C.ctrNuevo
, C.ctrfecini
, C.ctrinmcod
, C.ctrTitNom
, C.ctrbaja
, C.ctrfecanu
, Raiz = C.ctrCod
, nivel = 0
FROM #CTR AS C
LEFT JOIN #CTIT AS T
ON  C.ctrcod = T.ctrNuevo 
WHERE T.ctrNuevo IS NULL
AND (@fechaDesde IS NULL OR C.ctrfecini>=@fechaDesde)
AND (@fechaHasta IS NULL OR C.ctrfecini< @fechaHasta)

UNION ALL 
SELECT C.ctrCod
	 , C.ctrNuevo
	 , C.ctrfecini
	 , C.ctrinmcod
	 , C.ctrTitNom
	 , C.ctrbaja
	 , C.ctrfecanu
	 , Raiz = T.Raiz
	 , nivel = nivel + 1 
FROM #CTR AS C
INNER JOIN CTE AS T
ON T.ctrNuevo = C.ctrcod
)


SELECT * FROM CTE ORDER BY nivel;

IF OBJECT_ID('tempdb..#CTR') IS NOT NULL DROP TABLE #CTR;   
IF OBJECT_ID('tempdb..#CTIT') IS NOT NULL DROP TABLE #CTIT;   

GO
