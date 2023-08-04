ALTER PROCEDURE [dbo].[CobLin_Update_old]
(
	  @cblScd smallint
     ,@cblPpag smallint
     ,@cblNum int
     ,@cblLin smallint
     ,@cblFacCod smallint
     ,@cblPer varchar(6)
     ,@cblFacVersion SMALLINT = NULL
     ,@cblImporte money
)
AS
	SET NOCOUNT OFF;

	DECLARE @myError AS INT = 0
	
	BEGIN TRANSACTION

		UPDATE coblin
		   SET 
			   [cblFacCod] = @cblFacCod
			  ,[cblPer] = @cblPer
			  ,[cblImporte] = @cblImporte
			  ,[cblFacVersion] = @cblFacVersion 
		 WHERE (cblScd = @cblScd AND cblPpag=@cblPpag AND cblNum=@cblNum AND cblLin=@cblLin );
 
	SET @myError = @@ERROR IF @myError <> 0 GOTO ERROR   
    
	
	--EXEC @myError = CobLin_GenerarDesglose 1, @cblScd, @cblPpag, @cblNum, @cblLin
	--Para no asignar importe de cobro si la linea es liquidada:
	EXEC @myError = CobLin_GenerarDesglosePrioritario 1, @cblScd, @cblPpag, @cblNum, @cblLin, NULL, NULL, NULL, NULL, NULL, NULL, 1;


	IF @myError <> 0 GOTO ERROR
 
	COMMIT TRANSACTION
	RETURN 0

	ERROR:
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
		RETURN @myError 

GO


