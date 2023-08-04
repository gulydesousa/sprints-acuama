--1ra Opcion
SELECT pgsClave, pgsvalor, O.ottdes 
--UPDATE P SET pgsvalor=NULL , pgsCacheable=0
FROM parametros AS P 
LEFT JOIN ottipos AS O
ON O.ottcod= P.pgsvalor
WHERE pgsclave LIKE 'OT_CAMBIOTITULAR' 

--Segunda Opcion
SELECT pgsClave, pgsvalor, O.ottdes 
--UPDATE P SET pgsvalor='06' , pgsCacheable=0
FROM parametros AS P 
LEFT JOIN ottipos AS O
ON O.ottcod= P.pgsvalor
WHERE pgsclave LIKE 'OT_TIPO_CC' 

SELECT * FROM ottipos