--DELETE FROM parametros WHERE pgsClave= 'OT_CC_MediaCnsNumPeriodos'
INSERT INTO parametros(pgsclave, pgsdesc, pgstdato, pgsvalor, pgsorden, pgsPgsTipCod, pgsCacheable)
OUTPUT INSERTED.*
SELECT pgsclave='OT_CC_MediaCnsNumPeriodos'
, pgsdesc='Numero de periodos a evaluar para obtener la media de consumo'
, pgstdato= 1
, pgsvalor = CASE pgsvalor 
				WHEN 'Alamillo' THEN 4			--ORDEN DE TRABAJO FINALIZADA
				WHEN 'Almaden' THEN 4			--ORDEN DE TRABAJO FINALIZADA
				WHEN 'AVG' THEN 4				--Trabajos finalizados
				WHEN 'Biar' THEN 4				--ORDEN DE TRABAJO FINALIZADA
				WHEN 'Guadalajara' THEN 4		--CAMBIO DE CONTADOR
				WHEN 'Melilla' THEN 4			--REALIZADO CAMBIO DE CONTADOR
				WHEN 'Ribadesella' THEN 4		--ORDEN DE TRABAJO FINALIZADA
				WHEN 'Soria' THEN 1				--REALIZADO
				WHEN 'SVB' THEN 4				--ORDEN DE TRABAJO FINALIZADA
				WHEN 'Valdaliga' THEN 4			--ORDEN DE TRABAJO FINALIZADA
				ELSE 4 END
, pgsorden=0 
, pgsPgsTipCod=1
, pgsCacheable = 0
FROM parametros AS P WHERE pgsclave='EXPLOTACION';

