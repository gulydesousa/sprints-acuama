ALTER PROCEDURE [dbo].[Cobros_SelectPorFiltro] 
@filtro varchar(500) = NULL,
@cobctr int = NULL,

@pageSize int = NULL,
@pageIndex int = NULL
AS 

SET NOCOUNT ON; 

DECLARE @pageLowerBound INT; 
DECLARE @pageUpperBound INT; 

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

SET @WHERE = dbo.AddCondition(@WHERE, 'AND cobCtr = ' + CAST(@cobctr AS VARCHAR));


--[03]SELECT
SET @SQL = ' SELECT *
			, ROW_NUMBER() OVER (ORDER BY cobScd, cobPpag, cobNum) AS rowIndex
			FROM dbo.cobros AS C' + @where; 


--[04]Límites de la paginación
IF @pageLowerBound IS NOT NULL AND @pageUpperBound IS NOT NULL
SET @BETWEEN = CONCAT(' WHERE C.rowIndex BETWEEN ', @pageLowerBound, ' AND ' , @pageUpperBound, ' '); 

--[11]Registros por pagina
--SET @SQL = CONCAT('WITH COB AS (', @SQL,  ') SELECT * FROM COB AS C ', @BETWEEN, ' ORDER BY C.rowIndex ASC');		
--SET @SQL = CONCAT('SELECT * FROM (', @SQL,  ') AS C ', @BETWEEN, ' ORDER BY C.rowIndex ASC');
SET @SQL = CONCAT('SELECT * FROM (', @SQL,  ') AS C ', @BETWEEN);		

EXEC(@SQL);
SELECT @registros=@@ROWCOUNT;

--[12]TotalRowCount: Registros totales
SET @SQL = ' SELECT COUNT(C.cobNum) AS TotalRowCount FROM dbo.cobros AS C ' + @WHERE;
EXEC(@SQL);


--[99]TRAZA
DECLARE @spName VARCHAR(100) = FORMATMESSAGE('%s.%s', OBJECT_SCHEMA_NAME(@@PROCID), OBJECT_NAME(@@PROCID));
DECLARE @spParams VARCHAR(500) = FORMATMESSAGE('@filtro=''%s'', @cobctr=%i, @pageSize=%s, @pageIndex=%s'
								 , @filtro
								 , CAST(@cobctr AS INT)
								 , COALESCE(CAST(@pageSize AS VARCHAR), 'NULL')
								 , COALESCE(CAST(@pageIndex AS VARCHAR), 'NULL'));

DECLARE @spMessage VARCHAR(4000) = FORMATMESSAGE('Tiempo Ejecución: %s, Registros: %s' , FORMAT(DATEDIFF(MICROSECOND, @starttime, GETDATE()), 'N0', 'es-ES'),  FORMAT(@registros, 'N0', 'es-ES')); 
EXEC Trabajo.errorLog_Insert @spName, @spParams, @spMessage;



GO


