--******************************************
--Insertamos los tarval como nueva tarifa+1
--******************************************
FALTÓ VALIDAR QUE SEAN SOLO TARIFAS DE CONTRATOSSERVICIOS

BEGIN TRAN

INSERT INTO dbo.tarifas
SELECT  T.trfsrvcod
, T.trfcod+1
, [trfdes] = CONCAT(T.trfdes, ' (18-01-2023)')
, T.trfescala1
, T.trfescala2
, T.trfescala3
, T.trfescala4
, T.trfescala5
, T.trfescala6
, T.trfescala7
, T.trfescala8
, T.trfescala9
, T.trfpromedio
, T.trfFechaBaja
, T.trfUsrBaja
, T.trfctacon
, [trfUdsPorEsc] = 1 --multiplicarEscPorUds
, T.trfUdsPorPrecio
, T.trfBonificable
, [trfFecUltMod] = NULL
, [trfUsrUltMod] = NULL
, [trfFecReg] = '20230210'
, [trfUsrReg] = 'gmdesousa'
, T.trfCodDesglose
, T.trfCB
, T.trfAplicarEscMax
, T.trfAplicarEscMin 

FROM dbo.tarifas AS T
INNER JOIN dbo.tarval AS TV
ON TV.trvsrvcod = T.trfsrvcod
AND TV.trvtrfcod = T.trfcod

WHERE T.trfFechaBaja IS NULL  
 AND TV.trvfecha ='20230131' AND TV.trvfechafin  IS NULL
ORDER BY trfsrvcod, trfcod


--COMMIT
--ROLLBACK
SELECT * FROM dbo.Tarifas --515 => 678


