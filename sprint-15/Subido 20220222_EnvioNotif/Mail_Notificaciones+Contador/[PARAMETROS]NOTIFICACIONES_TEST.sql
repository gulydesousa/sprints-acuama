INSERT INTO parametros VALUES
('NOTIFICACIONES_TEST', 'Correo electronico a donde se envian las pruebas de notificaciones', 2, NULL, 0, 1, 1)

SELECT * 
--UPDATE P SET pgsvalor= 'neoris_gmdesousa@sacyr.com'
FROM parametros AS P WHERE pgsClave = 'NOTIFICACIONES_TEST'


--SELECT * FROM vEmailNotificaciones