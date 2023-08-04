
CREATE TRIGGER trgFacTotalesTrab_FacTotalesUpdate
ON dbo.FacTotalesTrab
AFTER DELETE
AS
SET NOCOUNT ON;

--[v2.1]Si no está en la versión del buscador de facturas no hacemos nada
IF NOT EXISTS(SELECT pgsValor FROM dbo.parametros WHERE pgsclave = 'FAC_APERTURA' AND pgsValor IS NOT NULL AND pgsValor>='2.1.0') RETURN;

DECLARE @facturas AS tFacturasPK;

--[01]Facturas afectadas
INSERT INTO  @facturas
SELECT fcttCod, fcttPerCod, fcttCtrCod, fcttVersion FROM DELETED;

--[11]Borramos lo que hay
IF EXISTS (SELECT 1 FROM @facturas)
BEGIN

	DELETE F 
	FROM dbo.facTotales AS F
	INNER JOIN @facturas AS FF
	ON  FF.facCod	  = F.fctCod 
	AND FF.facPerCod   = F.fctPerCod 
	AND FF.facCtrCod   = F.fctCtrCod;

	--SELECT * FROM @facturas;

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
	EXEC FacTotales_SelectPorFiltro @facturas;
END

GO


