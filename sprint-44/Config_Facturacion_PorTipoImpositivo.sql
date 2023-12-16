DELETE FROM ExcelPerfil WHERE ExPCod = '000/006'
DELETE FROM ExcelConsultas WHERE ExcCod = '000/006'

INSERT INTO dbo.ExcelConsultas
VALUES ('000/006',	'Fact.Tipo Impositivo', 'Facturacion Tipo Impositivo', 18, '[InformesExcel].[Facturacion_PorTipoImpositivo]', '000'
, 'Facturas cuyos totales por tipo impositivo difiere con la totalización por linea usada por acuama. <br>Sería necesario ajustar manualmente el redondeo de los importes para que el total de los impuestos coincida en ambos totales. <b>Recueda ajustar la precisión en la columna Excel para ver los importes a 4 decimales.</b>'
, NULL, NULL, NULL, NULL);

INSERT INTO ExcelPerfil
VALUES('000/006', 'root', 4, NULL)

INSERT INTO ExcelPerfil
VALUES('000/006', 'jefeExp', 4, NULL)

INSERT INTO ExcelPerfil
VALUES('000/006', 'jefAdmon', 4, NULL)
