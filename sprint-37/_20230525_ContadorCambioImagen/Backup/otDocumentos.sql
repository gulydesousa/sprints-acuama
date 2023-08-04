--DROP TABLE dbo.otDocumentos
CREATE TABLE dbo.otDocumentos
(
otdID INT IDENTITY(1,1),

otdSerScd SMALLINT NOT NULL,
otdSerCod SMALLINT NOT NULL,
otdNum INT NOT NULL,
otdTipoCodigo VARCHAR(5) NOT NULL,

otdFechaReg DATETIME NOT NULL DEFAULT dbo.GetAcuamaDate(),

otdDocumento IMAGE NULL,
otdDescripcion VARCHAR(250) NULL,

CONSTRAINT [PK_otDocumentos] PRIMARY KEY(otdID),
CONSTRAINT [FK_otDocumentos_ordenTrabajo] FOREIGN KEY(otdSerScd, otdSerCod, otdNum) REFERENCES dbo.ordentrabajo(otSerScd, otSerCod, otNum),
CONSTRAINT [FK_otDocumentos_otDocumentoTipo] FOREIGN KEY(otdTipoCodigo) REFERENCES dbo.otDocumentoTipo(otdtCodigo)
)

--SELECT * FROM dbo.otDocumentos

--SELECT * into tt FROM otDocumentos 
----INSERT INTO otDocumentos SELECT 1, 80, 22995, 'CCR', *, 'prueba imagen retirada'  FROM ACUAMA_RIBADESELLA_DESA.dbo.imagenes
----INSERT INTO otDocumentos SELECT 1, 80, 22997, 'CCR', *, 'prueba imagen retirada'  FROM ACUAMA_RIBADESELLA_DESA.dbo.imagenes

--INSERT INTO dbo.otDocumentos (otdSerScd,otdSerCod,otdNum, otdTipoCodigo, otdDocumento, otdDescripcion)   SELECT * FROM tt