--EXEC dbo.OtImagenTipo_Select 'CCR'
--DROP PROCEDURE ContadorCambioImagenTipo_Select
--DROP TABLE contadorCambioImagenTipo
CREATE PROCEDURE dbo.OtImagenTipo_Select @otitCodigo VARCHAR(5)= NULL
AS

SET NOCOUNT ON;

SELECT *
FROM dbo.otImagenTipo AS T
WHERE @otitCodigo IS NULL OR T.otitCodigo=@otitCodigo;

GO