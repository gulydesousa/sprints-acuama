--DROP TABLE dbo.otImagenes
CREATE TABLE dbo.otImagenes
(
otiOtSerScd SMALLINT NOT NULL,
otiOtSerCod SMALLINT NOT NULL,
otiOtNum INT NOT NULL,
otiTipoCodigo VARCHAR(5) NOT NULL,
otiImagen IMAGE NULL,
otiDescripcion VARCHAR(250) NULL,
CONSTRAINT [PK_contadorCambioImagen] PRIMARY KEY(otiOtSerScd, otiOtSerCod, otiOtNum, otiTipoCodigo),
CONSTRAINT [FK_contadorCambioImagen_contadorCambio] FOREIGN KEY(otiOtSerScd, otiOtSerCod, otiOtNum) REFERENCES dbo.ordentrabajo(otSerScd, otSerCod, otNum),
CONSTRAINT [FK_contadorCambioImagen_contadorCambioImagenTipo] FOREIGN KEY(otiTipoCodigo) REFERENCES dbo.otImagenTipo(otitCodigo)
)

--SELECT * into tt FROM otImagenes 
----INSERT INTO otImagenes SELECT 1, 80, 22995, 'CCR', *, 'prueba imagen retirada'  FROM ACUAMA_RIBADESELLA_DESA.dbo.imagenes
----INSERT INTO otImagenes SELECT 1, 80, 22997, 'CCR', *, 'prueba imagen retirada'  FROM ACUAMA_RIBADESELLA_DESA.dbo.imagenes
--SELECT * FROM dbo.otImagenes
--INSERT INTO dbo.otImagenes SELECT * FROM tt