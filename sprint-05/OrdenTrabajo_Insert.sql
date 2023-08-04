ALTER PROCEDURE [dbo].[OrdenTrabajo_Insert]
(
	@otserscd smallint,
	@otsercod smallint,
	@otfsolicitud datetime = null,
	@otfrealizacion datetime = null,
	@otfcierre datetime = null,
	@otottcod varchar(4) = null,
	@otdessolicitud varchar(80) = null,
	@otdesrealizacion varchar(80) = null,
	@otobs varchar(500) = null,
	@otiptcod varchar(14) = null,
	@otcotcod varchar(6) = null,
	@otsubcotcod varchar(6) = null,
	@otalmcod varchar(4) = null,
	@otPrvCod varchar(3) = null,
	@otPobCod varchar(3) = null,
	@otdireccion varchar(200) = null,
	@otCliCod int=null,
	@otCtrCod int=null,
	@otCtrVersion smallint=null,
	@otUsuSolicitud varchar(10)=null,
	@otUsuRealizacion varchar(10)=null,
	@otUsuCierre varchar(10)=null,
	@otEplCod smallint =null,
	@otEplCttCod smallint =null,
	@otDepCod int =null,
	@otMtcCod int =null,
	@otObsRealizacion varchar(500)=null,
	@otFechaReg datetime =null,
	@otFPrevision datetime=null
	, @otPrioridad SMALLINT = NULL
	, @otFecRechazo DATETIME = NULL
	, @otUsuRechazo VARCHAR(10)=NULL
	, @otnumNuevo int OUTPUT
)
AS
	SET NOCOUNT OFF;

	DECLARE @myError AS INT
	DECLARE @TRANCOUNT AS INT SET @TRANCOUNT = @@TRANCOUNT
	IF @TRANCOUNT = 0 BEGIN TRAN T_OrdenTrabajo_Insert ELSE SAVE TRAN T_OrdenTrabajo_Insert

	SET @otnumNuevo = NULL

	-- OBTENER NUMERADOR
	UPDATE series set sernumfra = ISNULL(sernumfra, 0) + 1 WHERE sercod = @otsercod AND serscd = @otserscd
	SELECT @otnumNuevo = sernumfra FROM series WHERE sercod = @otsercod AND serscd = @otserscd

	--INSERTAR EN OT
	INSERT INTO [ordenTrabajo]
		([otserscd], [otsercod], [otnum], 
		 [otfsolicitud], [otfrealizacion], [otfcierre], 
		 [otottcod], 
		 [otdessolicitud], 
		 [otdesrealizacion], 
		 [otobs], 
		 [otiptcod], 
		 [otcotcod], 
		 [otsubcotcod], 
		 [otalmcod], 
		 [otPrvCod], [otPobCod], [otdireccion],
		 [otCliCod], [otCtrCod], [otCtrVersion],
		 [otUsuSolicitud], [otUsuRealizacion], [otUsuCierre],
		 [otEplCod], [otEplCttCod], [otDepCod],
		 [otMtcCod], [otObsRealizacion], [otFechaReg], [otFPrevision]
		 , [otPrioridad]
		 , [otFecRechazo]
		 , [otUsuRechazo]) 
	VALUES (@otserscd, @otsercod, @otnumNuevo, 
			@otfsolicitud, @otfrealizacion, @otfcierre, 
			@otottcod, 
			@otdessolicitud, 
			@otdesrealizacion, 
			@otobs, 
			@otiptcod, 
			@otcotcod, 
			@otsubcotcod, 
			@otalmcod, 
			@otPrvCod, @otPobCod, @otdireccion,
			@otCliCod, @otCtrCod, @otCtrVersion,
			@otUsuSolicitud, @otUsuRealizacion, @otUsuCierre,
			@otEplCod, @otEplCttCod, @otDepCod,
			@otMtcCod, @otObsRealizacion, ISNULL(@otFechaReg,GETDATE()), @otFPrevision
			, @otPrioridad
			, @otFecRechazo
			, @otUsuRechazo);

	SET @myError = @@error 
	IF @myError <> 0 GOTO ERROR

	IF @TRANCOUNT = 0
		COMMIT TRAN T_OrdenTrabajo_Insert

	RETURN 0

ERROR:
	ROLLBACK TRAN T_OrdenTrabajo_Insert
	RETURN @myError

GO


