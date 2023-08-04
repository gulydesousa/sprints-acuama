--Incrementa el numerador y devuelve el nuevo valor
CREATE PROCEDURE Cobros_IncrementarNumerador
   @cbnScd AS SMALLINT
 , @cbnPpag AS SMALLINT
 AS

	DECLARE @RESULT AS INT = -1;

	BEGIN TRY
		
		DECLARE @NUMCOB TABLE (ID INT);
		
		UPDATE N 
		SET N.cbnNumero = N.cbnNumero + 1
		OUTPUT INSERTED.cbnNumero INTO @NUMCOB
		FROM dbo.cobrosNum AS N
		WHERE N.cbnScd = @cbnScd
		  AND N.cbnPpag = @cbnPpag;
		
		SELECT @RESULT = ID FROM @NUMCOB;

	END TRY
	BEGIN CATCH
		SET @RESULT = -1;
	END CATCH

	RETURN @RESULT;
GO
