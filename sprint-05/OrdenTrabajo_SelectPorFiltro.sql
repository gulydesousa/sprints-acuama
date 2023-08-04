/*
EXEC [dbo].[OrdenTrabajo_SelectPorFiltro] 

EXEC [dbo].[OrdenTrabajo_SelectPorFiltro] '', 16, 2
*/


ALTER PROCEDURE [dbo].[OrdenTrabajo_SelectPorFiltro] 
@filtro varchar(500) = NULL,
@pageSize int = NULL,
@pageIndex int = NULL

AS 
SET NOCOUNT ON; 

DECLARE @pageLowerBound INT; 
DECLARE @pageUpperBound INT; 

DECLARE @SQL VARCHAR(MAX);
DECLARE @SQLPAGE VARCHAR(MAX);
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

SET @WHERE += IIF(@WHERE = '', ' WHERE ', ' AND ') + 'otmNum IS NULL'; 

--[03]SELECT
SET @SQL = 
'WITH CTR AS(
SELECT C.ctrCod
, C.ctrVersion
, C.ctrZonCod
, ROW_NUMBER() OVER (PARTITION BY C.ctrCod ORDER BY ctrVersion DESC ) AS RN
FROM dbo.Contratos AS C

), OT AS(
SELECT O.*
, C.ctrZonCod
, OC.otmNum
, Diferido = (SELECT ISNULL(SUM(difBaseImp*difUds), 0)
			   FROM dbo.diferidos
			   WHERE difCtrCod = O.otCtrCod
			   AND difOrigen = ''OT''
			   AND difOriNum = O.otNum) 
, rowIndex = ROW_NUMBER() OVER (ORDER BY O.otserscd, O.otsercod, O.otnum)
FROM [dbo].[ordenTrabajo] AS O
LEFT JOIN [dbo].[otManCom] AS OC 
ON OC.otmNum = O.otnum 
--Join con la version del contrato o la última version si esta está a NULL en la OT
LEFT JOIN CTR AS C
ON  (O.otctrCod IS NOT NULL AND O.otctrCod = C.ctrCod)
AND ((O.otCtrVersion IS NOT NULL AND O.otCtrVersion = C.CtrVersion) OR (O.otCtrVersion IS NULL AND C.RN=1))
' + @WHERE + ')';

--[04]Límites de la paginación
IF @pageLowerBound IS NOT NULL AND @pageUpperBound IS NOT NULL
SET @BETWEEN = CONCAT(' WHERE OT.rowIndex BETWEEN ', @pageLowerBound, ' AND ' , @pageUpperBound, ' '); 

--[11]Registros por pagina
SET @SQLPAGE = CONCAT(@SQL, 'SELECT * FROM OT ', @BETWEEN, ' ORDER BY OT.rowIndex');				
EXEC(@SQLPAGE);

SELECT @registros=@@ROWCOUNT;

--[12]TotalRowCount: Registros totales
SET @SQL = CONCAT(@SQL, 'SELECT COUNT(otnum) AS TotalRowCount FROM OT')
EXEC(@SQL);


--[99]TRAZA
DECLARE @spName VARCHAR(100) = FORMATMESSAGE('%s.%s', OBJECT_SCHEMA_NAME(@@PROCID), OBJECT_NAME(@@PROCID));
DECLARE @spParams VARCHAR(500) = FORMATMESSAGE('@filtro=''%s'', @pageSize=%s, @pageIndex=%s'
								 , @filtro
								 , COALESCE(CAST(@pageSize AS VARCHAR), 'NULL')
								 , COALESCE(CAST(@pageIndex AS VARCHAR), 'NULL'));

DECLARE @spMessage VARCHAR(4000) = FORMATMESSAGE('Tiempo Ejecución: %s, Registros: %s' , FORMAT(DATEDIFF(MICROSECOND, @starttime, GETDATE()), 'N0', 'es-ES'),  FORMAT(@registros, 'N0', 'es-ES')); 
EXEC Trabajo.errorLog_Insert @spName, @spParams, @spMessage;

GO


