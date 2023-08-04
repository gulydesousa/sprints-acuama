
CREATE PROCEDURE [dbo].[LiquidacionesLote_RegistrarID]
  @liqLoteTipoId INT
, @liqLoteUsr VARCHAR(10)
, @parametros VARCHAR(500)
AS
BEGIN 

DECLARE @IDLOTE INT = 0;

INSERT INTO dbo.liquidacionesLotes(liqLoteTipoId, liqLoteUsr, liqLoteParametros) VALUES(@liqLoteTipoId, @liqLoteUsr, @parametros);

SELECT TOP(1) @IDLOTE = liqLoteNum
FROM dbo.liquidacionesLotes
WHERE liqLoteTipoId=@liqLoteTipoId
ORDER BY liqLoteFecha DESC;

RETURN @IDLOTE;
END


--DROP PROCEDURE LiquidacionesLote_ID
GO


