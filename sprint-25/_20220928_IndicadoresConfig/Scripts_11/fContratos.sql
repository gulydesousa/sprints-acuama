--SELECT * FROM Indicadores.fContratos ('20220101', '20220131', NULL, 1)

CREATE FUNCTION Indicadores.fContratos
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
	  (C.ctrfecanu IS NULL OR C.ctrfecanu >=@fDesde) AND
	  (@ctrUso IS NULL OR C.ctrUsoCod = @ctrUso) AND
	  (@esDomiciliado IS NULL OR (@esDomiciliado=1 AND C.ctrIban IS NOT NULL) OR (@esDomiciliado=0 AND C.ctrIban IS NULL)) 

) 

SELECT * FROM CTR WHERE RN=1
)
GO


--.D.....H..[....................]..............

---D--------[-----H--------------]---------------
---D--------[--------------------]---H-----------
---D--------[--------------------]--------------*
------------[-----D---------H----]---------------
------------[-----D--------------]---H-----------
------------[-----D--------------]--------------*

--..........[....................]...D.....H.....
--..........[....................]...D..........*