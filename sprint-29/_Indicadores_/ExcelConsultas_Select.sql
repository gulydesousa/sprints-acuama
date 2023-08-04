
--EXEC ExcelConsultas_Select

ALTER PROCEDURE [dbo].[ExcelConsultas_Select]
@id varchar(8) = NULL
AS 
	SET NOCOUNT ON; 

	SELECT ExcCod
	, ExcDescCorta
	, ExcDescLarga
	, ExcFilCodGroup
	, ExcConsulta
	, ExcPlantilla
	, ExcAyuda
	, ExcLogo
	, ExcEnvioEmail
	, ExcFtpSite
	--Solo se intenta enviar por FTP desde producción
	, ExcFtpActivo =  IIF(@@SERVERNAME NOT IN ('SQLPRO42') , CAST(0 AS BIT), ExcFtpActivo)
	FROM ExcelConsultas
	WHERE @id IS NULL OR ExcCod=@id


GO


