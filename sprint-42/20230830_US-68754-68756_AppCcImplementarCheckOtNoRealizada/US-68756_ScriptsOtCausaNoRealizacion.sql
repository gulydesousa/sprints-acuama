SELECT * FROM menu WHERE menutitulo_es='Causas no realización'
SELECT * FROM otCausasNoRealizacion

INSERT INTO dbo.menu (menuid,menupadre,menutitulo_es,menuToolTip_es,menucolorpagina,menuurl,menucss,menujs,menuicono,menuorden,menuvisible,menuactivo)
VALUES (678,35,'Causas no realización','Causas no realización',NULL,'~/Almacen/TO038_OtCausasNoRealizacion.aspx',NULL,NULL,NULL,220,1,1)
GO


CREATE TABLE otCausasNoRealizacion (
	otcnrCod SMALLINT NOT NULL,
	otcnrDes VARCHAR(50) NOT NULL,
	CONSTRAINT PK_CausaNoRealizacion PRIMARY KEY (otcnrCod)
);
GO
INSERT INTO otCausasNoRealizacion (otcnrCod, otcnrDes) VALUES (0, 'OTRA');
INSERT INTO otCausasNoRealizacion (otcnrCod, otcnrDes) VALUES (1, 'ORDEN O RUTA INCORRECTA');
INSERT INTO otCausasNoRealizacion (otcnrCod, otcnrDes) VALUES (2, 'NO SE LOCALIZA EL CONTADOR');
INSERT INTO otCausasNoRealizacion (otcnrCod, otcnrDes) VALUES (3, 'INSTALACIÓN DEFECTUOSA');
INSERT INTO otCausasNoRealizacion (otcnrCod, otcnrDes) VALUES (4, 'NO HAY LLAVES / NO ABREN');
INSERT INTO otCausasNoRealizacion (otcnrCod, otcnrDes) VALUES (5, 'ACCESO CERRADO');
GO


CREATE PROCEDURE otCausasNoRealizacion_Delete
(
	@otcnrCod smallint
)
AS SET NOCOUNT OFF;
DELETE FROM otCausasNoRealizacion WHERE (otcnrCod = @otcnrCod);
GO

CREATE PROCEDURE otCausasNoRealizacion_Insert
(
	@otcnrCod SMALLINT = null OUTPUT,
	@otcnrDes VARCHAR(50)
)
AS SET NOCOUNT OFF;
SET @otcnrCod = ISNULL(@otcnrCod, (SELECT ISNULL(MAX(otcnrCod), 0) + 1 FROM otCausasNoRealizacion));	
INSERT INTO otCausasNoRealizacion (otcnrCod, otcnrDes) VALUES (@otcnrCod, @otcnrDes);
GO

CREATE PROCEDURE otCausasNoRealizacion_Select
(
	@otcnrCod SMALLINT = NULL
)
AS SET NOCOUNT ON; 
SELECT otcnrCod, otcnrDes
FROM otCausasNoRealizacion
WHERE otcnrCod = CASE WHEN @otcnrCod IS NULL THEN otcnrCod ELSE @otcnrCod END
ORDER BY otcnrDes ASC;
GO

CREATE PROCEDURE otCausasNoRealizacion_SelectPorFiltro
(
	@filtro VARCHAR(500) = NULL
)
AS SET NOCOUNT ON; 
EXECUTE('SELECT otcnrCod, otcnrDes FROM otCausasNoRealizacion ' + @filtro);
GO

CREATE PROCEDURE otCausasNoRealizacion_Update
(
	@otcnrCod SMALLINT,
	@otcnrDes VARCHAR(50)
)
AS SET NOCOUNT OFF;
UPDATE otCausasNoRealizacion SET otcnrDes = @otcnrDes WHERE otcnrCod = @otcnrCod;
SELECT otcnrCod, otcnrDes FROM otCausasNoRealizacion WHERE otcnrCod = @otcnrCod;
GO
