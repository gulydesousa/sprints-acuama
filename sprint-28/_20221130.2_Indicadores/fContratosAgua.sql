/*
DECLARE @fDesde DATE='20220201';
DECLARE @fHasta DATE = '20220301';
DECLARE @usos VARCHAR(100) = '1,2,4,6'

SELECT * FROM [Indicadores].[fContratosAgua](@fDesde, @fHasta, @usos)

*/

CREATE FUNCTION [Indicadores].[fContratosAgua]
( @fDesde DATE
, @fHasta DATE
, @usos VARCHAR(100) = NULL)
RETURNS TABLE
AS
RETURN(

WITH U AS(
SELECT DISTINCT(value) FROM dbo.Split(@usos, ',')

), CTR AS(
SELECT C.ctrcod
, C.ctrversion
, C.ctrUsoCod
, usoCod = U.value
--RN=1 : Para quedarnos con la ultima version en el rango de fechas
, RN = ROW_NUMBER() OVER (Partition BY C.ctrcod ORDER BY C.ctrversion DESC)
FROM dbo.contratos AS C 
LEFT JOIN U 
ON C.ctrUsoCod = U.value
WHERE (C.ctrfecreg  < @fHasta) AND 
	  (C.ctrfecanu IS NULL OR C.ctrfecanu >=@fDesde)

), AGUA AS(
SELECT C.ctrcod
, C.ctrversion
, C.ctrUsoCod
, C.usoCod
, CS.ctstar
--RN=1: Ultima ocurrencia del servicio en el rango de fechas
, RN = ROW_NUMBER() OVER(PARTITION BY CS.ctsctrcod ORDER BY CS.ctsfecalt)
FROM CTR AS C
INNER JOIN dbo.contratoservicio AS CS
ON  C.RN = 1
AND C.ctrcod = CS.ctsctrcod
AND CS.ctssrv = 1
AND CS.ctsfecalt< @fHasta 
AND (CS.ctsfecbaj IS NULL OR CS.ctsfecbaj >= @fDesde)) 

--Ultina version del agua activa del contrato en el rango de fechas con el uso seleccionado
SELECT ctrcod, ctrversion, ctrUsoCod, ctstar
FROM AGUA AS A
WHERE RN=1 
AND (@usos IS NULL OR usoCod IS NOT NULL )
 
)
GO

