DECLARE @menuID INT;
DECLARE @menuPadre INT;
DECLARE @menuOrden INT;
DECLARE @menuURL VARCHAR(250) = '~/Facturacion/CL025_inspeccionesEntradaMasiva.aspx';

SELECT @menuID = MAX(menuid)+1 FROM menu;

SELECT @menuPadre= menupadre , @menuOrden = menuOrden +1 FROM menu WHERE menuurl LIKE '%~/Facturacion/CL008_inspeccionesEntrada.aspx%';

IF(NOT EXISTS (SELECT 1 FROM menu WHERE menuurl = @menuURL))
INSERT INTO menu VALUES(
@menuID, 
@menuPadre,
'Entrada Inspecc. Masivas',
'Entrada de Inspecciones Masivas',
NULL,
'~/Facturacion/CL025_inspeccionesEntradaMasiva.aspx',
'~/Facturacion/Css/inspeccionesEntradaMasiva.css',
NULL, 
NULL,
@menuOrden,
1, 
1)
