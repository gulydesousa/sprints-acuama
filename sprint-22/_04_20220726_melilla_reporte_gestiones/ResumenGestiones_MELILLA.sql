
/*
DELETE FROM ExcelPerfil WHERE ExPCod='100/001'

DELETE FROM dbo.ExcelConsultas WHERE ExcCod='100/001'

INSERT INTO dbo.ExcelConsultas
VALUES ('100/001',	'Resumen de gestiones', 'Resumen de gestiones', 18, '[InformesExcel].[ResumenGestiones_MELILLA]', 'CSV+', '<b>MELILLA: </b>Resumen de gestiones<br>Comparativa entre periodos de facturación.');

INSERT INTO ExcelPerfil
VALUES('100/001', 'root', 4, NULL)

INSERT INTO ExcelPerfil
VALUES('100/001', 'direcc', 4, NULL)

*/

/*
	DECLARE @p_params NVARCHAR(MAX);
	DECLARE @p_errId_out INT;
	DECLARE @p_errMsg_out NVARCHAR(2048);

	SET @p_params= '<NodoXML><LI><periodoD>202103</periodoD><periodoH>202202</periodoH><zonaD>1</zonaD><zonaH>3</zonaH></LI></NodoXML>'

	
	EXEC [InformesExcel].[ResumenGestiones_MELILLA] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;

*/

CREATE PROCEDURE [InformesExcel].[ResumenGestiones_MELILLA]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS


	--*******
	--PARAMETROS:
	--*******
	DECLARE @xml AS XML = @p_params;

	DECLARE @params TABLE (periodoD VARCHAR(6) NULL, periodoH VARCHAR(6) NULL
						 , fInforme DATETIME
						 , zonaD VARCHAR(4) NULL, zonaH VARCHAR(4) NULL);

	INSERT INTO @params
	SELECT periodoD = M.Item.value('periodoD[1]', 'VARCHAR(6)')
		 , periodoH = M.Item.value('periodoH[1]', 'VARCHAR(6)')
		
		 , fInforme = dbo.GetAcuamaDate()
		
		
		 , zonaD = M.Item.value('zonaD[1]', 'VARCHAR(4)')
		 , zonaH = M.Item.value('zonaH[1]', 'VARCHAR(4)')	
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

	IF EXISTS(SELECT 1 FROM @params WHERE zonaD='')
	UPDATE @params SET zonaD = (SELECT MIN(zoncod) FROM dbo.zonas);

	IF EXISTS(SELECT 1 FROM @params WHERE zonaH='')
	UPDATE @params SET zonaH = (SELECT MAX(zoncod) FROM dbo.zonas);

	--**************************
	SELECT * FROM @params;

	--********************
	--INICIO:
	--********************
	DECLARE @zonaD VARCHAR(4);
	DECLARE @zonaH VARCHAR(4);
	DECLARE @periodoD VARCHAR(6);
	DECLARE @periodoH VARCHAR(6);

	SELECT @zonaD = P.zonaD
	, @zonaH = P.zonaH
	, @periodoD = P.periodoD
	, @periodoH = P.periodoH
	FROM @params AS P;


	DECLARE @AGUA INT = 1;
	SELECT @AGUA = pgsvalor  
	FROM dbo.parametros AS P
	WHERE P.pgsclave = 'SERVICIO_AGUA';

	
	DECLARE @SVC_DERECHOS INT =10;
	
	DECLARE @TRF_CONTRATACION INT = 1000;
	DECLARE @TRF_TITULARIDAD INT = 2000;
	DECLARE @TRF_REENGANCHE INT = 3000;

BEGIN TRY

	WITH VPER AS(
	--[01]Todos los periodos con su fecha inicio/fin
	SELECT percod = przcodper
	, periodoD = CAST(przfPeriodoD AS DATE) 
	, periodoH = CAST(przfPeriodoH AS DATE) 
	, periodoD_Ant = CAST(DATEADD(DAY, -1, przfPeriodoD) AS DATE)
	FROM dbo.vPerzonaFechas AS P
	WHERE P.RN=1

	), PER AS(
	--[02]Periodos que conforman el rango de consulta
	--Enlazado con el periodo anterior
	SELECT P.percod
	, P.periodoD
	, P.periodoH
	, [percod_Ant]	 = P0.percod
	, [periodoD_Ant] = P0.periodoD
	, [periodoH_Ant] = P0.periodoH
	FROM VPER AS P
	LEFT JOIN VPER AS P0
	ON P0.periodoH = P.periodoD_Ant
	WHERE P.percod >= @periodoD	
	  AND P.percod <= @periodoH)

	--[03]#CS: Para todos los contratos:
	--Enlazamos los contratos por servicios segun el rango de los periodos en evaluación
	SELECT C.ctrCod
	, C.ctrzoncod
	, C.ctrBaja
	--**************
	, P.percod
	, P.periodoD
	, P.periodoH
	--**************
	, P.percod_Ant
	, P.periodoD_Ant
	, P.periodoH_Ant
	--**************
	, CS.ctssrv 
	, CS.ctstar
	, [ctsfecalt] = CAST(CS.ctsfecalt AS DATE)
	, [ctsfecbaj] = CAST(CS.ctsfecbaj AS DATE)
	
	--Vigencia anterior del servicio de agua con la misma tarifa
	, [ctsfecalt_0] = LEAD(CAST(CS.ctsfecalt AS DATE)) OVER(PARTITION BY C.ctrCod, CS.ctssrv, CS.ctstar, P.percod 
					  ORDER BY CS.ctsfecalt DESC, IIF(CS.ctsfecbaj IS NULL, '19000101', CS.ctsfecbaj))

	, [ctsfecbaj_0] = LEAD(CAST(CS.ctsfecbaj AS DATE)) OVER(PARTITION BY C.ctrCod, CS.ctssrv, CS.ctstar, P.percod 
					  ORDER BY CS.ctsfecalt DESC, IIF(CS.ctsfecbaj IS NULL, '19000101', CS.ctsfecbaj))
	

	--RN=1: Para quedarnos con la ultima vigencia del servicio
	--Cuando hay dos altas en la misma fecha nos quedamos con la de vigencia mas reciente
	, [RN] = ROW_NUMBER() OVER(PARTITION BY C.ctrCod,  CS.ctssrv , P.percod 
						  ORDER BY CS.ctsfecalt DESC, IIF(CS.ctsfecbaj IS NULL, '19000101', CS.ctsfecbaj))
	
	INTO #CS
	FROM dbo.vContratosUltimaVersion AS C
	CROSS JOIN PER AS P
	LEFT JOIN dbo.contratoServicio AS CS
	ON  CS.ctsctrcod = C.ctrCod
	AND CS.ctssrv = @AGUA
	AND CS.ctsfecalt <= P.PeriodoD
	WHERE (@zonaD IS NULL OR C.ctrzoncod >= @zonaD)
	  AND (@zonaH IS NULL OR C.ctrzoncod <= @zonaH)
	
	--[04]#FL_DERECHOS: DERECHOS DE CONTRATACIÓN
	--Lineas de factura
	SELECT C.ctrCod
	, C.percod
	--Lineas por tarifa
	, CN_Reenganche   = SUM(IIF(FL.fclTrfCod=@TRF_REENGANCHE, 1, 0))
	, CN_Contratacion = SUM(IIF(FL.fclTrfCod=@TRF_CONTRATACION, 1, 0))
	, CN_Titularidad  = SUM(IIF(FL.fclTrfCod=@TRF_TITULARIDAD, 1, 0))
	INTO #FL_DERECHOS
	FROM  #CS AS C
	INNER JOIN dbo.facturas AS F
	ON C.RN=1
	AND F.facCtrCod = C.ctrCod
	AND F.facPerCod = C.percod
	AND F.facFechaRectif IS NULL
	INNER JOIN dbo.faclin AS FL 
	ON FL.fclFacPerCod = F.facPerCod
	AND FL.fclFacCtrCod = F.facCtrCod
	AND FL.fclFacVersion = F.facVersion
	AND FL.fclFacCod = F.facCod
	AND FL.fclTrfSvCod = @SVC_DERECHOS
	GROUP BY C.ctrCod, C.percod;
	

	--*******************************
	--[05]#FCL: LineaImporte Agua
	WITH F AS(
	SELECT C.ctrCod
	, C.percod
	, F.facCod
	, F.facVersion
	, F.facCtrVersion 
	, [Cuota] = MAX(FL.fclUnidades)
	, [Cns.Factura] = MAX(F.facConsumoFactura)
	, [Imp.Agua] = SUM(FL.fcltotal)
	, [Uds] = MAX(ISNULL(FL.fclUnidades1, 0) 
				+ ISNULL(FL.fclUnidades2, 0) 
				+ ISNULL(FL.fclUnidades3, 0) 
				+ ISNULL(FL.fclUnidades4, 0) 
				+ ISNULL(FL.fclUnidades5, 0) 
				+ ISNULL(FL.fclUnidades6, 0) 
				+ ISNULL(FL.fclUnidades7, 0) 
				+ ISNULL(FL.fclUnidades8, 0) 
				+ ISNULL(FL.fclUnidades9, 0))
	, [inldes] = MAX(I.inldes)
	FROM #CS AS C
	INNER JOIN dbo.facturas AS F
	ON  C.RN=1
	AND F.facCtrCod = C.ctrCod
	AND F.facPerCod = C.percod
	AND F.facFechaRectif IS NULL
	INNER JOIN dbo.faclin AS FL 
	ON  FL.fclFacPerCod = F.facPerCod
	AND FL.fclFacCtrCod = F.facCtrCod
	AND FL.fclFacVersion = F.facVersion
	AND FL.fclFacCod = F.facCod
	AND FL.fclTrfSvCod = @AGUA
	LEFT JOIN incilec AS I
	ON I.inlcod = ISNULL(F.facInsInlCod, facLecInlCod)
	GROUP BY  C.ctrCod, C.percod, F.facCod, F.facVersion, F.facCtrVersion
	
	), F0 AS(
	SELECT C.ctrCod
	, C.percod_Ant
	, F.facCod
	, F.facVersion
	, [Cuota_Ant] = MAX(FL.fclUnidades)
	, [Cns.Factura_Ant] = MAX(F.facConsumoFactura)
	, [facCtrVersion_Ant] = F.facCtrVersion
	, [Imp.Agua_Ant] = SUM(FL.fcltotal) 
	, [Uds_Ant] = MAX(ISNULL(FL.fclUnidades1, 0) 
					+ ISNULL(FL.fclUnidades2, 0) 
					+ ISNULL(FL.fclUnidades3, 0) 
					+ ISNULL(FL.fclUnidades4, 0) 
					+ ISNULL(FL.fclUnidades5, 0) 
					+ ISNULL(FL.fclUnidades6, 0) 
					+ ISNULL(FL.fclUnidades7, 0) 
					+ ISNULL(FL.fclUnidades8, 0) 
					+ ISNULL(FL.fclUnidades9, 0))
	, [inldes] = MAX(I.inldes)
	FROM #CS AS C
	INNER JOIN dbo.facturas AS F
	ON  C.RN=1
	AND F.facCtrCod = C.ctrCod
	AND F.facPerCod = C.percod_Ant
	AND F.facFechaRectif IS NULL
	INNER JOIN dbo.faclin AS FL 
	ON  FL.fclFacPerCod = F.facPerCod
	AND FL.fclFacCtrCod = F.facCtrCod
	AND FL.fclFacVersion = F.facVersion
	AND FL.fclFacCod = F.facCod
	AND FL.fclTrfSvCod = @AGUA
	LEFT JOIN incilec AS I
	ON I.inlcod = ISNULL(F.facInsInlCod, F.facLecInlCod)
	GROUP BY C.ctrCod, C.percod_Ant, F.facCod, F.facVersion,  F.facCtrVersion
	
	), FF AS(
	SELECT * 
	--Si hay varias facturas, nos quedamos solo con la primera
	, RN = ROW_NUMBER() OVER (PARTITION BY F.ctrCod, F.percod ORDER BY F.facCod, F.facVersion)
	, CN = COUNT(F.facCod) OVER (PARTITION BY F.ctrCod, F.percod)
	FROM F
	
	), FF0 AS(
	SELECT * 
	--Si hay varias facturas, nos quedamos solo con la primera
	, RN = ROW_NUMBER() OVER (PARTITION BY F0.ctrCod, F0.percod_Ant ORDER BY F0.facCod, F0.facVersion)
	, CN = COUNT(F0.facCod) OVER (PARTITION BY F0.ctrCod, F0.percod_Ant)
	FROM F0)
	
	SELECT C.ctrCod
	, C.ctrzoncod
	, C.percod
	, C.periodoD
	, C.periodoH
	, [Alta.Agua] = C.ctsfecalt
	, [Baja.Agua] = C.ctsfecbaj
	, [Alta.Agua_Ant] = C.ctsfecalt_0
	, [Baja.Agua_Ant] = C.ctsfecbaj_0	
	, [ctrfec]	= CAST(CC.ctrfec AS DATE) 
	, [ctrfecini] = CAST(CC.ctrfecini AS DATE)
	, CC.ctrfecanu
	, CC.ctrbaja
	, CC.ctrTitCod
	, CC.ctrversion
	, FF.[Imp.Agua]
	, FF.[Cuota]
	, FF.[Cns.Factura]
	, FF.[Uds]
	, FF.inldes
	--***********
	, [percod_0] = C.percod_Ant
	, [periodoD_0] = C.periodoD_Ant
	, [periodoH_0] = C.periodoH_Ant

	, [ctrTitCod_0]  = CC0.ctrTitCod
	, [ctrversion_0] = CC0.ctrversion
	, [Imp.Agua_0] = FF0.[Imp.Agua_Ant]
	, [Cuota_0] = FF0.[Cuota_Ant]
	, [Cns.Factura_0] = FF0.[Cns.Factura_Ant]
	, [Uds_0] = FF0.[Uds_Ant]
	, [inldes_0] = FF0.inldes
	--***********
	--esBaja: Se cuentan como bajas las efectuadas dentro del periodo anterior
	, [esBaja] = CASE WHEN (C.ctsfecbaj IS NOT NULL AND C.ctsfecbaj>=C.periodoD_Ant AND C.ctsfecbaj<=C.periodoH_Ant) THEN 1 
					  WHEN (CC.ctrBaja = 1 AND CC.ctrfecanu >= C.periodoD AND  CC.ctrfecanu <= C.periodoH) THEN 1 	
						ELSE 0  END	
	, [esSvcBaja] = IIF(C.ctsfecbaj IS NOT NULL AND C.ctsfecbaj>=C.periodoD_Ant AND C.ctsfecbaj<=C.periodoH_Ant, 1, 0)
	, [esCtrBaja] = IIF(CC.ctrBaja = 1 AND CC.ctrfecanu >= C.periodoD AND  CC.ctrfecanu <= C.periodoH, 1, 0)

	--esReenganche: Se cuentan como reenganches cuando se hace hace el alta del servicio que anteriormente se le había dado de baja y tiene el servicio de reconexión
	, [esReenganche] = IIF(ctsfecalt>=periodoD AND ctsfecalt<=periodoH AND ctsfecbaj_0 IS NOT NULL, 1, 0)
	, [conTrfReenganche] = IIF(D.CN_Reenganche>0, 1, 0)
	
	--EsAlta:Altas de servicios por contrato entre las fechas de período inicio y fin, antes no tenía servicios por contrato 
	--Además coincide la fecha de inicio del servicio por contrato de distribución con la fecha de inicio y fecha de contrato
	, [esAlta] = IIF(ctsfecalt>=periodoD AND ctsfecalt<=periodoH AND ctsfecbaj_0 IS NULL AND C.ctsfecalt = CC.ctrfec AND C.ctsfecalt = CC.ctrfecini, 1, 0)
	, [conTrfContratacion] = IIF(D.CN_Contratacion>0, 1, 0)
	
	--EsCambioTitular:
	, [esCambioTitular] = IIF(CC.ctrTitCod <> CC0.ctrTitCod, 1, 0)
	, [conTrfCambioTitular] = IIF(D.CN_Titularidad>0, 1, 0)
	
	, [Obs] = IIF(FF.CN>1 OR FF0.CN>1, 'Hay mas de una factura en este periodo', NULL) 

	, ctssrv
	, ctstar
	INTO #RESULT
	FROM #CS AS C
	LEFT JOIN FF 
	ON C.ctrCod = FF.ctrCod
	AND C.percod = FF.percod
	AND FF.RN=1
	LEFT JOIN FF0 
	ON C.ctrCod = FF0.ctrCod
	AND C.percod_Ant = FF0.percod_Ant
	AND FF0.RN=1
	LEFT JOIN #FL_DERECHOS AS D
	ON  D.ctrCod = C.ctrCod
	AND D.percod = C.percod
	LEFT JOIN dbo.contratos AS CC 
	ON FF.ctrCod = CC.ctrCod
	AND FF.facCtrVersion = CC.ctrversion
	LEFT JOIN dbo.contratos AS CC0 
	ON FF0.ctrCod = CC0.ctrCod
	AND FF0.facCtrVersion_Ant = CC0.ctrversion
	WHERE C.RN=1;


	--*******************************	
	--[R01] Nombre de Grupos 
	SELECT * FROM (VALUES ('Resumen'), ('Detalle x Contrato')) 
	AS DataTables(Grupo);

	--*******************************
	--[R02] RESUMEN

	SELECT [Periodo] = R.percod
	, [Zona] = R.ctrzoncod
	, [Bajas] = SUM(IIF(esSvcBaja=1 OR esCtrBaja=1, 1, 0))
	, [Reenganches] = SUM(esReenganche*conTrfReenganche)
	, [Altas] = SUM(esAlta*conTrfContratacion)
	, [Cambio Titular] = SUM(esCambioTitular*conTrfCambioTitular)
	FROM #RESULT AS R
	GROUP BY R.percod, R.ctrzoncod
	ORDER BY R.ctrzoncod, R.percod;
	
	--*******************************
	--[R03] DETALLE
	SELECT [Zona]		= ctrzoncod
		 , [Contrato]	= ctrCod
		 , [Periodo]	= percod
		 , [per.Desde]	= periodoD
		 , [per.Hasta]	= periodoH
		 , [Tarifa]		= T.trfdes
		 , [Agua Desde] = [Alta.Agua]
		 , [Agua Hasta] = [Baja.Agua]
		 , [Agua Anterior D.] = [Alta.Agua_Ant]
		 , [Agua Anterior H.] = [Baja.Agua_Ant]

		 , [Ctr.Baja]		= ctrbaja
		 , [Ctr.Version]	= ctrversion
		 , [Ctr.Fecha]		= ctrfec
		 , [Ctr.Inicio]		= ctrfecini
		 , [Ctr.Anulación]	= ctrfecanu
		 , [Ctr.Titular]	= ctrTitCod

		 , [Cns.Factura]	= [Cns.Factura]
		 , [Cuota]
		 , [Imp.Agua]
		 , [Incidencia]		= inldes 

		 , [Periodo Ant.]	 = percod_0
		 , [Periodo Ant. D]  = periodoD_0
		 , [Periodo Ant. H]  = periodoH_0
		 , [Ctr.Version Ant] = ctrversion_0
		 , [Ctr.Titular Ant] = ctrTitCod_0
 
		 , [Cns.Factura Ant.]	= [Cns.Factura_0]
		 , [Cuota Ant.]			= Cuota_0
		 , [Imp.Agua Ant.]		= [Imp.Agua_0]
		 , [Incidencia Ant.]	= inldes_0 

		 , esSvcBaja
		 , esCtrBaja

		 , esReenganche
		 , conTrfReenganche
		 
		 , esAlta
		 , conTrfContratacion
		 
		 , esCambioTitular
		 , conTrfCambioTitular
		 
	FROM #RESULT AS R
	LEFT JOIN tarifas AS T
	ON R.ctssrv = T.trfsrvcod
	AND R.ctstar = T.trfcod
	WHERE COALESCE(ctrversion, ctrversion_0
				, IIF(esSvcBaja+esCtrBaja > 0, 1, NULL)
				, IIF(esReenganche+conTrfReenganche > 1, 1, NULL)
				, IIF(esAlta+conTrfContratacion > 1, 1, NULL)
				, IIF(esCambioTitular+conTrfCambioTitular>1, 1, NULL)) IS NOT NULL
	ORDER BY ctrCod, percod;




	

	
END TRY

BEGIN CATCH
	SELECT  @p_errId_out = ERROR_NUMBER(),
		    @p_errMsg_out= ERROR_MESSAGE();
END CATCH

IF OBJECT_ID('tempdb..#CS') IS NOT NULL
DROP TABLE #CS;

IF OBJECT_ID('tempdb..#FL_DERECHOS') IS NOT NULL
DROP TABLE #FL_DERECHOS;

IF OBJECT_ID('tempdb..#FL_AGUA') IS NOT NULL
DROP TABLE #FL_AGUA;


IF OBJECT_ID('tempdb..#RESULT') IS NOT NULL
DROP TABLE #RESULT;

GO