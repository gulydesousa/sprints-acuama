CREATE TABLE dbo.facDeudaEstados(
  fdeCod TINYINT NOT NULL
, fdeDescripcion VARCHAR(50) NOT NULL
, fdeCondicion VARCHAR(250) NOT NULL

, CONSTRAINT PK_FacDeudaEstado PRIMARY KEY (fdeCod));
GO
