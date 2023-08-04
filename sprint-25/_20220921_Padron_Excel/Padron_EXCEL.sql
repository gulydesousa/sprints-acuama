/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_error_out INT;
DECLARE @p_errMsg_out   NVARCHAR(MAX);

SET @p_params= '<NodoXML><LI><periodoD>202204</periodoD><periodoH>202204</periodoH></LI></NodoXML>'

EXEC [InformesExcel].[Padron_EXCEL_] @p_params, @p_error_out OUTPUT, @p_errMsg_out OUTPUT;
*/

ALTER PROCEDURE [InformesExcel].[Padron_EXCEL]
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
	
	DECLARE @params TABLE (periodoD VARCHAR(6) NULL, periodoH VARCHAR(6) NULL, fInforme DATETIME);

	INSERT INTO @params
	SELECT periodoD = M.Item.value('periodoD[1]', 'VARCHAR(6)')
		 , periodoH = M.Item.value('periodoH[1]', 'VARCHAR(6)')
		 , fInforme = GETDATE()	
	FROM @xml.nodes('NodoXML/LI')AS M(Item);

	--********************
	--VALIDAR PARAMETROS
	--********************
	IF EXISTS(SELECT 1 FROM @params WHERE periodoD='')
	UPDATE @params SET periodoD = (SELECT MIN(percod) FROM periodos);

	IF EXISTS(SELECT 1 FROM @params WHERE periodoH='')
	UPDATE @params SET periodoH = (SELECT MAX(percod) FROM periodos);

	IF EXISTS(SELECT 1 FROM @params WHERE periodoD> periodoH)
	UPDATE @params SET periodoD = periodoH , periodoH=periodoD;

	IF NOT EXISTS(SELECT 1 FROM dbo.periodos AS PP 
				  INNER JOIN @params AS P
				  ON PP.percod BETWEEN P.periodoD AND P.periodoH)
	UPDATE @params 
	SET periodoD = (SELECT MIN(percod) FROM periodos)
	  , periodoH = (SELECT MAX(percod) FROM periodos);

	SELECT * FROM @params;
	
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
	, CAST(NULL AS MONEY) AS facTotal
	INTO #FACS
	FROM dbo.facturas AS F
	INNER JOIN @params AS P
	ON  F.facPerCod>=P.periodoD
	AND F.facPerCod<=P.periodoH
	AND F.facFechaRectif IS NULL;
	
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
	, ROW_NUMBER() OVER (PARTITION BY F.facCod, F.facCtrCod, F.facPerCod, F.facVersion ORDER BY CC.ctcFec DESC) AS RN
	FROM #FACS AS F
	LEFT JOIN dbo.ctrcon AS CC 
	ON CC.ctcCtr = F.facCtrCod
	AND ((F.facLecActFec IS NOT NULL AND CC.ctcFec <= F.facLecActFec) OR (CC.ctcFec <= GETDATE()))
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
	
	SELECT C.tipo
	, C.svccod
	, C.Concepto
	, C.ConceptoDesc
	, C.scsSctoID AS Subconcepto
	, C.SubConceptoDesc
	, C.svctipo
	, C.svcdes
	, ISNULL(C.orgCodigo, 0) AS orgId
	, IIF(C.orgCodigo IS NULL, Explotacion, C.orgDescripcion) AS orgDesc
	, C.totalDesglosado
	INTO #SVC
	FROM  SERV AS S
	INNER JOIN InformesExcel.PadronExcel_Conceptos AS C
	ON C.svccod = S.fclTrfSvCod;

	--*******************************	
	--[R01] Nombre de Grupos 
	--Servicios con lineas en el periodo
	--#GRUPOS
	WITH CONCEPTOS AS(
	SELECT tipo
	, Concepto
	, Subconcepto
	, svccod
	, svcdes
	, svctipo
	, totalDesglosado
	, orgId
	, orgDesc
	, ISNULL(C.ctoDesc, S.svcDes) AS Grupo
	, ROW_NUMBER() OVER (ORDER BY IIF(orgId=0, 1, 0), orgId, svctipo, Concepto) AS RN
	FROM #SVC AS S
	LEFT JOIN InformesExcel.conceptos AS C
	ON  S.tipo='CONCEPTO'
	AND C.ctoID = S.Concepto

	), GRUPO AS(
	SELECT Grupo
	, Concepto
	, Subconcepto
	, svctipo AS Tipo
	, orgId
	, orgDesc
	, totalDesglosado
	, MAX(RN) AS RN
	FROM CONCEPTOS 
	GROUP BY Grupo, Concepto, Subconcepto, svctipo, orgId, orgDesc, totalDesglosado 
		
	UNION ALL
	SELECT 'Factura', NULL, NULL, NULL, NULL, NULL, NULL, NULL)

	SELECT * 
	INTO #GRUPOS
	FROM GRUPO;
	
	SELECT * FROM #GRUPOS
	--IMPORTANTE mantener el orden
	ORDER BY RN

	--*******************************
	--[R02] Raíz de los datos: Facturas 
	SELECT F.facCtrCod AS [Contrato]
	, F.facPerCod AS [Cod.Periodo]
	FROM #FACS AS F
	--IMPORTANTE mantener el orden
	ORDER BY ID ASC;
	
	--*******************************
	--[R03]:  Detalles de las facturas 
	SELECT C.ctrTitDocIden AS [NIF]
	, C.ctrTitNom AS [Cliente]
	--
	, I.inmDireccion AS [Dirección Suministro]
	, CLL.cllCpos AS [CP Suministro] 
	, PB.pobdes AS [Población Suministro]

	, C.ctrEnvDir AS [Dirección Envío Facturas]
	, C.ctrEnvCPos AS [CP Envío Facturas]
	, C.ctrEnvPob AS [Población Envío Facturas]
	, C.ctrEnvPrv AS [Provincia Envío Facturas]

	, IIF(C.ctrIban IS NULL OR C.ctrIban = '', ''
							, FORMATMESSAGE('IBAN %s %s %s %s %s %s'
							, LTRIM(RTRIM(ISNULL(C.ctrBic, '')))
							, SUBSTRING(C.ctrIban, 1, 4)
							, SUBSTRING(C.ctrIban, 5, 4)
							, SUBSTRING(C.ctrIban, 9, 4)
							, SUBSTRING(C.ctrIban, 13, 4)
							, SUBSTRING(C.ctrIban, 17, 4)
							)) AS [Cuenta Bancaria]

	, FORMAT(F.facFecha, 'dd/MM/yyyy') AS [Fecha Factura]
	, F.facNumero AS [Nº Factura Oficial]
	, IIF(F.facFechaRectif IS NULL, 'ORIGINAL', 'RECTIFICADA') AS [Tipo factura]
	, IIF(P.pertipo = '', YEAR(F.facFecha), LEFT(F.facPerCod, 4)) AS [Año] 
	, CASE P.pertipo 
	  WHEN 'B' THEN 'BIMESTRAL'
	  WHEN 'T' THEN 'TRIMESTRAL' 
	  ELSE UPPER(P.perdes) END 
	  AS [Periodicidad]
	, CAST(RIGHT(F.facPerCod, 2) AS INT) AS [Periodo] 
	
	, CCC.conDiametro AS [Calibre Esf 1]
	, CCC.conNumSerie AS [NºSerie Contador Esf1]
	, F.facLecAnt AS [Lectura Anterior Esf 1]
	, FORMAT(F.facLecAntFec, 'dd/MM/yyyy') AS [Fecha Lectura Anterior]
	, F.facLecAct AS [Lectura Actual Esf 1]
	, FORMAT(F.facLecActFec, 'dd/MM/yyyy') AS [Fecha Lectura Actual]
	, ISNULL(F.facLecAct, 0) - ISNULL(F.facLecAnt, 0) AS [m3 Consumidos]

	, F.facTotal AS [Total factura]
	, U.usodes AS [Uso]
	FROM #FACS AS F
	INNER JOIN dbo.periodos AS P
	ON P.percod = F.facPerCod
	INNER JOIN dbo.contratos AS C
	ON C.ctrCod = F.facCtrCod
	AND C.ctrVersion = F.facCtrVersion
	LEFT JOIN dbo.usos AS U
	ON U.usocod = C.ctrUsoCod
	INNER JOIN dbo.inmuebles AS I
	ON I.inmcod = C.ctrinmcod
	LEFT JOIN dbo.poblaciones AS PB
	ON PB.pobcod = I.inmPobCod
	AND PB.pobprv = I.inmPrvCod
	LEFT JOIN dbo.calles AS CLL
	ON I.inmcllcod = CLL.cllcod
	AND I.inmmnccod = CLL.cllmnccod
	AND I.inmPrvCod = CLL.cllPrvCod
	AND I.inmPobCod = CLL.cllPobCod
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
	, IIF(P.fclTrfSvCod IS NULL, ' ', S.orgDesc) AS Organismo
	, S.Concepto AS GrupoConcepto 
	, S.ConceptoDesc AS GrupoConceptoDesc
	, IIF(P.fclTrfSvCod IS NULL, ' ', S.svcDes)  AS Concepto
	, IIF(P.fclTrfSvCod IS NULL, ' ', S.SubconceptoDesc) AS SubConcepto
	, P.Tarifa
	, ISNULL(P.Consumo, 0) AS Consumo
	, P.Importe
	, [_Importe] = SUM(Importe) OVER (PARTITION BY  F.ID, S.Concepto)
	, P.Variable
	, [_Variable] = SUM(Variable) OVER (PARTITION BY  F.ID, S.Concepto) 
	, P.Fijo
	, [_Fijo] = SUM(Fijo) OVER (PARTITION BY  F.ID, S.Concepto) 
	, P.Cuota
	
	, ISNULL(P.Impuesto, 0) AS Impuesto
	, ISNULL(P.ImporteImpuesto, 0) AS ImporteImpuesto
	, S.tipo
	, S.totalDesglosado
	--RN=1: Si varios servicios se unifican en un solo concepto, los ordenamos por factura 
	--y nos quedamos con el que tiene el primer servicio del grupo
	, ROW_NUMBER() OVER (PARTITION BY  F.ID, S.Concepto ORDER BY P.fclTrfSvCod DESC, P.Tarifa) AS RN  	
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
	DECLARE @concepto	 VARCHAR(250);
	DECLARE @subconcepto VARCHAR(50);
	DECLARE @tipo VARCHAR(1);
	DECLARE @desglosado BIT;
	
	DECLARE @orgID INT;
	DECLARE @orgDesc VARCHAR(150);	
	DECLARE @orgLAG INT;

	DECLARE @sqlOrganismo	 AS VARCHAR(50) = '';
	DECLARE @sqlSubconcepto AS VARCHAR(50) = '';
	DECLARE @sqlConsumo AS VARCHAR(50) = '';
	DECLARE @sqlConcepto AS VARCHAR(150) = '';
	DECLARE @sqlImporte AS VARCHAR(250) = '';

	DECLARE @sqlCols AS VARCHAR(MAX) = '';
	DECLARE @sqlQuery AS VARCHAR(MAX) = '';

	--*************
	--CURSOR: SVC_
	--[RN*] Valores por servicio 
	DECLARE SVC_ CURSOR FOR
	SELECT Concepto
	, Subconcepto
	, Tipo
	, orgId
	, orgDesc
	, totalDesglosado
	, LAG(orgId) OVER (ORDER BY RN) AS orgLAG
	FROM #GRUPOS
	WHERE RN IS NOT NULL
	--IMPORTANTE mantener el orden
	ORDER BY RN;
	
	OPEN SVC_
	FETCH NEXT FROM SVC_ INTO @concepto, @subconcepto, @tipo, @orgID, @orgDesc, @desglosado, @orgLAG

	WHILE @@FETCH_STATUS = 0  
	BEGIN
	--SELECT  @concepto, @subconcepto, @tipo, @orgID, @orgDesc, @desglosado, @orgLAG;
	
	--Los servicios están ordenados horizontalmente por organismo 
	IF (@orgLAG IS NULL OR @orgID <> @orgLAG)	--[RN_1] Se muestra el organismo 
		SET @sqlOrganismo =  'Organismo,';		

	IF (@subconcepto IS NOT NULL)	--[RN_2] se muestra el subconcepto 
		SET @sqlSubconcepto = 'Subconcepto,';

	IF (@tipo IS NOT NULL AND @tipo='M')		--[RN_3] se muestra el consumo 
		SET @sqlConsumo = 'Consumo,';	

	IF (@concepto IS NULL)						--[RN_4] se muestra el concepto y el servicio 
		SET @sqlconcepto = 'Concepto,';	
	ELSE
		SET @sqlConcepto = 'IIF(fclTrfSvCod IS NULL, NULL, GrupoConcepto) AS Concepto, Concepto AS Servicio,';

	IF (@desglosado IS NULL OR @desglosado = 0)	--[RN_5] se muestra el importe o se muestra fijo y variable 
	BEGIN
		SET @sqlImporte = '[Importe] = _Importe,'
	END
	ELSE
	BEGIN
		SET @sqlImporte = '_Variable AS [Importe Variable], IIF(fclTrfSvCod IS NULL, NULL, ''CUOTA DE SERVICIO'') AS [Subconcepto Cuota], Cuota AS [Cantidad Fija], _Fijo AS [Importe Fijo],'
		SET @sqlSubconcepto = '''CONSUMO'' AS ' + @sqlSubconcepto; 
	END
	--Dinamicamente hacemos la select para sacar los datos de cada servicio por factura	
	SET @sqlCols  = FORMATMESSAGE('%s %s [Tarifa]= IIF(Importe<>_Importe, ''(*)'', '''') + Tarifa, %s %s %s Impuesto, ImporteImpuesto', @sqlOrganismo, @sqlConcepto, @sqlSubconcepto, @sqlConsumo, @sqlImporte);
	SET @sqlQuery = FORMATMESSAGE('SELECT %s FROM #CONCEPTOS WHERE GrupoConcepto=''%s'' AND RN=1 ORDER BY ID', @sqlCols, @concepto);

	--SELECT @sqlQuery;
	EXECUTE (@sqlQuery);

	SELECT @sqlOrganismo = '',  @sqlSubconcepto = '',  @sqlConsumo = '',  @sqlConcepto = '';
	
	FETCH NEXT FROM SVC_ INTO @concepto, @subconcepto, @tipo, @orgID, @orgDesc, @desglosado, @orgLAG

	END  
	--CURSOR: SVC_
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


