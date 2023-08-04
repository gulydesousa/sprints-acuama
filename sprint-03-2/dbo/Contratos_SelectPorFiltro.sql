ALTER PROCEDURE [dbo].[Contratos_SelectPorFiltro] 
@filtro varchar(500) = NULL,
@soloComunitarios bit = NULL,
@soloFacturasE bit =NULL,
@orden varchar(100) = NULL,
@soloDocIdenIncorrectos BIT = NULL,
@soloVip BIT = NULL, --Si vale 1 se seleccionan solo los contratos V.I.P., si vale 0 o null se seleccionaran todos los contratos
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

SET @WHERE = dbo.AddConditionByBit(@WHERE, @soloComunitarios, 'AND EXISTS(SELECT C2.ctrcod FROM dbo.contratos AS C2 WHERE C2.ctrComunitario = C.ctrcod AND C2.ctrfecanu IS NULL)', NULL);

SET @WHERE = dbo.AddConditionByBit(@WHERE, @soloFacturasE,    'AND EXISTS(SELECT C3.ctrcod FROM dbo.contratos AS C3 WHERE (C3.ctrCod = C.ctrCod) AND (C3.ctrFace = 1))', NULL)	

SET @WHERE = dbo.AddConditionByBit(@WHERE, @soloDocIdenIncorrectos, 'AND (C.ctrTitDocIden IS NOT NULL AND 
																		     (
																		     CASE WHEN C.ctrTitTipDoc = (SELECT D.didcod FROM dociden AS D WHERE D.diddes = ''DNI'') THEN dbo.ValidarNIF(ctrTitDocIden) ELSE 1 END = 0 
																		     OR 
																		     CASE WHEN C.ctrTitTipDoc = (SELECT D.didcod FROM dociden AS D WHERE D.diddes = ''CIF'') THEN dbo.ValidarCIF(ctrTitDocIden) ELSE 1 END = 0
																			 OR
																		     CASE WHEN C.ctrTitTipDoc = (SELECT D.didcod FROM dociden AS D WHERE D.diddes = ''NIE'') THEN dbo.ValidarNIE(ctrTitDocIden) ELSE 1 END = 0
																			 )
																		  )', NULL)

SET @WHERE = dbo.AddConditionByBit(@WHERE, @soloVip, 'AND C.ctrTvipCodigo IS NOT NULL', NULL)

--[03]SELECT
SET @SQL = ' SELECT *
			, ROW_NUMBER() OVER (ORDER BY ' + 
									   CASE 
									   WHEN @orden IS NULL THEN ''  
									   WHEN @orden = 'direccionSuministro' THEN '(SELECT I.inmdireccion FROM dbo.inmuebles AS I WHERE I.inmcod = C.ctrinmcod), ' 
									   WHEN @orden = 'nombreTitular' THEN 'C.ctrTitNom, '
									   ELSE ''
									   END 
									 + ' ctrCod, ctrVersion) AS rowIndex
			FROM dbo.contratos AS C' + @where; 



--[04]Límites de la paginación
IF @pageLowerBound IS NOT NULL AND @pageUpperBound IS NOT NULL
SET @BETWEEN = CONCAT(' WHERE C.rowIndex BETWEEN ', @pageLowerBound, ' AND ' , @pageUpperBound, ' '); 

--[11]Registros por pagina
--SET @SQL = CONCAT('WITH CTR AS (', @SQL,  ') SELECT * FROM CTR AS C ', @BETWEEN, ' ORDER BY C.rowIndex ASC');
--SET @SQL = CONCAT('SELECT * FROM (', @SQL,  ') AS C ', @BETWEEN, ' ORDER BY C.rowIndex ASC');
SET @SQL = CONCAT('SELECT * FROM (', @SQL,  ') AS C ', @BETWEEN);				
EXEC(@SQL);

SELECT @registros=@@ROWCOUNT;

--[12]TotalRowCount: Registros totales
SET @SQL = ' SELECT COUNT(C.ctrCod) AS TotalRowCount FROM dbo.contratos AS C ' + @WHERE;
EXEC(@SQL);


--[99]TRAZA
DECLARE @spName VARCHAR(100) = FORMATMESSAGE('%s.%s', OBJECT_SCHEMA_NAME(@@PROCID), OBJECT_NAME(@@PROCID));
DECLARE @spParams VARCHAR(500) = FORMATMESSAGE('@filtro=''%s'', @soloComunitario=%i, @soloFacturasE=%i, @orden=''%s'', @soloDocIdenIncorrectos=%i, @soloVip=%i, @pageSize=%s, @pageIndex=%s'
								 , @filtro
								 , CAST(@soloComunitarios AS INT)
								 , CAST(@soloFacturasE AS INT)
								 , @orden
								 , CAST(@soloDocIdenIncorrectos AS INT)
								 , CAST(@soloVip AS INT)
								 , COALESCE(CAST(@pageSize AS VARCHAR), 'NULL')
								 , COALESCE(CAST(@pageIndex AS VARCHAR), 'NULL'));

DECLARE @spMessage VARCHAR(4000) = FORMATMESSAGE('Tiempo Ejecución: %s, Registros: %s' , FORMAT(DATEDIFF(MICROSECOND, @starttime, GETDATE()), 'N0', 'es-ES'),  FORMAT(@registros, 'N0', 'es-ES')); 
EXEC Trabajo.errorLog_Insert @spName, @spParams, @spMessage;

GO

