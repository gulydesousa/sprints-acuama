/*
DECLARE @fDesde DATE='20220101';
DECLARE @fHasta DATE = '20220201';

SELECT * FROM Indicadores.fContadorCambio (@fDesde, @fHasta)

*/

CREATE FUNCTION Indicadores.fContadorCambio 
( @fDesde DATE, @fHasta DATE)
RETURNS TABLE

--Copiamos la select del informe CD008_ListadoCambiosContadores.rdl
RETURN(
SELECT CC.conCamOtSerCod
	 , CC.conCamOtSerScd
	 , CC.conCamOtNum
FROM dbo.contadorCambio AS CC
	INNER JOIN ordenTrabajo ON conCamOtSerScd = otserscd AND conCamOtSerCod = otsercod AND conCamOtNum = otnum
	INNER JOIN contratos c1 ON otCtrCod = ctrcod AND ctrversion = (SELECT MAX(ctrversion) FROM contratos c2 WHERE c1.ctrcod = c2.ctrcod)
	INNER JOIN inmuebles ON inmcod = ctrinmcod
	INNER JOIN contador contadorIns ON contadorIns.conID = conCamConID
	INNER JOIN marcon marConIns ON marconIns.mcncod = contadorIns.conMcnCod
	LEFT JOIN ctrcon ctrConRet ON ctcCtr = otCtrCod AND ctcOperacion = 'R' AND ctcFec = conCamFecha
	INNER JOIN contador contadorRet ON contadorRet.conID = ctcCon
	INNER JOIN marcon marConRet ON marconRet.mcncod = contadorRet.conMcnCod
	INNER JOIN usos ON ctrUsoCod = usocod
WHERE
    (CC.conCamFecha >= @fDesde) AND (CC.conCamFecha <@fHasta))

GO


