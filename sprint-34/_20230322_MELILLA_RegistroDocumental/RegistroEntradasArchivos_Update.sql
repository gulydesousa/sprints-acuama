-- =============================================
-- Author:		CPO
-- Create date: 05/03/10
-- =============================================
ALTER PROCEDURE [dbo].[RegistroEntradasArchivos_Update]
	 @regEntArcRegEntNum INT = NULL
	,@regEntArcId INT = NULL
	,@regEntArcRegEntTipCod INT = NULL
	,@regEntArcFichero VARBINARY(MAX) = NULL
	,@regEntArcFicheroNombre VARCHAR(256) = NULL
	,@regEntArcDes VARCHAR(100) = NULL
	,@regEntArcFecReg DATETIME = NULL
AS
	SET NOCOUNT OFF;


	--No se permite la entrada de registros sin fichero
	IF (@regEntArcFichero IS NULL OR @regEntArcFicheroNombre IS NULL)
		THROW 51000, 'El fichero es obligatorio para el registro de entrada.', 1;

    UPDATE registroEntradasArchivos SET 
 		   regEntArcFichero = @regEntArcFichero,
 		   regEntArcDes = @regEntArcDes,
 		   regEntArcFicheroNombre = @regEntArcFicheroNombre
    WHERE (
			@regEntArcRegEntNum=regEntArcRegEntNum AND 
		    @regEntArcId=regEntArcId AND
		    @regEntArcRegEntTipCod = regEntArcRegEntTipCod
		  )
GO


