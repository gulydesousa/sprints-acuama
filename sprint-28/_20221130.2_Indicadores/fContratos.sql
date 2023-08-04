--SELECT * FROM Indicadores.fContratos ('20221001', '20221101', NULL, NULL)
--SELECT * FROM Indicadores.fContratos ('20221001', '20221101', NULL, NULL) WHERE ctssrv IS NOT NULL

--.D.....H..[....................]..............

---D--------[-----H--------------]---------------
---D--------[--------------------]---H-----------
---D--------[--------------------]--------------*
------------[-----D---------H----]---------------
------------[-----D--------------]---H-----------
------------[-----D--------------]--------------*

--..........[....................]...D.....H.....
--..........[....................]...D..........*

ALTER FUNCTION [Indicadores].[fContratos]
( @fDesde DATE
, @fHasta DATE
, @ctrUso INT
, @esDomiciliado BIT)
RETURNS TABLE
AS
RETURN(

WITH CTR AS(
SELECT C.ctrcod
, C.ctrversion
, C.ctrfecreg
, C.ctrfecanu
, C.ctrbaja
, C.ctrTitDocIden
, C.ctrPagDocIden
, Pagador = ISNULL(C.ctrPagDocIden, C.ctrTitDocIden)
, C.ctrIban
, C.ctrUsoCod
, RN = ROW_NUMBER() OVER (Partition BY C.ctrcod ORDER BY C.ctrversion DESC)
FROM dbo.contratos AS C 
WHERE (C.ctrfecreg  < @fHasta) AND 
	  (C.ctrfecanu IS NULL OR C.ctrfecanu >=@fDesde)

), AGUA AS(

SELECT CS.* 
--RN=1: Ultima ocurrencia del servicio en el rango de fechas
, RN = ROW_NUMBER() OVER(PARTITION BY CS.ctsctrcod ORDER BY CS.ctsfecalt)
FROM dbo.contratoservicio AS CS
INNER JOIN dbo.parametros AS P
ON pgsclave ='SERVICIO_AGUA' 
AND P.pgsvalor = CS.ctssrv
AND CS.ctsfecalt< @fHasta 
AND (CS.ctsfecbaj IS NULL OR CS.ctsfecbaj >= @fDesde)) 

SELECT C.ctrcod, C.ctrversion
, C.ctrfecreg, C.ctrfecanu, C.ctrbaja
, C.ctrIban
, C.ctrUsoCod
, C.ctrTitDocIden, C.ctrPagDocIden
, S.ctssrv, S.ctstar, S.ctsuds  
FROM CTR AS C
LEFT JOIN AGUA AS S
ON  C.ctrcod = S.ctsctrcod
AND S.RN=1 
AND C.RN=1
WHERE C.RN=1
AND (@ctrUso IS NULL OR C.ctrUsoCod = @ctrUso) 
AND (@esDomiciliado IS NULL OR (@esDomiciliado=1 AND C.ctrIban IS NOT NULL) OR (@esDomiciliado=0 AND C.ctrIban IS NULL)) 
)
GO

