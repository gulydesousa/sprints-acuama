
--Incrementa el numerador y devuelve el nuevo valor
CREATE PROCEDURE [dbo].[Cobros_IncrementarNumerador]
   @cbnScd AS SMALLINT
 , @cbnPpag AS SMALLINT
 AS

	DECLARE @RESULT AS INT = -1;

	BEGIN TRY
		
		DECLARE @NUMCOB TABLE (ID INT);

		IF EXISTS (SELECT N.cbnNumero FROM dbo.cobrosNum AS N WHERE N.cbnScd = @cbnScd AND N.cbnPpag = @cbnPpag)
			--Incrementamos el numerador
			UPDATE N 
			SET N.cbnNumero = N.cbnNumero + 1
			OUTPUT INSERTED.cbnNumero INTO @NUMCOB
			FROM dbo.cobrosNum AS N
			WHERE N.cbnScd = @cbnScd
			  AND N.cbnPpag = @cbnPpag;
		ELSE 
			--Si el numerador no existe lo insertamos
			INSERT INTO dbo.cobrosNum 
			OUTPUT INSERTED.cbnNumero INTO @NUMCOB
			VALUES(@cbnScd, @cbnPpag, 1);
		
		SELECT @RESULT = ID FROM @NUMCOB;

	END TRY
	BEGIN CATCH
		SET @RESULT = -1;
	END CATCH

	RETURN @RESULT;
GO


