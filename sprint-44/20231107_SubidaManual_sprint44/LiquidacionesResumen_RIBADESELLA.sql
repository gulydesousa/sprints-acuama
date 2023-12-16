
/*
INSERT INTO ExcelFiltroGrupos
VALUES (14, 'Periodos, Fechas (desde, hasta)');

INSERT INTO ExcelFiltros
VALUES
(14, 'periodoD', 'Periodo Desde'),
(14, 'periodoH', 'Periodo Hasta'),
(14, 'fechaD', 'Fecha Desde'),
(14, 'fechaH', 'Fecha Hasta');
*/

/*
INSERT INTO dbo.ExcelConsultas
VALUES ('RIBA/002',	'Resumen Liquidaciones', 'Liquidaciones RIBADESELLA (Resumen)', 14, '[InformesExcel].[LiquidacionesResumen_RIBADESELLA]', '000', 'Saca un listado de los totales del fichero de liquidaciones.<br>Las fechas de los filtros corresponden a la <b>fecha de liquidación</b>.');

INSERT INTO ExcelPerfil
VALUES('RIBA/002', 'root', 4, NULL)

INSERT INTO ExcelPerfil
VALUES('RIBA/002', 'jefeExp', 4, NULL)

INSERT INTO ExcelPerfil
VALUES('RIBA/002', 'jefAdmon', 4, NULL)


SELECT * 
--DELETE E
FROM ExcelPerfil AS E WHERE ExPCod='RIBA/002' 

SELECT * 
--DELETE E
FROM  ExcelConsultas AS E WHERE ExcCod='RIBA/002' 
*/


/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_error_out INT;
DECLARE @p_errMsg_out   NVARCHAR(MAX);

SET @p_params= '<NodoXML><LI><periodoD>202205</periodoD><periodoH>202205</periodoH><FecDesde></FecDesde><FecHasta></FecHasta></LI></NodoXML>'

EXEC [InformesExcel].[LiquidacionesResumen_RIBADESELLA] @p_params, @p_error_out OUTPUT, @p_errMsg_out OUTPUT;

*/


ALTER PROCEDURE [InformesExcel].[LiquidacionesResumen_RIBADESELLA]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS

SET NOCOUNT ON;

--******************************************************
--Se ha hecho tomando como base Liquidaciones_RIBADESELLA
--******************************************************
DECLARE @AHORA DATETIME = (SELECT dbo.GETACUAMADATE());

BEGIN TRY
	--**********
	--PARAMETROS
	--**********
	DECLARE @xml AS XML = @p_params;
	DECLARE @params TABLE (periodoD VARCHAR(6) NULL, periodoH VARCHAR(6) NULL
						 , fInforme DATETIME
						 , fechaD DATE NULL, fechaH DATE NULL);

	INSERT INTO @params
	SELECT periodoD = M.Item.value('periodoD[1]', 'VARCHAR(6)')
		 , periodoH = M.Item.value('periodoH[1]', 'VARCHAR(6)')
		
		 , fInforme = @AHORA

		 , fechaD = CASE WHEN M.Item.value('fechaD[1]', 'DATE') = '19000101' THEN NULL 
						 ELSE M.Item.value('fechaD[1]', 'DATE') END
		
		 , fechaH = CASE   WHEN M.Item.value('fechaH[1]', 'DATE') = '19000101' THEN NULL 
						   ELSE M.Item.value('fechaH[1]', 'DATE') END	

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

	SELECT periodoD, periodoH
		, fInforme
		, fechaD AS [Fec.Liq Desde]
		, fechaH AS [Fec.Liq Hasta] 
			
	FROM @params;

	--Para comparar por fechas
	UPDATE P SET fechaH= DATEADD(DAY, 1, fechaH)
	FROM @params AS P
	WHERE P.fechaH IS NOT NULL;
	
	--*********************
	--SE OMITIRÁ TODA DEUDA INFERIOR A 6€
	DECLARE @MIN_DEUDA INT = 6;
	DECLARE @AytoRibadesella SMALLINT = 1;

	--*********************
	--[03]Relacion de Tributos x Servicio
	SELECT ENTEMI
	, TRIBUTO
	, CONCEPTO
	, SUBCONCEPTO_COD
	, SUBCONCEPTO_DESC
	, svcCod
	, svcDes
	, svcOrgCod
	, svctipo
	, esDescuento  
	INTO #TRIBUTOS
	FROM dbo.vLiquidacionesTributos
	WHERE liqTipoId = 0;

	--*********************
	--[10]#FACLIN: LINEAS DE FACTURA LIQUIDADAS 
	-- ...y liquidables por configuración del ayuntamiento
	SELECT F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion
	, F.facZonCod
	, C.ctrTitDocIden
	, T.svccod
	, T.svctipo
	, T.svcOrgCod
	, A.aprNumero
	
	, [Base2Dec] = ROUND(ISNULL(FL.fclBase, 0), 2)
	, [Impuesto] = FL.fclImpImpuesto

	, [RN_ORG]		 = ROW_NUMBER() OVER(PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, T.svcOrgCod ORDER BY fclTrfSvCod, fclNumLinea)
	, [Base2Dec_ORG] = SUM(ROUND(ISNULL(FL.fclBase, 0), 2)) OVER(PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, T.svcOrgCod)
	, [Impuesto_ORG] = SUM(FL.fclImpImpuesto) OVER(PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, T.svcOrgCod)	
	
	, [Omitir] = CAST(IIF(X.facCod IS NULL, 0, 1) AS BIT)
	, [Omitir.Obs] = X.Observacion
	INTO #FAC
	FROM dbo.facturas AS F
	INNER JOIN dbo.faclin AS FL
	ON F.facCod = FL.fclFacCod
	AND F.facPerCod = FL.fclFacPerCod
	AND F.facCtrCod = FL.fclFacCtrCod
	AND F.facVersion = FL.fclFacVersion
	AND F.facFecha IS NOT NULL
	AND FL.fclFecLiq IS NOT NULL	
	AND FL.fclUsrLiq IS NOT NULL
	INNER JOIN dbo.contratos AS C
	ON  C.ctrcod = F.facCtrCod
	AND C.ctrversion = F.facCtrVersion
	INNER JOIN #TRIBUTOS AS T
	ON T.svcCod = FL.fclTrfSvCod	
	LEFT JOIN dbo.apremios AS A
	ON  A.aprFacCod = F.facCod 
	AND A.aprFacCtrCod = F.facCtrCod 
	AND A.aprFacPerCod = F.facPerCod 
	AND A.aprFacVersion = F.facVersion
	--*******
	--EXCLUIR solo para Ribadesella, no el principado
	LEFT JOIN dbo.vLiquidaciones_RIBADESELLA_Omitir AS X
	ON  F.facCod		= X.facCod
	AND F.facPerCod		= X.facPerCod
	AND F.facCtrCod		= X.facCtrCod
	AND F.facVersion	= X.facVersion
	--*******	
	INNER JOIN @params AS P
	ON  (P.fechaD IS NULL OR FL.fclFecLiq >= P.fechaD)
	AND (P.fechaH IS NULL OR FL.fclFecLiq < P.fechaH)
	AND (P.periodoD IS NULL OR F.facPerCod >= P.periodoD)
	AND (P.periodoH IS NULL OR F.facPerCod <= P.periodoH)
	WHERE A.aprNumero IS NULL;
	 
	
	--*******************************	
	--[R01] Nombre de Grupos 
	
	SELECT Grupo = CAST('Ayto Ribadesella' AS VARCHAR(50)), RN= CAST(1 AS SMALLINT)
	INTO #GRUPOS;
	
	INSERT INTO #GRUPOS
	VALUES ('Principado Asturias', 2);

	INSERT INTO #GRUPOS
	SELECT DISTINCT Grupo= facPerCod, 99
	FROM #FAC;
	
	SELECT Grupo= CONCAT(IIF(RN=99, 'Periodo ', ''), Grupo)
	FROM #GRUPOS 
	ORDER BY RN, Grupo;
	--*******************************	

	--[R02]Totales por organismo
	DECLARE @svcOrgCod INT;
	DECLARE ORG CURSOR FOR

	SELECT Organismo=RN 
	FROM #GRUPOS 
	WHERE RN<>99
	ORDER BY Organismo;

	OPEN ORG
	FETCH NEXT FROM ORG INTO  @svcOrgCod ;
	WHILE @@FETCH_STATUS = 0  
	BEGIN  


		SELECT facPerCod
		, [Nº Facturas]		  = COUNT(faccod)
		, [Bases totales]	  = SUM(F.[Base2Dec_ORG])
		, [Impuestos totales] = SUM(ROUND(F.[Impuesto_ORG], 2))
		, [Totales] = SUM(F.[Base2Dec_ORG]+ ROUND(F.[Impuesto_ORG], 2))

		FROM #FAC AS F 
		WHERE (F.RN_ORG=1 AND F.Base2Dec_ORG>0) --Una linea por factura
		  AND (F.[Base2Dec_ORG] + ROUND(F.[Impuesto_ORG], 2) >= @MIN_DEUDA)
		  AND svcOrgCod = @svcOrgCod
		 --EXCLUIR solo para Ribadesella, no el principado
		  AND (@svcOrgCod<>@AytoRibadesella OR F.Omitir = 0) 
		GROUP BY facPerCod
	
		UNION 
		SELECT facPerCod = 'Totales'
		, [Nº Facturas]		  = COUNT(faccod)
		, [Bases totales]	  = SUM(F.[Base2Dec_ORG])
		, [Impuestos totales] = SUM(ROUND(F.[Impuesto_ORG], 2))
		, [Totales] = SUM(F.[Base2Dec_ORG]+ ROUND(F.[Impuesto_ORG], 2))
		FROM #FAC AS F 
		WHERE (F.RN_ORG=1 AND F.Base2Dec_ORG>0) --Una linea por factura
		  AND (F.[Base2Dec_ORG] + ROUND(F.[Impuesto_ORG], 2) >= @MIN_DEUDA)
		  AND svcOrgCod = @svcOrgCod
		  --EXCLUIR solo para Ribadesella, no el principado
		  AND (@svcOrgCod<>@AytoRibadesella OR F.Omitir = 0);

		
		FETCH NEXT FROM ORG INTO  @svcOrgCod ;
	END

	CLOSE ORG
	DEALLOCATE ORG
		
	DECLARE @percod VARCHAR(6);
	DECLARE PERCOD CURSOR FOR

	SELECT facPerCod=Grupo 
	FROM #GRUPOS 
	WHERE RN=99
	ORDER BY facPerCod;

	OPEN PERCOD
	FETCH NEXT FROM PERCOD INTO @percod;
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		WITH FAC AS(
		--Total por factura
		SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion
		, [Titular] = MAX(F.ctrTitDocIden)
		, [Omitir]  = MAX(F.[Omitir.Obs])
		
		, [Base_Ayto]	  = SUM(IIF(F.svcOrgCod=1, F.[Base2Dec], 0))
		, [Impuesto_Ayto] = SUM(IIF(F.svcOrgCod=1, ROUND(F.[Impuesto], 2), 0))

		, [Base_Principado]	    = SUM(IIF(F.svcOrgCod=2, F.[Base2Dec], 0))
		, [Impuesto_Principado] = SUM(IIF(F.svcOrgCod=2, ROUND(F.[Impuesto], 2), 0))

		FROM #FAC AS F
		GROUP BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion
		
		), SVC AS(
		--Total por servicio y factura
		SELECT F.facCod, F.facPerCod, facCtrCod, facVersion
			
		, [Base_1]		= SUM(IIF(svcCod=1, [Base2Dec], 0)) 
		, [Impuesto_1]	= SUM(IIF(svcCod=1, ROUND([Impuesto], 2), 0)) 
		
		, [Base_2]		= SUM(IIF(svcCod=2, [Base2Dec], 0)) 
		, [Impuesto_2]	= SUM(IIF(svcCod=2, ROUND([Impuesto], 2), 0)) 
		
		, [Base_3]		= SUM(IIF(svcCod=3, [Base2Dec], 0)) 
		, [Impuesto_3]	= SUM(IIF(svcCod=3, ROUND([Impuesto], 2), 0)) 
		
		, [Base_4]		= SUM(IIF(svcCod=4, [Base2Dec], 0)) 
		, [Impuesto_4]	= SUM(IIF(svcCod=4, ROUND([Impuesto], 2), 0)) 
		
		, [Base_5]		= SUM(IIF(svcCod=5, [Base2Dec], 0)) 
		, [Impuesto_5]	= SUM(IIF(svcCod=5, ROUND([Impuesto], 2), 0)) 
		
		, [Base_6]		= SUM(IIF(svcCod=6, [Base2Dec], 0)) 
		, [Impuesto_6]	= SUM(IIF(svcCod=6, ROUND([Impuesto], 2), 0)) 

		, [Base_57]		= SUM(IIF(svcCod=57, [Base2Dec], 0)) 
		, [Impuesto_57]	= SUM(IIF(svcCod=57, ROUND([Impuesto], 2), 0)) 
		
		, [Base_58]		= SUM(IIF(svcCod=58, [Base2Dec], 0)) 
		, [Impuesto_58]	= SUM(IIF(svcCod=58, ROUND([Impuesto], 2), 0)) 

		, [Base_7]		= SUM(IIF(svcCod=7, [Base2Dec], 0)) 
		, [Impuesto_7]	= SUM(IIF(svcCod=7, ROUND([Impuesto], 2), 0)) 

		, [Base_9]		= SUM(IIF(svcCod=9, [Base2Dec], 0)) 
		, [Impuesto_9]	= SUM(IIF(svcCod=9, ROUND([Impuesto], 2), 0)) 
		
		, [Base_11]		= SUM(IIF(svcCod=11, [Base2Dec], 0)) 
		, [Impuesto_11]	= SUM(IIF(svcCod=11, ROUND([Impuesto], 2), 0)) 

		, [Base_12]		= SUM(IIF(svcCod=12, [Base2Dec], 0)) 
		, [Impuesto_12]	= SUM(IIF(svcCod=12, ROUND([Impuesto], 2), 0)) 

		FROM #FAC AS F
		WHERE F.facPerCod = @percod
		GROUP BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion 
		
		)

		--Total por factura desglosado por servicio
		SELECT F.facCod, F.facCtrCod, F.facPerCod, F.facVersion, F.Titular
		, F.Base_Ayto, F.Impuesto_Ayto
		, S.Base_1, S.Impuesto_1
		, S.Base_2, S.Impuesto_2
		, S.Base_3, S.Impuesto_3
		, S.Base_4, S.Impuesto_4
		, S.Base_5, S.Impuesto_5
		, S.Base_6, S.Impuesto_6
		, S.Base_57, S.Impuesto_57
		, S.Base_58, S.Impuesto_58

		, F.Base_Principado, F.Impuesto_Principado
		, S.Base_7, S.Impuesto_7
		, S.Base_9, S.Impuesto_9
		, S.Base_11, S.Impuesto_11
		, S.Base_12, S.Impuesto_12	
		--EXCLUIR solo para Ribadesella, no el principado
		, [Omitir] = CASE WHEN (F.Base_Ayto + F.Impuesto_Ayto < @MIN_DEUDA) THEN FORMATMESSAGE('Ayto.Ribadesella: Deuda inferior %i€', @MIN_DEUDA)
						WHEN F.Omitir IS NOT NULL THEN FORMATMESSAGE('Ayto.Ribadesella: %s', F.Omitir)
						ELSE NULL END	 
		FROM FAC AS F
		LEFT JOIN SVC AS S
		ON  S.facCod	 = F.facCod
		AND S.facPerCod  = F.facPerCod
		AND S.facCtrCod  = F.facCtrCod
		AND S.facVersion = F.facVersion
		WHERE F.facPerCod = @percod
		AND ([Base_Ayto]>0 OR [Base_Principado]>0)  
		
		FETCH NEXT FROM PERCOD INTO @percod;
	END

	CLOSE PERCOD
	DEALLOCATE PERCOD
	END TRY

BEGIN CATCH
		IF CURSOR_STATUS('global','PERCOD') >= -1
		BEGIN
		IF CURSOR_STATUS('global','PERCOD') > -1 CLOSE PERCOD;
		DEALLOCATE PERCOD;
		END


		IF CURSOR_STATUS('global','ORG') >= -1
		BEGIN
			IF CURSOR_STATUS('global','ORG') > -1 CLOSE ORG;
			DEALLOCATE ORG;
		END

		SELECT  @p_errId_out = ERROR_NUMBER()
			 ,  @p_errMsg_out= ERROR_MESSAGE();
END CATCH

IF OBJECT_ID(N'tempdb..#TRIBUTOS') IS NOT NULL
DROP TABLE #TRIBUTOS;

IF OBJECT_ID(N'tempdb..#FAC') IS NOT NULL
DROP TABLE #FAC;

IF OBJECT_ID(N'tempdb..#GRUPOS') IS NOT NULL
DROP TABLE #GRUPOS;


GO

