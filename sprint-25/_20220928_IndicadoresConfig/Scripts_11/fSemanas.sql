/*
DECLARE @fecha DATE, @semanas INT;
DECLARE @RESULT TABLE (semana INT, fechaD DATE, fechaH DATE);

SELECT * FROM Indicadores.fSemanas(@fecha, @semanas)
*/

CREATE FUNCTION Indicadores.fSemanas(@fecha DATE, @semanas INT)
RETURNS @RESULT TABLE (semana INT, fLunes DATE, fDomingo DATE)
AS
BEGIN 

DECLARE @DATEFIRST INT = @@DATEFIRST; 
DECLARE @AHORA DATE = [dbo].[GetAcuamaDate]();
DECLARE @FECHAD DATE;
DECLARE @FECHAH DATE;

--**************************************************************
--Comprobamos que en SQL tengamos el lunes como el primer dia de la semana para continuar
IF (@DATEFIRST <> 1) RETURN;

SET @fecha = ISNULL(@fecha, @AHORA);
SET @semanas = ISNULL(@semanas, 12);

--First Day of Current Week (DATEFIRST)
SELECT @FECHAH = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @fecha), @fecha)
SELECT @FECHAD = DATEADD(WEEK, -@semanas, @FECHAH);


--****************************
INSERT INTO @RESULT
SELECT semana = N.number
, DATEADD(DAY,(N.number-1) *7,  @FECHAD)
, DATEADD(DAY,(N.number *7)-1,  @FECHAD) 
FROM master..spt_values N 
WHERE N.type = 'P' 
AND N.number BETWEEN 1 AND @semanas;

--SELECT * FROM @RESULT;

RETURN;

END
