/*
--DROP PROCEDURE [InformesExcel].[ResumenGestionesxFechaLectura_MELILLA]
--SELECT * FROM ExcelConsultas
--DELETE FROM ExcelPerfil WHERE ExPCod IN ('100/002', '100/102')
--DELETE FROM dbo.ExcelConsultas WHERE ExcCod IN ('100/002', '100/102')

INSERT INTO dbo.ExcelConsultas VALUES ('100/002','Resumen gestión fechas', 'Melilla: Resumen de gestiones por fechas', 11, '[InformesExcel].[ResumenGestionesPorFechas_MELILLA]', 'CSV+', 
'<table><tr><td width="50px"><b>Bajas:</b></td><td>CONTAR(conSvcBaja=1)</td><td>&nbsp;&nbsp;</td>
<td><b>Altas: </b></td><td>conTrfContratacion=1 => SUMA(udsContratacion)</td></tr>
<tr><td colspan="5"></td></tr>
<tr><td><b>Cambio Titular:</b></td><td>CONTAR(conTrfCambioTitular=1)</td><td>&nbsp;&nbsp;</td>
<td><b>Reenganches:</b></td><td>conTrfReenganche=1 => SUMA(udsReenganche)</td></tr></table>', NULL, NULL, NULL, NULL);

INSERT INTO ExcelPerfil VALUES('100/002', 'root', 4, NULL)
INSERT INTO ExcelPerfil VALUES('100/002', 'direcc', 4, NULL)
*/

/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);
SET @p_params='<NodoXML><LI><fechaD>20231201</fechaD><fechaH>20231231</fechaH><zonaD></zonaD><zonaH></zonaH></LI></NodoXML>'

EXEC [InformesExcel].[ResumenGestionesPorFechas_MELILLA] @p_params, @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/

ALTER PROCEDURE [InformesExcel].[ResumenGestionesPorFechas_MELILLA]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT,
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS


--PARAMETROS
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

SELECT fechaD, fechaH, fInforme, zonaD, zonaH 
FROM @params;

--PARAMETROS
DECLARE @zonaD VARCHAR(4), @zonaH VARCHAR(4), @fDesde DATE, @fHasta DATE;
SELECT @zonaD = P.zonaD, @zonaH = P.zonaH, @fDesde = P.fechaD, @fHasta = DATEADD(DAY, 1, P.fechaH) 
FROM @params AS P;

--VARIABLES
DECLARE @AGUA INT = 1;
DECLARE @SVC_DERECHOS INT =10;
DECLARE @TRF_CONTRATACION INT = 1000;
DECLARE @TRF_TITULARIDAD INT = 2000;
DECLARE @TRF_REENGANCHE INT = 3000;

SELECT @AGUA = P.pgsvalor FROM dbo.parametros AS P WHERE P.pgsclave = 'SERVICIO_AGUA';

DECLARE @perCod VARCHAR(6), @periodoD DATETIME, @periodoH DATETIME , @perCod_Ant VARCHAR(6), @periodoD_Ant DATETIME , @periodoH_Ant DATETIME;

BEGIN TRY

	--#CS: Ultima version de cada contrato con sus servicios de agua
	SELECT C.ctrCod
		, C.ctrversion
		, C.ctrComunitario
		, C.ctrzoncod
		, C.ctrBaja
		, CS.ctssrv
		, CS.ctstar
		, CC.ctrfecreg
		, [ctsfecalt] = CAST(CS.ctsfecalt AS DATE)
		, [ctsfecbaj] = CAST(CS.ctsfecbaj AS DATE)
		, [ctsfecrealbaja] = CAST(CS.ctsfecrealbaja AS DATE)
		--Vigencia anterior del servicio de agua con la misma tarifa
		, [ctsfecalt_0] = LEAD(CAST(CS.ctsfecalt AS DATE)) OVER(PARTITION BY C.ctrCod, CS.ctssrv, CS.ctstar ORDER BY CS.ctsfecalt DESC, IIF(CS.ctsfecbaj IS NULL, '19000101', CS.ctsfecbaj))
		, [ctsfecbaj_0] = LEAD(CAST(CS.ctsfecbaj AS DATE)) OVER(PARTITION BY C.ctrCod, CS.ctssrv, CS.ctstar ORDER BY CS.ctsfecalt DESC, IIF(CS.ctsfecbaj IS NULL, '19000101', CS.ctsfecbaj))
		, [ctsfecrealbaja_0] = LEAD(CAST(CS.ctsfecrealbaja AS DATE)) OVER(PARTITION BY C.ctrCod, CS.ctssrv, CS.ctstar ORDER BY CS.ctsfecalt DESC, IIF(CS.ctsfecrealbaja IS NULL, '19000101', CS.ctsfecrealbaja))
		--RN=1: Para quedarnos con la ultima vigencia del servicio, cuando hay dos altas en la misma fecha nos quedamos con la de vigencia mas reciente
		, [RN] = ROW_NUMBER() OVER(PARTITION BY C.ctrCod, CS.ctssrv ORDER BY CS.ctsfecalt DESC, IIF(CS.ctsfecbaj IS NULL, '19000101', CS.ctsfecbaj))
	INTO #CS
	FROM dbo.vContratosUltimaVersion AS C
	LEFT JOIN dbo.contratoServicio AS CS 
	ON CS.ctsctrcod = C.ctrCod AND CS.ctssrv = @AGUA
	LEFT JOIN dbo.contratos AS CC 
	ON C.ctrCod = CC.ctrCod AND C.ctrVersion = CC.ctrversion
	WHERE (@zonaD IS NULL OR C.ctrzoncod >= @zonaD) AND (@zonaH IS NULL OR C.ctrzoncod <= @zonaH);

	--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
	--Comprobar que no sea que una factura repita servicio de agua en servicios por contrato
	--SELECT * FROM #CS WHERE [RN]>1;
	--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
	
	--#FL_DERECHOS: DERECHOS DE CONTRATACIÓN. Lineas de factura
	SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, FL.fclNumLinea
		, F.facLecLectorFec
		--RN=1 para quedarnos con una linea por contrato
		, RN = ROW_NUMBER() OVER (PARTITION BY F.facCtrCod ORDER BY  F.facCod, F.facPerCod, F.facVersion, FL.fclNumLinea)
		--**************
		, CN_Reenganche = SUM(IIF(FL.fclTrfCod=@TRF_REENGANCHE, 1, 0)) OVER(PARTITION BY F.facCtrCod)
		, CN_UdsReenganche = SUM(IIF(FL.fclTrfCod=@TRF_REENGANCHE, FL.fclUnidades, 0)) OVER(PARTITION BY F.facCtrCod)
		, CN_Contratacion = SUM(IIF(FL.fclTrfCod=@TRF_CONTRATACION, 1, 0)) OVER(PARTITION BY F.facCtrCod)
		, CN_UdsContratacion = SUM(IIF(FL.fclTrfCod=@TRF_CONTRATACION,  FL.fclUnidades, 0)) OVER(PARTITION BY F.facCtrCod)
		, CN_Titularidad = SUM(IIF(FL.fclTrfCod=@TRF_TITULARIDAD, 1, 0)) OVER(PARTITION BY F.facCtrCod)
		, CN_UdsTitularidad = SUM(IIF(FL.fclTrfCod=@TRF_TITULARIDAD,  FL.fclUnidades, 0)) OVER(PARTITION BY F.facCtrCod)
		--Para comprobar que solo hay una ocurrencia de cada servicio por factura: debería haber 1 ó 0, si hay mas es porque hay varias ocurrencias de la misma tarifa
		, CN_ReenganchesxFactura = SUM(IIF(FL.fclTrfCod=@TRF_REENGANCHE, 1, 0)) OVER(PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion)
		, CN_ContratacionxFactura = SUM(IIF(FL.fclTrfCod=@TRF_CONTRATACION, 1, 0)) OVER(PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion)
		, CN_TitularidadxFactura = SUM(IIF(FL.fclTrfCod=@TRF_TITULARIDAD, 1, 0)) OVER(PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion)
	INTO #FL_DERECHOS
	FROM #CS AS C
	INNER JOIN dbo.facturas AS F 
	ON  C.RN=1 --Solo queremos una linea por contrato
	AND F.facCtrCod = C.ctrCod 
	AND F.facFechaRectif IS NULL
	AND ((F.facLecLectorFec IS NOT NULL AND F.facLecLectorFec >= @fDesde AND F.facLecLectorFec < @fHasta)
	  OR (F.facLecLectorFec IS NULL AND F.facZonCod = 51 AND F.facFecha >= @fHasta AND (C.ctrfecreg >= @fDesde AND C.ctrfecreg < @fHasta)))
	INNER JOIN dbo.faclin AS FL 
	ON  FL.fclFacPerCod = F.facPerCod 
	AND FL.fclFacCtrCod = F.facCtrCod 
	AND FL.fclFacVersion = F.facVersion 
	AND FL.fclFacCod = F.facCod 
	AND FL.fclTrfSvCod = @SVC_DERECHOS;

	--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
	--Comprobar que no sea que una factura repita servicios y afecten nuestro resultado
	--SELECT * FROM #FL_DERECHOS WHERE CN_ReenganchesxFactura>1 OR CN_ContratacionxFactura>1 OR CN_TitularidadxFactura>1;
	--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

	--#FL_AGUA: LineaImporte Agua
	SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, FL.fclNumLinea
	, F.facInsInlCod
	, F.facLecInlCod
	, F.facLecLectorFec
	, F.facConsumoFactura
	, [inlcod] = ISNULL(F.facInsInlCod, facLecInlCod)
	, FL.fclUnidades
	, FL.fcltotal
	, [Uds] = ISNULL(FL.fclUnidades1,0)+
			  ISNULL(FL.fclUnidades2,0)+
			  ISNULL(FL.fclUnidades3,0)+
			  ISNULL(FL.fclUnidades4,0)+
			  ISNULL(FL.fclUnidades5,0)+
			  ISNULL(FL.fclUnidades6,0)+
			  ISNULL(FL.fclUnidades7,0)+
			  ISNULL(FL.fclUnidades8,0)+ 
			  ISNULL(FL.fclUnidades9,0)
	--RN=1: Si se repite el servicio de agua en una misma factura contamos solo una de las lineas
	, RN = ROW_NUMBER() OVER (PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion ORDER BY FL.fclNumLinea)
	--CN>1: Servicios que se repiten en una factura
	, CN = COUNT(FL.fclNumLinea) OVER (PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion)
	INTO #FL_AGUA
	FROM #CS AS C
	INNER JOIN dbo.facturas AS F 
	ON C.RN=1 
	AND F.facCtrCod = C.ctrCod 
	AND F.facFechaRectif IS NULL 
	AND (F.facLecLectorFec >= @fDesde AND F.facLecLectorFec < @fHasta)
	INNER JOIN dbo.faclin AS FL 
	ON  FL.fclFacPerCod = F.facPerCod 
	AND FL.fclFacCtrCod = F.facCtrCod 
	AND FL.fclFacVersion = F.facVersion 
	AND FL.fclFacCod = F.facCod 
	AND FL.fclTrfSvCod = @AGUA;
	
	--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
	--Comprobar que no sea que una factura repita el servicio de agua y afecten nuestro resultado
	--SELECT * FROM FL_AGUA WHERE CN>1;
	--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx


	--#RESULT
	WITH FACS AS(
	SELECT A.facCod, A.facPerCod, A.facCtrCod, A.facVersion 
	FROM #FL_AGUA AS A
	UNION
	SELECT D.facCod, D.facPerCod, D.facCtrCod, D.facVersion 
	FROM #FL_DERECHOS AS D)

	SELECT C.ctrCod
		, C.ctrcomunitario
		, C.ctrzoncod
		, F.facCod
		, F.facPerCod
		, F.facVersion
		, [Alta.Agua] = C.ctsfecalt
		, [Baja.Agua] = C.ctsfecbaj
		, [Baja.Real.Agua] = C.ctsfecrealbaja
		, [Alta.Agua_Ant] = C.ctsfecalt_0
		, [Baja.Agua_Ant] = C.ctsfecbaj_0
		, [Baja.Real.Agua_Ant] = C.ctsfecrealbaja_0
		, [ctrfec] = CAST(CC.ctrfec AS DATE)
		, [ctrfecini] = CAST(CC.ctrfecini AS DATE)
		, CC.ctrfecanu
		, CC.ctrbaja
		, CC.ctrTitCod
		, CC.ctrversion
		, [facLecturaFecha] = CAST(A.facLecLectorFec AS DATE)
		, [Imp.Agua] = A.fcltotal
		, [Cuota] = A.fclUnidades
		, [Cns.Factura] = A.facConsumoFactura
		, A.[Uds]
		, [Incidencia] = I.inldes
		, [conSvcBaja] = IIF(C.ctsfecrealbaja IS NOT NULL AND C.ctsfecrealbaja>=@fDesde AND C.ctsfecrealbaja<@fHasta, 1, IIF(C.ctsfecrealbaja_0 IS NOT NULL AND C.ctsfecrealbaja_0>=@fDesde AND C.ctsfecrealbaja_0<@fHasta, 1, 0))
		, [conTrfReenganche] = IIF(D.CN_Reenganche>0, 1, 0)
		, [udsReenganche] = CN_UdsReenganche
		, [conTrfContratacion] = IIF(D.CN_Contratacion>0, 1, 0)
		, [udsContratacion] = CN_UdsContratacion
		, [conTrfCambioTitular] = IIF(D.CN_Titularidad>0, 1, 0)
		, [Obs] = IIF(A.CN>1, 'Hay mas de una factura en este periodo ', '')
		, [svcAgua] = C.ctssrv
		, [trfAgua] = C.ctstar
	INTO #RESULT
	FROM #CS AS C
	INNER JOIN dbo.contratos AS CC 
	ON  C.RN=1
	AND C.ctrCod = CC.ctrCod 
	AND C.ctrVersion = CC.ctrversion
	LEFT JOIN FACS AS F
	ON F.facCtrCod = CC.ctrcod
	LEFT JOIN #FL_AGUA AS A 
	ON  A.RN=1
	AND F.facCod= A.facCod
	AND F.facPerCod = A.facPerCod
	AND F.facCtrCod = A.facCtrCod
	AND F.facVersion = A.facVersion

	LEFT JOIN #FL_DERECHOS AS D 
	ON D.RN=1
	AND F.facCod= D.facCod
	AND F.facPerCod = D.facPerCod
	AND F.facCtrCod = D.facCtrCod
	AND F.facVersion = D.facVersion
	LEFT JOIN incilec AS I
	ON I.inlcod = A.inlcod;
	
	
	--*******************************	
	--[R01] Nombre de Grupos 
	SELECT * FROM (VALUES ('Totales por zona'), ('Detalle x Contrato')) 
	AS DataTables(Grupo);
	

	--*******************************
	--[R02] RESUMEN
	SELECT [Zona] = ctrzoncod
	, [Bajas] = SUM(IIF(conSvcBaja=1, 1, 0))
	, [Altas] = SUM(IIF(udsContratacion IS NULL, 0, CAST(ROUND(udsContratacion, 0) AS INT)))
	, [Cambio Titular] =  SUM(IIF(conTrfCambioTitular=1, 1, 0))
	, [Reenganches] = SUM(IIF(udsReenganche IS NULL, 0, CAST(ROUND(udsReenganche, 0) AS INT)))
	FROM #RESULT
	GROUP BY ctrzoncod
	ORDER BY Zona;

	--*******************************
	--[R03] DETALLE
	SELECT * FROM #RESULT
	ORDER BY ctrCod;


END TRY
BEGIN CATCH
	SELECT @p_errId_out = ERROR_NUMBER(), @p_errMsg_out= ERROR_MESSAGE();
END CATCH
/*
IF OBJECT_ID('tempdb..#CS') IS NOT NULL DROP TABLE #CS;
IF OBJECT_ID('tempdb..#FL_DERECHOS') IS NOT NULL DROP TABLE #FL_DERECHOS;
IF OBJECT_ID('tempdb..#FL_AGUA') IS NOT NULL DROP TABLE #FL_AGUA;
IF OBJECT_ID('tempdb..#RESULT') IS NOT NULL DROP TABLE #RESULT;
*/
DROP TABLE IF EXISTS #CS;
DROP TABLE IF EXISTS #FL_DERECHOS;
DROP TABLE IF EXISTS #FL_AGUA;
DROP TABLE IF EXISTS #RESULT;


GO


