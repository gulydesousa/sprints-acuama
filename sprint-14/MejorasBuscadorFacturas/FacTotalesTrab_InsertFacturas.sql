CREATE PROCEDURE dbo.FacTotalesTrab_InsertFacturas 
 @facturas AS tFacturasPK READONLY
AS

	--[v2.1]Si no está en la versión del buscador de facturas no hacemos nada
	IF NOT EXISTS(SELECT pgsValor FROM dbo.parametros WHERE pgsclave = 'FAC_APERTURA' AND pgsValor IS NOT NULL AND pgsValor>='2.1.0') RETURN;


	INSERT INTO dbo.facTotalesTrab(fcttCod, fcttCtrCod, fcttPerCod, fcttVersion) 
	SELECT F.facCod, F.facCtrCod, F.facPerCod, F.facVersion
	FROM @facturas AS F
	LEFT JOIN dbo.facTotalesTrab AS T
	ON F.facCod		= T.fcttCod
	AND F.facPerCod = T.fcttPerCod
	AND F.facCtrCod = T.fcttCtrCod
	AND F.facVersion = T.fcttVersion
	WHERE T.fcttCod IS NULL;

GO 