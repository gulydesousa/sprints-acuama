CREATE PROCEDURE dbo.FacTotales_Update
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
		AND FF.facCtrCod = F.fctCtrCod;

		
		--[99]Insertamos el re-calculo
		INSERT INTO dbo.facTotales(fctCod, fctCtrCod, fctPerCod, fctVersion, fctActiva
								 , fctBase, fctImpuestos, fctTotal
								 , fctFacturado, fctCobrado, fctEntregasCta
								 , fctTipoImp1, fctBaseTipoImp1
								 , fctTipoImp2, fctBaseTipoImp2
								 , fctTipoImp3, fctBaseTipoImp3
								 , fctTipoImp4, fctBaseTipoImp4
								 , fctTipoImp5, fctBaseTipoImp5
								 , fctTipoImp6, fctBaseTipoImp6)
		EXEC FacTotales_SelectPorFiltro @FACS;
END
GO