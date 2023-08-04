--DELETE FROM parametros WHERE pgsClave= 'OTCC_FRC_OBLIGATORIO'
INSERT INTO parametros(pgsclave, pgsdesc, pgstdato, pgsvalor, pgsorden, pgsPgsTipCod, pgsCacheable)
OUTPUT INSERTED.*
SELECT pgsclave='OTCC_ASIGNACION_OT'
, pgsdesc='OTCC 1 se descargan todas las OTs, 2 filtra por usuario, 3 filtra por contratista'
, pgstdato= 1
, pgsvalor = CASE pgsvalor 
				WHEN 'Alamillo' THEN 1			
				WHEN 'Almaden' THEN 1			
				WHEN 'AVG' THEN 1		
				WHEN 'Biar' THEN 1		
				WHEN 'Guadalajara' THEN 1
				WHEN 'Melilla' THEN 2		
				WHEN 'Ribadesella' THEN 1
				WHEN 'Soria' THEN 1		
				WHEN 'SVB' THEN 1		
				WHEN 'Valdaliga' THEN 1			
				ELSE 2 END
, pgsorden=0 
, pgsPgsTipCod=1
, pgsCacheable = 0
FROM parametros AS P WHERE pgsclave='EXPLOTACION';

