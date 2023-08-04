CREATE TRIGGER trgCoblin_FacTotalesUpdate
ON dbo.coblin
AFTER INSERT, UPDATE, DELETE
AS
SET NOCOUNT ON;

--[2.1]Si no está en la versión del buscador de facturas no hacemos nada
IF NOT EXISTS(SELECT pgsValor FROM dbo.parametros WHERE pgsclave = 'FAC_APERTURA' AND pgsValor IS NOT NULL AND pgsValor>='2.1.0') RETURN;

DECLARE @facturas AS tFacturasPK;

--[01]Facturas afectadas
INSERT INTO  @facturas

SELECT CL.cblFacCod, CL.cblPer, C.cobCtr, ISNULL(CL.cblFacVersion, 1)
FROM dbo.cobros AS C
INNER JOIN INSERTED AS CL
ON CL.cblScd = C.cobScd
AND CL.cblPpag = C.cobPpag
AND CL.cblNum = C.cobNum
UNION
SELECT CL.cblFacCod, CL.cblPer, C.cobCtr, ISNULL(CL.cblFacVersion, 1)
FROM dbo.cobros AS C
INNER JOIN DELETED AS CL
ON CL.cblScd = C.cobScd
AND CL.cblPpag = C.cobPpag
AND CL.cblNum = C.cobNum;

--[99]Actualizar totales
EXEC dbo.FacTotales_Update @facturas;

GO


