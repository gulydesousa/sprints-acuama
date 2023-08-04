
DELETE trabajo.ExcelConsultas_Plantillas WHERE ecpPlantillaId IN ('CSV+', 'CSV', 'CSVH', '001');


INSERT INTO Trabajo.ExcelConsultas_Plantillas VALUES
( '001'
, 'Plantilla Básica Excel: Filtros + Datos'
, CONCAT('Filtros para el encabezados. Datatable con una fila. ' ,  CHAR(10) , 'La columna fInforme marca un salto de linea para los resultados en el fichero excel.')
, 'Tabla única con los datos.'
, NULL
, NULL
, NULL)


INSERT INTO trabajo.ExcelConsultas_Plantillas
VALUES('CSV+', 'Plantilla combinada extrae los datos a ficheros sepadados - EXCEL: para el primer datatable de datos, CSV para los siguientes datatables.'
, 'Filtros para el encabezados. Datatable con una fila. La columna fInforme marca un salto de linea para los resultados en el fichero excel.'
, 'Tabla con los nombres de los grupos de datos (Para nombrar cada fichero)'
, 'Tabla de datos que salen al formato excel'
, NULL
, 'Tablas de datos que salen cada una a formato CSV. Solo las columnas con su encabezado (no incluye el apartado para los filtros)')


INSERT INTO trabajo.ExcelConsultas_Plantillas
VALUES('CSV', 'Plantilla Simple: Combina en un solo CSV todos los datatables uno al lado del otro. Por lo tanto es importante que cada datatable tenga el mismo numero de filas y el mismo orden'
, 'Filtros para el encabezados. Datatable con una fila. La columna fInforme marca un salto de linea para los resultados en el fichero excel.'
, 'Tabla con los nombres de los grupos de datos'
, NULL
, NULL
, 'Tablas de datos que se trasladan a un unico fichero CSV  uno al lado del otro (Incluyendo encabezados)')



INSERT INTO trabajo.ExcelConsultas_Plantillas
VALUES('CSVH', 'Plantilla Simple: Combina en un solo CSV todos los datatables uno al lado del otro. Por lo tanto es importante que cada datatable tenga el mismo numero de filas y el mismo orden (incluye apartado para los filtros)'
, 'Filtros para el encabezados. Datatable con una fila. La columna fInforme marca un salto de linea para los resultados en el fichero excel.'
, 'Tabla con los nombres de los grupos de datos'
, NULL
, NULL
, 'Tablas de datos que se trasladan a un unico fichero CSV  uno al lado del otro (Incluyendo filtros y encabezados)')


SELECT * FROM trabajo.ExcelConsultas_Plantillas
