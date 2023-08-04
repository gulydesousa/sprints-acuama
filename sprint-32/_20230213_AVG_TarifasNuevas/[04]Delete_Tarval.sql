--******************************************
--Borramos los tarval
--******************************************

BEGIN TRAN

DELETE TV
--SELECT TV.* , trfFechaBaja
FROM dbo.tarval AS TV
INNER JOIN dbo.tarifas AS T
ON T.trfcod = TV.trvtrfcod
AND T.trfsrvcod = TV.trvsrvcod
where trfFechaBaja='20230130' and tv.trvfecha ='20230131';

--COMMIT
--ROLLBACK

SELECT * FROM dbo.tarval-- 1231 => 1068