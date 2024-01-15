/*
--SELECT * FROM Trabajo.ExcelConsultas_Plantillas
--SELECT * FROM ExcelConsultas
--DELETE FROM ExcelPerfil WHERE ExPCod='000/015'
--DELETE FROM dbo.ExcelConsultas WHERE ExcCod='000/015'
INSERT INTO dbo.ExcelConsultas VALUES ('000/015','Padrón x F.Lectura', 'Padrón por fecha de lecturas', 11, '[InformesExcel].[PadronxFechaLectura_EXCEL]', 'CSVH', 'Padrón por fecha de lectura', NULL, NULL, NULL, NULL);
INSERT INTO ExcelPerfil VALUES('000/015', 'root', 4, NULL)
INSERT INTO ExcelPerfil VALUES('000/015', 'direcc', 4, NULL)
*/


/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_error_out INT;
DECLARE @p_errMsg_out   NVARCHAR(MAX);

SET @p_params='<NodoXML><LI><fechaD>20231201</fechaD><fechaH>20231231</fechaH><zonaD></zonaD><zonaH></zonaH></LI></NodoXML>'

EXEC [InformesExcel].[PadronxFechaLectura_EXCEL] @p_params, @p_error_out OUTPUT, @p_errMsg_out OUTPUT;
*/

CREATE PROCEDURE [InformesExcel].[PadronxFechaLectura_EXCEL]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS

	--*******
	--PLANTILLA: 005
	--Se retorna: Parametros, Grupos, Raíz del grupo, Datos*
	--Grupos: Son los encabezados para el datatable de Datos*
	--*******
	--PARAMETROS: 
	--[1]periodoD: periodo desde
	--[2]periodoH: periodo hasta
	--*******
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
	DECLARE @AHORA DATETIME = (SELECT dbo.GETACUAMADATE());
	DECLARE @HOY DATE = @AHORA;
	DECLARE @params TABLE (fInforme DATETIME, fechaD DATE NULL, fechaH DATE NULL, zonaD VARCHAR(4) NULL, zonaH VARCHAR(4) NULL);

	INSERT INTO @params
	SELECT fInforme = GETDATE() 
		 , fechaD = CASE WHEN M.Item.value('fechaD[1]', 'DATE') = '19000101' THEN NULL ELSE M.Item.value('fechaD[1]', 'DATE') END
		 , fechaH = CASE WHEN M.Item.value('fechaH[1]', 'DATE') = '19000101' THEN NULL ELSE M.Item.value('fechaH[1]', 'DATE') END
		 , zonaD = M.Item.value('zonaD[1]', 'VARCHAR(4)')
		 , zonaH = M.Item.value('zonaH[1]', 'VARCHAR(4)')
	FROM @xml.nodes('NodoXML/LI') AS M(Item);

	--VALIDAR PARAMETROS
	IF EXISTS(SELECT 1 FROM @params WHERE fechaD IS NULL) 
		UPDATE @params SET fechaD = DATEADD(WEEK, -1, @HOY);
	IF EXISTS(SELECT 1 FROM @params WHERE fechaH IS NULL) 
		UPDATE @params SET fechaH = DATEADD(DAY, 1, @HOY);
	IF EXISTS(SELECT 1 FROM @params WHERE zonaD='') 
		UPDATE @params SET zonaD = (SELECT MIN(zoncod) FROM dbo.zonas);
	IF EXISTS(SELECT 1 FROM @params WHERE zonaH='') 
		UPDATE @params SET zonaH = (SELECT MAX(zoncod) FROM dbo.zonas);

	SELECT * FROM @params;
	
	--PARAMETROS
	DECLARE @zonaD VARCHAR(4), @zonaH VARCHAR(4), @fDesde DATE, @fHasta DATE;
	SELECT @zonaD = P.zonaD, @zonaH = P.zonaH, @fDesde = P.fechaD, @fHasta = DATEADD(DAY, 1,P.fechaH)
	FROM @params AS P;

	SELECT * 
	FROM (VALUES('Padrón por bloques')) 
	AS DataTables(Grupo)
	--********************
	--DataTable[2]:  Datos
	--*******************	

	--[01]Facturas que forman parte del periodo de seleccion 	
	--#FACS
	SELECT ROW_NUMBER() OVER (ORDER BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion) AS ID
	, F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion
	, F.facCtrVersion
	, F.facNumero
	, F.facFecha
	, F.facFechaRectif
	, F.facLecActFec
	, F.facLecAct
	, F.facLecAntFec
	, F.facLecAnt
	, F.facConsumoFactura
	, F.facZonCod
	, CAST(NULL AS MONEY) AS facTotal
	INTO #FACS
	FROM dbo.facturas AS F
	INNER JOIN contratos AS C
	ON  C.ctrcod = F.facCtrCod
	AND C.ctrversion = F.facCtrVersion
	INNER JOIN @params AS P
	ON  F.facFechaRectif IS NULL
	AND ((F.facLecLectorFec IS NOT NULL AND F.facLecLectorFec >= @fDesde AND F.facLecLectorFec < @fHasta)
	  OR (F.facLecLectorFec IS NULL AND F.facZonCod = 51 AND F.facFecha >= @fHasta AND (C.ctrfecreg >= @fDesde AND C.ctrfecreg <  @fHasta)))
	AND F.facFechaRectif IS NULL

	WHERE (@zonaD IS NULL OR C.ctrzoncod >= @zonaD) AND (@zonaH IS NULL OR C.ctrzoncod <= @zonaH);
	
	--[02]Lineas de factura que se listan en el informe
	--#FCL
	SELECT F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion
	, FL.fclNumLinea
	, FL.fclTrfSvCod
	, FL.fclTrfCod
	, T.trfdes
	, T.trfAplicarEscMin
	, T.trfescala1
	, ISNULL(FL.fclUnidades1, 0) + ISNULL(FL.fclUnidades2, 0) + ISNULL(FL.fclUnidades3, 0) 
	+ ISNULL(FL.fclUnidades4, 0) + ISNULL(FL.fclUnidades5, 0) + ISNULL(FL.fclUnidades6, 0)
	+ ISNULL(FL.fclUnidades7, 0) + ISNULL(FL.fclUnidades8, 0) + ISNULL(FL.fclUnidades9, 0) AS [Consumo]

	--*********
	--Unidades
	, UDS1 = ISNULL(FL.fclUnidades1, 0) 
	, UDS2 = ISNULL(FL.fclUnidades2, 0)
	, UDS3 = ISNULL(FL.fclUnidades3, 0) 
	, UDS4 = ISNULL(FL.fclUnidades4, 0)
	, UDS5 = ISNULL(FL.fclUnidades5, 0)
	, UDS6 = ISNULL(FL.fclUnidades6, 0)
	, UDS7 = ISNULL(FL.fclUnidades7, 0)
	, UDS8 = ISNULL(FL.fclUnidades8, 0)
	, UDS9 = ISNULL(FL.fclUnidades9, 0) 
	--*********

	, ISNULL(FL.fclUnidades, 0) AS [Cuota]

	, ISNULL(FL.fclUnidades1, 0)* ISNULL(FL.fclPrecio1, 0) 
	+ ISNULL(FL.fclUnidades2, 0)* ISNULL(FL.fclPrecio2, 0)  
	+ ISNULL(FL.fclUnidades3, 0)* ISNULL(FL.fclPrecio3, 0)  
	+ ISNULL(FL.fclUnidades4, 0)* ISNULL(FL.fclPrecio4, 0)  
	+ ISNULL(FL.fclUnidades5, 0)* ISNULL(FL.fclPrecio5, 0)  
	+ ISNULL(FL.fclUnidades6, 0)* ISNULL(FL.fclPrecio6, 0)  
	+ ISNULL(FL.fclUnidades7, 0)* ISNULL(FL.fclPrecio7, 0)  
	+ ISNULL(FL.fclUnidades8, 0)* ISNULL(FL.fclPrecio8, 0)  
	+ ISNULL(FL.fclUnidades9, 0)* ISNULL(FL.fclPrecio9, 0)  AS [Variable]
	
	--*********
	--Importes
	, IMP1 = ISNULL(FL.fclUnidades1, 0)* ISNULL(FL.fclPrecio1, 0) 
	, IMP2 = ISNULL(FL.fclUnidades2, 0)* ISNULL(FL.fclPrecio2, 0)  
	, IMP3 = ISNULL(FL.fclUnidades3, 0)* ISNULL(FL.fclPrecio3, 0)  
	, IMP4 = ISNULL(FL.fclUnidades4, 0)* ISNULL(FL.fclPrecio4, 0)  
	, IMP5 = ISNULL(FL.fclUnidades5, 0)* ISNULL(FL.fclPrecio5, 0)  
	, IMP6 = ISNULL(FL.fclUnidades6, 0)* ISNULL(FL.fclPrecio6, 0)  
	, IMP7 = ISNULL(FL.fclUnidades7, 0)* ISNULL(FL.fclPrecio7, 0)  
	, IMP8 = ISNULL(FL.fclUnidades8, 0)* ISNULL(FL.fclPrecio8, 0)  
	, IMP9 = ISNULL(FL.fclUnidades9, 0)* ISNULL(FL.fclPrecio9, 0)  
	--*********

	, ISNULL(FL.fclUnidades, 0)* ISNULL(FL.fclPrecio, 0) AS [Fijo]

	, FL.fclImpuesto AS [Impuesto]
	, FL.fclImpImpuesto [ImporteImpuesto]
	, FL.fclBase
	, FL.fclTotal
	, FL.fclFecLiq	
	INTO #FCL
	FROM #FACS AS F
	INNER JOIN dbo.faclin AS FL
	ON F.facCod = FL.fclFacCod
	AND F.facPerCod = FL.fclFacPerCod
	AND F.facCtrCod = FL.fclFacCtrCod
	AND F.facVersion = FL.fclFacVersion
	AND FL.fclFecLiq IS NULL
	INNER JOIN dbo.tarifas AS T
	ON T.trfsrvcod = FL.fclTrfSvCod
	AND T.trfcod = FL.fclTrfCod;
	


	--[03]Total de las lineas no liquidadas de la factura
	--#FACS.facTotal
	WITH FACT AS(
	SELECT FL.facCod, FL.facPerCod, FL.facCtrCod, FL.facVersion
	, SUM(FL.fclTotal) AS facTotal
	FROM #FCL AS FL
	GROUP BY FL.facCod, FL.facPerCod, FL.facCtrCod, FL.facVersion)
	
	UPDATE F
	SET F.facTotal = ROUND(T.facTotal, 2) 
	FROM #FACS AS F
	INNER JOIN FACT AS T
	ON T.facCod = F.facCod
	AND T.facPerCod = F.facPerCod
	AND T.facCtrCod = F.facCtrCod
	AND T.facVersion = F.facVersion;

	--[04]CONTADOR POR FACTURA
	--#CONTADORES
	WITH C AS(
	SELECT F.facCod
	, F.facCtrCod
	, F.facPerCod
	, F.facVersion
	, F.facFecha
	, C.conID
	, CC.ctcFec
	, CC.ctcOperacion
	, C.conNumSerie
	, C.conDiametro
	, ROW_NUMBER() OVER (PARTITION BY F.facCod, F.facCtrCod, F.facPerCod, F.facVersion ORDER BY CC.ctcFec DESC, CAST(CC.ctcFecReg AS SMALLDATETIME) DESC, ctcOperacion ASC) AS RN
	FROM #FACS AS F
	LEFT JOIN dbo.ctrcon AS CC 
	ON CC.ctcCtr = F.facCtrCod
	AND ((F.facLecActFec IS NOT NULL AND CC.ctcFec <= F.facLecActFec) OR (F.facLecActFec IS NULL AND CC.ctcFec <= GETDATE()))
	LEFT JOIN dbo.contador AS C
	ON C.conID = CC.ctcCon)

	SELECT facCod
	, facPerCod
	, facCtrCod
	, facVersion
	, conID
	, ctcFec
	, ctcOperacion
	, conNumSerie
	, conDiametro 
	INTO #CONTADORES
	FROM C 
	WHERE RN=1 AND ctcOperacion = 'I';

	--[05]Datos del padrón para el informe
	--#PADRON	
	SELECT facCod
	, facPerCod
	, facCtrCod
	, facVersion
	, fclTrfSvCod
	, CAST(IIF(trfAplicarEscMin=1 AND Consumo<trfescala1, trfescala1, Consumo) AS INT) AS Consumo
	
	, UDS1, IMP1
	, UDS2, IMP2
	, UDS3, IMP3
	, UDS4, IMP4
	, UDS5, IMP5
	, UDS6, IMP6
	, UDS7, IMP7
	, UDS8, IMP8
	, UDS9, IMP9

	, CAST(Cuota AS INT) AS Cuota

	, CAST(Variable AS DECIMAL(12, 4)) AS Variable
	, CAST(Fijo AS DECIMAL(12, 4)) AS Fijo
	, CAST(Variable+Fijo AS DECIMAL(12, 4)) AS Importe

	, CAST(Impuesto AS DECIMAL(12, 2)) AS Impuesto
	, FORMATMESSAGE('%d-%s', fclTrfCod, trfdes) AS Tarifa
	, CAST(ImporteImpuesto AS DECIMAL(12, 2)) AS ImporteImpuesto
	INTO #PADRON
	FROM #FCL;
	
	---------------------------------
	--RESULTADOS EXCEL
	---------------------------------
	--[R00]Servicios que forman parte del informe
	--#SCV

	
	WITH SERV AS (
	--Servicios que forman parte de las facturas en el periodo de consulta
	SELECT DISTINCT fclTrfSvCod 
	FROM #FCL 
	WHERE fcltotal <> 0
	)
	
	SELECT T.svccod
	, T.svcdes
	INTO #SVC
	FROM SERV AS S
	INNER JOIN dbo.Servicios AS T
	ON T.svccod = S.fclTrfSvCod;

	
	--*******************************
	--[R03]:  Detalles de las facturas 
	SELECT [Contrato]	= F.facCtrCod 
	, [Cod.Periodo] = F.facPerCod  
	, [Uso]			= FORMATMESSAGE('%i-%s', C.ctrUsoCod, U.usodes)
	, [CIF/NIF]		= C.ctrTitDocIden 
	, [Titular]		= C.ctrTitNom 
	, [Fecha Factura]		= FORMAT(F.facFecha, 'dd/MM/yyyy')  
	, [Nº Factura Oficial]	= F.facNumero
	, [Zona]		= facZonCod
	, [Calibre]		= CCC.conDiametro
	, [Consumo factura (cns)]		= F.facConsumoFactura
	, [Total factura (euros)]	= FORMAT(F.facTotal , 'N2')
	FROM #FACS AS F
	INNER JOIN dbo.periodos AS P
	ON P.percod = F.facPerCod
	INNER JOIN dbo.contratos AS C
	ON C.ctrCod = F.facCtrCod
	AND C.ctrVersion = F.facCtrVersion
	LEFT JOIN dbo.usos AS U
	ON U.usocod = C.ctrUsoCod
	LEFT JOIN  #CONTADORES AS CCC
	ON  CCC.facCod = F.facCod
	AND CCC.facPerCod = F.facPerCod
	AND CCC.facCtrCod = F.facCtrCod
	AND CCC.facVersion = F.facVersion
	--IMPORTANTE mantener el orden
	ORDER BY ID ASC;
	--*******************************
	
	--[RN]: Todas las facturas con todos los servicios y los datos del padron
	--#CONCEPTOS
	SELECT F.ID
	, S.svccod 
	, P.fclTrfSvCod
	, P.Tarifa
	, ISNULL(P.Consumo, 0) AS Consumo
	, P.Importe
	, P.Variable
	, P.Fijo
	, P.Cuota
	, P.UDS1, P.IMP1
	, P.UDS2, P.IMP2
	, P.UDS3, P.IMP3
	, P.UDS4, P.IMP4
	, P.UDS5, P.IMP5
	, P.UDS6, P.IMP6
	, P.UDS7, P.IMP7
	, P.UDS8, P.IMP8
	, P.UDS9, P.IMP9
	, ISNULL(P.Impuesto, 0) AS Impuesto
	, ISNULL(P.ImporteImpuesto, 0) AS ImporteImpuesto
	--RN=1: Si varios servicios se unifican en un solo concepto, los ordenamos por factura 
	--y nos quedamos con el que tiene el primer servicio del grupo
	, ROW_NUMBER() OVER (PARTITION BY  F.ID, S.svccod ORDER BY P.fclTrfSvCod DESC) AS RN  
	, COUNT(fclTrfSvCod) OVER (PARTITION BY  F.ID, fclTrfSvCod) AS CN
	
	INTO #CONCEPTOS
	FROM #FACS AS F
	LEFT JOIN #SVC AS S
	ON S.svccod IS NOT NULL
	LEFT JOIN #PADRON AS P
	ON F.facCod = P.facCod
	AND F.facPerCod = P.facPerCod
	AND F.facCtrCod = P.facCtrCod
	AND F.facVersion = P.facVersion
	AND S.svccod = P.fclTrfSvCod;


	
	--[R*] CURSOR => Valores por servicio 
	--Hacemos un select por cada concepto que conforma el padrón
	--Cada datatable saldrá en el excel uno al lado del otro
	
	DECLARE @svcCod		INT;
	DECLARE @servicio	VARCHAR(250);
	DECLARE @desglose	INT;
	DECLARE @iDesglose	INT;
	
		
	DECLARE @sqlConcepto AS VARCHAR(250) = '';
	DECLARE @sqlImporte AS VARCHAR(500) = '';
	DECLARE @sqlCols AS VARCHAR(MAX) = '';
	DECLARE @sqlQuery AS VARCHAR(MAX) = '';

	
	--*************
	--CURSOR: SVC_
	--[RN*] Valores por servicio 
	DECLARE SVC_ CURSOR FOR
	WITH CONCEPTOS AS(
	SELECT svccod
	, desglose = MAX(CN) 
	FROM #CONCEPTOS AS C
	GROUP BY svccod)

	SELECT S.SvcCod
	, S.svcDes
	, C.desglose
	, 1
	FROM CONCEPTOS AS C
	LEFT JOIN #SVC AS S
	ON C.svcCod= S.svcCod
	--IMPORTANTE mantener el orden
	ORDER BY SvcCod;
	
	OPEN SVC_
	FETCH NEXT FROM SVC_ INTO @svcCod, @servicio, @desglose, @iDesglose

	WHILE @@FETCH_STATUS = 0  
	BEGIN
	
	--SELECT  svcCod=@svcCod, servicio=@servicio, desglose=@desglose;

	SET @sqlConcepto = FORMATMESSAGE('''%i - %s'' AS Servicio, ', @svcCod, @servicio);

	WHILE(@iDesglose<=@desglose)
	BEGIN
		SELECT @sqlImporte = CONCAT(
				  IIF(SUM(IIF(UDS1<>0, 1, 0))>0, 'Uds1, Imp1 = FORMAT(Imp1, ''N4''), ', '')
				, IIF(SUM(IIF(UDS2<>0, 1, 0))>0, 'Uds2, Imp2 = FORMAT(Imp2, ''N4''), ', '')
				, IIF(SUM(IIF(UDS3<>0, 1, 0))>0, 'Uds3, Imp3 = FORMAT(Imp3, ''N4''), ', '')
				, IIF(SUM(IIF(UDS4<>0, 1, 0))>0, 'Uds4, Imp4 = FORMAT(Imp4, ''N4''), ', '')
				, IIF(SUM(IIF(UDS5<>0, 1, 0))>0, 'Uds5, Imp5 = FORMAT(Imp5, ''N4''), ', '')
				, IIF(SUM(IIF(UDS6<>0, 1, 0))>0, 'Uds6, Imp6 = FORMAT(Imp6, ''N4''), ', '')
				, IIF(SUM(IIF(UDS7<>0, 1, 0))>0, 'Uds7, Imp7 = FORMAT(Imp7, ''N4''), ', '')
				, IIF(SUM(IIF(UDS8<>0, 1, 0))>0, 'Uds8, Imp8 = FORMAT(Imp8, ''N4''), ', '')
				, IIF(SUM(IIF(UDS9<>0, 1, 0))>0, 'Uds9, Imp9 = FORMAT(Imp9, ''N4''), ', '')
				, 'Variable AS [Imp.Consumo], [Cuota], ') 
		FROM #CONCEPTOS WHERE fclTrfSvCod=@svcCod AND RN=@iDesglose;
	

		SELECT @sqlImporte = CONCAT(@sqlImporte, IIF(SUM(IIF(ISNULL(Fijo, 0)<>0, 1, 0)) > 0, '[Imp.Cuota] = Fijo, ', ''))
		FROM #CONCEPTOS WHERE fclTrfSvCod=@svcCod AND RN=@iDesglose;


		--Dinamicamente hacemos la select para sacar los datos de cada servicio por factura	
		SET @sqlCols  = FORMATMESSAGE('%s Tarifa, %s ImporteImpuesto AS [Imp.Impuesto], Impuesto AS [Tipo Impositivo]', @sqlConcepto, @sqlImporte);
		SET @sqlQuery = FORMATMESSAGE('SELECT %s FROM #FACS AS F LEFT JOIN #CONCEPTOS AS C ON F.ID=C.ID AND svccod=%i AND RN=%i ORDER BY F.ID', @sqlCols, @svcCod, @iDesglose);
		--SELECT @sqlQuery;
		EXECUTE (@sqlQuery);

		SET @iDesglose = @iDesglose+1;
		SELECT @sqlConcepto = '', @sqlImporte='', @sqlCols = '', @sqlQuery='';
	END

	FETCH NEXT FROM SVC_ INTO @svcCod, @servicio, @desglose, @iDesglose

	END 
	 
	--*************
	--CURSOR: SVC_
	IF CURSOR_STATUS('global','SVC_') >= -1
	BEGIN
		IF CURSOR_STATUS('global','SVC_') > -1 CLOSE SVC_;
		DEALLOCATE SVC_;
	END
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

	IF OBJECT_ID('tempdb.dbo.#FACS', 'U') IS NOT NULL 
	DROP TABLE #FACS;
	
	IF OBJECT_ID('tempdb.dbo.#FCL', 'U') IS NOT NULL 
	DROP TABLE #FCL;
	
	IF OBJECT_ID('tempdb.dbo.#SVC', 'U') IS NOT NULL 
	DROP TABLE #SVC;
	
	IF OBJECT_ID('tempdb.dbo.#PADRON', 'U') IS NOT NULL 
	DROP TABLE #PADRON;

	IF OBJECT_ID('tempdb.dbo.#CONTADORES', 'U') IS NOT NULL 
	DROP TABLE #CONTADORES;
		
	IF OBJECT_ID('tempdb.dbo.#CONCEPTOS', 'U') IS NOT NULL 
	DROP TABLE #CONCEPTOS;

	IF OBJECT_ID('tempdb.dbo.#GRUPOS', 'U') IS NOT NULL 
	DROP TABLE #GRUPOS;

GO


