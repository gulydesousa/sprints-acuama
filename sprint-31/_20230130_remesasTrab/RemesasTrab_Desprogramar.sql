CREATE PROCEDURE dbo.RemesasTrab_Desprogramar
@remUsrCod VARCHAR(10),
@remCtrCod INT, 
@remPerCod VARCHAR(6),
@remFacCod INT,
@remEfePdteCod INT
AS

UPDATE T
SET T.[remTskType] = NULL, T.[remTskNumber]=NULL
FROM [dbo].[remesasTrab] AS T
WHERE T.remUsrCod = @remUsrCod 
  AND T.remCtrCod = @remCtrCod
  AND T.remPerCod =@remPerCod
  AND T.remFacCod = @remFacCod
  AND T.remEfePdteCod= @remEfePdteCod;

GO
