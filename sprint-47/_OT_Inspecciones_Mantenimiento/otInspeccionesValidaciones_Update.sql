/*
exec otInspeccionesValidaciones_Update @columna='aljibe',@descripcion='EL ACCESO AL ALJIBE Y/O GRUPO DE PRESIÓN SEPARADO DE LA PUERTA DE ACCESO AL CUARTO DE CONTADORES Y LA ZONA DE LECTURA',@descripcionCarta='qqqqq',@esCritica=0,@orden=6,@reqReglamentoCTE=0,@servicioCod=1

SELECT * FROM otInspeccionesValidaciones ORDER BY otivServicioCod, otivOrden
*/

CREATE PROCEDURE dbo.otInspeccionesValidaciones_Update
@columna VARCHAR(128),
@servicioCod TINYINT,
@esCritica BIT=NULL, 
@reqReglamentoCTE BIT=NULL, 
@orden TINYINT = NULL,
@descripcion VARCHAR(250) = NULL,
@descripcionCarta VARCHAR(250) = NULL
AS
SET NOCOUNT ON;

BEGIN TRY

	BEGIN TRAN
	DECLARE @iMax INT = 0;
	
	SELECT @iMax = MAX(otivOrden) 
	FROM  dbo.otInspeccionesValidaciones AS V
	WHERE otivServicioCod = @servicioCod AND otivColumna <> @columna;

	SET @orden = 
	CASE WHEN @orden IS NULL THEN  @iMax+1
	WHEN @orden>@iMax THEN @iMax+1
	WHEN @orden<0 THEN 0
	ELSE @orden END;

	UPDATE V SET
	otivCritica = @esCritica 
	, otivReqReglamentoCTE = @reqReglamentoCTE
	, otivOrden = @orden
	, otivDesc = @descripcion
	, otivDescParaCartas = @descripcionCarta
	OUTPUT INSERTED.*
	FROM dbo.otInspeccionesValidaciones AS V
	WHERE otivColumna = @columna
	AND otivServicioCod = @servicioCod;
	
	COMMIT TRAN
END TRY
BEGIN CATCH
	-- Si ocurre una excepción, se hace rollback a la transacción
	IF @@TRANCOUNT > 0
	ROLLBACK TRANSACTION;
	-- Luego, se devuelve la excepción
	THROW;
END CATCH
GO