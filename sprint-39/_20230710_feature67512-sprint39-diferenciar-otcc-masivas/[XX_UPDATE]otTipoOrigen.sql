SELECT OT.otnum, OT.otEplCod, OT.otEplCttCod , OT.*
--UPDATE OT SET OT.otTipoOrigen='CCCONTRATO'
FROM ordenTrabajo AS OT
INNER JOIN parametros AS P
ON pgsclave LIKE 'OT_TIPO_CC'
AND OT.otottcod=P.pgsvalor
WHERE OT.otobs = 'Generación órden de trabajo de cambio de contador desde contratos'



SELECT OT.otnum, OT.otEplCod, OT.otEplCttCod , OT.*
--UPDATE OT SET OT.otTipoOrigen='CCMASIVO'
FROM ordenTrabajo AS OT
INNER JOIN parametros AS P
ON pgsclave LIKE 'OT_TIPO_CC'
AND OT.otottcod=P.pgsvalor
WHERE COALESCE(OT.otEplCod, OT.otEplCttCod) IS NOT NULL


/*
SELECT OT.*
FROM ordenTrabajo AS OT
INNER JOIN parametros AS P
ON pgsclave LIKE 'OT_TIPO_CC'
AND OT.otottcod=P.pgsvalor
WHERE COALESCE(OT.otEplCod, OT.otEplCttCod) IS NOT NULL
*/


