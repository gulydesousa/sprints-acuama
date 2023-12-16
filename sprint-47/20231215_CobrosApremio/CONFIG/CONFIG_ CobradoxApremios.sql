--SELECT * FROM excelConsultas
--DELETE FROM ExcelPerfil WHERE ExPCod='400/002'
--DELETE FROM excelConsultas WHERE ExcCod='400/002'

INSERT INTO dbo.ExcelConsultas
VALUES ('400/002',	'Cobrado por apremios', 'Cobrado por apremios', 1, '[InformesExcel].[CobradoxApremios]', '001'
, 'Compara que los cobros por apremios en un rango de fechas coincidan con los datos enviados en la última carga de cobros por apremios'
, NULL, NULL, NULL, NULL);

INSERT INTO ExcelPerfil
VALUES('400/002', 'root', 5, NULL)

INSERT INTO ExcelPerfil
VALUES('400/002', 'jefAdmon', 5, NULL)

