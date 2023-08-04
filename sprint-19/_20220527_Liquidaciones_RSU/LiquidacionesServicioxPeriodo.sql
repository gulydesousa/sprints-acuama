
/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_error_out INT;
DECLARE @p_errMsg_out   NVARCHAR(MAX);

SET @p_params= '<NodoXML><LI><periodoD>201901</periodoD><periodoH>202212</periodoH><Servicio>3</Servicio></LI></NodoXML>'

EXEC [InformesExcel].[LiquidacionesServicioxPeriodo] @p_params, @p_error_out OUTPUT, @p_errMsg_out OUTPUT;
*/

ALTER PROCEDURE [InformesExcel].[LiquidacionesServicioxPeriodo]
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
	
	DECLARE @params TABLE (periodoD VARCHAR(6) NULL, Servicio INT NULL, periodoH VARCHAR(6) NULL, fInforme DATETIME);

	INSERT INTO @params
	SELECT periodoD = M.Item.value('periodoD[1]', 'VARCHAR(6)')
		 , Servicio = M.Item.value('Servicio[1]', 'INT')
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

	--[01]Lineas de factura que forman parte del periodo de seleccion 	
	--#FCL
	SELECT RN = ROW_NUMBER() OVER(PARTITION BY facCod, facPerCod, facCtrCod, facVersion, fclTrfSvCod ORDER BY fclNumLinea)
	--RN_FAC = 1 : Para obtener la ultima factura del contrato
	, RN_FAC = DENSE_RANK() OVER(PARTITION BY facCtrCod ORDER BY facPerCod DESC )
	, facCod
	, facPerCod
	, facCtrCod
	, facVersion
	, fclNumLinea
	, fclTrfSvCod 
	, fclTrfCod
	, facSerCod
	, facNumero
	, fclUsrLiq
	, fclFecLiq
	, T.trfdes
	, [Importe]			= FL.fcltotal
	, [Consumo]			= (fclunidades1 + fclunidades2 + fclunidades3 + fclunidades4 + fclunidades5 + fclunidades6 + fclunidades7 + fclunidades8 + fclunidades9)
	, [CargoFijo]		= CAST((fclUnidades * fclPrecio) AS MONEY)
	, [CargoVariable]	= CAST((fclunidades1*fclprecio1 + fclunidades2*fclprecio2 + fclunidades3*fclprecio3 + fclunidades4*fclprecio4 + fclunidades5*fclprecio5 + fclunidades6*fclprecio6 + fclunidades7*fclprecio7 + fclunidades8 * fclprecio8 + fclunidades9*fclprecio9) AS MONEY)

	INTO #FCL
	FROM dbo.faclin AS FL
	INNER JOIN dbo.facturas AS F
	ON F.facCtrCod	= FL.fclFacCtrCod
	AND F.facPerCod = FL.fclFacPerCod
	AND F.facVersion= FL.fclFacVersion
	AND F.facCod	= FL.fclFacCod
	INNER JOIN @params AS P
	ON  F.facPerCod>=P.periodoD
	AND F.facPerCod<=P.periodoH
	AND FL.fclTrfSvCod =  P.Servicio
	INNER JOIN dbo.tarifas AS T
	ON T.trfcod = FL.fclTrfCod 
	AND T.trfsrvcod = FL.fclTrfSvCod
	WHERE 
	FL.fclFecLiq IS NOT NULL
	AND FL.fclUsrLiq IS NOT NULL
	AND F.facFechaRectif IS NULL;
	
	--[02]Bonificaciones en las facturas liquidadas
	--#BONIFICACIONES
	WITH LIQ AS(
	SELECT DISTINCT facCod , facPerCod, facCtrCod, facVersion
	FROM #FCL AS F
	INNER JOIN dbo.parametros AS P
	ON P.pgsclave = 'EXPLOTACION'
	AND P.pgsvalor='Soria')

	SELECT facCod
		 , facPerCod
		 , facCtrCod
		 , facVersion
		 , FL.fclTrfCod
		 , FL.fclTrfSvCod
		 , T.trfdes
		 , [Importe]		= SUM(FL.fcltotal) 
							OVER (PARTITION BY facCod, facPerCod, facCtrCod, facVersion)
		
		, [CargoFijo]		= SUM(fclUnidades * fclPrecio) 
							OVER (PARTITION BY facCod, facPerCod, facCtrCod, facVersion)
		
		, [CargoVariable]	= SUM(fclunidades1*fclprecio1 + fclunidades2*fclprecio2 + fclunidades3*fclprecio3 + fclunidades4*fclprecio4 
								+ fclunidades5*fclprecio5 + fclunidades6*fclprecio6 + fclunidades7*fclprecio7 + fclunidades8 * fclprecio8 + fclunidades9*fclprecio9)
							OVER (PARTITION BY facCod, facPerCod, facCtrCod, facVersion)

		 , CN = COUNT(FL.fclTrfCod) OVER (PARTITION BY facCod, facPerCod, facCtrCod, facVersion)
		 , RN = ROW_NUMBER() OVER (PARTITION BY facCod, facPerCod, facCtrCod, facVersion ORDER BY FL.fclTrfSvCod, FL.fclTrfCod)
	INTO #BONIFICACIONES
	FROM LIQ AS F
	INNER JOIN dbo.faclin AS FL
	ON  F.facCtrCod	= FL.fclFacCtrCod
	AND F.facPerCod = FL.fclFacPerCod
	AND F.facVersion= FL.fclFacVersion
	AND F.facCod	= FL.fclFacCod
	INNER JOIN dbo.servicios AS S
	ON S.svcdes LIKE 'BONIFICACION ECOVIDRIO%'
	AND S.svccod = FL.fclTrfSvCod
	INNER JOIN dbo.tarifas AS T
	ON T.trfcod = FL.fclTrfCod 
	AND T.trfsrvcod = FL.fclTrfSvCod;
	
	--*******************************	
	--[R01] Nombre de Grupos 
	--Servicios con lineas en el periodo
	--#GRUPOS
	SELECT DISTINCT Grupo = CONCAT('_', facPerCod), facPerCod
	INTO #GRUPOS
	FROM #FCL;

	
	SELECT [Grupo] = 'Tarifa'
		 , [Orden]= 0	
	UNION ALL
	
	SELECT Grupo 
		 , facPerCod
	FROM #GRUPOS
	--IMPORTANTE mantener el orden
	ORDER BY Orden;

	
	--*******************************
	--[R02] Raíz de los datos: Facturas 

	DECLARE @CTR AS TABLE(ctrCod INT, RN INT, [TotalCargoFijo] MONEY);

	INSERT INTO @CTR
	SELECT F.facCtrCod
		 , F.RN 
		 , [Total Cargo Fijo] = SUM(F.CargoFijo - ISNULL(B.CargoFijo, 0))
	FROM #FCL AS F
	LEFT JOIN #BONIFICACIONES AS B
	ON B.facCod		 = F.facCod
	AND B.facPerCod  = F.facPerCod
	AND B.facCtrCod  = F.facCtrCod
	AND B.facVersion = F.facVersion
	AND F.RN=1
	AND B.RN=1
	GROUP BY F.facCtrCod, F.RN;

	SELECT Contrato				= C.ctrCod
		 , [Titular DNI]		= CC.ctrTitDocIden
		 , [Titular Nombre]		= CC.ctrTitNom

		 , [Dirección]			= IIF(CC.ctrEnvNom IS NULL, CC.ctrTitDir, CC.ctrEnvDir) 
		 , [Poblacion]			= IIF(CC.ctrEnvNom IS NULL, CC.ctrTitPob, CC.ctrEnvPob) 
		 , [Provincia]			= IIF(CC.ctrEnvNom IS NULL, CC.ctrTitPrv, CC.ctrEnvPrv) 
	
		 , [Dir. Suministro]	= I.inmdireccion
		 , [C.P. Suministro]	= ISNULL(I.inmcpost,'42000')
		 , [Pob. Suministro]	= PP.pobdes	
		--, [Zona]		 = CC.ctrzoncod
	FROM @CTR AS C
	INNER JOIN dbo.vContratosUltimaVersion AS V
	ON C.ctrCod = V.ctrCod
	INNER JOIN dbo.contratos AS CC
	ON V.ctrcod		 = CC.ctrCod
	AND V.ctrVersion = CC.ctrversion
	LEFT JOIN dbo.inmuebles AS I
	ON I.inmcod = CC.ctrinmcod
	INNER JOIN dbo.provincias AS P 
	ON I.inmPrvCod = P.prvcod
	INNER JOIN dbo.poblaciones AS PP 
	ON  PP.pobprv = I.inmPrvCod 
	AND PP.pobcod = I.inmPobCod
	--IMPORTANTE mantener el orden
	ORDER BY C.ctrCod, C.RN;

	--*******************************
	--[R03] Tarifas en la factura de mayor periodo de facturación 
	SELECT [Tarifa]			  = F.fclTrfCod
		 , [Nombre Tarifa]	  = F.trfdes
		 , [Cargo Fijo (Total_Sin IVA)] = C.TotalCargoFijo
		--, C.ctrCod
		--, F.facPerCod	
	FROM @CTR AS C
	LEFT JOIN #FCL AS F
	ON F.facCtrCod = C.ctrCod
	AND F.RN = C.RN
	--Factura de mayor periodo en el contrato
	AND F.RN_FAC=1
	--IMPORTANTE mantener el orden
	ORDER BY C.ctrCod, C.RN;


	--*******************************
	--[R04] Periodos

	DECLARE @periodo VARCHAR(6);
	
	DECLARE PER CURSOR FOR
	SELECT facPerCod FROM #GRUPOS ORDER BY Grupo
	OPEN PER
	FETCH NEXT FROM PER INTO @periodo

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		PRINT @periodo;

		IF EXISTS (SELECT 1 FROM #BONIFICACIONES WHERE facPerCod=@periodo)
			SELECT [Periodo]			= @periodo
				 , [Fac.Serie]			= F.facSerCod
				 , [Fac.Numero]			= F.facNumero
				 
				 , [Liq.Cargo Fijo]		= F.CargoFijo 
				 , [Liq.Total]			= F.Importe
				 
				 , [Bonif. Tarifa]		= B.trfdes
				 , [Bonif. Cargo Fijo]	= B.Importe
				 , [Bonif. Total]		= B.Importe
				 
				 , [Total]				= F.Importe+ B.Importe
			FROM @CTR AS C
			LEFT JOIN #FCL AS F
			ON F.facCtrCod = C.ctrCod
			AND F.RN = C.RN
			AND F.facPerCod=@periodo
			--IMPORTANTE mantener el orden
			LEFT JOIN #BONIFICACIONES AS B
			ON B.facCod		 = F.facCod
			AND B.facPerCod  = F.facPerCod
			AND B.facCtrCod  = F.facCtrCod
			AND B.facVersion = F.facVersion
			AND F.RN=1
			AND B.RN=1
			ORDER BY C.ctrCod, C.RN;
		ELSE
			SELECT [Periodo]		= @periodo
				 , [Fac.Serie]		= F.facSerCod
				 , [Fac.Numero]		= F.facNumero
				 
				 , [Liq.Cargo Fijo]	= F.CargoFijo 
				 , [Liq.Total]		= F.Importe
			FROM @CTR AS C
			LEFT JOIN #FCL AS F
			ON F.facCtrCod = C.ctrCod
			AND F.RN = C.RN
			AND F.facPerCod=@periodo
			--IMPORTANTE mantener el orden
			ORDER BY C.ctrCod, C.RN;
		
		FETCH NEXT FROM PER INTO @periodo
	END
	CLOSE PER  
	DEALLOCATE PER  

	END TRY
	

	BEGIN CATCH
		IF CURSOR_STATUS('global','PER') >= -1
		BEGIN
		IF CURSOR_STATUS('global','PER') > -1 CLOSE PER;
		DEALLOCATE PER;
		END

		SELECT  @p_errId_out = ERROR_NUMBER()
			 ,  @p_errMsg_out= ERROR_MESSAGE();
	END CATCH

	IF OBJECT_ID('tempdb..#FCL') IS NOT NULL
	DROP TABLE #FCL;

	IF OBJECT_ID('tempdb..#GRUPOS') IS NOT NULL
	DROP TABLE #GRUPOS;

	IF OBJECT_ID('tempdb..#BONIFICACIONES') IS NOT NULL
	DROP TABLE #BONIFICACIONES;

	--SELECT @p_errId_out ,  @p_errMsg_out
GO