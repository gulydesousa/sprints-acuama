
--indFuncion
--SELECT [VALOR]= COUNT(*) FROM dbo.fContadoresxOperacion ('I', @fDesde, @fHasta)

CREATE FUNCTION dbo.fCtrAltasBajas(@fechaD DATE, @fechaH DATE, @tipo CHAR(1), @verBajasPorCambioDeTitular BIT)
RETURNS @result TABLE (ctrCod INT, ctrNuevo INT, tipo VARCHAR(1))
BEGIN

IF (@fechaD IS NULL OR @fechaH IS NULL OR @tipo IS NULL OR @tipo NOT IN ('A', 'B') OR @verBajasPorCambioDeTitular IS NULL)
	RETURN

--Consulta del informe: CC034_CtrAltasBajas
INSERT INTO @result
SELECT DISTINCT C.ctrcod, ctrNuevo, [tipo] = @tipo
FROM dbo.contratos AS C
WHERE (@tipo = 'A' AND C.ctrBaja = 0 AND C.ctrfecanu IS NULL AND C.ctrfecini IS NOT NULL AND C.ctrfecini >= @fechaD AND C.ctrfecini < @fechaH AND NOT EXISTS(SELECT CT.ctrcod FROM dbo.contratos AS CT WHERE CT.ctrNuevo = C.ctrcod)) 
	  OR 
	  (@tipo = 'B' AND C.ctrBaja = 1						 AND C.ctrfecanu IS NOT NULL AND C.ctrfecanu >= @fechaD AND C.ctrfecanu < @fechaH AND (@verBajasPorCambioDeTitular = 1 OR C.ctrNuevo IS NULL));

RETURN;
END