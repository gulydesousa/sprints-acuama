--DROP TABLE dbo.otDocumentoTipo
--SELECT * FROM dbo.otDocumentoTipo

CREATE TABLE dbo.otDocumentoTipo
(
otdtCodigo VARCHAR(5) NOT NULL,
otdtDescripcion VARCHAR(100) NOT NULL,
otdtFormato VARCHAR(25) NOT NULL,
otdtMaxPorTipo TINYINT NOT NULL DEFAULT (1),

CONSTRAINT [PK_ordenTrabajoDocumentoTipo] PRIMARY KEY(otdtCodigo)
)

/*
INSERT INTO otDocumentoTipo VALUES ('CCR', 'Lectura de Retirada', 'image/jpeg', 3)
INSERT INTO otDocumentoTipo VALUES ('OTRO', 'Otro', 'image/jpeg', 10)
*/