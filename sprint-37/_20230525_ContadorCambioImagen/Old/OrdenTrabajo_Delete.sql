ALTER PROCEDURE [dbo].[OrdenTrabajo_Delete]
(
	@Original_otserscd smallint,
	@Original_otsercod smallint,
	@Original_otnum int
	
)
AS
	SET NOCOUNT OFF;

SET NOCOUNT OFF;
	DECLARE @error int

	BEGIN TRANSACTION
	
		DELETE FROM dbo.OtImagen WHERE (otiOtSerScd = @Original_otserscd AND otiOtSerCod = @Original_otsercod AND otiOtNum = @Original_otnum);
		SET @error = @@error
		IF @error <> 0 GOTO HANDLE_ERROR;
		
		/*AL BORRAR UNA ORDEN DE TRABAJO IMPLICA QUE SE BORRARÁ EL OTMANCOM ASOCIADO CON SUS LÍNEAS*/
		DELETE FROM otManOpeAct WHERE (otoScd = @Original_otserscd AND otoSer = @Original_otsercod AND otoNum = @Original_otnum)
		SET @error = @@error
		IF @error <> 0
			GOTO HANDLE_ERROR
		
		DELETE FROM otManCom WHERE (otmScd = @Original_otserscd AND otmSer = @Original_otsercod AND otmNum = @Original_otnum)
		SET @error = @@error
		IF @error <> 0
			GOTO HANDLE_ERROR
		
		/*PRIMERO SE DEBEN BORRAR SUS otDatosValor si existen*/
		DELETE FROM otDatosValor WHERE (otdvOtSerScd = @Original_otserscd  AND otdvOtSerCod = @Original_otsercod AND otdvOtNum = @Original_otnum)
		SET @error = @@error
		IF @error <> 0
			GOTO HANDLE_ERROR
		
		/*PRIMERO SE DEBEN BORRAR SUS LINEAS*/
		DELETE FROM movmps WHERE (mmporiscd = @Original_otserscd  AND mmporiser = @Original_otsercod AND mmporinum = @Original_otnum)
		SET @error = @@error
		IF @error <> 0
			GOTO HANDLE_ERROR

		/*SI SE HAN BORRADO LAS LÍNEAS CORRECTAMENTE SE BORRARÁ LA CABECERA*/
		DELETE FROM [ordenTrabajo] WHERE (([otserscd] = @Original_otserscd) AND ([otsercod] = @Original_otsercod) AND ([otnum] = @Original_otnum))
		SET @error = @@error
		IF @error <> 0
			GOTO HANDLE_ERROR

	COMMIT TRANSACTION
	RETURN 0

	HANDLE_ERROR: 
		ROLLBACK TRANSACTION
		RETURN @error

GO


