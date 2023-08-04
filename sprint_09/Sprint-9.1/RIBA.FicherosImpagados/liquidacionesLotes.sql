CREATE TABLE dbo.liquidacionesLotes(
  liqLoteId [INT] IDENTITY(1,1) NOT NULL
, liqLoteFecha DATETIME NOT NULL CONSTRAINT DEFAULT_liqLoteFecha DEFAULT (dbo.GetAcuamaDate())
, liqLoteTipoId INT NOT NULL
, liqLoteNum INT 
, liqLoteUsr VARCHAR(10) 
, liqLoteParametros VARCHAR(500)
, CONSTRAINT [PK_LiquidacionesLotes] PRIMARY KEY (liqLoteId)
, CONSTRAINT FK_LiquidacionesTipos FOREIGN KEY (liqLoteTipoId) REFERENCES liquidacionesTipos(liqTipoId)
);
GO



CREATE TRIGGER liquidacionesLote_UpadateInstead
ON dbo.liquidacionesLotes
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
	FROM DATA WHERE RN=1
END
GO