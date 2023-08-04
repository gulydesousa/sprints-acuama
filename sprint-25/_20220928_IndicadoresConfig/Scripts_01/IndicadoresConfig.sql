--DROP TABLE Indicadores.Indicadores
--SELECT * FROM  Indicadores.IndicadoresConfig
--ALTER TABLE Indicadores.IndicadoresConfig ALTER COLUMN indFuncion VARCHAR(MAX) NOT NULL;

CREATE TABLE Indicadores.IndicadoresConfig(
indAcr VARCHAR(5) NOT NULL,
indDescripcion VARCHAR(150) NOT NULL,
indAnotaciones VARCHAR(MAX) NOT NULL,
indPeriodicidad CHAR(1) NOT NULL,
indUnidad VARCHAR(15) NOT NULL CONSTRAINT IndUnidad_Default  DEFAULT('??'),
indAcuama VARCHAR(MAX) NOT NULL,
indFuncion VARCHAR(MAX) NOT NULL,
indFuncionInfo VARCHAR(250) NOT NULL,
indUsrCod VARCHAR(10) NOT NULL, 
CONSTRAINT PK_Indicadores PRIMARY KEY (indAcr), 
CONSTRAINT FK_IndicadoresUsuarios FOREIGN KEY (indUsrCod) REFERENCES Usuarios(usrCod)
)

