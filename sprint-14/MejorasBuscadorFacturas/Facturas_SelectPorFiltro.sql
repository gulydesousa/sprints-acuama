/*
--TODOS SIN PAGINA 03:10
EXEC [dbo].[Facturas_SelectPorFiltro] @filtro=' fctTotal<-0.00001'

--UNA PAGINA 00:08 / 00:11
EXEC [dbo].[Facturas_SelectPorFiltro]  @pageSize=20, @pageIndex=5


*/


ALTER PROCEDURE [dbo].[Facturas_SelectPorFiltro] 
@soloPendientes BIT = NULL,
@soloInspeccionables BIT = NULL,
@soloFacturase BIT = NULL,
@estadoDeuda TINYINT = NULL, 

@filtro varchar(500) = NULL,
@pageSize int = NULL,
@pageIndex int = NULL
AS

SET NOCOUNT ON; 

DECLARE @pageLowerBound INT; 
DECLARE @pageUpperBound INT; 

DECLARE @FROM VARCHAR(MAX);
DECLARE @SQL VARCHAR(MAX);
DECLARE @WHERE AS VARCHAR(MAX);
DECLARE @BETWEEN AS VARCHAR(MAX)='';
DECLARE @FILTRO_TOTALFAC BIT = 0;
DECLARE @FILTRO_TOTALCOB BIT = 0;



--[00]Para medir el tiempo de ejecucion
DECLARE @starttime DATETIME =  GETDATE();
DECLARE @registros INT;

--[01]Límites de la paginación
SET @pageLowerBound = (@pageSize * @pageIndex)+1;
SET @pageUpperBound = @pageLowerBound + @pageSize-1;


--[02]WHERE
SET @WHERE = dbo.AddCondition(@WHERE, @filtro);


IF(EXISTS(SELECT fdeCod FROM dbo.facDeudaEstados WHERE @estadoDeuda IS NOT NULL AND fdeCod=@estadoDeuda))
BEGIN
	SET @WHERE += (SELECT ' AND ' + fdeCondicion FROM dbo.facDeudaEstados WHERE fdeCod=@estadoDeuda);
END

SET @WHERE = dbo.AddConditionByBit(@WHERE, @soloPendientes, 'AND facLecLector IS NULL AND facLecInspector IS NULL AND facInsInlCod IS NULL AND facLecInlCod IS NULL AND facLecInspectorFec IS NULL AND facLecLectorFec IS NULL AND EXISTS(SELECT * FROM perzona WHERE przcodzon=facZonCod AND przcodper=facpercod AND przcierrereal IS NULL)', NULL);
SET @WHERE = dbo.AddConditionByBit(@WHERE, @soloInspeccionables, 'AND ISNULL(facInspeccion, 0) <> 0', NULL);
SET @WHERE = dbo.AddConditionByBit(@WHERE, @soloFacturase, 'AND facEnvSERES IS NOT NULL', NULL);

SET @FILTRO_TOTALFAC = IIF(CHARINDEX('fctTotal', @WHERE)>0 OR @estadoDeuda IS NOT NULL, 1, 0);

IF(@FILTRO_TOTALFAC = 1)
BEGIN
	SET @WHERE = REPLACE(@WHERE, 'T.fctTotal', 'ROUND(T.fctTotal, 2)')
END

--[03]SELECT
SET @FROM = ' FROM dbo.facturas AS F 
			  INNER JOIN dbo.contratos AS C ON C.ctrCod = F.facCtrCod AND C.ctrVersion = F.facCtrVersion '

SET @FROM = @FROM + IIF(@FILTRO_TOTALFAC=1, ' INNER JOIN dbo.facTotales AS T ON T.fctCod = F.facCod AND T.fctPerCod = F.facPerCod AND T.fctCtrCod = F.facCtrCod AND T.fctVersion=F.facVersion ', '');


SET @FROM = @FROM + @WHERE; 



SET @SQL = ' SELECT facCod	
		   , facPerCod
		   , facCtrCod
		   , facVersion
		   , facCtrVersion
		   , facSerScdCod
		   , facSerCod
		   , facNumero
		   , facFecha
		   , facClicod
		   , facSerieRectif
		   , facNumeroRectif
		   , facFechaRectif
		   , facLecAnt
		   , facLecAntFec
		   , facLecLector
		   , facLecLectorFec
		   , facLecInlCod
		   , facLecInspector
		   , facLecInspectorFec
		   , facInsInlCod
		   , facLecAct
		   , facLecActFec
		   , facConsumoReal
		   , facConsumoFactura
		   , facLote
		   , facLectorEplCod
		   , facLectorCttCod
		   , facInspectorEplCod
		   , facInspectorCttCod
		   , facNumeroRemesa
		   , facFechaRemesa
		   , facZonCod
		   , facInspeccion
		   , facFecReg
		   , facOTNum
		   , facOTSerCod
		   , facCnsFinal
		   , facCnsComunitario
		   , facFecContabilizacion
		   , facFecContabilizacionAnu
		   , facUsrContabilizacion
		   , facUsrReg
		   , facUsrContabilizacionAnu
	   	   , facRazRectcod
		   , facRazRectDescType
		   , facMeRect
		   , facMeRectType
		   , facEnvSERES
		   , facEnvSAP
		   , facTipoEmit' +
		   IIF(@FILTRO_TOTALFAC=1, ', T.fctTotal, T.fctFacturado, T.fctCobrado', '') +
		   ', ROW_NUMBER() OVER (ORDER BY F.facPerCod DESC, F.facZoncod DESC, F.facCtrCod DESC, F.facCod DESC, F.facVersion DESC) AS rowIndex' + @FROM; 


--[04]Límites de la paginación
IF @pageLowerBound IS NOT NULL AND @pageUpperBound IS NOT NULL
SET @BETWEEN = CONCAT(' WHERE F.rowIndex BETWEEN ', @pageLowerBound, ' AND ' , @pageUpperBound, ' '); 

--[11]Registros por pagina
--SET @SQL = CONCAT('WITH FACS AS (', @SQL,  ') SELECT * FROM FACS AS F ', @BETWEEN, ' ORDER BY F.rowIndex ASC');
--SET @SQL = CONCAT('SELECT * FROM (', @SQL,  ') AS F ', @BETWEEN, ' ORDER BY F.rowIndex ASC');	
SET @SQL = CONCAT('SELECT * FROM (', @SQL,  ') AS F ', @BETWEEN);		
EXEC(@SQL);
SELECT @registros=@@ROWCOUNT;


--[12]TotalRowCount: Registros totales
SET @SQL = 'SELECT COUNT(F.facCod) AS TotalRowCount' + @FROM;
EXEC(@SQL);


--[99]TRAZA
DECLARE @FAC_APERTURA VARCHAR(25) = '1.0';
SELECT  @FAC_APERTURA = pgsValor FROM dbo.parametros WHERE pgsclave = 'FAC_APERTURA';
  
DECLARE @spName VARCHAR(100) = FORMATMESSAGE('%s.%s', OBJECT_SCHEMA_NAME(@@PROCID), OBJECT_NAME(@@PROCID));
DECLARE @spParams VARCHAR(500) = FORMATMESSAGE('FAC_APERTURA= ''%s'', @filtro=''%s'', @soloPendientes=%s, @soloInspeccionables =%s, @soloFacturase=%s, @pageSize=%s, @pageIndex=%s'
								 , @FAC_APERTURA
								 , @filtro
								 , COALESCE(CAST(@soloPendientes AS VARCHAR), 'NULL')
								 , COALESCE(CAST(@soloInspeccionables AS VARCHAR), 'NULL')
								 , COALESCE(CAST(@soloFacturase AS VARCHAR), 'NULL')
								 , COALESCE(CAST(@pageSize AS VARCHAR), 'NULL')
								 , COALESCE(CAST(@pageIndex AS VARCHAR), 'NULL'));

DECLARE @spMessage VARCHAR(4000) = FORMATMESSAGE('Tiempo Ejecución: %s, Registros: %s %s %s' 
								 , FORMAT(DATEDIFF(MILLISECOND, @starttime, GETDATE()), 'N0', 'es-ES')
								 , FORMAT(@registros, 'N0', 'es-ES')
								 , CHAR(13)
								 , @FROM); 
EXEC Trabajo.errorLog_Insert @spName, @spParams, @spMessage;


GO


