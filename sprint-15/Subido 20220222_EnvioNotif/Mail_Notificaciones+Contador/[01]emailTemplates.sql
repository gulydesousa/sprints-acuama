INSERT INTO [emailTemplates]
VALUES('envioNotificaciones', 'aplicacion', 'Notificaciones' 
, 'Estimado Sr/a. {0}. <p>Adjuntamos una notificaci�n referente a su contrato {1}.</p> <p>Desde la oficina on-line podr� realizar sus gestiones con mayor comodidad, seguridad e inmediatez, 365 d�as al a�o, 24 horas al d�a.</p>'
, 'Notificaci�n en relaci�n a su contrato {0}'
, 'nombre, contrato');

--DELETE [emailTemplates] WHERE etpId='envioNotificaciones'

