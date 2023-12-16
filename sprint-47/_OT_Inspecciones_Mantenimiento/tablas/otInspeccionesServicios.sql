CREATE TABLE dbo.otInspeccionesServicios
(
otisCod TINYINT NOT NULL, 
otisDescripcion VARCHAR(25) NOT NULL,
CONSTRAINT PK_otInspeccionesServicios_Melilla PRIMARY KEY CLUSTERED (otisCod));

GO


INSERT INTO otInspeccionesServicios VALUES
(1, 'BATERIAS'),
(2, 'CONTADORES');


SELECT * FROM dbo.otInspeccionesServicios
