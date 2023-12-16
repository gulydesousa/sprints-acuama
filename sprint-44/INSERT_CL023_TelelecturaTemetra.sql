DECLARE @menuID INT;
DECLARE @menuPadre INT;
DECLARE @menuOrden INT;
DECLARE @menuURL VARCHAR(250) = '~/Facturacion/CL023_TelelecturaTemetra.aspx';

SELECT @menuID = MAX(menuid)+1 FROM menu;
SELECT @menuPadre= menuid , @menuOrden = menuOrden +1 FROM menu WHERE menuurl IS NULL AND menutitulo_es='Facturación';

SELECT @menuOrden = MAX(menuorden)+1 FROM menu WHERE menupadre=@menuPadre


IF(NOT EXISTS (SELECT 1 FROM menu WHERE menuurl = @menuURL))
INSERT INTO menu VALUES(
@menuID, 
@menuPadre,
'Telelectura Temetra',
'Telelectura Temetra',
NULL,
@menuURL,
NULL,
NULL, 
NULL,
@menuOrden,
1, 
1)

SELECT * 
--DELETE
FROM Menu WHERE menuid=680

SELECT * 
--UPDATE T SET tskTOverlapping=0
FROM Task_Types AS T WHERE tskTType=735
