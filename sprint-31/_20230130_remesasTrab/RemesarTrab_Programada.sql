CREATE PROCEDURE dbo.RemesarTrab_Programada(@usrCod VARCHAR(10), @tskType SMALLINT, @tskNumber INT)
AS
UPDATE T
SET T.remTskType = @tskType
  , T.remTskNumber = @tskNumber
FROM dbo.remesasTrab AS T 
WHERE T.remUsrCod = @usrCod 
AND T.remTskType IS NULL
AND T.remTskNumber IS NULL;

GO