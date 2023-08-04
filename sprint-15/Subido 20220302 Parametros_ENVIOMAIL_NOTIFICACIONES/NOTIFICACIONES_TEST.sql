
SELECT * 
--UPDATE P SET pgsvalor= 'esamper@sacyr.com', pgsCacheable=0
--UPDATE P SET pgsvalor= 'neoris_gmdesousa@sacyr.com', pgsCacheable=0
--UPDATE  P SET pgsCacheable=0
FROM parametros AS P WHERE pgsClave = 'NOTIFICACIONES_TEST'

SELECT DISTINCT emailTo FROm vEmailNotificaciones