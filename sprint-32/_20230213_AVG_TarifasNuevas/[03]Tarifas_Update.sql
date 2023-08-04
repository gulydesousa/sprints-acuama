--******************************************
--Ponemos fecha fin a la tarifa
--******************************************
BEGIN TRAN

--SELECT *
UPDATE T
SET T.trfFechaBaja = tv.trvfechafin
, T.trfUsrBaja = 'gmdesousa'
OUTPUT INSERTED.*
FROM dbo.tarval AS TV
INNER JOIN dbo.tarifas AS T
ON T.trfcod = TV.trvtrfcod
AND T.trfsrvcod = TV.trvsrvcod
WHERE trfFechaBaja is null and tv.trvfechafin ='20230130'

--COMMIT

SELECT * FROM dbo.tarifas --678
