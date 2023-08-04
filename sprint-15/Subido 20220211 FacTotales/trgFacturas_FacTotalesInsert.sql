ALTER TRIGGER trgFacturas_FacTotalesInsert
ON [dbo].[facturas]
AFTER INSERT, UPDATE
AS
SET NOCOUNT ON;

--[v2.1]Si no está en la versión del buscador de facturas no hacemos nada
IF NOT EXISTS(SELECT pgsValor FROM dbo.parametros WHERE pgsclave = 'FAC_APERTURA' AND pgsValor IS NOT NULL AND pgsValor>='2.1.0') RETURN;

DECLARE @facturas AS tFacturasPK;

--[01]Facturas afectadas
INSERT INTO  @facturas
SELECT facCod, facPerCod, facCtrCod, facVersion FROM INSERTED;

--[99]Actualizar totales
EXEC dbo.FacTotales_Update @facturas;

GO