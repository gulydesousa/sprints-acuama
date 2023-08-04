/*

SELECT COUNT(ctcCon) FROM dbo.fContratos_ContadoresInstalados('20230201') WHERE ctcCon IS NOT NULL

DECLARE @fecha AS DATE = '20230201';

SELECT * FROM Indicadores.fContadoresInstalados(@fecha)

*/

CREATE FUNCTION Indicadores.fContadoresInstalados(@fecha DATE)
RETURNS TABLE AS
RETURN
(
WITH A AS(
SELECT conId
, ctrcod
, conNumSerie
--RN=1: Para quedarnos con la ultima instalacion del contrato
, RN= ROW_NUMBER() OVER(PARTITION BY ctrcod ORDER BY  [I.ctcFec] DESC)
FROM dbo.vCambiosContador
WHERE [I.ctcFec] < @fecha
AND ([R.ctcFec] IS NULL OR [R.ctcFec] >= @fecha)
) 

SELECT conId
, ctrCod
, conNumSerie
FROM A WHERE RN = 1
)

GO