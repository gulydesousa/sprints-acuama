DELETE ExcelPerfil WHERE ExPCod='100/003'
DELETE FROM dbo.ExcelConsultas WHERE ExcCod='100/003'

INSERT INTO dbo.ExcelConsultas VALUES ('100/003', 'Registros para Traspasar', 'Registros para Traspasar por fechas', 1, '[InformesExcel].[RegistroEntradasArchivos_SelectDesdeFecha_MELILLA]', '000', '<b>MELILLA: </b>Registros para Traspasar por fechas<br>', NULL, NULL, NULL, NULL);
INSERT INTO ExcelPerfil VALUES('100/003', 'root', 9, NULL)
INSERT INTO ExcelPerfil VALUES('100/003', 'direcc', 9, NULL)
INSERT INTO ExcelPerfil VALUES('100/003', 'comerc', 9, NULL)