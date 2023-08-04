--DROP PROCEDURE OtDocumentos_Insert
--SELECT * FROM otDocumentos ORDER BY otdNum
--SELECT * FROM otDocumentoTipo


--EXEC OtDocumentos_Insert 1, 80, 22995, 'CCR', '*****', 'NUEVO'

CREATE PROCEDURE OtDocumentos_Insert
	  @otSerScd SMALLINT 
	, @otSerCod SMALLINT
	, @otNum INTEGER 
	, @otdTipoCodigo VARCHAR(5)
	
	, @otdDocumento IMAGE	
	, @otdDescripcion VARCHAR(250) = NULL	
AS 

	SET NOCOUNT ON;
		
	BEGIN TRY
		BEGIN TRAN;
		
		--Hacemos espacio, borrando el mas antiguo
		WITH DOC AS(
		SELECT * 
		--Ordenamos del mas reciente al mas antiguo
		, RN = ROW_NUMBER() OVER (PARTITION BY otdSerScd, otdSerCod, otdNum, otdTipoCodigo ORDER BY otdFechaReg DESC) 
		FROM dbo.otDocumentos AS D
		INNER JOIN dbo.otDocumentoTipo AS T
		ON T.otdtCodigo = D.otdTipoCodigo
		WHERE otdSerScd = @otSerScd
		AND otdSerCod = @otSerCod
		AND otdNum = @otNum
		AND otdTipoCodigo = @otdTipoCodigo)

		
		DELETE DD
		FROM DOC AS D
		INNER JOIN dbo.otDocumentos AS DD
		ON D.otdID = DD.otdID		 
		AND D.otdSerScd= DD.otdSerScd
		AND D.otdSerCod = DD.otdSerCod  
		AND D.otdNum = DD.otdNum 
		AND D.otdTipoCodigo=DD.otdTipoCodigo
		WHERE D.RN>=D.otdtMaxPorTipo;
		
		--Insertamos
		INSERT INTO dbo.otDocumentos(otdSerScd, otdSerCod, otdNum, otdTipoCodigo, otdDocumento, otdDescripcion)
		SELECT @otSerScd, @otSerCod, @otNum, @otdTipoCodigo, @otdDocumento, @otdDescripcion;


		COMMIT TRAN;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
	END CATCH
	
GO
