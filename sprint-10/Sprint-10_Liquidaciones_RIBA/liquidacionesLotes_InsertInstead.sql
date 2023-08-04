--DROP TRIGGER [dbo].[liquidacionesLote_UpadateInstead]

CREATE TRIGGER [dbo].[liquidacionesLotes_InsertInstead]
ON [dbo].[liquidacionesLotes]
INSTEAD OF INSERT
AS
BEGIN
	SET NOCOUNT ON;
	
	WITH DATA AS(
	SELECT liqLoteTipoId = I.liqLoteTipoId
		 , liqLoteNum = ISNULL(T.liqLoteNum, 0)
		 , liqLoteUsr = I.liqLoteUsr
		 , liqLoteParametros = I.liqLoteParametros

		 , RN = ROW_NUMBER() OVER (PARTITION BY  I.liqLoteTipoId ORDER BY T.liqLoteFecha DESC)
	FROM INSERTED AS I
	LEFT JOIN dbo.liquidacionesLotes AS T
	ON I.liqLoteTipoId = T.liqLoteTipoId)

	INSERT INTO dbo.liquidacionesLotes (liqLoteTipoId, liqLoteNum, liqLoteUsr, liqLoteParametros)	
	SELECT liqLoteTipoId
		 , IIF(liqLoteNum>=9999, 0, liqLoteNum+1)
		 , liqLoteUsr
		 , liqLoteParametros
	FROM DATA WHERE RN=1;
END

GO


