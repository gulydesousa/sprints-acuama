ALTER PROCEDURE [dbo].[CobLin_Delete]
(
	@cblScd smallint,
	@cblPpag smallint,
	@cblNum int,
	@cblLin smallint = NULL
)
AS
	SET NOCOUNT OFF;
	DECLARE @error INT

BEGIN TRANSACTION	

	/*PRIMERO SE DEBEN BORRAR LOS DESGLOSES DE LAS LINEAS*/
	EXEC @error = [CobLinDes_Delete] @cblScd, @cblPpag, @cblNum, @cblLin
	IF @error <> 0 GOTO HANDLE_ERROR

	
	/*EFECTOS NO-DOMICILIADOS: Se borra la relacion con el cobro en cobLinEfectosPendientes*/
	EXEC dbo.[CobLinEfectosPendientes_Delete] @cleCblScd=@cblScd, @cleCblPpag=@cblPpag, @cleCblNum=@cblNum, @cleCblLin=@cblLin;


	/*SI SE HAN BORRADO LOS DESGLOSES CORRECTAMENTE SE BORRARÁ LA LÍNEA*/
	DELETE FROM coblin 
	WHERE 
		cblScd = @cblScd AND 
		cblPpag=@cblPpag AND 
		cblNum=@cblNum AND 
		(cblLin=@cblLin OR @cblLin IS NULL)

	SET @error = @@error
	IF @error <> 0	GOTO HANDLE_ERROR

	COMMIT TRANSACTION
	RETURN 0

HANDLE_ERROR: 
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	RETURN @error

GO


