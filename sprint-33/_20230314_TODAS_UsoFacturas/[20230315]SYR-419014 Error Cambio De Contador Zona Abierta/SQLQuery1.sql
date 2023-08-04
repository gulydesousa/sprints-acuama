--SELECT distinct facpercod, faczoncod FROm facturas where facfecha is null order by facpercod DESC

--SELECT * FROM ORdentrabajo WHERE otCtrCod=5254
--SELECT * FROM contadorCambio WHERE conCamOtNum=15575
--SELECT C.ctrcod, ctrversion,ctrLecturaUlt, ctrLecturaUltFec FROM contratos AS C WHERE ctrcod=22484 ORDER BY ctrLecturaUltFec DESC

SELECT * 
--UPDATE F SET facLecAct=5254, facLecActFec='20220916 08:18:57.563'
FROM facturas AS  F WHERE facCtrcod=22464 AND facpercod='202304'


RETURN;
DECLARE @EXPLO AS VARCHAR(50);
SELECT @EXPLO = ISNULL(pgsValor,'') FROM dbo.parametros AS P WHERE pgsclave LIKE 'EXPLOTACION';

WITH F AS(

	SELECT  
	  id='FAC'
	, F.facCtrCod
	, F.facPerCod
	, F.facLecAct
	, F.facLecActFec
	, RN = ROW_NUMBER() OVER(PARTITION BY F.facCtrCod 
						ORDER BY IIF(@EXPLO='BIAR', FORMAT(P.perFecFinPagoVol, 'yyyyMMdd'), facPercod) DESC, facVersion DESC)
	FROM dbo.facturas  AS F
	LEFT JOIN dbo.periodos AS P
	ON P.percod = F.facPerCod
	WHERE LEFT(F.facPerCod, 1) NOT IN ('0', '9') --Excluimos facturas que no son de consumo
	AND (@EXPLO<>'BIAR' OR F.facNumeroRectif IS NULL)
)

SELECT * FROM F WHERE RN=1;

WITH C AS(
SELECT id='CTR'
, C.ctrcod
, C.ctrversion
, C.ctrLecturaUlt
, C.ctrLecturaUltFec
, RN= ROW_NUMBER() OVER(PARTITION BY C.ctrcod ORDER BY C.ctrversion DESC)
FROM dbo.contratos AS C)

SELECT * FROM C WHERE RN=1


WITH CC AS(
SELECT id='CONCAM'
	, OT.otCtrCod
	, C.conCamLecIns
	, C.conCamFecha
	, RN= ROW_NUMBER() OVER(PARTITION BY OT.otCtrCod ORDER BY C.conCamFecha DESC)
FROM dbo.contadorCambio AS C
INNER JOIN dbo.ordenTrabajo AS OT 
ON  C.conCamOtSerCod = OT.otSerCod 
AND C.conCamOtSerScd = OT.otSerScd 
AND C.conCamOtNum = OT.otNum 
AND OT.otFecRechazo IS NULL

)

SELECT * FROM CC WHERE RN=1