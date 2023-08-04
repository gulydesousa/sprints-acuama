DELETE ExcelPerfil WHERE ExPCod='000/900'
DELETE ExcelConsultas WHERE ExcCod='000/900'
DELETE ExcelPerfil WHERE ExPCod='000/901'
DELETE ExcelConsultas WHERE ExcCod='000/901'



INSERT INTO dbo.ExcelConsultas
VALUES ('000/900',	'Indicadores: Acuama', 'Consulta de Indicadores', 3, '[InformesExcel].[Indicadores]', '000', 'Informe preliminar para la consulta de los indicadores: Mensuales y Semanales a la fecha indicada como parámetro.', NULL, 1, NULL, 1);


INSERT INTO dbo.ExcelConsultas
VALUES ('000/901',	'Indicadores: IDbox', 'Indicadores Plantilla IDbox', 3, '[InformesExcel].[Indicadores_IDbox]', 'CABECERA-DATOS', '<b>Plantilla IDbox</b>: Indicadores para envio FTP.', 'IDbox.jpg', 0, 'IDbox', 1);



INSERT INTO ExcelPerfil
SELECT '000/900', prfcod , 3, NULL FROM Perfiles WHERE prfcod='root'

INSERT INTO ExcelPerfil
SELECT '000/901', prfcod , 3, NULL FROM Perfiles WHERE prfcod='root'


--DELETE ExcelPerfil WHERE ExPCod='000/902'
--DELETE ExcelConsultas WHERE ExcCod='000/902'

--INSERT INTO dbo.ExcelConsultas
--VALUES ('000/902',	'Indicadores: IDbox Prueba', 'Indicadores Plantilla IDbox', 3, '[InformesExcel].[Indicadores_IDbox]', 'CABECERA-DATOS', '<b>Plantilla IDbox</b>: Indicadores para envio FTP.', 'IDbox.jpg', 0, 'IDbox', 1);


--INSERT INTO ExcelPerfil
--SELECT '000/902', prfcod , 3, NULL FROM Perfiles