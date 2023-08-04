--DROP VIEW dbo.vPerzonaMensual

CREATE VIEW dbo.vPerzonaMensual
AS

SELECT DISTINCT P.przcodper 
, P.przfPeriodoD
, P.przfPeriodoH
FROM dbo.perzona AS P
WHERE MONTH(P.przfPeriodoH) = MONTH(P.przfPeriodoD);

GO