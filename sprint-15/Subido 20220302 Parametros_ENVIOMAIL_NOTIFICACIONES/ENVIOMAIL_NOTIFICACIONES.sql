SELECT * 
--UPDATE P SET pgsValor='OFF'
--UPDATE P SET pgsClave='ENVIOMAIL_NOTIFICACIONES'
FROM parametros AS P WHERE pgsClave='ENVIOMAIL_NOTIFICACIONES'



INSERT INTO dbo.parametros VALUES
('ENVIOMAIL_NOTIFICACIONES', 'ON: Hace visible la opci�n Enviar Email en catastro/Emision de notific./Dispone de e-mail (S�)', 2, 'OFF', 0, 1, 0);


--*******************
--PRUEBAS:  ENVIOMAIL_NOTIFICACIONES=OFF y NO hay correo en NOTIFICACIONES_TEST
--Ningun usuario puede enviar notificaciones

--PRUEBAS:  ENVIOMAIL_NOTIFICACIONES=OFF y hay correo en NOTIFICACIONES_TEST
--Si me conecto yo, no me sale la opci�n enviar correo
--Si se conecta elena, como es su correo el de NOTIFICACIONES_TEST le muestra la opcion y todos los correos llegan a ella

--PRUEBAS:  ENVIOMAIL_NOTIFICACIONES=ON y NO hay correo en NOTIFICACIONES_TEST
--Todos los usuarios podr�n enviar por correo al usuario real

--PRUEBAS:  ENVIOMAIL_NOTIFICACIONES=ON y hay correo en NOTIFICACIONES_TEST
--Todos los usuarios podr�n enviar por correo al usuario de pruebas			