CREATE PROCEDURE [dbo].[OT_GenerarOtMtto]
--PARAMETROS DE ENTRADA
@otSociedad AS SMALLINT,
@otSerie AS SMALLINT,

@tipoComponente AS INT = NULL,
@componente AS VARCHAR(150) = NULL,
@operacion AS INT = NULL,
@fechaMtto AS DATETIME = NULL,

@otUsuCodSolicitud AS VARCHAR(10) = NULL,

@otTipo AS VARCHAR(4) = NULL,
@otcotcod AS VARCHAR(6) = NULL,
@otsubcotcod AS VARCHAR(6) = NULL,
@otImputacion AS VARCHAR(14) = NULL,
@otAlmacen AS VARCHAR(4) = NULL,

@otFechaPrevision AS DATETIME = NULL,
@otFechaSolicitud AS DATETIME = NULL,
@otFechaRealizacion AS DATETIME = NULL,
@otFechaCierre AS DATETIME = NULL,

@otDescripcionSolicitud AS VARCHAR(80) = NULL,
@otObservaciones AS VARCHAR(500) = NULL,
@otDireccion AS VARCHAR(200) = NULL,
@otDescripcionRealizacion AS VARCHAR(80) = NULL

, @otObservacionesRealizacion AS VARCHAR(MAX) = NULL
, @otUsuCodRealizacion AS VARCHAR(10) = NULL
, @otUsuCodCierre AS VARCHAR(10) = NULL

, @otEplCod SMALLINT = NULL
, @otEplCttCod SMALLINT = NULL
, @otDepCod INT = NULL
, @otMtcCod INT = NULL

--PARAMETROS DE SALIDA
, @otNum AS INT OUT
AS

BEGIN
SET NOCOUNT ON;

DECLARE @fecActual AS DATETIME = getdate()

DECLARE @myError AS INT	
SET @otNum = 0

BEGIN TRY

	BEGIN TRAN

	--Insertar OT y OtManCom
	SET @otNum = NULL
	EXEC @myError = OtManCom_Insert @otSociedad, @otSerie, @otNum OUTPUT, @componente, @tipoComponente, @operacion, @fecActual, @fechaMtto, @otUsuCodSolicitud, @otObservaciones, @otTipo, @otcotcod, @otsubcotcod, @otImputacion, @otAlmacen,
		@otFechaPrevision, @otFechaSolicitud, @otFechaRealizacion, @otFechaCierre, @otDescripcionSolicitud, @otObservaciones, @otDireccion, @otDescripcionRealizacion
		, @otObservacionesRealizacion
		, @otUsuCodRealizacion
		, @otUsuCodCierre
		, @otEplCod, @otEplCttCod, @otDepCod, @otMtcCod

	IF @myError <> 0
	BEGIN 
	   RAISERROR('Error inserción OT Componente', 1, 1);
	END
	
	--Insertar las líneas de la OT
	INSERT INTO otManOpeAct(otoScd, otoSer, otoNum, otoLin, otoOpeDes, otoOpePedVal, otoOpeValor)
	SELECT @otSociedad, @otSerie, @otNum, opaLin, opaDes, opaPedValor, NULL
	FROM operacionesAct
	WHERE opaCod = @operacion
	
	IF @myError <> 0 
	BEGIN 
	   RAISERROR('Error inserción OT Componente Línea', 1, 1);
	END

	COMMIT

END TRY
	
BEGIN CATCH
		
	DECLARE @erlNumber INT = (SELECT ERROR_NUMBER());
	DECLARE @erlSeverity INT = (SELECT ERROR_SEVERITY());
	DECLARE @erlState INT = (SELECT ERROR_STATE());
	DECLARE @erlProcedure nvarchar(128) = (SELECT ERROR_PROCEDURE());
	DECLARE @erlLine int = (SELECT ERROR_LINE());
	DECLARE @erlMessage nvarchar(4000) = (SELECT ERROR_MESSAGE());
	
	DECLARE @erlParams varchar(500) = NULL;
		
	DECLARE @expl VARCHAR(20) = NULL
	SET @expl = (SELECT pgsvalor FROM parametros WHERE pgsclave = 'EXPLOTACION')

	ROLLBACK

	BEGIN TRAN
		EXEC ErrorLog_Insert  @expl, 'OT_GenerarOTMtto', @erlNumber, @erlSeverity, @erlState, @erlProcedure, @erlLine, @erlMessage, @erlParams	
	COMMIT TRAN
	
END CATCH

END

GO


