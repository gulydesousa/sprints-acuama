CREATE TRIGGER trgFacLin_FacTotalesUpdate
ON dbo.faclin
AFTER INSERT, UPDATE, DELETE
AS
SET NOCOUNT ON;

--[v2.1]Si no está en la versión del buscador de facturas no hacemos nada
IF NOT EXISTS(SELECT pgsValor FROM dbo.parametros WHERE pgsclave = 'FAC_APERTURA' AND pgsValor IS NOT NULL AND pgsValor>='2.1.0') RETURN;

DECLARE @facturas AS tFacturasPK;

--[01]Facturas afectadas
INSERT INTO  @facturas
SELECT fclFacCod, fclFacPerCod, fclFacCtrCod, fclFacVersion FROM INSERTED
UNION 
SELECT fclFacCod, fclFacPerCod, fclFacCtrCod, fclFacVersion FROM DELETED;

--[99]Actualizar totales
EXEC dbo.FacTotales_Update @facturas;

GO


