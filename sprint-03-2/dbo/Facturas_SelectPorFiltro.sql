
ALTER PROCEDURE [dbo].[Facturas_SelectPorFiltro] 
@soloPendientes BIT = NULL,
@soloInspeccionables BIT = NULL,
@soloFacturase BIT = NULL,

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

--[00]Para medir el tiempo de ejecucion
DECLARE @starttime DATETIME =  GETDATE();
DECLARE @registros INT;

--[01]Límites de la paginación
SET @pageLowerBound = (@pageSize * @pageIndex)+1;
SET @pageUpperBound = @pageLowerBound + @pageSize-1;


--[02]WHERE
SET @WHERE = dbo.AddCondition(@WHERE, @filtro);

SET @WHERE = dbo.AddConditionByBit(@WHERE, @soloPendientes, 'AND facLecLector IS NULL AND facLecInspector IS NULL AND facInsInlCod IS NULL AND facLecInlCod IS NULL AND facLecInspectorFec IS NULL AND facLecLectorFec IS NULL AND EXISTS(SELECT * FROM perzona WHERE przcodzon=facZonCod AND przcodper=facpercod AND przcierrereal IS NULL)', NULL);
SET @WHERE = dbo.AddConditionByBit(@WHERE, @soloInspeccionables, 'AND ISNULL(facInspeccion, 0) <> 0', NULL);
SET @WHERE = dbo.AddConditionByBit(@WHERE, @soloFacturase, 'AND facEnvSERES IS NOT NULL', NULL);


--[03]SELECT
SET @FROM = ' FROM dbo.facturas AS F 
			  INNER JOIN dbo.contratos AS C ON C.ctrCod = F.facCtrCod AND C.ctrVersion = F.facCtrVersion ' + @WHERE; 


SET @SQL = ' SELECT facCod	
		   ,facPerCod
		   ,facCtrCod
		   ,facVersion
		   ,facCtrVersion
		   ,facSerScdCod
		   ,facSerCod
		   ,facNumero
		   ,facFecha
		   ,facClicod
		   ,facSerieRectif
		   ,facNumeroRectif
		   ,facFechaRectif
		   ,facLecAnt
		   ,facLecAntFec
		   ,facLecLector
		   ,facLecLectorFec
		   ,facLecInlCod
		   ,facLecInspector
		   ,facLecInspectorFec
		   ,facInsInlCod
		   ,facLecAct
		   ,facLecActFec
		   ,facConsumoReal
		   ,facConsumoFactura
		   ,facLote
		   ,facLectorEplCod
		   ,facLectorCttCod
		   ,facInspectorEplCod
		   ,facInspectorCttCod
		   ,facNumeroRemesa
		   ,facFechaRemesa
		   ,facZonCod
		   ,facInspeccion
		   ,facFecReg
		   ,facOTNum
		   ,facOTSerCod
		   ,facCnsFinal
		   ,facCnsComunitario
		   ,facFecContabilizacion
		   ,facFecContabilizacionAnu
		   ,facUsrContabilizacion
		   ,facUsrReg
		   ,facUsrContabilizacionAnu
	   	   ,facRazRectcod
		   ,facRazRectDescType
		   ,facMeRect
		   ,facMeRectType
		   ,facEnvSERES
		   ,facEnvSAP
		   ,facTipoEmit
		   , ROW_NUMBER() OVER (ORDER BY F.facPerCod DESC, F.facZoncod DESC, F.facCtrCod DESC, F.facCod DESC, F.facVersion DESC) AS rowIndex' + @FROM; 


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
DECLARE @spName VARCHAR(100) = FORMATMESSAGE('%s.%s', OBJECT_SCHEMA_NAME(@@PROCID), OBJECT_NAME(@@PROCID));
DECLARE @spParams VARCHAR(500) = FORMATMESSAGE('@filtro=''%s'', @soloPendientes=%s, @soloInspeccionables =%s, @soloFacturase=%s, @pageSize=%s, @pageIndex=%s'
								 , @filtro
								 ,  COALESCE(CAST(@soloPendientes AS VARCHAR), 'NULL')
								 ,  COALESCE(CAST(@soloInspeccionables AS VARCHAR), 'NULL')
								 ,  COALESCE(CAST(@soloFacturase AS VARCHAR), 'NULL')
								 , COALESCE(CAST(@pageSize AS VARCHAR), 'NULL')
								 , COALESCE(CAST(@pageIndex AS VARCHAR), 'NULL'));

DECLARE @spMessage VARCHAR(4000) = FORMATMESSAGE('Tiempo Ejecución: %s, Registros: %s' , FORMAT(DATEDIFF(MICROSECOND, @starttime, GETDATE()), 'N0', 'es-ES'),  FORMAT(@registros, 'N0', 'es-ES')); 
EXEC Trabajo.errorLog_Insert @spName, @spParams, @spMessage;

GO


