/*
SELECT * FROM excelConsultas WHERE ExcCod='000/801'
SELECT * FROM excelConsultas WHERE ExcCod='000/802'
*/

/*
DELETE FROM ExcelPerfil WHERE ExPCod='000/801'
DELETE FROM ExcelPerfil WHERE ExPCod='000/802'

DELETE  FROM excelConsultas WHERE ExcCod='000/801'
DELETE  FROM excelConsultas WHERE ExcCod='000/802'
*/

/*
INSERT INTO dbo.ExcelConsultas
VALUES ('000/801',	'Cobros-Desglose Dif.', 'Cobros: Facturas y diferencias en el desglose de lineas', 0, '[InformesExcel].[Cobros_DiferenciasDesglose]', '005', '<b>Para localizar fallos en el desglose de cobros por lineas de factura:</b><br>Emite un listado de las facturas en las que al menos uno de sus cobros el desglose por lineas de factura no coincide con el total de las lineas.', NULL, NULL, NULL, NULL);

INSERT INTO dbo.ExcelConsultas
VALUES ('000/802',	'Deuda por Factura', 'Facturas con deuda', 0, '[InformesExcel].[Deuda_Facturas]', '001', '<b>Listado de las facturas activas con deuda pendiente:</b><br>Emite un listado de las facturas en las que el importe cobrado difiere al facturado.<br>Incluye tambien las que el coblindes es diferente al total de la factura.', NULL, NULL, NULL, NULL);
*/

INSERT INTO ExcelPerfil
VALUES('000/801', 'root', 5, NULL)

INSERT INTO ExcelPerfil
VALUES('000/802', 'root', 5, NULL)


INSERT INTO ExcelPerfil
VALUES('000/801', 'jefeExp', 5, NULL)

INSERT INTO ExcelPerfil
VALUES('000/802', 'jefeExp', 5, NULL)


INSERT INTO ExcelPerfil
VALUES('000/801', 'jefAdmon', 5, NULL)

INSERT INTO ExcelPerfil
VALUES('000/802', 'jefAdmon', 5, NULL)


