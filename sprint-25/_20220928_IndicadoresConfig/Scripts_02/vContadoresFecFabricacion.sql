--SELECT * FROM dbo.vContadoresFecFabricacion

CREATE VIEW dbo.vContadoresFecFabricacion
AS

WITH A AS(
SELECT C.conID
, conFecReg		= MIN(C.conFecReg)
, conAnyoFab	= MIN(C.conAnyoFab)
, conFecPrimIns = MIN(C.conFecPrimIns)
, ctcFec		= MIN(CC.ctcFec)
FROM contador AS C
LEFT JOIN ctrcon AS CC
ON CC.ctcCon = C.conID
AND CC.ctcOperacion='I'
AND COALESCE(C.conAnyoFab,C.conFecPrimIns) IS NULL
GROUP BY C.conID)

SELECT *
--Fecha por defecto para calcular la edad
, fechaFabricacion = CAST(COALESCE(conAnyoFab, conFecPrimIns, ctcFec, conFecReg) AS DATE)
FROM A 


GO