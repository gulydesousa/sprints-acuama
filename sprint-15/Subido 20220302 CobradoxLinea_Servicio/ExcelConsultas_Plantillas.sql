--DROP  TABLE Trabajo.ExcelConsultas_Plantillas
CREATE TABLE Trabajo.ExcelConsultas_Plantillas
(
--Descripción de formato que aplica cada una de las plantillas al dataset
ecpPlantillaId VARCHAR(50) NOT NULL, 
ecpDescripcion VARCHAR(500) NOT NULL, 
[ecpDataTable.0] VARCHAR(250) NOT NULL,
[ecpDataTable.1] VARCHAR(250) NOT NULL,
[ecpDataTable.2] VARCHAR(250) NULL,
[ecpDataTable.3] VARCHAR(250) NULL, 
[ecpDataTable.n] VARCHAR(250) NULL, 
CONSTRAINT PK_ExcelConsultas_Plantillas PRIMARY KEY (ecpPlantillaId)
)

/*
INSERT INTO Trabajo.ExcelConsultas_Plantillas VALUES
( '001'
, 'Plantilla Básica Excel: Filtros + Datos'
, CONCAT('Filtros para el encabezados. Datatable con una fila. ' ,  CHAR(10) , 'La columna fInforme marca un salto de linea para los resultados en el fichero excel.')
, 'Tabla única con los datos.'
, NULL
, NULL
, NULL)

SELECT * FROM Trabajo.ExcelConsultas_Plantillas
*/