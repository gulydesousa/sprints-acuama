DELETE ExcelPerfil WHERE ExPCod='000/023'
DELETE ExcelConsultas WHERE ExcCod='000/023'

INSERT INTO ExcelConsultas VALUES(  
  '000/023'   
, 'Contadores F.Instalaci�n'   
, 'Cambios de Contadores por fecha de instalaci�n (�ltima instalaci�n)'  
, '102'  
, '[InformesExcel].[ContadoresxInstalacion]'  
, '005'  
, 'Contadores instalados en el rango de fechas indicado. Incluye el emplazamiento, zona, ruta y el contador retirado.'  
, NULL
, NULL
, NULL
, NULL)  
  
  
--NO SALE POR INFORMES EXCEL: NO INSERTAR PERFILES
--SELECT * FROM excelConsultas WHERE ExcDescCorta='Contadores F.Instalaci�n' 