 
DELETE ExcelPerfil WHERE ExPCod='000/024'
DELETE ExcelConsultas WHERE ExcCod='000/024'

--****** CONFIGURACION ******   
INSERT INTO ExcelConsultas VALUES(  
  '000/024'   
, 'Contador Cambios Pdtes.'   
, 'Ordenes de trabajo de cambio de contador pendientes de cierre'  
, '1'  
, '[InformesExcel].[CambiosContador_PendienteCierre]'  
, '001'  
, 'Selecciona las <b>Ordenes de Trabajo</b> de <i>Cambio de Contador</i> pendientes de cierre. Muestra los datos en la APP cambio contadores..<p>Se filtra por la <b>Fecha de Creación</b>: Fecha de solicitud de la OT.<p>'  
, NULL
, NULL
, NULL
, NULL)  
  
INSERT INTO ExcelPerfil VALUES('000/024', 'root', 3, NULL)  
INSERT INTO ExcelPerfil VALUES('000/024', 'jefAdmon', 3, NULL)  
INSERT INTO ExcelPerfil VALUES('000/024', 'jefeExp', 3, NULL)  
INSERT INTO ExcelPerfil VALUES('000/024', 'direcc', 3, NULL)  
