--EXEC dbo.OtDocumentoTipo_Select @otdtCodigo='CCR'
--DROP PROCEDURE OtDocumentoTipo_Select
CREATE PROCEDURE dbo.OtDocumentoTipo_Select @otdtCodigo VARCHAR(5)= NULL
AS

SET NOCOUNT ON;

SELECT *
FROM dbo.otDocumentoTipo AS T
WHERE (@otdtCodigo IS NULL OR T.otdtCodigo=@otdtCodigo);

GO