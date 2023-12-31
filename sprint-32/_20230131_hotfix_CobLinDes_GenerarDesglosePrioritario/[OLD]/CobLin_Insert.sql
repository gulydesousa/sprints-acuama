ALTER PROCEDURE [dbo].[CobLin_Insert]
(
	 @cblScd  smallint
	,@cblPpag smallint
	,@cblNum int
	,@cblFacCod smallint
	,@cblPer varchar(6)
	,@cblFacVersion SMALLINT = NULL
	,@cblImporte money
	,@cblLin smallint output
	,@servicioLiquidado bit = NULL
)
AS
	SET NOCOUNT OFF;
	
	DECLARE @myError AS INT = 0
	
	BEGIN TRANSACTION
	
	SELECT @cblLin = ISNULL(max(cblLin),0) + 1 FROM coblin WHERE cblScd = @cblScd AND cblPpag = @cblPpag AND cblNum = @cblNum

	INSERT INTO coblin ([cblScd],[cblPpag],[cblNum],[cblLin],[cblFacCod],[cblPer], [cblFacVersion], [cblImporte])
    VALUES             (@cblScd,@cblPpag,@cblNum,@cblLin,@cblFacCod,@cblPer, @cblFacVersion, @cblImporte)
     
	SET @myError = @@ERROR IF @myError <> 0 GOTO ERROR   
    
	EXEC @myError = CobLin_GenerarDesglosePrioritario 1, @cblScd, @cblPpag, @cblNum, @cblLin, NULL, NULL, NULL, NULL, NULL, NULL, @servicioLiquidado

	IF @myError <> 0 GOTO ERROR   

	COMMIT TRANSACTION
	RETURN 0

	ERROR:
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
		RETURN @myError
	


