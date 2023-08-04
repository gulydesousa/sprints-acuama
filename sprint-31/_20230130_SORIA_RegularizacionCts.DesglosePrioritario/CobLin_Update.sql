
ALTER PROCEDURE [dbo].[CobLin_Update]
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
    
	
		--Para no asignar importe de cobro si la linea es liquidada:
		--EXEC @myError = CobLin_GenerarDesglosePrioritario 1, @cblScd, @cblPpag, @cblNum, @cblLin, NULL, NULL, NULL, NULL, NULL, NULL, 1;
		--*************************
		--BUGFIX:54221 [30/01/2023]
		--DECLARE @servicioLiquidado BIT = 1;
		--IF(@servicioLiquidado IS NULL OR @servicioLiquidado=0)
		--BEGIN
			DELETE FROM dbo.cobLinDes WHERE cldCblScd = @cblScd AND cldCblPpag = @cblPpag AND cldCblNum = @cblNum AND cldCblLin = @cblLin;
			
			INSERT INTO dbo.cobLinDes
			EXEC dbo.CobLinDes_GenerarDesglosePrioritario @cblScd, @cblPpag, @cblNum, @cblLin;	
		--END
		--ELSE
		--BEGIN
		--	EXEC @myError = CobLin_GenerarDesglosePrioritario 1, @cblScd, @cblPpag, @cblNum, @cblLin
		--													, NULL, NULL, NULL, NULL, NULL, NULL, @servicioLiquidado;
		--END
		--*************************

	IF @myError <> 0 GOTO ERROR
 
	COMMIT TRANSACTION
	RETURN 0

	ERROR:
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
		RETURN @myError 

GO


