CREATE PROCEDURE FacTotalesTrab_DeleteFacturas
 @facturas AS tFacturasPK READONLY
AS
--La eliminacion de los registros de esta tabla 
--dispara el trigger que actualiza los registros de las facturas DELETED
--tgrFacTotalesTrab_FacTotalesUpdate

DELETE T 
FROM dbo.facTotalesTrab AS T
INNER JOIN @facturas AS F
ON  T.fcttCod		= F.facCod
AND T.fcttCtrCod	= F.facCtrCod
AND T.fcttPerCod	= F.facPerCod
AND T.fcttVersion	= F.facVersion

GO