ALTER PROCEDURE [dbo].[Cobros_GenerarRectificativoPorLiquidacion]
--PAR�METROS DE ENTRADA
@contrato int,
@periodo varchar(6),
@usuario varchar(10)

AS
BEGIN
	SET NOCOUNT OFF;
	
DECLARE @myError AS INT = 0
DECLARE @sociedad AS SMALLINT = NULL
DECLARE @ppago AS SMALLINT = NULL
DECLARE @cobrado AS MONEY = NULL
DECLARE @facCod AS SMALLINT = NULL
DECLARE @version AS SMALLINT = NULL
DECLARE @fechaLiq AS DATETIME = NULL
DECLARE @medpc AS SMALLINT = NULL

DECLARE cLiq CURSOR FOR	
	WITH COBS AS(
	SELECT C.cobScd
	, C.cobPpag
	, C.cobNum
	, fclFacCtrCod
	, fclFacPerCod
	, fclFacCod
	, fclFacVersion
	, fclNumLinea
	, fclFecLiq
	, fclTrfSvCod
	, fclTotal
	, cblImporte
	, COBRADO = SUM(cblImporte) OVER (PARTITION BY cobScd, cobPpag, cblFacCod, cobCtr, cblPer, fclfacversion, fclFecLiq)
	, RN =  ROW_NUMBER() OVER (PARTITION BY cobScd, cobPpag, cblFacCod, cobCtr, cblPer, fclfacversion, fclFecLiq  ORDER BY fclNumLinea)
	, DR = DENSE_RANK() OVER (PARTITION BY cobScd, cobPpag, cblFacCod, cobCtr, cblPer, fclfacversion ORDER BY  fclFecLiq DESC)
	--, CN =  COUNT(cobScd) OVER (PARTITION BY cobScd, cobPpag, cblFacCod, cobCtr, cblPer, fclfacversion, fclFecLiq )
	FROM dbo.cobros AS C
	INNER JOIN coblin AS CL 
	ON  CL.cblScd = cobScd 
	AND CL.cblPpag = cobPpag 
	AND CL.cblNum = cobNum
	AND C.cobCtr =  @contrato
	AND CL.cblPer = @periodo
	INNER JOIN dbo.faclin AS FL 
	ON  FL.fclFacCtrCod = C.cobCtr 
	AND FL.fclFacPerCod = CL.cblPer 
	AND FL.fclFacCod = CL.cblFacCod 
	--AND FL.fclFacVersion = CL.cblFacVersion
	AND fclFecLiq IS NOT NULL
	AND C.cobFecReg <= FL.fclFecLiq)


	SELECT cobScd, cobPpag, fclFacCtrCod, fclFacPerCod, fclFacCod, fclFecLiq, fclfacversion, COBRADO
	FROM COBS
	WHERE RN=1 AND DR=1

OPEN cLiq 

	BEGIN TRANSACTION
	
	FETCH NEXT FROM cLiq INTO @sociedad, @ppago, @contrato, @periodo, @facCod, @fechaLiq, @version, @cobrado
	WHILE @@FETCH_STATUS = 0 BEGIN
		DECLARE @fechaReg DATETIME = GETDATE()
		DECLARE @cobNum AS INT
		SELECT @medpc = pgsvalor FROM parametros WHERE pgsclave ='MEDIO_PAGO_RECTIFICATIVOS'
	
		EXEC @myError = Cobros_Insert 1, @ppago, @usuario, @fechaLiq, @contrato, NULL, NULL, 0, @medpc, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @cobNum OUTPUT, 'Rectificativo', @fechaLiq 
		IF @myError <> 0 GOTO ERROR
		
		DECLARE @importeLinea AS MONEY = -@cobrado
		DECLARE @cblLin AS SMALLINT = NULL
		DECLARE @cblLinAux SMALLINT = NULL
		
		EXEC @myError = CobLin_Insert @sociedad, @ppago, @cobNum, @facCod, @periodo, @version, @importeLinea, @cblLin OUTPUT 
		IF @myError <> 0 GOTO ERROR
		ELSE SET @cblLinAux = @cblLin
		
		--Borrar los desgloses de la l�nea del cobro, para volver a generarlos por c�digo correctamente
		EXEC @myError = CobLinDes_Delete @sociedad, @ppago, @cobNum, @cblLin, NULL, NULL, NULL, NULL 
		IF @myError <> 0 GOTO ERROR
		
		EXEC @myError = CobLin_GenerarDesglosePrioritario 1, @sociedad, @ppago, @cobNum, @cblLinAux, NULL, @fechaLiq, NULL, NULL, NULL, NULL, 1, 1
		IF @myError <> 0 GOTO ERROR

		EXEC @myError = CobLin_Insert @sociedad, @ppago, @cobNum, @facCod, @periodo, @version, @cobrado, @cblLin OUTPUT 
		IF @myError <> 0 GOTO ERROR
		ELSE SET @cblLinAux = @cblLin
		
		--Borrar los desgloses de la l�nea del cobro, para volver a generarlos por c�digo correctamente
		EXEC @myError = CobLinDes_Delete @sociedad, @ppago, @cobNum, @cblLin, NULL, NULL, NULL, NULL 
		IF @myError <> 0 GOTO ERROR

		--Generar de nuevo los desgloses borrados anteriormente
		EXEC @myError = CobLin_GenerarDesglosePrioritario 1, @sociedad, @ppago, @cobNum, @cblLin, NULL, @fechaLiq, NULL, NULL, NULL, NULL, 1, NULL
		IF @myError <> 0 GOTO ERROR
		
		FETCH NEXT FROM cLiq INTO @sociedad, @ppago, @contrato, @periodo, @facCod, @fechaLiq, @version, @cobrado
END
CLOSE cLiq
DEALLOCATE cLiq

COMMIT TRANSACTION
RETURN 0
--Manejar error y salir
ERROR:
	CLOSE cLiq
	DEALLOCATE cLiq
	ROLLBACK TRANSACTION
END	



GO


