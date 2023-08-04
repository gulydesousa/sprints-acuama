--DELETE FROM parametros WHERE pgsClave= 'OT_CC_NumConsumoCero'
INSERT INTO parametros(pgsclave, pgsdesc, pgstdato, pgsvalor, pgsorden, pgsPgsTipCod, pgsCacheable)
OUTPUT INSERTED.*
SELECT pgsclave='OT_CC_NumConsumoCero'
, pgsdesc='Numero de facturas desde la mas reciente para comprobar el consumo real'
, pgstdato= 1
, pgsvalor = CASE pgsvalor 
				WHEN 'Alamillo' THEN 2			--ORDEN DE TRABAJO FINALIZADA
				WHEN 'Almaden' THEN 2			--ORDEN DE TRABAJO FINALIZADA
				WHEN 'AVG' THEN 2				--Trabajos finalizados
				WHEN 'Biar' THEN 2				--ORDEN DE TRABAJO FINALIZADA
				WHEN 'Guadalajara' THEN 2		--CAMBIO DE CONTADOR
				WHEN 'Melilla' THEN 2			--REALIZADO CAMBIO DE CONTADOR
				WHEN 'Ribadesella' THEN 2		--ORDEN DE TRABAJO FINALIZADA
				WHEN 'Soria' THEN 2				--REALIZADO
				WHEN 'SVB' THEN 2				--ORDEN DE TRABAJO FINALIZADA
				WHEN 'Valdaliga' THEN 2			--ORDEN DE TRABAJO FINALIZADA
				ELSE 2 END
, pgsorden=0 
, pgsPgsTipCod=1
, pgsCacheable = 0
FROM parametros AS P WHERE pgsclave='EXPLOTACION';

