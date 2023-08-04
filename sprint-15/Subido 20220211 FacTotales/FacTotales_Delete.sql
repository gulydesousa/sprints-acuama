ALTER PROCEDURE dbo.FacTotales_Delete
@facturas tFacturasPK READONLY
AS 
	SET NOCOUNT ON;
	DECLARE @FACS AS tFacturasPK;

	--[01]Omitimos facturas si es el caso
	INSERT INTO @FACS
	SELECT FF.* 
	FROM @facturas AS FF
	LEFT JOIN dbo.facTotalesTrab AS FT
	ON  FF.facCod	=  FT.fcttCod 
	AND FF.facPerCod=  FT.fcttPerCod
	AND FF.facCtrCod=  FT.fcttCtrCod
	AND FF.facVersion= FT.fcttVersion
	WHERE FT.fcttCod IS NULL;


	--[11]Borramos lo que hay
	IF EXISTS (SELECT 1 FROM @FACS)
	BEGIN
		DELETE F 
		FROM dbo.facTotales AS F
		INNER JOIN @FACS AS FF
		ON  FF.facCod	 = F.fctCod 
		AND FF.facPerCod = F.fctPerCod 
		AND FF.facCtrCod = F.fctCtrCod
		--Si borramos una cabecera de factura se borra solo esa
		AND FF.facVersion = F.fctVersion;
	END
GO