
BEGIN TRAN;

WITH CTR AS(
SELECT c.ctrcod, C.ctrobs, c.ctravisolector, ctrversion, ctrfecanu 
--RN=1: Ultima version
, RN= ROW_NUMBER() OVER(PARTITION BY c.ctrcod ORDER BY ctrversion DESC)
FROM contratos AS C 
) , V AS(
SELECT C.ctrcod, C.ctrVersion, C.ctrobs, C.ctravisolector
FROM CTR AS C
--Ultima version
WHERE RN=1)

--SELECT C.ctrCod, C.ctrobs, C.ctravisolector
UPDATE V 
SET V.ctrobs=V.ctravisolector
OUTPUT INSERTED.*, DELETED.ctrobs
FROM V
INNER JOIN contratos AS C
ON C.ctrCod = V.ctrCod
AND C.ctrVersion = V.ctrVersion

WHERE ISNULL(V.ctrobs, '')='' AND ISNULL(V.ctravisolector, '') <>''

--COMMIT
--ROLLBACK
