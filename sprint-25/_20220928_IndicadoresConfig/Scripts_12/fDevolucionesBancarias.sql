
--SELECT * FROM Indicadores.fDevolucionesBancarias ('20220101', '20220131')

CREATE FUNCTION [Indicadores].[fDevolucionesBancarias]
( @fDesde DATE
, @fHasta DATE
)
RETURNS TABLE
AS
RETURN(

SELECT C.cobNum, C.cobScd, C.cobPpag, C.cobFec
FROM dbo.cobros AS C 
WHERE C.cobDevCod IS NOT NULL 
  AND C.cobFec >=@fDesde 
  AND C.cobFec <@fHasta
)
GO
