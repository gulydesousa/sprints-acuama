/*

DECLARE @zona VARCHAR(4) = 'NA03'
DECLARE @periodo VARCHAR(6) = '202301'
DECLARE @fechaPeriodoDesde DATETIME = '20230101'
DECLARE @fechaPeriodoHasta DATETIME = '20230331'
----***************************
DECLARE @tskUser VARCHAR(10) = 'admin'	
DECLARE @tskType SMALLINT = 40
DECLARE @tskNumber INT = 6
----***************************
DECLARE @facturasInsertadas AS INT
DECLARE @facturasError AS INT
DECLARE @otrosErrores AS VARCHAR(3) 

EXEC dbo.Tasks_Facturas_AperturaPorContrato @zona, @periodo, @fechaPeriodoDesde, @fechaPeriodoHasta, @tskUser, @tskType, @tskNumber, @facturasInsertadas OUT,@facturasError OUT , @otrosErrores OUT

*/

/*
DECLARE @u INT
EXEC Facturas_EliminarApertura '202301', 'NA03', @u OUT ;
*/

--[01]Quitamos la retirada de contador
SELECT * 
--DELETE C 
FROM ctrcon AS C WHERE ctcCtr=5365 AND ctcOperacion='R'

--[02]Rehabilitamos los servicios
SELECT * 
--UPDATE C SET ctsfecbaj=NULL
FROM contratoServicio AS C WHERE ctsctrcod=5365 AND ctsfecbaj='20230131'

--[03]Deshacemos el cambio de titula
SELECT * 
--UPDATE C SET ctrfecanu=NULL,	ctrusrcodanu=NULL, ctrbaja=0, ctrFecSolBaja=NULL, ctrNuevo=NULL, ctrLecturaUltFec='20221219', ctrLecturaUlt='342'
--UPDATE C SET ctrLecturaUltFec='20221219', ctrLecturaUlt='342'
FROM contratos AS C WHERE C.ctrcod=5365 and ctrversion=3

--[04] Borramos la facturación de la baja
SELECT * 
--DELETE L
FROM facSIIDesgloseFactura AS L WHERE fclSiiFacCtrCod=5365 AND fclSiiFacPerCod IN ('000002', '202301')

SELECT * 
--DELETE L
FROM facSII AS L WHERE fcSiiFacCtrCod=5365 AND fcSiiFacPerCod IN ('000002', '202301')


SELECT * 
--DELETE FL
FROM faclin AS FL where fclFacCtrCod=5365 AND fclFacPerCod IN ('000002', '202301')

SELECT * 
--DELETE FL
FROM facturas AS FL where facCtrCod=5365 AND facPerCod IN ('000002', '202301')

SELECT CC.* 
--DELETE CC
FROM ordenTrabajo 
INNER JOIN contadorCambio AS CC
ON otnum=conCamOtNum
WHERE otCtrCod=5365 AND otfcierre IS NULL


SELECT * 
--DELETE OT
FROM ordenTrabajo AS OT
WHERE otCtrCod=5365 AND otfcierre IS NULL




DECLARE @ctrCod INT = 5365;

DECLARE @LECTURAS AS TABLE(id VARCHAR(10), fechaLectura DATETIME, lectura INT);

DECLARE @EXPLO AS VARCHAR(50);
SELECT @EXPLO = ISNULL(pgsValor,'') FROM dbo.parametros AS P WHERE pgsclave LIKE 'EXPLOTACION';
--*******************************
--FACTURA (lectura, fecha lectura)
IF (@EXPLO = 'BIAR')
BEGIN
	INSERT INTO @LECTURAS(id, lectura, fechaLectura)
	SELECT TOP 1 
	id='FAC', lectura = facLecAct, fechaLectura = facLecActFec
	FROM facturas f
	WHERE facCtrCod = @ctrCod
	AND LEFT(facPerCod, 1) <> '0' AND LEFT(facPerCod, 1) <> '9' --CÓDIGOS DE PERIODO RESERVADOS
	AND facNumeroRectif IS NULL -- QUITAR RECTIFICADAS
	ORDER BY (SELECT perFecFinPagoVol from periodos WHERE percod = facPerCod) DESC
END 
ELSE 
BEGIN
	INSERT INTO @LECTURAS(id, lectura, fechaLectura)
	SELECT TOP 1 
	  id='FAC'
	, lectura = facLecAct
	, fechaLectura = facLecActFec
	FROM facturas f
	WHERE facCtrCod = @ctrCod
	AND LEFT(facPerCod, 1) <> '0' AND LEFT(facPerCod, 1) <> '9' --CÓDIGOS DE PERIODO RESERVADOS
	ORDER BY facPercod DESC, facVersion DESC
END

--*******************************
--CONTRATO (lectura, fecha lectura)
INSERT INTO @LECTURAS(id, lectura, fechaLectura)
SELECT id='CTR'
	, lectura=C.ctrLecturaUlt
	, fechaLectura=C.ctrLecturaUltFec
FROM dbo.contratos AS C 
INNER JOIN dbo.vContratosUltimaVersion AS V
ON  C.ctrcod = V.ctrCod
AND C.ctrversion = V.ctrVersion
AND C.ctrcod=@ctrCod;

--*******************************
--CTRCON  (lectura, fecha lectura)
INSERT INTO @LECTURAS(id, lectura, fechaLectura)
SELECT TOP 1 
	  id='CONCAM'
	, lectura=CC.conCamLecIns
	, fechaLectura=CC.conCamFecha
FROM dbo.contadorCambio AS CC
INNER JOIN dbo.ordenTrabajo AS OT 
ON  conCamOtSerCod = OT.otSerCod 
AND conCamOtSerScd = OT.otSerScd 
AND conCamOtNum = OT.otNum 
AND OT.otFecRechazo IS NULL
WHERE otCtrCod = @ctrCod
ORDER BY conCamFecha DESC;


SELECT *
FROM @LECTURAS ORDER BY IIF(fechaLectura IS NULL, 1, 0) ASC, fechaLectura DESC;

SELECT *
FROM dbo.contadorCambio AS CC
INNER JOIN dbo.ordenTrabajo AS OT 
ON  conCamOtSerCod = OT.otSerCod 
AND conCamOtSerScd = OT.otSerScd 
AND conCamOtNum = OT.otNum 
AND OT.otFecRechazo IS NULL
WHERE otCtrCod = 5365
ORDER BY conCamFecha DESC;
