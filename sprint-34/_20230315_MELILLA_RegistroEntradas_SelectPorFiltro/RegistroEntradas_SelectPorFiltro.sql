
ALTER PROCEDURE [dbo].[RegistroEntradas_SelectPorFiltro] 
	 @filtro			 VARCHAR(500) = NULL
	,@regEntRclCod		 INT = NULL
	,@regEntRegEntTipCod INT = NULL
	---------------
	,@regEntCliCod 		 INT = NULL
	,@regEntCtrCod 		 INT = NULL
	,@regEntCtrVer 		 SMALLINT = NULL
	,@regEntOtSerScd	 SMALLINT = NULL
	,@regEntOtSerCod	 SMALLINT = NULL
	,@regEntOtNum		 INT = NULL
	,@regEntDepCod		 INT = NULL
	,@regEntExcNumExp	 INT = NULL
	,@regEntUsuCodReg	 VARCHAR(10) = NULL
AS 
	SET NOCOUNT ON; 
	
IF @filtro is NULL SET @filtro = '' 
DECLARE @where_or_and as varchar(6) --Ponemos la palabra "WHERE" o "AND" según sea necesario
IF CHARINDEX('WHERE',@filtro) = 0 SET @where_or_and = ' WHERE ' ELSE SET @where_or_and = ' AND '

DECLARE @sql AS VARCHAR(MAX)	

SET @sql = ('SELECT regEntNum,regEntRegEntTipCod,regEntAsunto,regEntTexto,regEntFecReg,regEntRclCod, regEntCliCod,
				regEntCtrCod, regEntCtrVer, regEntOtSerScd, regEntOtSerCod, regEntOtNum, regEntDepCod, regEntExcNumExp
				, regEntUsuCodReg
			 FROM registroEntradas ' 
			+ @filtro + @where_or_and + 
			'('+ ISNULL(CAST(@regEntRclCod AS VARCHAR),'NULL') +' IS NULL OR '+ ISNULL(CAST(@regEntRclCod AS VARCHAR),'NULL') +' = regEntRclCod) AND ' +
			'('+ ISNULL(CAST(@regEntRegEntTipCod AS VARCHAR),'NULL') +' IS NULL OR '+ ISNULL(CAST(@regEntRegEntTipCod AS VARCHAR),'NULL') +' = regEntRegEntTipCod) AND ' +
			 
			'('+ ISNULL(CAST(@regEntCliCod AS VARCHAR),'NULL') +' IS NULL OR '+ ISNULL(CAST(@regEntCliCod AS VARCHAR),'NULL') +' = regEntCliCod) AND ' + 
			'('+ ISNULL(CAST(@regEntCtrCod AS VARCHAR),'NULL') +' IS NULL OR '+ ISNULL(CAST(@regEntCtrCod AS VARCHAR),'NULL') +' = regEntCtrCod) AND ' +			 
			'('+ ISNULL(CAST(@regEntCtrVer AS VARCHAR),'NULL') +' IS NULL OR '+ ISNULL(CAST(@regEntCtrVer AS VARCHAR),'NULL') +' = regEntCtrVer) AND ' + 
			'('+ ISNULL(CAST(@regEntOtSerScd AS VARCHAR),'NULL') +' IS NULL OR '+ ISNULL(CAST(@regEntOtSerScd AS VARCHAR),'NULL') +' = regEntOtSerScd) AND ' +
			'('+ ISNULL(CAST(@regEntOtSerCod AS VARCHAR),'NULL') +' IS NULL OR '+ ISNULL(CAST(@regEntOtSerCod AS VARCHAR),'NULL') +' = regEntOtSerCod) AND ' + 
			'('+ ISNULL(CAST(@regEntOtNum AS VARCHAR),'NULL') +' IS NULL OR '+ ISNULL(CAST(@regEntOtNum AS VARCHAR),'NULL') +' = regEntOtNum) AND ' +
			'('+ ISNULL(CAST(@regEntDepCod AS VARCHAR),'NULL') +' IS NULL OR '+ ISNULL(CAST(@regEntDepCod AS VARCHAR),'NULL') +' = regEntDepCod) AND ' + 
			'('+ ISNULL(CAST(@regEntExcNumExp AS VARCHAR),'NULL') +' IS NULL OR '+ ISNULL(CAST(@regEntExcNumExp AS VARCHAR),'NULL') +' = regEntExcNumExp) AND ' +
			'('+ ISNULL(CAST(@regEntUsuCodReg AS VARCHAR),'NULL') +' IS NULL OR '+ ISNULL(CAST(@regEntUsuCodReg AS VARCHAR),'NULL') +' = regEntUsuCodReg)') +
			' ORDER BY regEntFecReg DESC, regEntNum DESC ' 
	
exec(@sql)
GO


