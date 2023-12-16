--TRUNCATE TABLE otInspeccionesValidaciones
--DROP TABLE IF EXISTS otInspeccionesValidaciones
--GO

CREATE TABLE otInspeccionesValidaciones (
    otivColumna VARCHAR(128),
    otivServicioCod TINYINT,
    otivCritica BIT CONSTRAINT DF_otivCritica DEFAULT 1 NOT NULL, 
    otivReqReglamentoCTE BIT CONSTRAINT DF_otivReqReglamentoCTE DEFAULT 1 NOT NULL, 
    otivOrden TINYINT NOT NULL,
    otivDesc VARCHAR(250) NOT NULL,
    otivDescParaCartas VARCHAR(250),
    CONSTRAINT PK_otInspeccionesValidaciones PRIMARY KEY (otivColumna, otivServicioCod),
	CONSTRAINT FK_otInspeccionesValidaciones_otInspeccionesServicios 
	FOREIGN  KEY (otivServicioCod)
	REFERENCES otInspeccionesServicios(otisCod));


INSERT INTO otInspeccionesValidaciones
OUTPUT INSERTED.*
SELECT otiaColumna
, IIF(otiaServicio='BATERIAS', 1, 2)
, IIF(otiaCritico='SI', 1, 0)
, otiaReqisitoReglamentoCTE
, otiaOrden
, otiaDescripcion
, NULL
FROM otInspeccionesApto_Melilla


SELECT * FROM otInspeccionesValidaciones