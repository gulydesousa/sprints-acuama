INSERT INTO Trabajo.FAC_APERTURA VALUES
('1.0.0', 'Versión inicial'), 
('2.0.0', 'Se crea una trasacción por factura en los procesos de apertura, ampliación, cierre, remesas. Si falla una factura se hace rollback de esa y continua con la siguiente.'), 
('2.0.1', 'Se resuelve el BUG en la concurrencia de cobros en las remesas Usa la nueva tabla cobrosNum para guardar el último id de cobro en uso.'), 
('2.1.0', 'Nuevo buscador de facturas. Usa la tabla facTotales actualizada por medio de triggers. La remesa aplaza los triggers en facTotalesTrab hasta la finalización de la tarea.'), 
('2.1.1', 'La remesa no aplaza los triggers.'), 
('2.1.2', 'Aplicar consumos comunitarios aplaza los triggers de facTotales hasta la finalización de la tarea');
GO


EXEC Trabajo.Parametros_FAC_APERTURA '2.1.2'
GO

INSERT INTO Trabajo.ExcelConsultas_Plantillas VALUES
( '001'
, 'Plantilla Básica Excel: Filtros + Datos'
, CONCAT('Filtros para el encabezados. Datatable con una fila. ' ,  CHAR(10) , 'La columna fInforme marca un salto de linea para los resultados en el fichero excel.')
, 'Tabla única con los datos.'
, NULL
, NULL
, NULL);
GO



UPDATE T SET etpCuerpo = 'Estimado Sr/a. {0}. <p>Adjuntamos una notificación referente a su contrato {1}.</p>'
FROM emailTemplates AS T WHERE etpId='envioNotificaciones'
GO


INSERT INTO dbo.parametros VALUES
('ENVIOMAIL_NOTIFICACIONES', 'ON: Hace visible la opción Enviar Email en catastro/Emision de notific./Dispone de e-mail (Sí)', 2, 'OFF', 0, 1, 0);


UPDATE  P SET pgsCacheable=0
FROM parametros AS P WHERE pgsClave = 'NOTIFICACIONES_TEST';


SELECT DISTINCT emailTo FROm vEmailNotificaciones;

/*
INSERT INTO dbo.ExcelConsultas
VALUES ('000/004',	'Sistema facTotales', 'Sistema: Comprobar datos en facTotales', 0, '[InformesExcel].[FacTotales_Comprobar]', 'CSVH', 'Para comprobar que los totales en la tabla facTotales están todos a nivel.');

INSERT INTO ExcelPerfil
VALUES('000/004', 'root', 4, NULL)
*/

/*
SELECT DISTINCT [emailTo] FROM ACUAMA_MELILLA.dbo.vEmailNotificaciones
SELECT * 
--UPDATE P SET pgsvalor= 'esamper@sacyr.com'
FROM ACUAMA_MELILLA.dbo.parametros AS P WHERE pgsClave = 'NOTIFICACIONES_TEST'


SELECT DISTINCT [emailTo] FROM ACUAMA_SVB.dbo.vEmailNotificaciones
SELECT * 
--UPDATE P SET pgsvalor= 'elamuno@sacyr.com'
FROM ACUAMA_SVB.dbo.parametros AS P WHERE pgsClave = 'NOTIFICACIONES_TEST'

SELECT DISTINCT [emailTo] FROM ACUAMA_GUADALAJARA.dbo.vEmailNotificaciones
SELECT * 
--UPDATE P SET pgsvalor= 'apastrana@sacyr.com'
FROM ACUAMA_GUADALAJARA.dbo.parametros AS P WHERE pgsClave = 'NOTIFICACIONES_TEST'









--************************
SELECT DISTINCT [emailTo] FROM ACUAMA_ALAMILLO.dbo.vEmailNotificaciones
SELECT * 
--UPDATE P SET pgsvalor= 'neoris_gmdesousa@sacyr.com'
FROM ACUAMA_ALAMILLO.dbo.parametros AS P WHERE pgsClave = 'NOTIFICACIONES_TEST'

SELECT DISTINCT [emailTo] FROM ACUAMA_ALMADEN.dbo.vEmailNotificaciones
SELECT * 
--UPDATE P SET pgsvalor= 'neoris_gmdesousa@sacyr.com'
FROM ACUAMA_ALMADEN.dbo.parametros AS P WHERE pgsClave = 'NOTIFICACIONES_TEST'

SELECT DISTINCT [emailTo] FROM ACUAMA_AVG.dbo.vEmailNotificaciones
SELECT * 
--UPDATE P SET pgsvalor= 'neoris_gmdesousa@sacyr.com'
FROM ACUAMA_AVG.dbo.parametros AS P WHERE pgsClave = 'NOTIFICACIONES_TEST'



SELECT DISTINCT [emailTo] FROM ACUAMA_BIAR.dbo.vEmailNotificaciones
SELECT * 
--UPDATE P SET pgsvalor= 'neoris_gmdesousa@sacyr.com'
FROM ACUAMA_BIAR.dbo.parametros AS P WHERE pgsClave = 'NOTIFICACIONES_TEST'

SELECT DISTINCT [emailTo] FROM ACUAMA_CANAL_AVERIAS.dbo.vEmailNotificaciones
SELECT * 
--UPDATE P SET pgsvalor= 'neoris_gmdesousa@sacyr.com'
FROM ACUAMA_CANAL_AVERIAS.dbo.parametros AS P WHERE pgsClave = 'NOTIFICACIONES_TEST'

SELECT DISTINCT [emailTo] FROM ACUAMA_RIBADESELLA.dbo.vEmailNotificaciones
SELECT * 
--UPDATE P SET pgsvalor= 'neoris_gmdesousa@sacyr.com'
FROM ACUAMA_RIBADESELLA.dbo.parametros AS P WHERE pgsClave = 'NOTIFICACIONES_TEST'




SELECT DISTINCT [emailTo] FROM ACUAMA_SORIA.dbo.vEmailNotificaciones
SELECT * 
--UPDATE P SET pgsvalor= 'neoris_gmdesousa@sacyr.com'
FROM ACUAMA_SORIA.dbo.parametros AS P WHERE pgsClave = 'NOTIFICACIONES_TEST'


SELECT DISTINCT [emailTo] FROM ACUAMA_VALDALIGA.dbo.vEmailNotificaciones
SELECT * 
--UPDATE P SET pgsvalor= 'neoris_gmdesousa@sacyr.com'
FROM ACUAMA_VALDALIGA.dbo.parametros AS P WHERE pgsClave = 'NOTIFICACIONES_TEST'
*/




--************************
--SELECT * 
----UPDATE P SET pgsvalor= 'neoris_gmdesousa@sacyr.com'
--FROM parametros AS P WHERE pgsClave = 'NOTIFICACIONES_TEST'


--EXEC ReportingServices.Informe_COMUN_CA013_EmisionNotificaciones @tipo=N'lectura',@cartaTipo=1,@periodo=N'202104', @tieneEmail= 1 , @contratoD=2302, @contratoH=2302
--EXEC ReportingServices.Informe_MELILLA_CA013_EmisionNotificaciones @tipo=N'lectura',@cartaTipo=1,@periodo=N'202104', @tieneEmail= 1 , @contratoD=7, @contratoH=7

--EXEC ReportingServices.Informe_COMUN_CA013_EmisionNotificaciones @tipo=N'lectura',@cartaTipo=1,@periodo=N'202104', @contratoD=18489, @contratoH=18489	--66548078
--EXEC ReportingServices.Informe_MELILLA_CA013_EmisionNotificaciones @tipo=N'lectura',@cartaTipo=1,@periodo=N'202104', @contratoD=18489, @contratoH=18489 --66548070
