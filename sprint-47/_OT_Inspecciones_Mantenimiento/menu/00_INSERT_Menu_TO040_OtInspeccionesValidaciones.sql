DECLARE @menuID INT;
DECLARE @menuPadre INT;
DECLARE @menuOrden INT;
DECLARE @menuURL VARCHAR(250) = '~/Almacen/TO040_OtInspeccionesValidaciones.aspx';
SELECT 1 FROM menu WHERE menuurl = @menuURL
SELECT @menuID = MAX(menuid)+1 FROM menu;

DELETE FROM menu WHERE menuurl = @menuURL

SELECT @menuPadre= menupadre , @menuOrden = menuOrden +1 
FROM menu WHERE menuurl LIKE '%TA027_%';

IF(NOT EXISTS (SELECT 1 FROM menu WHERE menuurl = @menuURL))
INSERT INTO menu VALUES(
@menuID, 
@menuPadre,
'Insp. Validaciones',
'Inspecciones Validaciones',
NULL,
@menuURL,
'~/Almacen/Css/otInspeccionesValidaciones.css',
NULL, 
NULL,
@menuOrden,
1, 
1)


SELECT *
--DELETE
FROM menu WHERE menuurl = @menuURL