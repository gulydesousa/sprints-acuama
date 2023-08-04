--SELECT * FROM parametros WHERE pgsclave='ValidarNIFAEAT'
DELETE FROM parametros WHERE pgsClave= 'ValidarNIFAEAT'


INSERT INTO parametros(pgsclave, pgsdesc, pgstdato, pgsvalor, pgsorden, pgsPgsTipCod, pgsCacheable)
OUTPUT INSERTED.*
SELECT pgsclave='ValidarNIFAEAT'
, pgsdesc='Para habilitar la ejecución de la función  ValidarNIFAEAT'
, pgstdato= 1
, pgsvalor = CASE pgsvalor 
				WHEN 'Alamillo' THEN 1			
				WHEN 'Almaden' THEN 1			
				WHEN 'AVG' THEN 1				
				WHEN 'Biar' THEN 1				
				WHEN 'Guadalajara' THEN 1	
				WHEN 'Melilla' THEN 1			
				WHEN 'Ribadesella' THEN 1		
				WHEN 'Soria' THEN 1				
				WHEN 'SVB' THEN 1				
				WHEN 'Valdaliga' THEN 1		
				ELSE 1 END
, pgsorden=0 
, pgsPgsTipCod=1
, pgsCacheable = 0
FROM parametros AS P WHERE pgsclave='EXPLOTACION';

