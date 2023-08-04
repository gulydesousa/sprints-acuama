--DELETE FROM task_schedule WHERE tskUser='gmdesousa'

/*
DECLARE @user AS VARCHAR(10) = 'gmdesousa';
DECLARE @ExcCod VARCHAR(10) =  '000/901';
DECLARE @tskScheduledDate DATETIME = GETDATE();
DECLARE @afecha DATE = NULL;
DECLARE @tipoEnvio INT =2;

EXEC [dbo].[Task_Schedule_InformesExcel] @user, @ExcCod, @tskScheduledDate, @afecha, @tipoEnvio;

*/

ALTER PROCEDURE  [dbo].[Task_Schedule_InformesExcel]
@user AS VARCHAR(10) = 'admin', 
@ExcCod VARCHAR(10) =  '000/900',
@tskScheduledDate DATETIME = NULL, 
@aFecha DATE = NULL,
@tipoEnvio TINYINT = 0
AS
SET NOCOUNT ON;

--**********
--Parametros
DECLARE @filePath VARCHAR(500) = FORMATMESSAGE('~/Ficheros/Documentos/__personal__/InformesExcel/__inbox__/%s/' , CAST(newid() AS VARCHAR(50)))


DECLARE @filtro VARCHAR(10);
DECLARE @informe VARCHAR(25);
DECLARE @gestorDocumental VARCHAR(150);

SELECT @filtro=ExcFilCodGroup 
	 , @informe = ExcDescCorta
	 , @tipoEnvio = CASE @tipoEnvio --1:Si el tipo de envio es correo, lo enviaremos aunque la tarea no lo tenga habilidado
									WHEN 1 THEN 1 --IIF(ISNULL(E.ExcEnvioEmail, 0)=1, 1, 0)
									--2: Si el tipo de envio es FTP y no lo tiene configurado así el reporte, lo dejamos como informe excel 
									WHEN 2 THEN IIF(ISNULL(E.ExcFtpActivo, 0)=1 AND IIF(ISNULL(E.ExcFtpSite, '')<>'', 1, 0)=1, 2, 0)
									--3: Si no tiene configurado el envio FTP hacemos solo el envio por correo
									WHEN 3 THEN IIF(ISNULL(E.ExcFtpActivo, 0)=1 AND IIF(ISNULL(E.ExcFtpSite, '')<>'', 1, 0)=1, 3, 1) 
									ELSE 0 END
	, @gestorDocumental = FORMATMESSAGE('<span style=''color:yellow''>%s</span>', E.ExcFtpSite)
FROm ExcelConsultas AS E
WHERE ExcCod=@ExcCod;

			   
SET @tskScheduledDate = ISNULL(@tskScheduledDate, DATEADD(MINUTE, 1, GETDATE()));

SELECT @aFecha = ISNULL(@aFecha,  @tskScheduledDate)
	 , @gestorDocumental = IIF(@tipoEnvio IN (2,3), @gestorDocumental, '');

--**********
--Tarea
DECLARE @TSKPTYPE SMALLINT = 520;

DECLARE @insertedNumber INT;
DECLARE @insertedScheduledDate DATETIME;
DECLARE @return_value INT;
DECLARE @tskpId BIT = 0;

--**********
--ERRORES
DECLARE @ERR AS VARCHAR(MAX);

BEGIN TRY
		
	IF @filtro NOT IN ('0', '3') 
	BEGIN;
		RAISERROR ('Opción disponible solo para informes sin parametros.', 16 /* Severity*/, 1 /*State*/);
	END
	

	BEGIN TRAN
	--**********
	--Tarea
	EXEC @return_value = [dbo].[Task_Schedule_INSERT]
		@tskUser = @user,
		@tskType = @TSKPTYPE,
		@tskStatus = 1,
		@tskScheduledDate = @tskScheduledDate,
		@insertedNumber = @insertedNumber OUTPUT,
		@insertedScheduledDate = @insertedScheduledDate OUTPUT,
		@tskStop  = 0;
		
	--**********
	--Parametros
	INSERT INTO Task_Parameters (tskpUser, tskpType, tskpNumber, tskpName, tskpHumanizedName, tskpValue, tskpId, tskpOrder)
	VALUES (@user, @tskpType, @insertedNumber, 'filtro', NULL, @filtro, @tskpId, 1);
		
	INSERT INTO Task_Parameters (tskpUser, tskpType, tskpNumber, tskpName, tskpHumanizedName, tskpValue, tskpId, tskpOrder)
	VALUES
	(@user, @tskpType, @insertedNumber, 'codId', NULL, @ExcCod, @tskpId, 2),
	(@user, @tskpType, @insertedNumber, 'filePath', NULL, @filePath, @tskpId, 3),
    (@user, @tskpType, @insertedNumber, 'informe', '{{text:informe}}', @informe, @tskpId, 4);

	INSERT INTO Task_Parameters (tskpUser, tskpType, tskpNumber, tskpName, tskpHumanizedName, tskpValue, tskpId, tskpOrder)
	VALUES (@user, @tskpType, @insertedNumber, 'tipoEnvio', NULL, @tipoEnvio, @tskpId, 5);


	IF(@filtro='3')
	INSERT INTO Task_Parameters (tskpUser, tskpType, tskpNumber, tskpName, tskpHumanizedName, tskpValue, tskpId, tskpOrder)
	VALUES (@user, @tskpType, @insertedNumber, 'Fecha', '{{text:afecha}}', @aFecha, @tskpId, 6);
	
	IF(@gestorDocumental<>'')
	INSERT INTO Task_Parameters (tskpUser, tskpType, tskpNumber, tskpName, tskpHumanizedName, tskpValue, tskpId, tskpOrder)
	VALUES (@user, @tskpType, @insertedNumber, 'gestorDocumental', '{{text:gestorDocumental}}', @gestorDocumental, @tskpId, 7);
	
	
	COMMIT TRAN
	
END TRY
BEGIN CATCH
	
	SELECT @ERR = ERROR_MESSAGE();
	
	IF(@@TRANCOUNT > 0) ROLLBACK TRAN;

	 EXEC Trabajo.errorLog_Insert 'Task_Schedule_InformesExcel', @ExcCod, @ERR;  

	 
END CATCH
GO


