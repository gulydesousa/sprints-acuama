CREATE PROCEDURE FacTotalesTrab_Delete
  @facCod INT = NULL
, @facPerCod VARCHAR(6) = NULL
, @facCtrCod INT = NULL
, @facVersion INT = NULL
AS
--La eliminacion de los registros de esta tabla 
--dispara el trigger que actualiza los registros de las facturas DELETED
--tgrFacTotalesTrab_FacTotalesUpdate

DELETE FROM dbo.facTotalesTrab
WHERE (@facCod IS NULL OR fcttCod = @facCod)
  AND (@facCtrCod IS NULL OR fcttCtrCod = @facCtrCod)
  AND (@facPerCod IS NULL OR fcttPerCod = @facPerCod)
  AND (@facVersion IS NULL OR fcttVersion = @facVersion);

GO