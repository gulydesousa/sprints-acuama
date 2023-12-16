

INSERT INTO ExcelFiltroGrupos VALUES (13, 'Zona, Dir.Suministro, Contratos, Orden')
SELECT * FROM ExcelFiltros WHERE ExFCodGrupo=13


INSERT INTO ExcelFiltros VALUES 
(13, 'zonaD', 'Zona desde'),
(13, 'zonaH', 'Zona hasta'),
(13, 'direccion', 'Dirección'),
(13, 'contratos', 'Contratos'),
(13, 'orden', 'Orden')


--SELECT * FROm excelConsultas WHERE ExcConsulta LIKE '%contac%'
INSERT INTO excelConsultas VALUES('000/002',	'Contactos Contratos',
'Contratos: Dirección, telefono y email',	13	, '[dbo].[Excel_ExcelConsultas.ContratosContactos]'
, '001', 	'Se listan los contratos con los datos de contacto, titular, pagador y ruta', 	NULL, NULL, NULL, NULL)

INSERT INTO ExcelPerfil VALUES
('000/002', 'root', 3, NULL),
('000/002', 'jefAdmon', 3, NULL)

--DELETE FROM TASK_SCHEDULE WHERE tskUser='gmdesousa'