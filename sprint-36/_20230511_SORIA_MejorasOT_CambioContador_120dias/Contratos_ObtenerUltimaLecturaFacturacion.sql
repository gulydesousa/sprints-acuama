
/*
DECLARE @ctrCod INT= 147;
DECLARE @ctrVersion SMALLINT = NULL;
DECLARE @lectura INT = NULL;
DECLARE @fechaLectura DATETIME = NULL;

EXEC [Contratos_ObtenerUltimaLecturaFacturacion] @ctrCod, @ctrVersion, @lectura OUT, @fechaLectura OUT;

SELECT @lectura,  @fechaLectura

*/
ALTER PROCEDURE [dbo].[Contratos_ObtenerUltimaLecturaFacturacion]
@ctrCod INT,
@ctrVersion SMALLINT = NULL,
@lectura INT = NULL OUT,
@fechaLectura DATETIME = NULL OUT
AS
SET NOCOUNT ON;
--********************************************
--Sprint#35: "Bug para recuperar la ultima lectura en la apertura y ampliacion. Versión inicial"
--Contratos_ObtenerUltimaLecturaFacturacion: Va por origen (Factura, Contador Cambio, Contrato)
--Contratos_ObtenerUltimaLectura: Va por fecha de lectura
--********************************************

--INICIALIZAR VALORES DE SALIDA
SET @lectura = NULL
SET @fechaLectura = NULL

--OBTENGO LA LECTURA ANTERIOR Y LA FECHA DE LA LECTURA ANTERIOR
IF (SELECT ISNULL(pgsValor,'') FROM parametros WHERE pgsclave LIKE 'EXPLOTACION') = 'BIAR' BEGIN
	SELECT TOP 1 @lectura = facLecAct, @fechaLectura = facLecActFec
	FROM facturas f
	WHERE facCtrCod = @ctrCod
	AND LEFT(facPerCod, 1) <> '0' AND LEFT(facPerCod, 1) <> '9' --CÓDIGOS DE PERIODO RESERVADOS
	AND facNumeroRectif IS NULL -- QUITAR RECTIFICADAS
	ORDER BY (SELECT perFecFinPagoVol from periodos WHERE percod = facPerCod) DESC
END ELSE BEGIN
	SELECT TOP 1 @lectura = facLecAct, @fechaLectura = facLecActFec
	FROM facturas f
	WHERE facCtrCod = @ctrCod
	AND LEFT(facPerCod, 1) <> '0' AND LEFT(facPerCod, 1) <> '9' --CÓDIGOS DE PERIODO RESERVADOS
	ORDER BY facPercod DESC, facVersion DESC
END

--SI HAY FECHA DE LECTURA --> HAY LECTURA
IF @fechaLectura IS NOT NULL SET @lectura = ISNULL(@lectura, 0)

--SI LA LECTURA ANTERIOR NO TIENE DATOS, LOS COJO DE LA ORDEN DE TRABAJO DE INSTALACIÓN DEL CONTADOR
IF(@lectura IS NULL)
	SELECT TOP 1 @fechaLectura = conCamFecha, @lectura = conCamLecIns
	FROM contadorCambio
	INNER JOIN dbo.ordenTrabajo AS OT 
	ON  conCamOtSerCod = OT.otSerCod 
	AND conCamOtSerScd = OT.otSerScd 
	AND conCamOtNum = OT.otNum 
	AND OT.otFecRechazo IS NULL
	WHERE otCtrCod = @ctrCod
	ORDER BY conCamFecha DESC

--SI LA LECTURA ANTERIOR NO TIENE DATOS, LOS COJO DEL CONTRATO
IF(@lectura IS NULL)
	SELECT @lectura = ISNULL(ctrLecturaUlt,0), @fechaLectura = ctrLecturaUltFec
	FROM contratos c
	WHERE ctrCod = @ctrCod AND
		-- Cogemos la versión que nos llega por parámetro
		(ctrVersion = @ctrVersion OR 
		-- Si no nos llega versión por parámetro cogemos la última versión del contrato
		(@ctrVersion IS NULL AND ctrVersion = (SELECT MAX(ctrVersion) FROM contratos c2 WHERE c2.ctrCod = c.ctrCod)))

GO


