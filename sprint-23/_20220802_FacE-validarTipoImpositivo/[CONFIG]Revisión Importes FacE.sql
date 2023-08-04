DELETE FROM ExcelPerfil WHERE ExPCod = '000/102'
DELETE FROM ExcelConsultas WHERE ExcCod = '000/102'
--SELECT * FROM ExcelConsultas
INSERT INTO dbo.ExcelConsultas
VALUES ('000/102',	'Revisión Importes FacE', 'Revisión Importes FacE', 18, '[InformesExcel].[RevisionImportesFacE]', '000', 'Facturas cuyos totales por tipo impositivo (FacE) difiere con la totalización por linea usada por acuama. <br>Sería necesario ajustar manualmente el redondeo de los importes para que el total de los impuestos coincida en ambas facturas. <b>Recueda ajustar la precisión en la columna Excel para ver los importes a 4 decimales.</b>', NULL);

INSERT INTO ExcelPerfil
VALUES('000/102', 'root', 4, NULL)

INSERT INTO ExcelPerfil
VALUES('000/102', 'jefeExp', 4, NULL)

INSERT INTO ExcelPerfil
VALUES('000/102', 'jefAdmon', 4, NULL)
