--SELECT * FROM parametros WHERE pgsclave='AutoRegistroFacInspecciones'
DELETE FROM parametros WHERE pgsClave= 'AutoRegistroInspecciones'


INSERT INTO parametros(pgsclave, pgsdesc, pgstdato, pgsvalor, pgsorden, pgsPgsTipCod, pgsCacheable)
OUTPUT INSERTED.*
SELECT pgsclave='AutoRegistroInspecciones'
, pgsdesc='Para habilitar la opción "Entrada de Inspecciones Masivas" '
, pgstdato= 2
, pgsvalor = CASE pgsvalor 
				WHEN 'Alamillo' THEN 'OFF'			
				WHEN 'Almaden' THEN 'OFF'			
				WHEN 'AVG' THEN 'OFF'				
				WHEN 'Biar' THEN 'OFF'			
				WHEN 'Guadalajara' THEN 'OFF'	
				WHEN 'Melilla' THEN 'OFF'			
				WHEN 'Ribadesella' THEN 'OFF'		
				WHEN 'Soria' THEN 'OFF'	
				WHEN 'SVB' THEN 'OFF'				
				WHEN 'Valdaliga' THEN 'OFF'		
				ELSE 'OFF' END
, pgsorden=0 
, pgsPgsTipCod=1
, pgsCacheable = 0
FROM parametros AS P WHERE pgsclave='EXPLOTACION';

