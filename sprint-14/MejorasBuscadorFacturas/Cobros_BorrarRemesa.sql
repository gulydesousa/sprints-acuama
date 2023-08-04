/*
--TRUNCATE TABLE errorlog
Para borrar todo lo referente a una remesa
	• @numeroRemesa
	SELECT facNumeroRemesa, facFechaRemesa, CN= COUNT(facNumeroRemesa) 
	FROM facturas 
	GROUP BY facNumeroRemesa, facFechaRemesa 
	ORDER BY facFechaRemesa DESC
	
	• @fechaRemesa
	SELECT DISTINCT FORMAT(facFechaRemesa,'yyyyMMdd HH:mm:ss.fff')
	FROM facturas 
	WHERE facNumeroRemesa=425
	
	• @usuarioRemesa
	SELECT DISTINCT cobUsr 
	FROM cobros 
	WHERE cobOrigen='remesa' AND cobConcepto LIKE '%425%'
*/

/*
DECLARE @numeroRemesa INT = 425
DECLARE @fechaRemesa DATETIME = '20220131 18:40:02.940'
DECLARE @usuarioRemesa VARCHAR(20)= 'gmdesousa'
DECLARE @soloConsulta BIT = 0
DECLARE @RESULT INT;

EXEC @RESULT = Cobros_BorrarRemesa @numeroRemesa, @fechaRemesa, @usuarioRemesa, @soloConsulta

SELECT [@RESULT] = @RESULT;

--Remesas con facturas y efectos pendientes
--SELECT * FROM efectosPendientes WHERE efePdteFecRemesada='2019-09-09 15:59:35.137'
--SELECT * FROM facturas WHERE facFechaRemesa IN(SELECT DISTINCT efePdteFecRemesada  FROM efectosPendientes)
*/

ALTER PROCEDURE [dbo].[Cobros_BorrarRemesa]
  @numeroRemesa INT
, @fechaRemesa DATETIME
, @usuarioRemesa VARCHAR(20)
, @soloConsulta BIT = 1
AS
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @cobConcepto VARCHAR(50) = FORMATMESSAGE('Remesa:%i.Fecha:%s', @numeroRemesa, FORMAT(@fechaRemesa, 'dd/MM/yyyy'));
	DECLARE @LOG AS TABLE(errNum INT, mensaje VARCHAR(1000), fecha DATETIME);
	DECLARE @params VARCHAR(250) = FORMATMESSAGE('REMESA: %i | Fecha: %s | Usuario: %s', @numeroRemesa, CONVERT(VARCHAR, @fechaRemesa, 21), @usuarioRemesa);

	DECLARE @RESULT INT = 0;

	SET @soloConsulta = ISNULL(@soloConsulta, 1);

	DECLARE @TranCounter INT;  
	SET @TranCounter = @@TRANCOUNT; 
	IF @TranCounter > 0 
		SAVE TRANSACTION ProcedureSave;  
    ELSE
		BEGIN TRANSACTION; 
	
	BEGIN TRY
		--[00]Borramos los cobros con select de lo borrado
		INSERT INTO @LOG VALUES (@@ERROR, '[0/5] INICIO', GETDATE());

		--[01]dbo.cobLinDes
		DELETE CLD 
		OUTPUT DELETED.*
		FROM dbo.cobros AS C
		INNER JOIN dbo.cobLin AS CL
		ON  C.cobScd = CL.cblScd
		AND C.cobPpag= CL.cblPpag
		AND C.cobNum = CL.cblNum
		INNER JOIN dbo.cobLinDes AS CLD
		ON  CL.cblScd = CLD.cldCblScd
		AND CL.cblPpag= CLD.cldCblPpag
		AND CL.cblNum = CLD.cldCblNum
		AND CL.cblLin = CLD.cldCblLin
		WHERE cobOrigen='Remesa'
		AND REPLACE(cobConcepto, ' ', '') = @cobConcepto
		AND cobUsr=@usuarioRemesa;

		INSERT INTO @LOG VALUES (@@ERROR, FORMATMESSAGE('[1/5] Se han descartado %i registros de dbo.coblindes', @@ROWCOUNT), GETDATE());
	
		--[02]dbo.cobLin
		CREATE TABLE #COBLIN(
		  cblScd SMALLINT
		, cblPpag SMALLINT
		, cblNum INT
		, cblLin SMALLINT
		, cblFacCod SMALLINT
		, cblPer VARCHAR(6)
		, cblImporte MONEY
		,cblFacVersion SMALLINT)

		INSERT INTO #COBLIN
		OUTPUT INSERTED.*
		SELECT CL.*
		FROM dbo.cobros AS C
		INNER JOIN dbo.cobLin AS CL
		ON  C.cobScd = CL.cblScd
		AND C.cobPpag= CL.cblPpag
		AND C.cobNum = CL.cblNum
		WHERE cobOrigen='Remesa'
		AND REPLACE(cobConcepto, ' ', '') = @cobConcepto
		AND cobUsr=@usuarioRemesa;

		DELETE CL
		FROM dbo.cobLin AS CL
		INNER JOIN #COBLIN AS TMP
		ON  CL.cblScd = TMP.cblScd
		AND CL.cblPpag= TMP.cblPpag
		AND CL.cblNum = TMP.cblNum
		AND CL.cblLin = TMP.cblLin;

		INSERT INTO @LOG VALUES (@@ERROR, FORMATMESSAGE('[2/5] Se han descartado %i registros de dbo.coblin', @@ROWCOUNT), GETDATE());

		--[03]dbo.cobros
		CREATE TABLE #COB(
		[cobScd] SMALLINT,
		[cobPpag] SMALLINT,
		[cobNum] INT,
		[cobFecReg] DATETIME,
		[cobUsr]  VARCHAR(10),
		[cobFec] DATETIME,
		[cobCtr] INT,
		[cobNom] VARCHAR(40),
		[cobDocIden]  VARCHAR(14),
		[cobImporte] MONEY,
		[cobMpc] SMALLINT,
		[cobMpcDato1] VARCHAR(40),
		[cobMpcDato2] VARCHAR(40),
		[cobMpcDato3] VARCHAR(40),
		[cobMpcDato4] VARCHAR(40),
		[cobMpcDato5] VARCHAR(40),
		[cobMpcDato6] VARCHAR(40),
		[cobConcepto] VARCHAR(50),
		[cobDevCod]  VARCHAR(4),
		[cobUsrContabilizacion] VARCHAR(10),
		[cobFecContabilizacion] DATETIME,
		[cobComCodigo] SMALLINT,
		[cobFecUltMod] DATETIME,
		[cobUsrUltMod] VARCHAR(10),
		[cobOrigen] VARCHAR(20))
		INSERT INTO #COB
		OUTPUT INSERTED.*
		SELECT C.*
		FROM dbo.cobros AS C
		WHERE cobOrigen='Remesa'
		AND REPLACE(cobConcepto, ' ', '') = @cobConcepto
		AND cobUsr=@usuarioRemesa;

		DELETE C 
		FROM dbo.cobros AS C
		INNER JOIN #COB AS TMP
		ON  C.cobScd = TMP.cobScd
		AND C.cobPpag= TMP.cobPpag
		AND C.cobNum = TMP.cobNum;

		INSERT INTO @LOG VALUES (@@ERROR, FORMATMESSAGE('[3/5] Se han descartado %i registros de dbo.cobros', @@ROWCOUNT), GETDATE());

		--[10]Quitamos los datos de la remesa de la factura con select de lo actualizado
		SELECT F.* 
		FROM dbo.facturas AS F 
		WHERE F.facFechaRemesa=@fechaRemesa
		AND F.facNumeroRemesa = @numeroRemesa;

		UPDATE F 
		SET F.facFechaRemesa=NULL, F.facNumeroRemesa=NULL 
		FROM dbo.facturas AS F 
		WHERE F.facFechaRemesa=@fechaRemesa
		AND F.facNumeroRemesa = @numeroRemesa;
	
		INSERT INTO @LOG VALUES (@@ERROR, FORMATMESSAGE('[4/5] Se han actualizado %i registros de dbo.facturas para quitar la referencia a la remesa [%i]', @@ROWCOUNT, @numeroRemesa), GETDATE());

		--[20]Quitamos los datos de la remesa de los efectos pendientes con select de lo actualizado
		UPDATE EP
		SET EP.efePdteFecRemesada=NULL, EP.efePdteUsrRemesada=NULL
		OUTPUT DELETED.*
		FROM dbo.efectospendientes AS EP
		WHERE EP.efePdteFecRemesada = @fechaRemesa
		AND EP.efePdteUsrRemesada=@usuarioRemesa;

		INSERT INTO @LOG VALUES (@@ERROR, FORMATMESSAGE('[5/5] Se han actualizado %i registros de dbo.efectospendientes para deshacer la remesa [%i]', @@ROWCOUNT, @numeroRemesa), GETDATE());

		IF (@soloConsulta = 1) 
		BEGIN
		-- RAISERROR with severity 11-19 will cause execution to jump to the CATCH block.  
		   RAISERROR ('Consultando Remesa' , 11, -1, 'CONSULTA REMESA');  
		END
	
		INSERT INTO @LOG VALUES (@@ERROR, FORMATMESSAGE('[FIN] REMESA BORRADA', @numeroRemesa, CONVERT(VARCHAR, @fechaRemesa, 121), @usuarioRemesa), GETDATE());
		SET @RESULT = 1;
		
		IF (@TranCounter = 0) COMMIT TRANSACTION;
	END TRY

	BEGIN CATCH
		DECLARE @error INT, @message VARCHAR(4000), @xstate INT;
        SELECT  @error = ERROR_NUMBER(),
                @message = ERROR_MESSAGE(), 
                @xstate = XACT_STATE();
        SELECT @error, @message, @xstate;

		IF (@xstate = -1)
            ROLLBACK TRANSACTION;
        IF (@xstate = 1 AND @TranCounter = 0)
            ROLLBACK TRANSACTION;
        IF (@xstate = 1 and @TranCounter > 0)
            ROLLBACK TRANSACTION ProcedureSave;


		DECLARE @msg VARCHAR(250) = IIF(@soloConsulta = 1, '[FIN] %s', '[ERROR] Rollback de los cambios: %s');


		INSERT INTO @LOG VALUES (@@ERROR, FORMATMESSAGE(@msg, CAST(ERROR_MESSAGE() AS VARCHAR(250))), GETDATE());
	END CATCH

	IF OBJECT_ID('tempdb.dbo.#COBLIN', 'U') IS NOT NULL 
	DROP TABLE #COBLIN;

	IF OBJECT_ID('tempdb.dbo.#COB', 'U') IS NOT NULL 
	DROP TABLE #COB;

	--*****************
	--LOG DE RESULTADOS
	DECLARE @explotacion VARCHAR(200);
	DECLARE @procedimiento VARCHAR(200);
	DECLARE @errNumLog INT;
	DECLARE @mensajeLog VARCHAR(1000);
	DECLARE @fechaLog VARCHAR(50);

	DECLARE cursorElement CURSOR FOR
	
	SELECT explotacion = P.pgsvalor  
	, procedimiento = OBJECT_NAME(@@PROCID)
	, errNum = L.errNum
	, mensaje = L.mensaje 
	, fecha = CONVERT(VARCHAR, L.fecha, 21)
	FROM @LOG AS L
	LEFT JOIN dbo.parametros AS P
	ON P.pgsclave='EXPLOTACION';

	OPEN cursorElement

	FETCH NEXT FROM cursorElement INTO @explotacion, @procedimiento, @errNumLog, @mensajeLog, @fechaLog;

	WHILE ( @@FETCH_STATUS = 0 )
	BEGIN
		EXEC dbo.ErrorLog_Insert @explotacion, @fechaLog, @errNumLog, NULL, NULL, @procedimiento, NULL, @mensajeLog, @params;

		FETCH NEXT FROM cursorElement INTO @explotacion, @procedimiento, @errNumLog, @mensajeLog, @fechaLog;
	END         
	CLOSE cursorElement
	DEALLOCATE cursorElement
	--*****************


	RETURN @RESULT;
GO


