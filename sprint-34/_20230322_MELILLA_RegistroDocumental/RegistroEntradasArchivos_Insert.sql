-- =============================================
-- Author:		CPO
-- Create date: 05/03/10
-- =============================================
ALTER PROCEDURE [dbo].[RegistroEntradasArchivos_Insert]
	 @regEntArcRegEntNum INT 
	,@regEntArcRegEntTipCod INT
	,@regEntArcId INT = NULL OUT
	,@regEntArcFichero VARBINARY(MAX) = NULL
	,@regEntArcFicheroNombre VARCHAR(256) = NULL
	,@regEntArcFecReg DATETIME = NULL
	,@regEntArcDes VARCHAR(100) = NULL
AS
	SET NOCOUNT OFF;

	SET @regEntArcId = ISNULL(@regEntArcId, (SELECT ISNULL(MAX(regEntArcId), 0) + 1 
											 FROM registroEntradasArchivos 
											 WHERE @regEntArcRegEntNum = regEntArcRegEntNum AND
												   @regEntArcRegEntTipCod = regEntArcRegEntTipCod))

	--No se permite la entrada de registros sin fichero
	IF (@regEntArcFichero IS NULL OR @regEntArcFicheroNombre IS NULL)
		THROW 51000, 'El fichero es obligatorio para el registro de entrada.', 1;

    INSERT INTO registroEntradasArchivos(
		   regEntArcRegEntNum
		  ,regEntArcRegEntTipCod
		  ,regEntArcId
		  ,regEntArcFichero
		  ,regEntArcFicheroNombre
		  ,regEntArcFecReg
		  ,regEntArcDes
	)
	VALUES(
		   @regEntArcRegEntNum
		  ,@regEntArcRegEntTipCod
		  ,@regEntArcId
		  ,@regEntArcFichero
		  ,@regEntArcFicheroNombre
		  ,ISNULL(@regEntArcFecReg,GETDATE())
		  ,@regEntArcDes
	)

GO


