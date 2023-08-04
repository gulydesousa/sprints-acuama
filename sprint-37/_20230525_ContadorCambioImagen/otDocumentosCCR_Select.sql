--EXEC otDocumentosCCR_Select 8409, 20775, '20180524 14:04:18.827', 0

CREATE PROCEDURE otDocumentosCCR_Select
  @ctcCtr INT
, @ctcCon INT
, @ctcFecReg DATETIME
, @indice TINYINT
AS

SET @ctcFecReg = DATEADD(ms, -DATEPART(ms, @ctcFecReg), @ctcFecReg);

WITH R AS(
SELECT CC.ctcCtr, CC.ctcCon, CC.ctcFecReg, CC.ctcOperacion, CC.ctcFec
	 , OT.otserscd, OT.otsercod, OT.otnum, OT.otottcod, OT.otCtrCod
	 , D.otdDocumento, D.otdTipoCodigo, D.otdDescripcion, D.otdID, D.otdFechaReg
	 , T.otdtDescripcion, T.otdtFormato, T.otdtMaxPorTipo
	 , RN = ROW_NUMBER() OVER(PARTITION BY CC.ctcCtr, CC.ctcCon, CC.ctcFecReg ORDER BY D.otdFechaReg DESC)
	 , CN = COUNT(D.otdID) OVER(PARTITION BY CC.ctcCtr, CC.ctcCon, CC.ctcFecReg)
FROM dbo.ctrcon AS CC
INNER JOIN dbo.ordenTrabajo AS OT
ON OT.otCtrCod = CC.ctcCtr
AND CC.ctcOperacion = 'R'
INNER JOIN parametros AS P
ON P.pgsclave = 'OT_TIPO_CC'
AND OT.otottcod = P.pgsvalor
INNER JOIN dbo.contadorCambio AS OTC
ON  OTC.conCamOtSerScd = OT.otserscd
AND OTC.conCamOtSerCod = OT.otsercod
AND OTC.conCamOtNum = OT.otnum
AND OTC.conCamFecha = CC.ctcFec
INNER JOIN dbo.otDocumentos AS D
ON D.otdSerScd = OT.otserscd
AND D.otdSerCod = OT.otsercod
AND D.otdNum = OT.otnum
INNER JOIN dbo.otDocumentoTipo AS T
ON T.otdtCodigo = D.otdTipoCodigo
AND T.otdtCodigo = 'CCR'
WHERE CC.ctcCtr= @ctcCtr AND CC.ctcCon=@ctcCon AND DATEADD(ms, -DATEPART(ms, CC.ctcFecReg), CC.ctcFecReg) = @ctcFecReg
)

SELECT * FROM R 
WHERE (@indice IS NULL) 
OR (@indice <= 0 AND RN=1) 
OR (@indice BETWEEN 1 AND CN AND RN=@indice) 
OR (@indice>CN AND RN=CN);

GO
