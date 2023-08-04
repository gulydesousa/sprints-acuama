--DROP TABLE dbo.otImagenTipo
--SELECT * FROM dbo.otImagenTipo

CREATE TABLE dbo.otImagenTipo
(
otitCodigo VARCHAR(5) NOT NULL,
otitDescripcion VARCHAR(100) NOT NULL,
otitFormato VARCHAR(25) NOT NULL,
CONSTRAINT [PK_ordenTrabajoImagenTipo] PRIMARY KEY(otitCodigo)

)

/*
INSERT INTO otImagenTipo VALUES ('CCR', 'Lectura de Retirada', 'image/jpeg')
INSERT INTO otImagenTipo VALUES ('OTRO', 'Otro', 'image/jpeg')
*/