DECLARE @OBS VARCHAR(50)= 'SYR-504418'

BEGIN TRAN
--UPDATE C SET C.ctrRuta5=TRIM(c.ctrRuta5), C.ctrobs= IIF(C.ctrobs IS NULL OR LEN(C.ctrobs) = 0, @OBS,  CONCAT(C.ctrobs, ' | ',  @OBS))
SELECT C.ctrcod, c.ctrRuta5, LEN(c.ctrRuta5), LEN(TRIM(c.ctrRuta5))
--OUTPUT INSERTED.ctrcod, INSERTED.ctrversion, INSERTED.ctrfecanu, INSERTED.ctrobs, INSERTED.ctrRuta5, DELETED.ctrRuta5, inserted.ctrzoncod
FROM vContratosUltimaVersion AS V
INNER JOIN Contratos AS C
ON C.ctrcod = V.ctrCod
AND C.ctrversion = V.ctrVersion
WHERE LEN(c.ctrRuta5) <> LEN(TRIM(c.ctrRuta5))
ORDER BY C.ctrRuta5, C.ctrcod

ROLLBACK


