--***********************************
--Agrupación de servicios por tributo
--***********************************
CREATE TABLE liquidacionesTributos(
  tribCodigo		CHAR(3)		NOT NULL
, tribConcTributa	CHAR(2)		NOT NULL
, tribDescripcion	CHAR(40)	NOT NULL
, CONSTRAINT PK_LiquidacionTributos PRIMARY KEY (tribCodigo)
);