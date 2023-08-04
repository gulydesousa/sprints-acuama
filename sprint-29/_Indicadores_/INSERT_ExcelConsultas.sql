--SELECT * FROM excelConsultas WHERE ExcCod LIKE '000/90%'
--SELECT * FROM ftpSites

--SELECT * FROM empleados

DELETE ExcelPerfil WHERE ExPCod='000/902'
DELETE ExcelConsultas WHERE ExcCod='000/902'


DELETE ExcelPerfil WHERE ExPCod='000/903'
DELETE ExcelConsultas WHERE ExcCod='000/903'


DELETE ExcelPerfil WHERE ExPCod='000/904'
DELETE ExcelConsultas WHERE ExcCod='000/904'

DELETE ExcelPerfil WHERE ExPCod='000/905'
DELETE ExcelConsultas WHERE ExcCod='000/905'


INSERT INTO dbo.ExcelConsultas
VALUES ('000/902',	'IDbox: A fecha', 'IDbox: A fecha', 3, '[InformesExcel].[Indicadores_IDbox_Afecha]', 'CABECERA-DATOS', '<b>Plantilla IDbox</b>: Indicadores por fecha para envio FTP', 'IDbox.jpg', 1, 'IDbox', 1);

INSERT INTO ExcelPerfil
SELECT '000/902', prfcod , 3, NULL FROM Perfiles WHERE prfcod='root'



INSERT INTO dbo.ExcelConsultas
VALUES ('000/903',	'IDbox: Mensuales', 'IDbox: Mensuales', 3, '[InformesExcel].[Indicadores_IDbox_Mensuales]', 'CABECERA-DATOS', '<b>Plantilla IDbox</b>: Indicadores mensuales para envio FTP', 'IDbox.jpg', 1, 'IDbox', 1);

INSERT INTO ExcelPerfil
SELECT '000/903', prfcod , 3, NULL FROM Perfiles WHERE prfcod='root'


INSERT INTO dbo.ExcelConsultas
VALUES ('000/904',	'IDbox: Semanales', 'IDbox: Semanales', 3, '[InformesExcel].[Indicadores_IDbox_Semanales]', 'CABECERA-DATOS', '<b>Plantilla IDbox</b>: Indicadores semanales para envio FTP', 'IDbox.jpg', 1, 'IDbox', 1);

INSERT INTO ExcelPerfil
SELECT '000/904', prfcod , 3, NULL FROM Perfiles WHERE prfcod='root'

INSERT INTO dbo.ExcelConsultas
VALUES ('000/905',	'IDbox: Anuales', 'IDbox: Anual', 3, '[InformesExcel].[Indicadores_IDbox_Anuales]', 'CABECERA-DATOS', '<b>Plantilla IDbox</b>: Indicadores anuales para envio FTP', 'IDbox.jpg', 1, 'IDbox', 1);

INSERT INTO ExcelPerfil
SELECT '000/905', prfcod , 3, NULL FROM Perfiles WHERE prfcod='root'