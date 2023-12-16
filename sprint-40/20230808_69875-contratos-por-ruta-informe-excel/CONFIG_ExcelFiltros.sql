INSERT INTO [dbo].[ExcelFiltros]
VALUES(21, 'zonaD', 'Zona desde'),
(21, 'zonaH',	'Zona hasta')
GO

INSERT INTO [dbo].[ExcelFiltroGrupos]
VALUES('21','Zona (desde, hasta)')
GO

UPDATE E SET ExcFilCodGroup=21
FROM ExcelConsultas AS E WHERE ExcCod='000/020' AND ExcFilCodGroup=19;
GO