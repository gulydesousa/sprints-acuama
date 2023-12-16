DELETE FROM  ExcelPerfil WHERE ExpCod='000/013'
DELETE FROM dbo.ExcelConsultas WHERE ExcCod='000/013'


INSERT INTO dbo.ExcelConsultas
VALUES ('000/013',	'Inspecciones: Aptas', 'Para comprobar el estado de las inspecciones de Melilla', 0, '[InformesExcel].[otInspecciones_Melilla_APTO]', '000', 'Para comprobar el esado de las inspecciones cargadas', NULL, NULL, NULL, NULL);

INSERT INTO ExcelPerfil
VALUES('000/013', 'root', 6, NULL)


