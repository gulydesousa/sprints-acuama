DECLARE @menuID INT;
DECLARE @menuPadre INT;

SELECT @menuID = MAX(menuid)+1 FROM menu;
SELECT @menuPadre=menuid FROM menu where menupadre=6 AND menutitulo_es='Informes'

IF(NOT EXISTS (SELECT 1 FROM menu WHERE menuurl ='~/Sistema/BX203_VisorInformesExcelPerfil.aspx?menu=6'))
INSERT INTO menu VALUES(
@menuID, 
@menuPadre,
'Informes Excel',
NULL,
NULL,
'~/Sistema/BX203_VisorInformesExcelPerfil.aspx?menu=6',
'~/Sistema/Css/visorInformesExcelPerfil.css',
NULL, 
NULL,
999,
1, 
1)


SELECT *
--DELETE
FROM menu WHERE menuurl ='~/Sistema/BX203_VisorInformesExcelPerfil.aspx?menu=6'