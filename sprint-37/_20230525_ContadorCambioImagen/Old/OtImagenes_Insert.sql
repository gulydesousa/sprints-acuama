--DROP PROCEDURE OtImagen_Insert

CREATE PROCEDURE OtImagenes_Insert
	  @otSerScd SMALLINT 
	, @otSerCod SMALLINT
	, @otNum INTEGER 
	, @otiImagen IMAGE	
	, @otiTipoCodigo VARCHAR(5)
	, @otiDescripcion VARCHAR(250) = NULL
AS 

	SET NOCOUNT ON;

	INSERT INTO dbo.otImagenes(otiOtSerScd, otiOtSerCod, otiOtNum, otiTipoCodigo, otiImagen, otiDescripcion)
	SELECT @otSerScd, @otSerCod, @otNum, @otiTipoCodigo, @otiImagen, @otiDescripcion
	WHERE @otiImagen IS NOT NULL AND @otiTipoCodigo IS NOT NULL;

GO
