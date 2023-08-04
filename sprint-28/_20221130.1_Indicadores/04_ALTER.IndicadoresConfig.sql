--SELECT * FROM Indicadores.IndicadoresConfig

ALTER TABLE Indicadores.IndicadoresConfig
ADD indActivo BIT;
GO

UPDATE Indicadores.IndicadoresConfig SET indActivo = 1;
GO

ALTER TABLE Indicadores.IndicadoresConfig
ALTER COLUMN indActivo BIT NOT NULL;
GO


UPDATE Indicadores.IndicadoresConfig SET indActivo = 0;
GO
