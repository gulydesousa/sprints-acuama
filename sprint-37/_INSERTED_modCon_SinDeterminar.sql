
INSERT INTO modcon
SELECT MA.mcncod, 0, 'Sin determinar' 
FROM marcon AS MA
LEFT JOIN modcon AS MO
ON MO.mdlMcnCod = MA.mcncod
WHERE mdlCod IS NULL