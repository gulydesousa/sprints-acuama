CREATE PROCEDURE FacTotalesTrab_Insert 
  @facCod INT
, @facPerCod VARCHAR(6)
, @facCtrCod INT
, @facVersion INT
AS
	--[v2.1]Si no está en la versión del buscador de facturas no hacemos nada
	IF NOT EXISTS(SELECT pgsValor FROM dbo.parametros WHERE pgsclave = 'FAC_APERTURA' AND pgsValor IS NOT NULL AND pgsValor>='2.1.0') RETURN;

	BEGIN TRY
	
	INSERT INTO dbo.facTotalesTrab(fcttCod, fcttCtrCod, fcttPerCod, fcttVersion) 
	VALUES(@facCod, @facCtrCod, @facPerCod, @facVersion);
	
	END TRY

	BEGIN CATCH

	END CATCH

GO 