--SELECT * FROM dbo.vContratoUltimaLectura ORDER BY ctrcod


ALTER VIEW dbo.vContratoUltimaLectura
AS

--Obtener ultima lectura
WITH FACS AS (
SELECT F.facCtrCod
	 , F.facPerCod
	 , F.facLecActFec
	 , F.facLecAct
	 , P.perFecFinPagoVol
	 , RN= ROW_NUMBER() OVER(PARTITION BY F.facCtrCod 
							 ORDER BY IIF(E.pgsvalor ='BIAR', perFecFinPagoVol, '') DESC,
									  IIF(E.pgsvalor<>'BIAR', facPercod, '') DESC)
FROM dbo.facturas AS F
INNER JOIN dbo.parametros AS E
ON E.pgsclave='EXPLOTACION'
LEFT JOIN dbo.periodos AS P
ON P.percod = F.facPerCod
WHERE F.facFechaRectif IS NULL
AND LEFT(F.facPerCod, 1) NOT IN ('0', '9')

), OTCC AS(

SELECT OT.otsercod, OT.otserscd, OT.otnum
, OT.otCtrCod
, CC.conCamFecha
, CC.conCamLecIns
, RN= ROW_NUMBER() OVER(PARTITION BY OT.otCtrCod ORDER BY  CC.conCamFecha DESC)
FROM dbo.ordenTrabajo AS OT
INNER JOIN dbo.contadorCambio AS CC
ON  CC.conCamOtSerCod = OT.otsercod
AND CC.conCamOtSerScd = OT.otserscd
AND CC.conCamOtNum = OT.otnum
AND OT.otFecRechazo IS NULL)

SELECT C.ctrcod, C.ctrversion
, F.facLecActFec, F.facLecAct
, C.ctrLecturaUltFec, C.ctrLecturaUlt
, O.conCamFecha, O.conCamLecIns

, [UltimaLectura] =  
	CASE --SI HAY FECHA DE LECTURA FACTURA --> HAY LECTURA:
	WHEN F.facLecActFec IS NOT NULL THEN ISNULL(F.facLecAct, 0) 
	--SI LA LECTURA ANTERIOR NO TIENE DATOS, LOS COJO DE LA ORDEN DE TRABAJO DE INSTALACIÓN DEL CONTADOR:
	WHEN O.conCamLecIns IS NOT NULL THEN O.conCamLecIns
	--SI LA LECTURA ANTERIOR NO TIENE DATOS, LOS COJO DEL CONTRATO:
	ELSE ISNULL(C.ctrLecturaUlt, 0) END

FROM vContratosUltimaVersion AS V
INNER JOIN dbo.contratos AS C
ON C.ctrcod = V.ctrCod
AND C.ctrversion = V.ctrVersion
LEFT JOIN FACS AS F
ON F.facCtrCod = C.ctrcod
AND F.RN=1
LEFT JOIN OTCC AS O
ON O.otCtrCod = C.ctrcod
AND O.RN = 1;

GO