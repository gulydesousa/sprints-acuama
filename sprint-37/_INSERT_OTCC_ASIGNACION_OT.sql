--DELETE FROM parametros WHERE pgsClave= 'OTCC_FRC_OBLIGATORIO'
INSERT INTO parametros(pgsclave, pgsdesc, pgstdato, pgsvalor, pgsorden, pgsPgsTipCod, pgsCacheable)
OUTPUT INSERTED.*
SELECT pgsclave='OTCC_FRC_OBLIGATORIO'
, pgsdesc='App Cambio Contador campo Foto Retirada Contador obligatorio en formulario'
, pgstdato= 5
, pgsvalor = CASE pgsvalor 
				WHEN 'Alamillo' THEN 'False'			
				WHEN 'Almaden' THEN 'False'			
				WHEN 'AVG' THEN 'False'				
				WHEN 'Biar' THEN 'False'				
				WHEN 'Guadalajara' THEN 'False'		
				WHEN 'Melilla' THEN 'True'			
				WHEN 'Ribadesella' THEN 'False'		
				WHEN 'Soria' THEN 'False'			
				WHEN 'SVB' THEN 'False'				
				WHEN 'Valdaliga' THEN 'False'			
				ELSE 'True' END
, pgsorden=0 
, pgsPgsTipCod=1
, pgsCacheable = 0
FROM parametros AS P WHERE pgsclave='EXPLOTACION';

