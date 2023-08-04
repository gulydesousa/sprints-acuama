
WITH SII AS(
--Todos los envios al SII ordenados por numero de envio
SELECT *
,RN= ROW_NUMBER() OVER (PARTITION BY fcSiiFacPerCod, fcSiiFacCtrCod, fcSiiFacVersion ORDER BY  fcSiiNumEnvio DESC) 
FROM facSII

), ULT AS(
--Ultimo Envio
SELECT facCod, facPerCod, facCtrCod, facVersion, fcSiiLoteID, fcSiiNumEnvio, fcSiicodErr
FROM facturas AS F
INNER JOIN SII AS S
ON F.facCod = S.fcSiiFacCod
AND F.facPerCod = S.fcSiiFacPerCod
AND F.facCtrCod = S.fcSiiFacCtrCod
AND F.facVersion = S.fcSiiFacVersion
AND RN=1 

), LOTE AS(
--Ultimo envio con el error 1219: exenta
SELECT facCod, facPerCod, facCtrCod, facVersion, fcSiiLoteID
, DR = DENSE_RANK() OVER(ORDER BY fcSiiLoteID)
FROM ULT
WHERE fcSiicodErr='1219')

--***********************
--Seleccionamos lotes enteros
--***********************
SELECT * FROM LOTE --WHERE DR<2


--SELECT * FROM facSIILote WHERE fcSiiLtFecEnvSap>'20220823' ORDER BY fcSiiLtEnvEstado
