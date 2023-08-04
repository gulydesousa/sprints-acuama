--DELETE FROM parametros WHERE pgsClave= 'OT_CC_MediaCnsPorcentaje'
INSERT INTO parametros(pgsclave, pgsdesc, pgstdato, pgsvalor, pgsorden, pgsPgsTipCod, pgsCacheable)
OUTPUT INSERTED.*
SELECT pgsclave='OT_CC_MediaCnsPorcentaje'
, pgsdesc='Porcentaje a aplicar para validar el consumo en una media'
, pgstdato= 1
, pgsvalor = CASE pgsvalor 
				WHEN 'Alamillo' THEN 30			--ORDEN DE TRABAJO FINALIZADA
				WHEN 'Almaden' THEN 30			--ORDEN DE TRABAJO FINALIZADA
				WHEN 'AVG' THEN 30				--Trabajos finalizados
				WHEN 'Biar' THEN 30				--ORDEN DE TRABAJO FINALIZADA
				WHEN 'Guadalajara' THEN 30		--CAMBIO DE CONTADOR
				WHEN 'Melilla' THEN 30			--REALIZADO CAMBIO DE CONTADOR
				WHEN 'Ribadesella' THEN 30		--ORDEN DE TRABAJO FINALIZADA
				WHEN 'Soria' THEN 30			--REALIZADO
				WHEN 'SVB' THEN 30				--ORDEN DE TRABAJO FINALIZADA
				WHEN 'Valdaliga' THEN 30		--ORDEN DE TRABAJO FINALIZADA
				ELSE 30 END
, pgsorden=0 
, pgsPgsTipCod=1
, pgsCacheable = 0
FROM parametros AS P WHERE pgsclave='EXPLOTACION';

