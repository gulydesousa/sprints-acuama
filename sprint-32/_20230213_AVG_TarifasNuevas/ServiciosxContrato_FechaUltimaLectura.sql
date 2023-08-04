

/*

INSERT INTO dbo.ExcelConsultas
VALUES ('000/501',	'Servicios x FechaLectura', 'Servicios por Contrato a fecha de la última lectura', 0, '[InformesExcel].[ServiciosxContrato_FechaUltimaLectura]', '005', 'Servicios por contrato vigentes a la fecha de la ultima lectura.<br><i>Cuando no hay lectura se usa la fecha actual</i>');

INSERT INTO ExcelPerfil
VALUES('000/501', 'root', 3, NULL)

INSERT INTO ExcelPerfil
VALUES('000/501', 'jefeExp', 3, NULL)

INSERT INTO ExcelPerfil
VALUES('000/501', 'jefAdmon', 3, NULL)

*/


/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI></LI></NodoXML>';

EXEC [InformesExcel].[ServiciosxContrato_FechaUltimaLectura] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/

ALTER PROCEDURE [InformesExcel].[ServiciosxContrato_FechaUltimaLectura]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS

	--***********************************
	--Para una fecha determinadas seleccionan los clientes titulares de algún contrato activo.
	--**********
	--PARAMETROS: 
	--[1]Fecha: Fecha
	--NULL=>Recuperamos las ayudas hasta la fecha actual
	--**********

	SET NOCOUNT ON;   
	BEGIN TRY
	
	--********************
	--INICIO: 2 DataTables
	-- 1: Paramentros del encabezado
	-- 2: Gurpos
	-- 3: Datos
	--********************
	
	--DataTable[1]:  Parametros
	DECLARE @xml AS XML = @p_params;
	
	DECLARE @params TABLE (fInforme DATETIME);

	INSERT INTO @params
	OUTPUT INSERTED.*	
	SELECT fInforme = GETDATE()
	FROM @xml.nodes('NodoXML/LI')AS M(Item);

	--********************
	--VALIDAR PARAMETROS
	--********************

	DECLARE @ahora DATE = GETDATE();

	--********************
	SELECT C.ctrcod
	, C.ctrVersion
	, C.ctrLecturaUltFec
	, C.ctrzoncod
	, CS.ctslin
	INTO #CTR
	FROM dbo.contratos AS C
	INNER JOIN dbo.contratoServicio AS CS
	ON  (CS.ctsctrcod = C.ctrcod)
	--AND (CS.ctsfecalt <= ISNULL(C.ctrLecturaUltFec, @ahora))
	AND (
		(CS.ctsfecbaj IS NULL) 
		 OR 
		(C.ctrLecturaUltFec IS NULL AND CS.ctsfecbaj >= DATEADD(DAY,1,  @ahora)) 
		 OR 
		(CS.ctsfecbaj > C.ctrLecturaUltFec)		
		)
	WHERE C.ctrfecanu IS NULL;
	--********************
	
	SELECT C.ctrCod
	, C.ctrVersion
	, C.ctrLecturaUltFec
	, C.ctrzoncod
	--*****************
	, CS.ctsfecalt	
	, CS.ctsfecbaj
	, S.svccod 
	, S.svcdes
	, T.trfcod	
	, T.trfdes
	, O.orgCodigo
	, COUNT(S.svccod) OVER (PARTITION BY CS.ctsctrcod, S.svccod) AS NumLineas
	, ROW_NUMBER() OVER(PARTITION BY CS.ctsctrcod ORDER BY S.svccod ASC) AS RN
	, ROW_NUMBER() OVER(PARTITION BY CS.ctsctrcod, S.svccod ORDER BY T.trfcod ASC) AS RN_SVC
	INTO #CTS
	FROM #CTR AS C
	INNER JOIN dbo.contratoServicio AS CS
	ON C.ctrCod = CS.ctsctrcod
	AND C.ctslin = CS.ctslin
	INNER JOIN dbo.servicios AS S
	ON S.svccod = CS.ctssrv
	INNER JOIN dbo.tarifas AS T
	ON T.trfCod = CS.ctstar
	AND T.trfsrvcod = CS.ctssrv 
	INNER JOIN dbo.servicios AS SS
	ON SS.svccod = S.svccod
	LEFT JOIN dbo.organismos AS O
	ON O.orgCodigo = SS.svcOrgCod;

	
	WITH SVC AS (
	--Servicios que forman parte de las facturas en el periodo de consulta
	SELECT svccod, MAX(svcdes) AS svcdes, MAX(orgCodigo) AS orgCodigo, MAX(NumLineas) AS NumLineas FROM #CTS
	GROUP BY svccod)

	SELECT S.svccod
	, FORMATMESSAGE('%s (%03i)', S.svcdes, S.svccod) AS Grupo
	, ISNULL(S.orgCodigo, 0) AS svcOrgCod
	, S.NumLineas
	INTO #SVC
	FROM SVC AS S;
		
	--*******************************	
	--[R01] Nombre de Grupos 
	--Servicios con lineas en el periodo
	--#GRUPOS
	SELECT *
	, ROW_NUMBER() OVER (ORDER BY svcOrgCod, svccod) AS RN  
	INTO #GRUPOS
	FROM #SVC;

	SELECT * FROM #GRUPOS ORDER BY RN ASC;


	--*******************************
	--[R02] Raíz de los datos: Contratos 
	SELECT ctrCod AS [Contrato Cod.]
	, ctrVersion AS [Contrato Version]
	, ctrLecturaUltFec AS [Fecha Lectura]
	, ctrzoncod AS [Zona]
	FROM #CTS
	WHERE RN=1
	--IMPORTANTE mantener el orden
	ORDER BY ctrCod ASC;


	--[R*] CURSOR => Valores por servicio 
	--Hacemos un select por cada concepto que conforma el padrón
	--Cada datatable saldrá en el excel uno al lado del otro
	DECLARE @svccod AS INT;
	DECLARE @grupo AS VARCHAR(40);
	DECLARE @svcOrgCod AS INT;
	DECLARE @numLineas AS INT;
	DECLARE @lag_org AS INT;
	DECLARE @linea INT = 0;
	DECLARE @alias VARCHAR(5);
	DECLARE @sqlCols AS VARCHAR(MAX) = '';
	DECLARE @sqlQuery AS VARCHAR(MAX) = '';
	DECLARE @sqlSelect AS VARCHAR(MAX) = '';
	DECLARE @sqlJoin AS VARCHAR(MAX) = '';
	--*************
	--CURSOR: SVC_
	--[RN*] Valores por servicio 
	--DINAMICAMENTE HACEMOS LA SELECT PARA SACAR LOS DATOS DE CADA SERVICIO

	--[R101]SERVICIOS VIGENTES PARA LOS CONTRATOS
	DECLARE SVC_ 
	CURSOR FOR
	SELECT svccod, Grupo, svcOrgCod, NumLineas
	--Para ver si ha habido un cambio de organismo
	, LAG(svcOrgCod) OVER (ORDER BY RN) lag_org  
	FROM #GRUPOS 
	WHERE svccod >= 0
	--IMPORTANTE mantener el orden
	ORDER BY RN;

	OPEN SVC_
	FETCH NEXT FROM SVC_ INTO @svccod, @Grupo, @svcOrgCod, @NumLineas, @lag_org;
	
	WHILE @@FETCH_STATUS = 0  
	BEGIN
		
		--SELECT @grupo, @numLineas AS numLineas, @lag_org;

		--[R201]Para iterar sobre el mismo servicio cuando alguna factura en el rango de selección tiene mas de una linea para ese servicio.			
		SELECT @linea = @linea+1;
		WHILE @linea <=@numLineas
		BEGIN
	
			--[R203]Para construir las columnas del select (@sqlCols) => @sqlSelect
			SELECT @alias = FORMATMESSAGE('C%i', @linea) ;
	

			--[R202]SELECT 
			SET @sqlCols = ':.trfcod AS [Tarifa Cod.$], ISNULL(:.trfdes, ''***'') AS [Tarifa Des.$], :.ctsfecalt AS [Fec.Alta.$], :.ctsfecbaj AS [Fec.Baja.$]';

			SET @sqlCols = REPLACE(@sqlCols, '$', IIF(@linea=1, '', CAST(@linea AS VARCHAR(5)))); --Alias para la columna
			SET @sqlCols = REPLACE(@sqlCols, ':', @alias); --Alias para las tablas
	
			SET @sqlSelect = @sqlSelect + IIF(@linea > 1, ', ', '') + @sqlCols;
	
	
			--[R204]Para construir el JOIN en caso de haber multiples ocurrencias del servicio
			IF(@linea > 1)
				SET @sqlJoin = FORMATMESSAGE('%sLEFT JOIN #CTS AS : ON C1.ctrCod = :.ctrCod AND :.svcCod=%i AND :.RN_SVC=%i', @sqlJoin, @svccod,  @linea);
	
			SET @sqlJoin = REPLACE(@sqlJoin, ':', @alias); --Alias para las tablas
		
			SET @linea = @linea+1;
		END --[R201_fin]

		SET @sqlQuery = FORMATMESSAGE('SELECT %s FROM #CTS AS C LEFT JOIN #CTS AS C1 ON C.ctrCod = C1.ctrCod AND C1.svcCod=%i AND C1.RN_SVC=1 %s WHERE C.RN=1 ORDER BY C.ctrCod ASC', @sqlSelect, @svccod, @sqlJoin);

		--SELECT @sqlQuery;
		EXECUTE (@sqlQuery);

		--Limpiamos las variables para la siguiente iteración
		SELECT  @sqlCols='', @sqlSelect='', @sqlJoin=' ', @sqlQuery='', @linea = 0;

	
		FETCH NEXT FROM SVC_ INTO @svccod,  @Grupo, @svcOrgCod, @NumLineas, @lag_org;
	END  --[R101_fin]
	--CURSOR: SVC_
	DEALLOCATE SVC_;
	--*************

	
END TRY
	

BEGIN CATCH


	IF CURSOR_STATUS('global','SVC_') >= -1
	BEGIN
	IF CURSOR_STATUS('global','SVC_') > -1 CLOSE SVC_;
	DEALLOCATE SVC_;
	END

	SELECT  @p_errId_out = ERROR_NUMBER()
			,  @p_errMsg_out= ERROR_MESSAGE();
END CATCH

IF OBJECT_ID('tempdb.dbo.#CTR', 'U') IS NOT NULL 
DROP TABLE #CTR;

IF OBJECT_ID('tempdb.dbo.#CTS', 'U') IS NOT NULL 
DROP TABLE #CTS;

IF OBJECT_ID('tempdb.dbo.#SVC', 'U') IS NOT NULL 
DROP TABLE #SVC;

IF OBJECT_ID('tempdb.dbo.#GRUPOS', 'U') IS NOT NULL 
DROP TABLE #GRUPOS;



GO


