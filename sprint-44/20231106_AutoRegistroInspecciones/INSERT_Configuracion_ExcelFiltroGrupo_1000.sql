SELECT *
--DELETE 
FROM ExcelFiltros WHERE ExFCodGrupo>102

--DELETE FROM excelConsultas WHERE ExcCod IN ('RPT/103', 'RPT/104')

SELECT *
--DELETE 
FROM ExcelFiltroGrupos WHERE ExcelGrupoFiltro>=102

INSERT INTO ExcelFiltroGrupos
VALUES('1000', 'Todos los filtros')

INSERT INTO ExcelFiltros VALUES
(1000, 'periodoD', 'Periodo Desde'),
(1000, 'periodoH', 'Periodo Hasta'),
(1000, 'versionD', 'Versión Desde'),
(1000, 'versionH', 'Versión Desde'),
(1000, 'zonaD', 'Zona Desde'),
(1000, 'zonaH', 'Zona Desde'),
(1000, 'fechaD', 'Fecha desde'),
(1000, 'fechaH', 'Fecha hasta'),
(1000, 'contratoD', 'Contrato desde'),
(1000, 'contratoH', 'Contrato hasta'),
(1000, 'preFactura', 'Prefacturas'),
(1000, 'consuMin', 'Cns. Min'),
(1000, 'consuMax', 'Cns. Max'),
(1000, 'empleadoD', 'Empleado desde'),
(1000, 'empleadoH', 'Empleado hasta'),
(1000, 'contratista', 'Contratista'),
(1000, 'Origen', 'Origen');

INSERT INTO ExcelFiltros VALUES
(1000, 'ruta1D', 'ruta1D'),
(1000, 'ruta1H', 'ruta1H'),
(1000, 'ruta2D', 'ruta2D'),
(1000, 'ruta2H', 'ruta2H'),
(1000, 'ruta3D', 'ruta3D'),
(1000, 'ruta3H', 'ruta3H'),
(1000, 'ruta4D', 'ruta4D'),
(1000, 'ruta4H', 'ruta4H'),
(1000, 'ruta5D', 'ruta5D'),
(1000, 'ruta5H', 'ruta5H'),
(1000, 'ruta6D', 'ruta6D'),
(1000, 'ruta6H', 'ruta6H');
