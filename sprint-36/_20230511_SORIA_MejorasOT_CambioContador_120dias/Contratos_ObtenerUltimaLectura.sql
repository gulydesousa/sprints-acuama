
/*
DECLARE @ctrCod INT= 147;
DECLARE @ctrVersion SMALLINT = NULL;
DECLARE @lectura INT = NULL;
DECLARE @fechaLectura DATETIME = NULL;

EXEC Contratos_ObtenerUltimaLectura @ctrCod, @ctrVersion, @lectura OUT, @fechaLectura OUT;

SELECT @lectura,  @fechaLectura

*/
ALTER PROCEDURE [dbo].[Contratos_ObtenerUltimaLectura]
@ctrCod INT,
@ctrVersion SMALLINT = NULL,
@lectura INT = NULL OUT,
@fechaLectura DATETIME = NULL OUT
AS
SET NOCOUNT ON;
--********************************************
--Sprint#34: "Mejoras Pantalla cambio de contador Soria"
--********************************************
--Sprint#35: "Bug para recuperar la ultima lectura en la apertura y ampliacion."
--Contratos_ObtenerUltimaLectura: Va por fecha de lectura
--Contratos_ObtenerUltimaLecturaFacturacion: Version original
--********************************************

EXEC [Contratos_ObtenerUltimaLecturaFacturacion] @ctrCod, @ctrVersion, @lectura OUT, @fechaLectura OUT;
RETURN


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
AND CC.conCamLecIns IS NOT NULL
ORDER BY conCamFecha DESC;


SELECT TOP 1
	   @lectura=lectura
	 , @fechaLectura=fechaLectura 
FROM @LECTURAS ORDER BY IIF(fechaLectura IS NULL, 1, 0) ASC, fechaLectura DESC;

--**************
--*** D E B U G 
--**************
--SELECT * FROM @LECTURAS ORDER BY IIF(fechaLectura IS NULL, 1, 0) ASC, fechaLectura DESC;


RETURN;

GO


