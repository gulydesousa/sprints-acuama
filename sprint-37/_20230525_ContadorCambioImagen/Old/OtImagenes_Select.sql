--EXEC [OtImagenes_Select] @otNum=22997, @otitCodigo= 'CCR'
--DROP PROCEDURE [OtImagen_Select]
--SELECT * FROM otImagen
CREATE PROCEDURE [dbo].[OtImagenes_Select]
@otSerScd SMALLINT = NULL,
@otSerCod SMALLINT = NULL,
@otNum INT = NULL, 
@otitCodigo VARCHAR(5) = NULL

AS 
	SET NOCOUNT ON; 
	SELECT I.*, T.otitDescripcion, T.otitFormato
	FROM dbo.otImagenes AS I
	LEFT JOIN dbo.otImagenTipo AS T	
	ON I.otiTipoCodigo = T.otitCodigo
	
	WHERE (@otSerScd IS NULL   OR I.otiOtSerScd = @otSerScd)
	AND   (@otSerCod IS NULL   OR I.otiOtSerCod = @otSerCod)
	AND   (@otNum IS NULL	   OR I.otiOtNum = @otNum)
	AND	  (@otitCodigo IS NULL OR T.otitCodigo = @otitCodigo)
	ORDER BY otiOtSerScd, otiOtSerCod, otiOtNum;


GO


