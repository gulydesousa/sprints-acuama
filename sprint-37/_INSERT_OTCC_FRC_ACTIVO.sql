--DELETE FROM parametros WHERE pgsClave= 'OT_CC_NumNoLeidoAusente'
INSERT INTO parametros(pgsclave, pgsdesc, pgstdato, pgsvalor, pgsorden, pgsPgsTipCod, pgsCacheable)
OUTPUT INSERTED.*
SELECT pgsclave='OTCC_FRC_ACTIVO'
, pgsdesc='App Cambio Contador campo Foto Retirada Contador mostrar en formulario'
, pgstdato= 5
, pgsvalor = CASE pgsvalor 
				WHEN 'Alamillo' THEN 'True'			
				WHEN 'Almaden' THEN 'True'			
				WHEN 'AVG' THEN 'True'				
				WHEN 'Biar' THEN 'True'				
				WHEN 'Guadalajara' THEN 'True'		
				WHEN 'Melilla' THEN 'True'			
				WHEN 'Ribadesella' THEN 'True'		
				WHEN 'Soria' THEN 'True'			
				WHEN 'SVB' THEN 'True'				
				WHEN 'Valdaliga' THEN 'True'			
				ELSE 'True' END
, pgsorden=0 
, pgsPgsTipCod=1
, pgsCacheable = 0
FROM parametros AS P WHERE pgsclave='EXPLOTACION';

