/*
DECLARE @contratosPK AS dbo.tContratosPK;

INSERT INTO @contratosPK VALUES (1, 1), (2, 1);

EXEC dbo.Contratos_ObtenerUltimaLecturaContratos @contratosPK

*/

ALTER PROCEDURE dbo.Contratos_ObtenerUltimaLecturaContratos(@contratosPK AS dbo.tContratosPK READONLY)

AS 

WITH CTR AS(
SELECT DISTINCT ctrCod FROM @contratosPK

), FACS AS (
--RN=1: Ultima factura de cada contrato
SELECT F.facCtrCod
	 , F.facPerCod
	 , F.facLecActFec
	 , F.facLecAct
	 , P.perFecFinPagoVol
	 , RN= ROW_NUMBER() OVER(PARTITION BY F.facCtrCod 
							 ORDER BY IIF(E.pgsvalor ='BIAR', perFecFinPagoVol, '') DESC,
									  IIF(E.pgsvalor<>'BIAR', facPercod, '') DESC)
FROM CTR
INNER JOIN dbo.facturas AS F
ON F.facCtrCod = CTR.ctrCod
INNER JOIN dbo.parametros AS E
ON E.pgsclave='EXPLOTACION'
LEFT JOIN dbo.periodos AS P
ON P.percod = F.facPerCod
WHERE F.facFechaRectif IS NULL
AND LEFT(F.facPerCod, 1) NOT IN ('0', '9')

), OTCC AS(
--RN=1: Ultimo Cambio de contador de cada contrato
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
AND OT.otFecRechazo IS NULL
INNER JOIN CTR
ON CTR.ctrcod = OT.otCtrCod)

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
INNER JOIN CTR
ON CTR.ctrcod = V.ctrCod

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