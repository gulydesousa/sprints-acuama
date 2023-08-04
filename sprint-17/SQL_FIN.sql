--******************************************
/*
SELECT * FROM Trabajo.VERSION_CNS_COMUNITARIOS
SELECT * FROM parametros AS P WHERE pgsclave='VERSION_CNS_COMUNITARIOS'

DELETE ExcelPerfil WHERE ExPCod='LOG/001';
DELETE ExcelConsultas WHERE ExcCod='LOG/001';

DELETE FROM ExcelPerfil WHERE ExPCod='000/102'
DELETE FROM excelConsultas WHERE ExcCod='000/102'
*/
--******************************************

/*
SELECT pgsValor FROM ACUAMA_ALAMILLO.dbo.parametros AS P WHERE pgsclave='VERSION_CNS_COMUNITARIOS'
SELECT * FROM ACUAMA_ALAMILLO.dbo.ExcelConsultas WHERE ExcCod IN('LOG/001', '000/102')

SELECT pgsValor FROM ACUAMA_ALMADEN.dbo.parametros AS P WHERE pgsclave='VERSION_CNS_COMUNITARIOS'
SELECT * FROM ACUAMA_ALMADEN.dbo.ExcelConsultas WHERE ExcCod IN('LOG/001', '000/102')

SELECT pgsValor FROM ACUAMA_BIAR.dbo.parametros AS P WHERE pgsclave='VERSION_CNS_COMUNITARIOS'
SELECT * FROM ACUAMA_BIAR.dbo.ExcelConsultas WHERE ExcCod IN('LOG/001', '000/102')

SELECT pgsValor FROM ACUAMA_RIBADESELLA.dbo.parametros AS P WHERE pgsclave='VERSION_CNS_COMUNITARIOS'
SELECT * FROM ACUAMA_RIBADESELLA.dbo.ExcelConsultas WHERE ExcCod IN('LOG/001', '000/102')

SELECT pgsValor FROM ACUAMA_MELILLA.dbo.parametros AS P WHERE pgsclave='VERSION_CNS_COMUNITARIOS'
SELECT * FROM ACUAMA_MELILLA.dbo.ExcelConsultas WHERE ExcCod IN('LOG/001', '000/102')

SELECT pgsValor FROM ACUAMA_SVB.dbo.parametros AS P WHERE pgsclave='VERSION_CNS_COMUNITARIOS'
SELECT * FROM ACUAMA_SVB.dbo.ExcelConsultas WHERE ExcCod IN('LOG/001', '000/102')

SELECT pgsValor FROM ACUAMA_VALDALIGA.dbo.parametros AS P WHERE pgsclave='VERSION_CNS_COMUNITARIOS'
SELECT * FROM ACUAMA_VALDALIGA.dbo.ExcelConsultas WHERE ExcCod IN('LOG/001', '000/102')

SELECT pgsValor FROM ACUAMA_SORIA.dbo.parametros AS P WHERE pgsclave='VERSION_CNS_COMUNITARIOS'
SELECT * FROM ACUAMA_SORIA.dbo.ExcelConsultas WHERE ExcCod IN('LOG/001', '000/102')

SELECT pgsValor FROM ACUAMA_AVG.dbo.parametros AS P WHERE pgsclave='VERSION_CNS_COMUNITARIOS'
SELECT * FROM ACUAMA_AVG.dbo.ExcelConsultas WHERE ExcCod IN('LOG/001', '000/102')


SELECT pgsValor FROM ACUAMA_GUADALAJARA.dbo.parametros AS P WHERE pgsclave='VERSION_CNS_COMUNITARIOS'
SELECT * FROM ACUAMA_GUADALAJARA.dbo.ExcelConsultas WHERE ExcCod IN('LOG/001', '000/102')
*/

INSERT INTO Trabajo.VERSION_CNS_COMUNITARIOS
VALUES ('1.0.0', 'Versión Inicial')

, ('2.0.0', 'Sin uso')
, ('2.1.0', 'Aplazando triggers en factotales por toda la zona')
, ('2.1.1', 'Aplazando triggers en factotales para las facturas en @tablaAuxiliar')

, ('3.0.0', 'DESCONTAR: Correcciones en @facConsumoFactura (Cns.), @facCnsFinal(Consumo final)')
, ('3.1.0', 'DESCONTAR: Correcciones aplazando triggers en factotales por toda la zona')
, ('3.1.1', 'DESCONTAR: Correcciones aplazando triggers en factotales para las facturas en @tablaAuxiliar')

GO


IF NOT EXISTS(SELECT * FROM parametros AS P WHERE pgsclave='VERSION_CNS_COMUNITARIOS')
	INSERT INTO dbo.parametros VALUES(
	  'VERSION_CNS_COMUNITARIOS'
	, 'Para condicionar la ejecución de Tasks_Facturas_AplicarConsumosComunitarios: 1.0.0, 2.1.0, 2.1.1, 3.0.0, 3.1.0, 3.1.1 para detalles de cada versión consulta en [Trabajo].[VERSION_CNS_COMUNITARIOS]'
	, 5
	, '3.1.1'
	, 0
	, 1
	, 0  )

ELSE
	UPDATE P SET 
	pgsdesc='Para condicionar la ejecución de Tasks_Facturas_AplicarConsumosComunitarios: 1.0.0, 2.1.0, 2.1.1, 3.0.0, 3.1.0, 3.1.1 para detalles de cada versión consulta en [Trabajo].[VERSION_CNS_COMUNITARIOS]'
	, pgsValor='3.1.1'
	FROM parametros AS P WHERE pgsclave='VERSION_CNS_COMUNITARIOS'
GO




--****** CONFIGURACION ******
INSERT INTO dbo.ExcelConsultas VALUES
('LOG/001', 'LOG Cns Comunitarios', 'ErrorLog', 1, '[InformesExcel].[LOG_Tasks_Facturas_AplicarConsumosComunitarios]', '001', 
'Consultar los tiempos de procesamiento de Tasks_Facturas_AplicarConsumosComunitarios');

INSERT INTO ExcelPerfil VALUES ('LOG/001', 'admon', 4, NULL);
INSERT INTO ExcelPerfil VALUES ('LOG/001', 'root', 4, NULL);

GO



--****** CONFIGURACION ******
INSERT INTO dbo.ExcelConsultas
VALUES ('000/102',	'Facturas-cabeceras-', 'Facturas (cabeceras)', 12, '[InformesExcel].[FacturasCabecera]', 'CSVH', 'Selección de todas las cabeceras de facturas por periodo.');

INSERT INTO ExcelPerfil VALUES('000/102', 'root', 4, NULL)
INSERT INTO ExcelPerfil VALUES('000/102', 'jefeExp', 4, NULL)
INSERT INTO ExcelPerfil VALUES('000/102', 'jefAdmon', 4, NULL)



/*
--**************************************
--Fue necesario para el publicador en PRE
--**************************************
ALTER TABLE dbo.facTotales
DROP COLUMN [fctPrecisionBase];

ALTER TABLE dbo.facTotales
ADD fctPrecisionBase AS LEN(CONVERT(INT, PARSE(REPLACE(REVERSE(CONVERT(VARCHAR(50), ABS(fctBase), 2)), '.', ',') AS FLOAT USING 'es-ES')));
*/
GO 