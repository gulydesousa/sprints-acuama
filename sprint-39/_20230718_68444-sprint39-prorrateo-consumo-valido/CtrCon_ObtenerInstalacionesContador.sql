--EXEC CtrCon_ObtenerInstalacionesContador 50
--DECLARE  @ctrCod AS INT=5

CREATE PROCEDURE dbo.CtrCon_ObtenerInstalacionesContador @ctrCod AS INT
AS

--SELECT * FROM vCambiosContador WHERE ctrCod=@ctrCod;

SELECT I.*
, RN= V.[I.RN]
FROM vCambiosContador  AS V
LEFT JOIN ctrcon AS I
ON  V.ctrCod = I.ctcCtr
AND V.conId = I.ctcCon
AND V.[I.ctcFecReg] = I.ctcFecReg
WHERE V.ctrCod= @ctrCod
ORDER BY RN;

SELECT R.*
, RN= V.[I.RN]
FROM vCambiosContador  AS V
LEFT JOIN ctrcon AS R
ON  V.ctrCod = R.ctcCtr
AND V.conId = R.ctcCon
AND V.[R.ctcFecReg] = R.ctcFecReg
WHERE V.ctrCod= @ctrCod
ORDER BY RN;

GO