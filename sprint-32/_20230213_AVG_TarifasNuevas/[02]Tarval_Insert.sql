--******************************************
--Insertamos los tarval en la nueva tarifa+1
--******************************************
BEGIN TRAN

INSERT INTO dbo.Tarval
SELECT trvsrvcod	
, [trvtrfcod] = trvtrfcod+1 
, trvfecha
, trvfechafin
, trvcuota
, trvprecio1
, trvprecio2
, trvprecio3
, trvprecio4
, trvprecio5
, trvprecio6
, trvprecio7
, trvprecio8
, trvprecio9
, trvlegalavb
, trvlegal
, trvumdcod
FROM dbo.tarval AS TV
WHERE TV.trvfecha='20230131' AND TV.trvfechafin  IS NULL;

--COMMIT
--ROLLBACK
SELECT * FROM dbo.tarval--1.068 => 1.231