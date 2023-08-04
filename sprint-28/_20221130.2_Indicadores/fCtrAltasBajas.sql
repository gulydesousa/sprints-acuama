/*
DECLARE @fechaD DATE='20210101'
DECLARE @fechaH DATE ='20220101'
DECLARE @tipo CHAR(1) = 'A'
DECLARE @verCambioDeTitular BIT=1
DECLARE @result TABLE (ctrCod INT, ctrNuevo INT, tipo VARCHAR(1))


SELECT * FROM dbo.fCtrAltasBajas(@fechaD, @fechaH, @tipo, 1);
SELECT * FROM dbo.fCtrAltasBajas(@fechaD, @fechaH, @tipo, @verCambioDeTitular);
SELECT * FROM dbo._fCtrAltasBajas(@fechaD, @fechaH, @tipo, @verCambioDeTitular);

*/

ALTER FUNCTION dbo.fCtrAltasBajas(@fechaD DATE, @fechaH DATE, @tipo CHAR(1), @verCambioDeTitular BIT)
RETURNS @result TABLE (ctrCod INT, ctrNuevo INT, tipo VARCHAR(1))
BEGIN 

--Consulta del informe: CC034_CtrAltasBajas
WITH RESULT AS(

SELECT DISTINCT ctrcod, ctrNuevo, tipo= 'B'
FROM dbo.contratos AS C
WHERE (@tipo = 'B') 
  AND (C.ctrfecanu IS NOT NULL AND C.ctrfecanu >= @fechaD AND C.ctrfecanu < @fechaH)
  AND (C.ctrBaja = 1)

UNION ALL

--Buscamos si son altas por cambio de contador
--¿Este contrato aparece como ctrNuevo de otro?
SELECT DISTINCT ctrcod, ctrNuevo = (SELECT MAX(CC.ctrcod) FROM contratos AS CC WHERE CC.ctrNuevo=C.ctrcod) , tipo= 'A'
FROM dbo.contratos AS C
WHERE (@tipo = 'A') 
  AND (C.ctrfecini IS NOT NULL AND C.ctrfecini >= @fechaD AND C.ctrfecini < @fechaH)
  AND (C.ctrBaja = 0)
  AND (C.ctrfecanu IS NULL OR C.ctrfecanu >= @fechaH))

INSERT INTO @result
SELECT * 
FROM RESULT
WHERE @verCambioDeTitular=1 
OR   (@verCambioDeTitular=0 AND ctrNuevo IS NULL); 

RETURN;
END