CREATE  TABLE dbo.cobrosNum (
  cbnScd	SMALLINT NOT NULL
, cbnPpag	SMALLINT NOT NULL
, cbnNumero INT NOT NULL 
, CONSTRAINT PK_cobrosNum PRIMARY KEY (cbnScd, cbnPpag));

GO
/*
INSERT INTO cobrosNum
SELECT scdcod, ppagCod, cbnNumero FROM dbo.vCobrosNumerador;

GO

SELECT * FROm cobrosNum  ORDER BY IIF(cbnNumero=0, 1, 0),  cbnScd, cbnPpag;
GO
*/

