--SELECT * FROM [motcierre]
--SELECT * FROM parametros WHERE pgsclave='OT_CC_MotivoCierre'
--INSERT INTO [motcierre] VALUES('REALIZADO CAMBIO DE CONTADOR', 0)
--DELETE FROM parametros WHERE pgsClave= 'OT_CC_MotivoCierre'
INSERT INTO parametros(pgsclave, pgsdesc, pgstdato, pgsvalor, pgsorden, pgsPgsTipCod, pgsCacheable)
OUTPUT INSERTED.*
SELECT pgsclave='OT_CC_MotivoCierre'
, pgsdesc='Motivo de cierre para las OT de la APP cambio de contador'
, pgstdato= 1
, pgsvalor = CASE pgsvalor 
				WHEN 'Alamillo' THEN 4			--ORDEN DE TRABAJO FINALIZADA
				WHEN 'Almaden' THEN 7			--ORDEN DE TRABAJO FINALIZADA
				WHEN 'AVG' THEN 100				--Trabajos finalizados
				WHEN 'Biar' THEN 9				--ORDEN DE TRABAJO FINALIZADA
				WHEN 'Guadalajara' THEN 6		--CAMBIO DE CONTADOR
				WHEN 'Melilla' THEN 9			--REALIZADO CAMBIO DE CONTADOR
				WHEN 'Ribadesella' THEN 1		--ORDEN DE TRABAJO FINALIZADA
				WHEN 'Soria' THEN 2				--REALIZADO
				WHEN 'SVB' THEN 1				--ORDEN DE TRABAJO FINALIZADA
				WHEN 'Valdaliga' THEN 4			--ORDEN DE TRABAJO FINALIZADA
				ELSE 0 END
, pgsorden=0 
, pgsPgsTipCod=1
, pgsCacheable = 0
FROM parametros AS P WHERE pgsclave='EXPLOTACION';

