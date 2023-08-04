DELETE ExcelPerfil WHERE ExPCod='000/023'
DELETE ExcelConsultas WHERE ExcCod='000/023'
DROP PROCEDURE [InformesExcel].[ContadoresxInstalación]

INSERT INTO ExcelConsultas VALUES(  
  '000/023'   
, 'Contadores F.Instalación'   
, 'Contadores por fecha de instalación'  
, '1'  
, '[InformesExcel].[ContadoresxInstalacion]'  
, '000'  
, 'Contadores instalados en el rango de fechas indicado. Incluye el emplazamiento, zona, ruta y el contador retirado.'  
, NULL
, NULL
, NULL
, NULL)  
  
INSERT INTO ExcelPerfil VALUES('000/023', 'root', 3, NULL)  
INSERT INTO ExcelPerfil VALUES('000/023', 'jefAdmon', 3, NULL)  
INSERT INTO ExcelPerfil VALUES('000/023', 'jefeExp', 3, NULL)  
INSERT INTO ExcelPerfil VALUES('000/023', 'direcc', 3, NULL)  