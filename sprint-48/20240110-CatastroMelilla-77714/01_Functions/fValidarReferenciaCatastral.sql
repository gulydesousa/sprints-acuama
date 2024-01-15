--DROP FUNCTION dbo.fValidarReferenciaCatastral

CREATE FUNCTION dbo.fValidarReferenciaCatastral(@referenciaCatastral NVARCHAR(20))
RETURNS INT AS
BEGIN
/*
.......................................................................................................................
Una vez llamada la función para validar la referencia catastral, puede devolver uno de los siguientes códigos:
-1: formato incorrecto, la referencia catastral no tiene 20 caracteres alfanuméricos, que es la longitud obligatoria.
0: lao es válida, los dígitos de control (los dos últimos, posiciones 19 y 20) son incorrectos.
1: la referencia catastral es válida.
*/

    DECLARE @pesoPosicion TABLE (posicion INT, peso INT);
	INSERT INTO @pesoPosicion VALUES (1,13),(2,15),(3,12),(4,5),(5,4),(6,17),(7,9),(8,21),(9,3),(10,7),(11,1);
	DECLARE @letraDc NVARCHAR(23) = 'MQWERTYUIOPASDFGHJKLBZX';
	DECLARE @cadenaPrimerDC NVARCHAR(11);
	DECLARE @cadenaSegundoDC NVARCHAR(11);
	DECLARE @dcCalculado NVARCHAR(2) = '';
	DECLARE @sumaDigitos INT = 0;
	DECLARE @valorCaracter INT;
	DECLARE @caracter NVARCHAR(1);
	DECLARE @i INT = 1;

	--https://trellat.es/validar-la-referencia-catastral-en-javascript/
	IF @referenciaCatastral IS NULL OR LEN(@referenciaCatastral) != 20
	BEGIN
    RETURN -1;
	--SELECT -1; RETURN;
	END

	SET @referenciaCatastral = UPPER(@referenciaCatastral);
	SET @cadenaPrimerDC = SUBSTRING(@referenciaCatastral, 1, 7) + SUBSTRING(@referenciaCatastral, 15, 4);
	SET @cadenaSegundoDC = SUBSTRING(@referenciaCatastral, 8, 7) + SUBSTRING(@referenciaCatastral, 15, 4);

	WHILE @i <= 2
	BEGIN
		SET @sumaDigitos = 0;
		DECLARE @j INT = 1;
		WHILE @j <= 11
		BEGIN
			SET @caracter = SUBSTRING(CASE WHEN @i = 1 THEN @cadenaPrimerDC ELSE @cadenaSegundoDC END, @j, 1);
			
			SET @valorCaracter = ASCII(@caracter);
			
			IF (ISNUMERIC(@caracter) = 1)
				SET @valorCaracter = @caracter;
			ELSE IF @caracter BETWEEN 'A' AND 'N'	
				SET @valorCaracter = @valorCaracter - 64;
			ELSE IF @caracter = 'Ñ'
				SET @valorCaracter = 15;
			ELSE IF @caracter > 'N'
				SET @valorCaracter = @valorCaracter - 63;
			
			SET @sumaDigitos = (@sumaDigitos + (@valorCaracter * (SELECT peso FROM @pesoPosicion WHERE posicion = @j))) % 23;
			SET @j = @j + 1;
		END
		SET @dcCalculado = @dcCalculado + SUBSTRING(@letraDc, @sumaDigitos + 1, 1);
		SET @i = @i + 1;
	END

	IF @dcCalculado != SUBSTRING(@referenciaCatastral, 19, 2)
	BEGIN
		RETURN 0;
		--SELECT 0; RETURN;
	END
	RETURN 1;
	--SELECT 1; RETURN;

END