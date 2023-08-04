INSERT INTO ExcelFiltroGrupos VALUES (101, 'Facturacion/Facturacion/InformeLecturas')

INSERT INTO ExcelFiltros VALUES
(101, 'contratista', 'Contratista'),
(101, 'empleadoD', 'Empleado desde'),
(101, 'empleadoH', 'Empleado hasta'),
(101, 'periodoD', 'Periodo desde'),
(101, 'periodoH', 'Periodo hasta'),
(101, 'fechaD', 'Fecha desde'),
(101, 'fechaH', 'Fecha hasta'),
(101, 'zonaD', 'Zona desde'),
(101, 'zonaH', 'Zona hasta')


INSERT INTO dbo.ExcelConsultas VALUES
('RPT/101'
, 'Inf.Lecturas Detallado'
, 'Informe de Lecturas Detallado'
, 101
, '[InformesExcel].[CL018_InformeLecturas]'
, 'CSV'
, 'CL018_InformeLecturas'
, NULL, NULL, NULL, NULL);
