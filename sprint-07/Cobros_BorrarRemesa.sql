/*
DECLARE @numeroRemesa INT = 44
DECLARE @fechaRemesa DATETIME = '20210907 15:32:02'
DECLARE @usuarioRemesa VARCHAR(20)= 'admin'
DECLARE @soloConsulta BIT = 1
DECLARE @RESULT INT;

EXEC @RESULT = Cobros_BorrarRemesa @numeroRemesa, @fechaRemesa, @usuarioRemesa, @soloConsulta

SELECT [@RESULT] = @RESULT;

SELECT TOP 25 * FROM errorLog order by erlFecha DESC, erlProcedimiento DESC, erlMessage DESC

--Remesas con facturas y efectos pendientes
--SELECT * FROM efectosPendientes WHERE efePdteFecRemesada='2019-09-09 15:59:35.137'
--SELECT * FROM facturas WHERE facFechaRemesa IN(SELECT DISTINCT efePdteFecRemesada  FROM efectosPendientes)
*/
CREATE PROCEDURE dbo.Cobros_BorrarRemesa
  @numeroRemesa INT
, @fechaRemesa DATETIME
, @usuarioRemesa VARCHAR(20)
, @soloConsulta BIT = 1
AS

SET NOCOUNT ON;

DECLARE @cobConcepto VARCHAR(50) = FORMATMESSAGE('Remesa:%i.Fecha:%s', @numeroRemesa, FORMAT(@fechaRemesa, 'dd/MM/yyyy'));
DECLARE @LOG AS TABLE(errNum INT, mensaje VARCHAR(1000), fecha DATETIME);
DECLARE @params VARCHAR(250) = FORMATMESSAGE('REMESA: %i | Fecha: %s | Usuario: %s', @numeroRemesa, CONVERT(VARCHAR, @fechaRemesa, 21), @usuarioRemesa);

DECLARE @RESULT INT = 0;

SET @soloConsulta = ISNULL(@soloConsulta, 1);

BEGIN TRAN

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
	DELETE CL 
	OUTPUT DELETED.*
	FROM dbo.cobros AS C
	INNER JOIN dbo.cobLin AS CL
	ON  C.cobScd = CL.cblScd
	AND C.cobPpag= CL.cblPpag
	AND C.cobNum = CL.cblNum
	WHERE cobOrigen='Remesa'
	AND REPLACE(cobConcepto, ' ', '') = @cobConcepto
	AND cobUsr=@usuarioRemesa;

	INSERT INTO @LOG VALUES (@@ERROR, FORMATMESSAGE('[2/5] Se han descartado %i registros de dbo.coblin', @@ROWCOUNT), GETDATE());

	--[03]dbo.cobros
	DELETE C 
	OUTPUT DELETED.*
	FROM dbo.cobros AS C
	WHERE cobOrigen='Remesa'
	AND REPLACE(cobConcepto, ' ', '') = @cobConcepto
	AND cobUsr=@usuarioRemesa;

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
	COMMIT;
	SET @RESULT = 1;
END TRY

BEGIN CATCH
	ROLLBACK;

	DECLARE @msg VARCHAR(250) = IIF(@soloConsulta = 1, '[FIN] %s', '[ERROR] Rollback de los cambios: %s')
	INSERT INTO @LOG VALUES (@@ERROR, FORMATMESSAGE(@msg, CAST(ERROR_MESSAGE() AS VARCHAR(250))), GETDATE());
	
END CATCH

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