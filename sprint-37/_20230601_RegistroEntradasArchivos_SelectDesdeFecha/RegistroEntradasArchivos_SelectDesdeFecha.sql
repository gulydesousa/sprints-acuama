CREATE PROCEDURE [dbo].[RegistroEntradasArchivos_SelectDesdeFecha]
	@fechaRegDesde datetime = NULL,
	@fechaRegHasta datetime = NULL
AS 
	SET NOCOUNT ON; 
	
IF(@fechaRegDesde IS NULL)
	SET @fechaRegDesde = GETDATE()

IF(@fechaRegHasta IS NULL)
	SET @fechaRegHasta = GETDATE()

SELECT [regEntArcRegEntNum]
	  , regEntAsunto
	  , regEntArcId
	  , regEntTipDesc
	  , regEntCtrCod
	  , regEntCliCod
      ,[regEntArcFichero]
	  ,[regEntArcFicheroNombre] = FORMATMESSAGE('%i_%i_%s', regEntArcRegEntNum, regEntArcId, regEntArcFicheroNombre)
      ,[regEntArcFecReg]

  FROM [registroEntradasArchivos]
	  inner join registroEntradasTipo on [regEntArcRegEntTipCod] = regEntTipCod
	  inner join registroEntradas on regEntNum = regEntArcRegEntNum and regEntRegEntTipCod = regEntArcRegEntTipCod
  WHERE
		CAST(regEntArcFecReg AS date) >= @fechaRegDesde and CAST(regEntArcFecReg AS date) <= @fechaRegHasta
		AND regEntTipCod not in ( 40, 41)
		AND regEntArcFichero is not null

		--se excluyen:
		--3		Entrada Solicitud de Bonificación
		--40	Entrada Grupo SyV
		--41	Salida Grupo SyV
GO


