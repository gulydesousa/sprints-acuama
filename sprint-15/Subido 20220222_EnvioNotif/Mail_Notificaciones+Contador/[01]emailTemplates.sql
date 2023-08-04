INSERT INTO [emailTemplates]
VALUES('envioNotificaciones', 'aplicacion', 'Notificaciones' 
, 'Estimado Sr/a. {0}. <p>Adjuntamos una notificación referente a su contrato {1}.</p> <p>Desde la oficina on-line podrá realizar sus gestiones con mayor comodidad, seguridad e inmediatez, 365 días al año, 24 horas al día.</p>'
, 'Notificación en relación a su contrato {0}'
, 'nombre, contrato');

--DELETE [emailTemplates] WHERE etpId='envioNotificaciones'

