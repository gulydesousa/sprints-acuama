--DELETE FROM parametros WHERE pgsClave= 'OT_CC_NumNoLeidoAusente'
INSERT INTO parametros(pgsclave, pgsdesc, pgstdato, pgsvalor, pgsorden, pgsPgsTipCod, pgsCacheable)
OUTPUT INSERTED.*
SELECT pgsclave='OT_CC_NumNoLeidoAusente'
, pgsdesc='Numero de facturas desde la mas reciente para comprobar la incidencia lectura No Leido. Ausente'
, pgstdato= 1
, pgsvalor = CASE pgsvalor 
				WHEN 'Alamillo' THEN 1			--ORDEN DE TRABAJO FINALIZADA
				WHEN 'Almaden' THEN 1			--ORDEN DE TRABAJO FINALIZADA
				WHEN 'AVG' THEN 1				--Trabajos finalizados
				WHEN 'Biar' THEN 1				--ORDEN DE TRABAJO FINALIZADA
				WHEN 'Guadalajara' THEN 1		--CAMBIO DE CONTADOR
				WHEN 'Melilla' THEN 1			--REALIZADO CAMBIO DE CONTADOR
				WHEN 'Ribadesella' THEN 1		--ORDEN DE TRABAJO FINALIZADA
				WHEN 'Soria' THEN 1				--REALIZADO
				WHEN 'SVB' THEN 1				--ORDEN DE TRABAJO FINALIZADA
				WHEN 'Valdaliga' THEN 1			--ORDEN DE TRABAJO FINALIZADA
				ELSE 1 END
, pgsorden=0 
, pgsPgsTipCod=1
, pgsCacheable = 0
FROM parametros AS P WHERE pgsclave='EXPLOTACION';

