--DROP FUNCTION dbo.fMismaCalle

CREATE FUNCTION dbo.fMismaCalle(@direccion VARCHAR(250), @calle0 VARCHAR(70), @calle1 VARCHAR(70))
RETURNS BIT 
AS BEGIN
	DECLARE @result AS BIT = 0;

	SET @result = IIF(@direccion COLLATE SQL_Latin1_General_CP1_CI_AI  LIKE '%' + @calle0 + '%' COLLATE SQL_Latin1_General_CP1_CI_AI, 1, 0);

	IF (@result=1 AND @calle1 IS NOT NULL AND LEN(@calle1) > 0)
		SET @result = IIF(@direccion COLLATE SQL_Latin1_General_CP1_CI_AI  LIKE '%' + @calle0 + '%' COLLATE SQL_Latin1_General_CP1_CI_AI, 1, 0);
	
	RETURN @result;

END

