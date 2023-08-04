--SELECT * FROM dbo.vContratosUltimasLecturas WHERE ctrcod=6
ALTER VIEW dbo.vContratosUltimasLecturas 
AS


WITH F AS(
--Lectura por factura mas reciente	
SELECT
  id='FAC'
, F.facCtrCod
, F.facPerCod
, F.facCod
, F.facVersion
, F.facLecAct
, F.facLecActFec
, F.facConsumoFactura
, F.facConsumoReal
, PP.pgsvalor
, RN = ROW_NUMBER() OVER(PARTITION BY F.facCtrCod 
					ORDER BY IIF(PP.pgsvalor='BIAR', FORMAT(P.perFecFinPagoVol, 'yyyyMMdd'), facPercod) DESC, facVersion DESC)
FROM dbo.facturas  AS F
LEFT JOIN dbo.periodos AS P
ON P.percod = F.facPerCod
LEFT JOIN  dbo.parametros  AS PP
ON PP.pgsclave LIKE 'EXPLOTACION'
WHERE LEFT(F.facPerCod, 1) NOT IN ('0', '9') --Excluimos facturas que no son de consumo
AND (PP.pgsvalor<>'BIAR' OR F.facNumeroRectif IS NULL)

), C AS(
--Lectura por ultima version de contrato
SELECT id='CTR'
, C.ctrcod
, C.ctrversion
, C.ctrLecturaUlt
, C.ctrLecturaUltFec
, RN= ROW_NUMBER() OVER(PARTITION BY C.ctrcod ORDER BY C.ctrversion DESC)
FROM dbo.contratos AS C

),  CC AS(
--Lectura por OT de cambio de contador
SELECT id='CONCAM'
	, OT.otCtrCod
	, OT.otserscd
	, OT.otsercod
	, OT.otnum
	, C.conCamLecRet
	, C.conCamLecIns
	, C.conCamFecha
	, C.conCamConsumoAFacturar
	, RN= ROW_NUMBER() OVER(PARTITION BY OT.otCtrCod ORDER BY C.conCamFecha DESC)
FROM dbo.contadorCambio AS C
INNER JOIN dbo.ordenTrabajo AS OT 
ON  C.conCamOtSerCod = OT.otSerCod 
AND C.conCamOtSerScd = OT.otSerScd 
AND C.conCamOtNum = OT.otNum 
AND OT.otFecRechazo IS NULL

), RESULT AS(
--Union de las tres lecturas
SELECT tipo=F.id
, ctrCod = F.facCtrCod
, lectura = F.facLecAct
, lecturaFecha = F.facLecActFec
, consumo = F.facConsumoFactura
, [conCam.LecIns] = NULL
, [fac.ConsumoReal] = F.facConsumoReal
, [fac.PerCod]= facpercod
, [ctr.version] = NULL
, [ot.ID] = NULL
, [fac.ID] = FORMATMESSAGE('%i|%s|%i|%i', F.facCod, F.facPerCod, F.facCtrCod, F.facVersion)
FROM F WHERE RN=1

UNION ALL
SELECT  tipo=C.id
, ctrCod =C.ctrcod
, lectura = C.ctrLecturaUlt
, lecturaFecha =C.ctrLecturaUltFec
, consumo = NULL
, conCamLecIns = NULL
, consumoReal = NULL
, facPerCod= NULL
, ctrversion = C.ctrversion
, otId = NULL
, [fac.ID] = NULL
FROM C WHERE RN=1

UNION ALL
SELECT  tipo=CC.id
, ctrCod =CC.otCtrCod
, lectura = CC.conCamLecRet
, lecturaFecha =CC.conCamFecha
, consumo = CC.conCamConsumoAFacturar
, CC.conCamLecIns
, consumoReal = NULL
, facPerCod= NULL
, ctrversion = NULL
, otId = FORMATMESSAGE('%i|%i|%i', CC.otserscd, CC.otsercod, CC.otnum)
, [fac.ID] = NULL
FROM CC WHERE RN=1)

SELECT R.*
, C.ctrBaja
, C.ctrVersion
--RN=1: Es la lectura mas reciente de los tres tipos
, RN = ROW_NUMBER() OVER(PARTITION BY R.ctrCod 
						ORDER BY R.lecturaFecha DESC,
								--Si comparten fecha de lectura, ordenamos según el origen
								CASE R.tipo WHEN 'CONCAM' THEN 1 WHEN 'FAC' THEN 2 ELSE 3 END)
FROM RESULT AS R
LEFT JOIN [dbo].[vContratosUltimaVersion] AS C
ON C.ctrCod = R.ctrCod;
GO