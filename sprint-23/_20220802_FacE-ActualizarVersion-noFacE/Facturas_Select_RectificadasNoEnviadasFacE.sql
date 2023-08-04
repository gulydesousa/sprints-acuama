/*

DECLARE @facturas AS [dbo].[tFacturasPK]
INSERT INTO @facturas (facCod, facPerCod, facCtrCod, facVersion) 
VALUES(1, '210103', 105, 2)

EXEC dbo.Facturas_SelectRectificadasNoEnviadasFacE @facturas;
*/
ALTER PROCEDURE dbo.Facturas_SelectRectificadasNoEnviadasFacE
   @facturas AS [dbo].[tFacturasPK] READONLY
 , @ctrFace BIT = NULL
 AS


SELECT F0.* 
FROM @facturas AS F
INNER JOIN dbo.facturas AS FF
ON  F.facCod	= FF.facCod
AND F.facPerCod = FF.facPerCod
AND F.facCtrCod = FF.facCtrCod
AND F.facVersion = FF.facVersion
--La factura está pendiente
AND FF.facEnvSERES = 'P'
INNER JOIN dbo.facturas AS F0
ON  F0.facCod = F.facCod
AND F0.facPerCod = F.facPerCod
AND F0.facCtrCod = F.facCtrCod
--Versiones previas sin estado enviado a face
AND F0.facVersion < F.facVersion
AND (F0.facEnvSERES IS NULL OR F0.facEnvSERES <> 'E')
--***********
INNER JOIN dbo.contratos AS C
ON C.ctrcod = F0.facCtrCod
AND C.ctrversion = F0.facCtrVersion
AND (@ctrFace IS NULL OR C.ctrFace = @ctrFace);

GO