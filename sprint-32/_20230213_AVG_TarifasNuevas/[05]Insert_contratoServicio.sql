

BEGIN TRAN

FALTO COMPROBAR QUE LA FECHA BAJA NO ES NULL
FALTO COMPROBAR QUE LA FECHA DE ALTA SEA ANTERIOR AL '20230130'
--SELECT * 
UPDATE CS SET ctsfecbaj=trfFechaBaja
OUTPUT INSERTED.*

FROM dbo.ContratoServicio AS CS
INNER JOIN  dbo.tarifas AS T
ON CS.ctssrv=T.trfsrvcod
AND CS.ctstar = T.trfcod
AND trfFechaBaja='20230130';



WITH L AS(
SELECT ctsctrcod
, LIN  = MAX(ctslin)
FROM dbo.ContratoServicio AS CS
GROUP BY ctsctrcod
)
INSERT INTO dbo.ContratoServicio
OUTPUT INSERTED.*
SELECT CS.ctsctrcod
, RN= ROW_NUMBER() OVER (PARTITION BY CS.ctsctrcod ORDER BY CS.ctslin ASC) +LIN
, CS.ctssrv
, T1.trfcod
, CS.ctsuds
, ctsusr = 'gmdesousa'
, ctsfecalt = '20230131'
, ctsfecbaj = NULL

FROM dbo.ContratoServicio AS CS
INNER JOIN  dbo.tarifas AS T
ON CS.ctssrv=T.trfsrvcod
AND CS.ctstar = T.trfcod
AND trfFechaBaja='20230130'
INNER JOIN dbo.tarifas AS T1
ON T1.trfsrvcod=T.trfsrvcod
AND T.trfcod+1 = T1.trfcod
LEFT JOIN L
ON L.ctsctrcod = CS.ctsctrcod
ORDER BY CS.ctsctrcod





--COMMIT
SELECT * FROM dbo.ContratoServicio --67.465 = > 88.350