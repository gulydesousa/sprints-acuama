--Incrementa el numerador y devuelve el nuevo valor
CREATE PROCEDURE Series_IncrementarNumerador
   @sercod AS SMALLINT
 , @serscd AS SMALLINT
 , @incremento AS INT = 1
 AS

	DECLARE @RESULT AS INT = -1;

	BEGIN TRY
		
		DECLARE @NUMFRA TABLE (ID INT);
		
		UPDATE S 
		SET S.sernumfra = S.sernumfra + @incremento
		OUTPUT DELETED.sernumfra + 1 INTO @NUMFRA
		FROM dbo.series AS S
		WHERE S.sercod = @sercod
		  AND S.serscd = @serscd;
		
		SELECT @RESULT = ID FROM @NUMFRA;

	END TRY
	BEGIN CATCH
		SET @RESULT = -1;
	END CATCH

	RETURN @RESULT;
GO
