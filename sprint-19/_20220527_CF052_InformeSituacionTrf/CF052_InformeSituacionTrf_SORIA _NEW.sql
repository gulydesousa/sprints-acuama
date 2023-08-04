/*
DECLARE @cvFecIni DATE = '20211117';
DECLARE @cvFecFin DATE = '20211204';
DECLARE @periodoD VARCHAR(6) = NULL;
DECLARE @periodoH VARCHAR(6) = NULL;
DECLARE @filtrar INT = 0;
DECLARE @xmlSerCodArray VARCHAR(MAX) = '';

--*******************
--** PARA PRUEBAS ***
DECLARE @ctrCod INT = NULL;

--SELECT @xmlSerCodArray = CONCAT(@xmlSerCodArray, '<servicioCodigo><value>') + CAST(svccod AS VARCHAR(5))+ '</value></servicioCodigo>'
--FROM dbo.servicios
--WHERE svccod NOT IN (11);

--SET @xmlSerCodArray = FORMATMESSAGE('<servicioCodigo_List>%s</servicioCodigo_List>', @xmlSerCodArray)


EXEC [ReportingServices].[CF052_InformeSituacionTrf_SORIA] @cvFecIni, @cvFecFin, @periodoD, @periodoH, @filtrar, @xmlSerCodArray;
*/

ALTER PROCEDURE [ReportingServices].[CF052_InformeSituacionTrf_SORIA_NEW]
(
	@cvFecIni		DATE = NULL,
	@cvFecFin		DATE = NULL,
	@periodoD		VARCHAR(6) = NULL,
	@periodoH		VARCHAR(6) = NULL,
	@filtrar		INT = 0,
	@xmlSerCodArray TEXT = NULL,
	@ctrCod			INT = 0
)
AS

SET NOCOUNT ON;

--****************************************
--Evolutivo SPRINT#19
--Creado sobre la base de:
--[ReportingServices].[CF052_InformeSituacionTrf_SORIA_OLD] renombrado
--****************************************

BEGIN TRY

	--***** P A R A M E T R O S *****
	SELECT @cvFecIni = ISNULL(@cvFecIni, '19010101')
		 , @cvFecFin = DATEADD(DAY, 1, ISNULL(@cvFecFin, GETDATE()))
		 , @filtrar  = ISNULL(@filtrar, 0)
		 , @ctrCod	 = ISNULL(@ctrCod, 0);

	--***** V A R I A B L E S *****
	DECLARE @EXPLOTACION VARCHAR(100) = NULL;
	DECLARE @SERV_AGUA INT = 1;
	DECLARE @SERVICIOFIANZA INT = NULL;
	DECLARE @MIN_PERIODO VARCHAR(6) = NULL;		--Minimo periodo de consumo en BBDD acuama	
	DECLARE @PERIODO_INICIO VARCHAR(6) = NULL;  --Periodo de consumo inicio de factuación acuama
	
	DECLARE @SERVICIOSEXCLUIDOS AS TABLE(servicioCodigo SMALLINT);
	DECLARE @SERVICIOSINCLUIDOS AS TABLE(servicioCodigo SMALLINT);
	
	DECLARE @NUM_ENTREGASCTA INT = 0;
	DECLARE @FAC AS dbo.tFacturasPK_info;
	DECLARE @FLS AS dbo.tFacLin_situacion;

	DECLARE @COB  AS dbo.tCobrosPK_info;
	DECLARE @COBS AS dbo.tCobLinDes_Situacion;

	SELECT @EXPLOTACION = UPPER(P.pgsValor) 
	FROM dbo.parametros AS P 
	WHERE P.pgsClave = 'EXPLOTACION';

	SELECT @SERV_AGUA = P.pgsValor 
	FROM dbo.parametros AS P 
	WHERE P.pgsClave = 'SERVICIO_AGUA';

	SELECT @SERVICIOFIANZA = P.pgsValor 
	FROM dbo.parametros AS P
	WHERE pgsClave='SERVICIO_FIANZA'
	AND @EXPLOTACION <> 'SORIA';

	--Minimo periodo de consumo por defecto
	SELECT @MIN_PERIODO = MIN(P.percod) 
	FROM dbo.periodos AS P 
	WHERE P.percod  NOT LIKE '0000%'

	--PERIODO_INICIO: Marca el inicio de factuación acuama
	SELECT @PERIODO_INICIO = P.pgsValor
	FROM dbo.parametros AS P
	WHERE P.pgsClave = 'PERIODO_INICIO';

	SELECT @PERIODO_INICIO = ISNULL(@PERIODO_INICIO, @MIN_PERIODO);

	--*****************************
	--Leemos los id de servicios enviados por parametros en formato XML
	INSERT INTO @SERVICIOSEXCLUIDOS(servicioCodigo)
	EXEC dbo.Servicios_XMLsvccod @xmlSerCodArray,'/servicioCodigo_List/servicioCodigo';

	INSERT INTO @SERVICIOSINCLUIDOS(servicioCodigo)
	SELECT S.svccod
	FROM dbo.servicios AS S
	LEFT JOIN @SERVICIOSEXCLUIDOS AS X
	ON X.servicioCodigo = S.svccod
	WHERE (@filtrar=0 AND (X.servicioCodigo IS NULL))
	   OR (@filtrar=1 AND (S.svcdes='RSU' OR S.svcdes LIKE 'BONIFICACION ECOVIDRIO%'));

	--==========================
	--**** D E B U G ***********
	--==========================
	DECLARE @svcs AS VARCHAR(MAX);
	SELECT  @svcs = COALESCE(@svcs + ', ' + CAST(servicioCodigo AS VARCHAR),  CAST(servicioCodigo AS VARCHAR)) FROM @SERVICIOSINCLUIDOS;
	DECLARE @sp_Name VARCHAR(100) = FORMATMESSAGE('%s.%s', OBJECT_SCHEMA_NAME(@@PROCID), OBJECT_NAME(@@PROCID));

	DECLARE @sp_Message AS VARCHAR(4000) = '';
	SELECT @sp_Message = FORMATMESSAGE('@MIN_PERIODO=%s, @PERIODO_INICIO= %s, @EXPLOTACION=%s, @SERVICIOFIANZA=%i, @cvFecIni=%s, @cvFecFin=%s, @periodoD=%s, @periodoH= %s, @filtrar= %i, num.Servicios= %i, servicios IN (%s)'
										, @MIN_PERIODO
										, @PERIODO_INICIO
										, @EXPLOTACION
										, @SERVICIOFIANZA
										, FORMAT(@cvFecIni, 'yyyyMMdd')
										, FORMAT(@cvFecFin, 'yyyyMMdd')
										, @periodoD
										, @periodoH
										, @filtrar
										, (SELECT COUNT(servicioCodigo) FROM @SERVICIOSINCLUIDOS)
										, @svcs);

	EXEC Trabajo.errorLog_Insert   @spName = @sp_Name, @spMessage = @sp_Message;

	--SELECT [@MIN_PERIODO]= @MIN_PERIODO
	--	 , [@PERIODO_INICIO]= @PERIODO_INICIO
	--	 , [@EXPLOTACION]=@EXPLOTACION
	--	 , [@SERVICIOFIANZA]= @SERVICIOFIANZA
	--	 , [@cvFecIni] = @cvFecIni
	--	 , [@cvFecFin] = @cvFecFin
	--	 , [@periodoD] = @periodoD
	--	 , [@periodoH] = @periodoH
	--	 , [@filtrar]  = @filtrar
	--	 , [num.Servicios] = (SELECT COUNT(servicioCodigo) FROM @SERVICIOSINCLUIDOS)
	--	 , [servicios] = @svcs;
	--*****************************
	;
	--=======================================================
	--[01] @FAC: PKs FACTURAS SEGUN LOS FILTROS DE SELECCION
	--Para clasificar (ORIGINAL, ANULADA ó CREADA)  
	--Esta tabla contiene todas las facturas que necesitamos para el informe sea por:
	--Facturación, Cobros o Versiones Previas para cobros
	--=======================================================
	--***** @FAC******
	INSERT INTO @FAC(facCod, facPerCod, facCtrCod, facVersion, facFecha, facFechaRectif, Original, Anulada, Creada, Cobrada)
	SELECT DISTINCT 
	  F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion
	, F.facFecha
	, F.facFechaRectif
	, Originales = 0
	, Anulada	 = 0
	, Creada	 = 0
	, Cobrado	 = 0
	FROM dbo.facturas AS F WITH(INDEX(PK_facturas))
	INNER JOIN dbo.faclin AS FL  WITH(INDEX(PK_faclin))
	ON  FL.fclfaccod = F.faccod 
	AND FL.fclfacpercod = F.facpercod 
	AND FL.fclfacctrcod = F.facctrcod 
	AND FL.fclfacversion = F.facversion 
	AND F.facNumero IS NOT NULL
	AND F.facFecha IS NOT NULL
	INNER JOIN @SERVICIOSINCLUIDOS AS SI
	ON  FL.fclTrfSvCod= SI.servicioCodigo
	AND (@ctrCod = 0 OR F.facCtrCod=@ctrCod)
	--*** EXCLUIR LIQUIDADAS  ***  
	WHERE ((FL.fclFecLiq IS NULL AND FL.fclUsrLiq IS NULL) OR FL.fclFecLiq>=@cvFecFin) 
	  AND (@servicioFianza IS NULL OR FL.fclTrfSvCod <> @servicioFianza)
	  AND (
		  (F.facFecha >= @cvFecIni AND F.facFecha < @cvFecFin) OR
		  ( F.facFechaRectif IS NOT NULL AND facFechaRectif >= @cvFecIni AND facFechaRectif  < @cvFecFin)
	  );

	--********************************
	--*****  O R I G I N A L E S *****
	UPDATE F SET Original=1
	FROM @FAC AS F
	WHERE facVersion=1 
	AND   facFecha >= @cvFecIni 
	AND   facFecha < @cvFecFin
	AND (
		  (facPerCod='000002') 
		  OR 
		  (
			(facPerCod<>'000002') AND 
			(@periodoD IS NULL OR facPerCod >= @periodoD OR facPerCod LIKE '0000%') AND 
			(@periodoH IS NULL OR facPerCod <= @periodoH OR facPerCod LIKE '0000%') AND 
			(facpercod >= @PERIODO_INICIO OR facpercod<@MIN_PERIODO)
		  )
	);
 
	--****************************
	--*****  A N U L A D A S *****
	UPDATE F 
	SET F.Anulada=1
	FROM @FAC AS F
	WHERE facFechaRectif IS NOT NULL
	  AND facFechaRectif >= @cvFecIni 
	  AND facFechaRectif  < @cvFecFin
	  AND (
			(@periodoD IS NULL OR facPerCod >= @periodoD OR facPerCod LIKE '0000%') AND 
			(@periodoH IS NULL OR facPerCod <= @periodoH OR facPerCod LIKE '0000%') AND 
			(facpercod >= @PERIODO_INICIO OR facpercod<@MIN_PERIODO)
		);
	
	--**************************
	--*****  C R E A D A S *****
	 UPDATE F 
	SET F.Creada=1
	FROM @FAC AS F
	WHERE facVersion>1 
	  AND facFecha >= @cvFecIni 
	  AND facFecha  < @cvFecFin
	  AND (
			(@periodoD IS NULL OR facPerCod >= @periodoD OR facPerCod LIKE '0000%') AND 
			(@periodoH IS NULL OR facPerCod <= @periodoH OR facPerCod LIKE '0000%') AND 
			(facpercod >= @PERIODO_INICIO OR facpercod<@MIN_PERIODO)
		);

	--**********************************
	--***** BORRAR NO CLASIFICADAS *****
	DELETE FROM @FAC 
	WHERE Original = 0 
	  AND Anulada = 0 
	  AND Creada = 0;
	
	--=======================================================
	--[02] @COB: PK DE LOS COBROS SEGUN LOS FILTROS DE SELECCION
	--=======================================================
	--***** @COB ******
	--Solo  a servicios incluidos
	INSERT INTO @COB(cobScd, cobPpag, cobNum, cblLin, cldFacLin, cldImporte
				   , facCod, facPerCod, facCtrCod, facVersion
				   , cobfecreg, ppebca)
	SELECT C.cobScd, C.cobPpag, C.cobNum, CL.cblLin, CLD.cldFacLin, CLD.cldImporte
	, CL.cblFacCod, CL.cblPer, C.cobCtr, CL.cblFacVersion
	, C.cobfecreg, E.ppebca 
	FROM dbo.cobros AS C WITH(INDEX(PK_cobros))
	INNER JOIN dbo.coblin AS CL  WITH(INDEX(PK_coblin))
	ON  CL.cblScd  = C.cobScd
	AND	CL.cblPpag = C.cobPpag
	AND	CL.cblNum  = C.cobnum
	AND (@ctrCod = 0 OR C.cobCtr=@ctrCod)
	--****************
	--Rango de periodos
	AND (CL.cblper >= @PERIODO_INICIO OR CL.cblper<@MIN_PERIODO)
	AND (@periodoD IS NULL OR CL.cblper >= @periodoD OR CL.cblper LIKE '0000%')		   
	AND (@periodoH IS NULL OR CL.cblper <= @periodoH OR CL.cblper LIKE '0000%')
	--********************
	AND (C.cobfecreg >=  @cvFecIni AND  C.cobfecreg <  @cvFecFin)
	INNER JOIN dbo.cobLinDes AS CLD
	ON  CLD.cldCblScd = CL.cblScd
	AND CLD.cldCblPpag = CL.cblPpag
	AND CLD.cldCblNum = CL.cblNum
	AND CLD.cldCblLin = CL.cblLin
	INNER JOIN dbo.ppagos AS PP 
	ON PP.ppagcod = C.cobppag
	INNER JOIN dbo.ppentidades AS E 
	ON E.ppecod = PP.ppagppcppeCod
	INNER JOIN @SERVICIOSINCLUIDOS AS SI
	ON CLD.cldTrfSrvCod= SI.servicioCodigo;
	
	--************************************
	--***** @COB: ENTREGAS A CUENTA ******
	--El insert de arriba NO trae EC porque no esos tienen coblindes
	INSERT INTO @COB(cobScd, cobPpag, cobNum, cblLin, cldFacLin, cldImporte
				   , facCod, facPerCod, facCtrCod, facVersion
				   , cobfecreg, ppebca)
	SELECT C.cobScd
	, C.cobPpag
	, C.cobNum
	, CL.cblLin
	, cldFacLin = 1
	, CL.cblImporte

	, facCod		= ROW_NUMBER() OVER(PARTITION BY CL.cblPer, C.cobCtr ORDER BY C.cobfecreg ASC)
	, facPerCod		= CL.cblPer
	, facCtrCod		= C.cobCtr
	, facVersion	= ISNULL(CL.cblFacVersion, 1)

	, C.cobfecreg
	, E.ppebca 
	FROM dbo.cobros AS C  WITH(INDEX(PK_cobros))
	INNER JOIN dbo.coblin AS CL   WITH(INDEX(PK_coblin))
	ON  CL.cblPer='999999'
	AND CL.cblScd  = C.cobScd
	AND	CL.cblPpag = C.cobPpag
	AND	CL.cblNum  = C.cobnum
	AND (@ctrCod = 0 OR C.cobCtr=@ctrCod)
	--****************
	--Rango de periodos
	AND (CL.cblper >= @PERIODO_INICIO OR CL.cblper<@MIN_PERIODO)
	AND (@periodoD IS NULL OR CL.cblper >= @periodoD OR CL.cblper LIKE '0000%')		   
	AND (@periodoH IS NULL OR CL.cblper <= @periodoH OR CL.cblper LIKE '0000%')
	--********************
	AND (C.cobfecreg >=  @cvFecIni AND  C.cobfecreg <  @cvFecFin)	
	INNER JOIN dbo.ppagos AS PP 
	ON PP.ppagcod = C.cobppag
	INNER JOIN dbo.ppentidades AS E 
	ON E.ppecod = PP.ppagppcppeCod;

	--=======================================================
	--[03] @FAC: PK DE LOS FACTURAS ASOCIADAS A LOS COBROS EN @COB
	--=======================================================
	--***** FACTURAS EN @COB ******
	WITH FAC AS(
	SELECT DISTINCT C.facCod
	, C.facPerCod
	, C.facCtrCod
	, C.facVersion
	FROM @COB AS C
	LEFT JOIN @FAC AS F
	ON  F.facCod = C.facCod
	AND F.facPerCod = C.facPerCod
	AND F.facCtrCod = C.facCtrCod
	AND F.facVersion = C.facVersion 
	WHERE F.facCod IS NULL)

	INSERT INTO @FAC (facCod, C.facPerCod, facCtrCod, facVersion, facFecha
					, Original, Anulada, Creada, Cobrada)
	SELECT F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion
	, T.facFecha
	, Original	= 0
	, Anulada	= 0
	, Creada	= 0
	, Cobrada	= 1
	FROM FAC AS F
	LEFT JOIN dbo.facturas AS T WITH(INDEX(PK_facturas))
	ON T.faccod		= F.facCod
	AND T.facPerCod = F.facPerCod
	AND T.facCtrCod = F.facCtrCod
	AND T.facVersion= F.facVersion;

	--=======================================================
	--[04] @FAC: PK DE LOS FACTURAS PREVIAS ASOCIADAS A LOS COBROS
	--Si la linea de factura tiene importe 0
	--Buscamos las facturas anteriores con el mismo sevicio e importe <>0 en la linea
	--=======================================================
	INSERT INTO @FAC (facCod, facPerCod, facCtrCod, facVersion, facFecha, facFechaRectif, Original, Anulada, Creada, Cobrada)
	SELECT DISTINCT 
	  F0.facCod
	, F0.facPerCod
	, F0.facCtrCod
	, F0.facVersion
	, F0.facFecha
	, F0.facFechaRectif
	, Original	= 0
	, Anulada	= 0
	, Creada	= 0
	, Cobrada	= 0
	FROM @FAC AS F
	INNER JOIN dbo.faclin AS FL WITH(INDEX(PK_faclin))
	ON  F.facCod	= FL.fclFacCod
	AND F.facPerCod = FL.fclFacPerCod
	AND F.facCtrCod = FL.fclFacCtrCod
	AND F.facVersion= FL.fclFacVersion
	--La linea de la factura es 0
	AND FL.fcltotal = 0
	INNER JOIN dbo.faclin AS FL0  WITH(INDEX(PK_faclin))
	ON  F.facCod	= FL0.fclFacCod
	AND F.facPerCod = FL0.fclFacPerCod
	AND F.facCtrCod = FL0.fclFacCtrCod
	AND FL0.fclFacVersion <= F.facVersion
	--Versiones anteriores que no tienen 0 en ese servicio
	AND FL0.fcltotal <> 0
	AND FL0.fclTrfSvCod = FL.fclTrfSvCod
	INNER JOIN dbo.facturas AS F0  WITH(INDEX(PK_facturas))
	ON  F0.facCod	  = FL0.fclFacCod
	AND F0.facPerCod  = FL0.fclFacPerCod
	AND F0.facCtrCod  = FL0.fclFacCtrCod
	AND F0.facVersion = FL0.fclFacVersion
	LEFT JOIN @FAC AS T
	ON  T.facCod	= F0.facCod
	AND T.facPerCod = F0.facPerCod
	AND T.facCtrCod = F0.facCtrCod
	AND T.facVersion= F0.facVersion
	--Las que no existen ya en @FAC
	WHERE T.facCod IS NULL;
	

	--=======================================================
	--[11] @FLS: LINEAS DE FACTURAS EN @FAC
	--CREATE: Lineas de factura (solo servicios incluidos)
	--INSERT: Lineas ficticias por Entregas a cuentas o inconsistencias en cobros
	--=======================================================
	--***** @FLS ******
	INSERT INTO @FLS ([FAC_ID]
					, [facCod], [facPerCod], [facCtrCod], [facVersion], FL.fclNumLinea
					, [cuatrimestre], [BloqueId]
					, [fclTrfSvCod], [fclTrfCod]
					, [servTarifa], [esServicio]
					, [facZonCod]
					, [facFechaRectif], [facFecha], [facFechaV1]
					, [fclBase], [fclImpImpuesto], [fcltotal]
					, [cargoFijo], [consumo]
					, [Original], [Anulada], [Creada], [Cobrada], [NoLiquidada])

	SELECT [FAC_ID]			 = DENSE_RANK()		  OVER(ORDER BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion)
		 , [facCod]			 = FL.fclFacCod
		 , [facPerCod]		 = FL.fclFacPerCod
		 , [facCtrCod]		 = FL.fclFacCtrCod
		 , [facVersion]		 = FL.fclFacVersion
		 , FL.fclNumLinea
	 			 	
		 , [cuatrimestre]	= 1 + ((MONTH(F.facFecha)-1)/4)
		 , [BloqueId]		= CASE WHEN B.sblqCod IS NULL THEN NULL
							  WHEN B.sblqCod IN(0, 99) AND F.facZonCod <>'0010' THEN 1
							  WHEN B.sblqCod IN(0, 99) AND F.facZonCod = '0010' THEN 2
							  ELSE B.sblqCod  END
						 
		 , FL.fclTrfSvCod
		 , FL.fclTrfCod

		 , [servTarifa]		= CASE WHEN FL.fclTrfSvCod NOT IN (1, 17, 9999) THEN FORMATMESSAGE('%04i-%03i', FL.fclTrfSvCod, 0)
							   WHEN FL.fclTrfSvCod <> @SERV_AGUA			THEN FORMATMESSAGE('%04i-%03i', 0, FL.fclTrfCod)
							   WHEN F.facpercod='999999'					THEN '-001'
							   WHEN FL.fclTrfCod IN (1, 3)					THEN '-100'
							   WHEN FL.fclTrfCod IN (2, 6, 5, 8)			THEN '-200' 
							   ELSE FORMATMESSAGE('%04i-%03i', 0, FL.fclTrfCod) END
						   
		, [esServicio]		= IIF(FL.fclTrfSvCod NOT IN (1, 17, 9999), 1,  0)
		
		, F.facZonCod
		
		, F.facFechaRectif
		, F.facFecha
		, facFechaV1		= IIF(fclFacVersion=1, CAST(F.facFecha AS DATE), F1.facFecha)
	 
	 	, FL.fclBase
		, FL.fclImpImpuesto
		, FL.fcltotal

		, [cargoFijo]	= CAST(ROUND(FL.fclUnidades*FL.fclPrecio, 4) AS DECIMAL(12,4)) 
		, [consumo]		= CAST((ROUND(FL.fclunidades1 * FL.fclprecio1, 4) + 
								ROUND(FL.fclunidades2 * FL.fclprecio2, 4) + 
								ROUND(FL.fclunidades3 * FL.fclprecio3, 4) + 
								ROUND(FL.fclunidades4 * FL.fclprecio4, 4) + 
								ROUND(FL.fclunidades5 * FL.fclprecio5, 4) +
								ROUND(FL.fclunidades6 * FL.fclprecio6, 4) + 
								ROUND(FL.fclunidades7 * FL.fclprecio7, 4) + 
								ROUND(FL.fclunidades8 * FL.fclprecio8, 4) + 
								ROUND(FL.fclunidades9 * FL.fclprecio9, 4)) AS DECIMAL(12,4))
		--**********************************************
		--Inicializamos con los valores que vienen de la factura
		--En el update de las columnas calculadas se actualizará dependiendo si es liquidada o no
		, [Original]	= V.Original
		, [Anulada]		= V.Anulada
		, [Creada]		= V.Creada
		, [Cobrada]		= V.Cobrada
		--**********************************************
		, [NoLiquidada]	= IIF((FL.fclFecLiq IS NULL AND FL.fclUsrLiq IS NULL) OR FL.fclFecLiq>=@cvFecFin, 1, 0)  
	FROM @FAC AS V
	INNER JOIN dbo.facturas AS F  WITH(INDEX(PK_facturas))
	ON F.facCod		 = V.facCod
	AND F.facPerCod  = V.facPerCod
	AND F.facCtrCod  = V.facCtrCod
	AND F.facVersion = V.facVersion
	INNER JOIN dbo.faclin AS FL  WITH(INDEX(PK_faclin))
	ON  FL.fclfaccod = F.faccod 
	AND FL.fclfacpercod = F.facpercod 
	AND FL.fclfacctrcod = F.facctrcod 
	AND FL.fclfacversion = F.facversion
	INNER JOIN @SERVICIOSINCLUIDOS AS SI
	ON SI.servicioCodigo = FL.fclTrfSvCod
	LEFT JOIN dbo.serviciosBloques AS B
	ON B.sblqSvcCod = FL.fclTrfSvCod
	--Version#1 de la factura
	LEFT JOIN dbo.facturas AS F1 WITH(INDEX(PK_facturas))
	ON  F.facCod	 = F1.facCod
	AND F.facPerCod  = F1.facPerCod
	AND F.facCtrCod  = F1.facCtrCod
	AND F.facVersion <> 1
	AND F1.facVersion = 1;

	--************************************
	--***** DUMMY: Factura ficticias
	--***** ENTREGAS A CUENTA
	--***** NO EXISTE LINEA FACTURA CON LOS DATOS DEL COBRO 
	--************************************
	WITH DUMMY AS(
	SELECT DISTINCT
	  C.facCod
	, C.facPerCod
	, C.facCtrCod
	, C.facVersion
	, fclNumLinea	= C.cldFacLin
	, fclTrfSvCod	= IIF(C.facPerCod= '999999', 9999, CLD.cldTrfSrvCod)
	, fclTrfCod		= IIF(C.facPerCod= '999999', 1, CLD.cldTrfCod)
	, fclImporte	= IIF(C.facPerCod= '999999', C.cldImporte, 0)
	FROM @COB AS C
	LEFT JOIN dbo.cobLinDes AS CLD
	ON  CLD.cldCblScd	= C.cobScd
	AND CLD.cldCblPpag	= C.cobPpag
	AND CLD.cldCblNum	= C.cobNum
	AND CLD.cldCblLin	= C.cblLin
	AND CLD.cldFacLin	= C.cldFacLin
	LEFT JOIN @SERVICIOSINCLUIDOS AS S
	ON S.servicioCodigo = CLD.cldTrfSrvCod
	LEFT JOIN @FLS AS F
	ON F.facCod			= C.facCod
	AND F.facPerCod		= C.facPerCod
	AND F.facCtrCod		= C.facCtrCod
	AND F.facVersion	= C.facVersion
	AND F.fclNumLinea	= C.cldFacLin
	--Solo los servicios incluidos, entregas a cuenta
	--A pesar de haber metido las facturas de los cobros en @FAC la linea de factura falta
	--Esto porque aun quedan inconsistencias en los datos de faclin y coblindes
	WHERE (S.servicioCodigo IS NOT NULL OR C.facPerCod='999999')
	  AND (F.facCod IS NULL)
	)
	--Las distinguimos de las lineas reales por tener FAC_ID negativo
	INSERT INTO @FLS ([FAC_ID]
					, [facCod], [facPerCod], [facCtrCod], [facVersion], FL.fclNumLinea
					, [cuatrimestre], [BloqueId]
					, [fclTrfSvCod], [fclTrfCod]
					, [servTarifa], [esServicio]
					, [facZonCod]
					, [fclBase], [fclImpImpuesto], [fcltotal]
					, [cargoFijo], [consumo]
					, [Original], [Anulada], [Creada], [Cobrada], [NoLiquidada])

	SELECT [FAC_ID]			 = (-1)*DENSE_RANK()  OVER(ORDER BY		F.facCod, F.facPerCod, F.facCtrCod, F.facVersion)
		 , [facCod]			= facCod
		 , [facPerCod]		= facPerCod
		 , [facCtrCod]		= facCtrCod
		 , [facVersion]		= facVersion
		 , fclNumLinea		= fclNumLinea
	 
		 , [cuatrimestre]	= 0
		 , [BloqueId]		= CASE	WHEN F.facPerCod = '999999'	AND C.ctrzoncod <>'0010' THEN 1
									WHEN F.facPerCod = '999999'	AND C.ctrzoncod ='0010'  THEN 2
									WHEN B.sblqCod IS NULL THEN NULL
									WHEN B.sblqCod IN(0, 99) AND C.ctrzoncod <>'0010'	THEN 1
									WHEN B.sblqCod IN(0, 99) AND C.ctrzoncod = '0010'	THEN 2
									ELSE B.sblqCod  END
						 
		 , fclTrfSvCod			= F.fclTrfSvCod
		 , fclTrfCod			= F.fclTrfCod

		 , [servTarifa]			= FORMATMESSAGE('%04i-%03i', F.fclTrfSvCod, F.fclTrfCod)
		 , [esServicio]			= IIF(F.fclTrfSvCod NOT IN (1, 17, 9999), 1,  0)
		 
		 , [facZonCod]			= C.ctrzoncod

		 , fclBase				= fclImporte
		 , fclImpImpuesto		= 0
		 , fcltotal				= fclImporte
	 
		 , [cargoFijo]		= 0
		 , [consumo]		= 0

		 , [Original]		= 0
		 , [Anulada]		= 0
		 , [Creada]			= 0
		 , [Cobrada]		= 1
		 , [NoLiquidada]	= 0
	FROM DUMMY AS F
	INNER JOIN dbo.vContratosUltimaVersion AS C
	ON  C.ctrCod = F.facCtrCod
	LEFT JOIN dbo.serviciosBloques AS B
	ON B.sblqSvcCod = F.fclTrfSvCod;
	
	--=======================================================
	--[12] #FPREV: LINEAS DE FACTURAS PRECEDENTES
	--Si factura no tiene lineas > 0
	--Buscamos las versiones anteriores por servicio y tarifa  (RN=1)
	--Buscamos las versiones anteriores solo por servicio	   (RN_SVC=1)
	--Lo necesitaremos para desglosar el importe de los cobros (CargoFijo, Consumo, Base, Impuesto, Total)
	--=======================================================
	--***** #FPREV *****	
	SELECT  FL.facCod
	, FL.facPerCod
	, FL.facCtrCod
	, FL.facVersion
	, FL.fclNumLinea
	
	, L.fclTrfCod
	, L.fclTrfSvCod	

	, FL.fcltotal
	
	--RN=1: Será la version mas reciente de la linea por factura, servicio y tarifa
	, RN = ROW_NUMBER() OVER (PARTITION BY FL.facCod, FL.facPerCod, FL.facCtrCod, L.fclTrfCod, L.fclTrfSvCod 
						ORDER BY  IIF(L.fclTrfCod=FL.fclTrfCod, 0, 1) ASC --Las que tienen la misma tarifa están en primer lugar
									, FL.facVersion DESC
									, FL.fclNumLinea ASC)

	--RN_SVC=1: Será la version mas reciente de la linea por factura y servicio (sin tarifa)
	, RN_SVC = ROW_NUMBER() OVER (PARTITION BY FL.facCod, FL.facPerCod, FL.facCtrCod, L.fclTrfSvCod 
							--Independientemente de la tarifa, las de mayor version y menor linea ocupan el primer lugar
							ORDER BY  FL.facVersion DESC
									, FL.fclNumLinea ASC)
	INTO #FPREV
	FROM @FLS AS L
	INNER JOIN @FLS AS FL
	ON  L.fclTotal = 0
	AND L.facCod	  = FL.facCod
	AND L.facPerCod   = FL.facPerCod
	AND L.facCtrCod   = FL.facCtrCod
	AND L.fclTrfSvCod = FL.fclTrfSvCod
	--Versiones de factura previas con importe en la linea
	AND FL.facVersion  <= L.facVersion
	AND FL.fcltotal <> 0;
	
	--=======================================================
	--[21] @COBS: DESGLOSE DE LAS LINEAS DE COBROS EN @COB
	--=======================================================
	--***** @COBS ******
	INSERT INTO @COBS([cobScd], [cobPpag], [cobNum], [cblLin], [cldFacLin], [cobfecreg]
					, [facCod], [facCtrCod], [facPerCod], [facVersion]
					, [cldTrfSrvCod], [cldTrfCod]
					, [cldImporte]
					, [esCobro], [esDevolucion], [esBanco], [esOficina])

	SELECT V.cobScd
		 , V.cobPpag
		 , V.cobNum
		 , V.cblLin
		 , V.cldFacLin
		 , V.cobFecReg
	
		 , V.facCod
		 , V.facCtrCod
		 , V.facPerCod
		 , V.facVersion
	
		 , cldTrfSrvCod	= IIF(V.facPerCod = '999999', 9999, CLD.cldTrfSrvCod)
		 , cldTrfCod	= IIF(V.facPerCod = '999999', 1, CLD.cldTrfCod)

		 , cldImporte	= IIF(V.facPerCod = '999999', CL.cblImporte, CLD.cldImporte)
	
		 , esCobro		= IIF(CL.cblImporte > 0, 1, 0) 
		 , esDevolucion	= IIF(CL.cblImporte > 0, 0, 1) 
		 , esBanco		= IIF(V.ppebca=1 , 1, 0)
		 , esOficina	= IIF(V.ppebca=1 , 0, 1)	
	FROM @COB AS V
	INNER JOIN dbo.coblin AS CL WITH(INDEX(PK_coblin))
	ON  CL.cblScd	= V.cobScd
	AND CL.cblPpag	= V.cobPPag
	AND CL.cblNum	= V.cobNum
	AND CL.cblLin	= V.cblLin
	LEFT JOIN dbo.cobLinDes AS CLD
	ON  CLD.cldCblScd	= V.cobScd
	AND CLD.cldCblPpag	= V.cobPPag
	AND CLD.cldCblNum	= V.cobNum
	AND CLD.cldCblLin	= V.cblLin
	AND CLD.cldFacLin	= V.cldFacLin;

	--=======================================================
	--[31] @FLS, @COBS: Asignamos VALORES DE LAS COLUMNAS CALCULADAS 
	--=======================================================
	--***** UPDATE @FLS *****
	UPDATE F SET
	  [periodoMensual]		= PZ.przCodPer
	, [periodoRegistrado]	= CASE  WHEN F.facPerCod= '000002' 
									THEN FORMATMESSAGE('%i%02i', YEAR(F.facfecha), F.cuatrimestre*4) 
									WHEN F.facPerCod LIKE '0%'
									THEN PZ.przCodPer 
									ELSE F.facPerCod END
	, [periodo]				= IIF(F.facPerCod= '000002', FORMATMESSAGE('%i%02i', YEAR(F.facfecha), F.cuatrimestre*4), F.facPerCod)
	
	, [przTipo]				= CASE  F.facPerCod
							  WHEN '999999' THEN 'ENTREGAS A CUENTA'
							  WHEN '000002' THEN 'Cuatrimestral'	
							  ELSE ISNULL(Z.przTipo, '') END

	, [desServTarifa]		= CASE WHEN F.esServicio=1 THEN S.svcdes
							   WHEN F.fclTrfSvCod = @SERV_AGUA AND T.trfcod IN (1, 3) THEN 'USO DOMÉSTICO' 
							   WHEN F.fclTrfSvCod = @SERV_AGUA AND T.trfcod IN (2, 6, 5, 8) THEN 'USO INDUSTRIAL' 
							   WHEN F.facpercod='999999' THEN 'ENTREGAS A CUENTA'
							   ELSE T.trfdes END

	, [Original]			= NoLiquidada*Original
	, [Anulada]				= NoLiquidada*Anulada
	, [Creada]				= NoLiquidada*Creada
	FROM @FLS AS F
	LEFT JOIN dbo.perzona AS Z  WITH(INDEX(PK_perzona))
	ON  Z.przcodzon = F.facZonCod
	AND Z.przcodper = F.facPerCod
	LEFT JOIN dbo.tarifas AS T
	ON T.trfcod		= F.fclTrfCod
	AND T.trfsrvcod = F.fclTrfSvCod
	LEFT JOIN dbo.servicios AS S
	ON S.svccod		= F.fclTrfSvCod
	LEFT JOIN dbo.vPerzonaMensual AS PZ
	ON  F.facPerCod LIKE '0%'
	AND F.facPerCod  <> '000002'
	AND F.facFechaV1 >= PZ.przfPeriodoD
	AND F.facFechaV1 <= PZ.przfPeriodoH;

	--***** UPDATE @COBS *****	
	WITH FAC AS (
	--Contamos las lineas por factura con importe <> 0
	SELECT facCod
	, facPerCod
	, facCtrCod
	, facVersion
	, [CN] = SUM(IIF(fcltotal=0, 0, 1))
	FROM @FLS AS F
	GROUP BY facCod, facPerCod, facCtrCod, facVersion)

	UPDATE C SET
	  [fclFicticia]	 = IIF(F1.FAC_ID<0, 1, 0)
	--************************************************
	--Cuando la factura no tiene lineas con importes, buscamos una linea de factura alternativa
	--Factura usada para obtener el cargofijo, consumo, base e impuesto
	, [fclTotal]	 = IIF(ISNULL(CN, 0)>0, F1.fcltotal		, ISNULL(F0.fcltotal	, F00.fcltotal))
	, [fclFacLin]	 = IIF(ISNULL(CN, 0)>0, F1.fclNumLinea	, ISNULL(F0.fclNumLinea	, F00.fclNumLinea))
	, [fclFacVersion]= IIF(ISNULL(CN, 0)>0, F1.facVersion	, ISNULL(F0.facVersion	, F00.facVersion))
	FROM @COBS AS C
	LEFT JOIN FAC AS F
	ON  F.facCod	= C.facCod
	AND F.facPerCod	= C.facPerCod
	AND F.facCtrCod = C.facCtrCod
	AND F.facVersion= C.facVersion
	LEFT JOIN @FLS AS F1
	ON  C.facCod	  = F1.facCod
	AND C.facCtrCod   = F1.facCtrCod
	AND C.facPerCod   = F1.facPerCod
	AND C.facVersion  = F1.facVersion
	AND C.cldFacLin	  = F1.fclNumLinea
	--Si la linea es 0: Buscamos la factura anterior por servicio y tarifa
	LEFT JOIN #FPREV AS F0
	ON  F1.fcltotal = 0 
	AND (C.esDevolucion=1 OR C.cldImporte<>0)
	AND C.facCod		= F0.facCod
	AND C.facPerCod		= F0.facPerCod
	AND C.facCtrCod		= F0.facCtrCod
	AND C.cldTrfSrvCod	= F0.fclTrfSvCod
	AND C.cldTrfCod		= F0.fclTrfCod
	AND F0.RN=1
	--Si la linea por servicio y tarifa es 0: Buscamos la factura anterior por servicio
	LEFT JOIN #FPREV AS F00
	ON  F0.fcltotal IS NULL 
	AND (C.esDevolucion=1 OR C.cldImporte<>0)
	AND C.facCod		= F00.facCod
	AND C.facPerCod		= F00.facPerCod
	AND C.facCtrCod		= F00.facCtrCod
	AND C.cldTrfSrvCod	= F00.fclTrfSvCod
	AND F00.RN_SVC=1;

	UPDATE C
	SET [cargoFijo]	 =  CASE WHEN ISNULL(T.fcltotal, 0) <> 0 
							 THEN (T.cargoFijo  *C.cldImporte)/T.fcltotal
							 ELSE NULL END

	, [consumo]		 =  CASE WHEN ISNULL(T.fcltotal, 0) <> 0
							 THEN (T.consumo   *C.cldImporte)/T.fcltotal
							 ELSE NULL END

	, [base]		 =  CASE WHEN ISNULL(T.fcltotal, 0) <> 0
							 THEN (T.fclBase   *C.cldImporte)/T.fcltotal
							 ELSE NULL END

	, [impuesto]	 = CASE WHEN ISNULL(T.fcltotal, 0) <> 0 
							THEN (T.fclImpImpuesto  *C.cldImporte)/T.fcltotal
							ELSE NULL END

	--Se contabiliza el cobro porque tiene una linea de factura asociada 
	, [cobContar]	 = CASE WHEN T.fcltotal  IS NULL THEN 0
							WHEN C.cldImporte IS NULL THEN 0
							WHEN T.fcltotal=0  THEN 0
							ELSE 1 END
	FROM @COBS AS C
	LEFT JOIN @FLS AS T
	ON C.facCod			= T.facCod
	AND C.facPerCod		= T.facPerCod
	AND C.facCtrCod		= T.facCtrCod
	--Calculamos los totales con la versión de factura alternativa
	AND C.fclFacVersion = T.facVersion
	AND C.fclFacLin		= T.fclNumLinea;

	--=======================================================
	--[91] RESULTADO 
	--=======================================================
	
	--***** #C  *****
	SELECT  BloqueId	= ISNULL(F.BloqueId, '')
	, F.przTipo 
	, F.periodo
	, periodoRegistrado = ISNULL(F.periodoRegistrado, '')
	, desServTarifa		= MAX(F.desServTarifa) 

	, nCobBanco			= SUM(C.cobContar	*esBanco*esCobro)
	, cobBanCargoFijo	= SUM(C.cargoFijo	*esBanco*esCobro)
	, cobBanConsumo		= SUM(C.consumo		*esBanco*esCobro)
	, cobBanBase		= SUM(C.base		*esBanco*esCobro)
	, cobBanImpuesto	= SUM(C.impuesto	*esBanco*esCobro)
	, cobBanTotal		= SUM(C.cldImporte	*esBanco*esCobro*C.cobContar)

	, nCobOficina		= SUM(C.cobContar	*esOficina*esCobro)
	, cobOfiCargoFijo	= SUM(C.cargoFijo	*esOficina*esCobro)
	, cobOfiConsumo		= SUM(C.consumo		*esOficina*esCobro)
	, cobOfiBase		= SUM(C.base		*esOficina*esCobro)
	, cobOfiImpuesto	= SUM(C.impuesto	*esOficina*esCobro)
	, cobOfiTotal		= SUM(C.cldImporte	*esOficina*esCobro*C.cobContar)

	, nDevBanco			= SUM(C.cobContar	*esBanco*esDevolucion)
	, DevBanCargoFijo	= SUM(C.cargoFijo	*esBanco*esDevolucion)
	, DevBanConsumo		= SUM(C.consumo		*esBanco*esDevolucion)
	, DevBanBase		= SUM(C.base		*esBanco*esDevolucion)
	, DevBanImpuesto	= SUM(C.impuesto	*esBanco*esDevolucion)
	, DevBanTotal		= SUM(C.cldImporte	*esBanco*esDevolucion*C.cobContar)

	, nDevOficina		= SUM(C.cobContar	*esOficina*esDevolucion)
	, DevOfiCargoFijo	= SUM(C.cargoFijo	*esOficina*esDevolucion)
	, DevOfiConsumo		= SUM(C.consumo		*esOficina*esDevolucion)
	, DevOfiBase		= SUM(C.base		*esOficina*esDevolucion)
	, DevOfiImpuesto	= SUM(C.impuesto	*esOficina*esDevolucion)
	, DevOfiTotal		= SUM(C.cldImporte	*esOficina*esDevolucion*C.cobContar)
	--Numero de cobros en la agrupacion
	, numCobros			= SUM(C.cobContar)
	INTO #C
	FROM @COBS AS C
	LEFT JOIN @FLS AS F
	ON  C.facCod		= F.facCod
	AND C.facPerCod		= F.facPerCod
	AND C.facCtrCod		= F.facCtrCod
	AND F.facVersion	= C.fclFacVersion
	AND F.fclNumLinea	= C.fclFacLin

	GROUP BY  F.BloqueId, F.przTipo, F.periodo, F.periodoRegistrado, F.servTarifa;

	--***************
	--***** #F  *****
	SELECT BloqueId		= ISNULL(F.BloqueId, '')
	, F.przTipo 
	, F.periodo
	, periodoRegistrado = ISNULL(F.periodoRegistrado, '')
	, desServTarifa		= MAX(F.desServTarifa) 
	, F.servTarifa		
	
	, Original			= SUM(Original)
	, facCargoFijo		= SUM(F.cargoFijo		*Original)
	, facConsumo		= SUM(F.consumo			*Original)
	, facBase			= SUM(F.fclBase			*Original)
	, facImpuesto		= SUM(F.fclImpImpuesto	*Original)
	, factotal			= SUM(F.fclTotal		*Original)
	
	, Anulada			= SUM(Anulada)
	, anuCargoFijo		= SUM(F.cargoFijo		*Anulada)
	, anuConsumo		= SUM(F.consumo			*Anulada)
	, anuBase			= SUM(F.fclBase			*Anulada)
	, anuImpuesto		= SUM(F.fclImpImpuesto	*Anulada)
	, anutotal			= SUM(F.fclTotal		*Anulada)
	
	, Creada			= SUM(Creada)
	, creCargoFijo		= SUM(F.cargoFijo		*Creada)
	, creConsumo		= SUM(F.consumo			*Creada)
	, creBase			= SUM(F.fclBase			*Creada)
	, creImpuesto		= SUM(F.fclImpImpuesto	*Creada)
	, cretotal			= SUM(F.fclTotal		*Creada)
	
	--Numero de facturas en la agrupación
	, numFacturas		= SUM(IIF(Original + Anulada + Creada > 0, 1, 0)) 
	INTO #F
	FROM @FLS AS F
	--Omitimos las facturas ficticias excepto las de entregas a cuentas
	WHERE (F.FAC_ID > 0 OR F.facPerCod='999999')
	GROUP BY  F.BloqueId, F.przTipo, F.periodo, F.periodoRegistrado, F.servTarifa;
	

	--****************************
	--******** RESULTADO  ********

	--xxxxxxxxxxxxxxxxxxxxxxxxx
	--xxxx  P R U E B A S  xxxx
	--xxxxxxxxxxxxxxxxxxxxxxxxx

	--SELECT C.*, F.periodoRegistrado 
	--FROM @COBS AS C
	--LEFT JOIN @FLS AS F
	--ON  C.facCod		= F.facCod
	--AND C.facPerCod		= F.facPerCod
	--AND C.facCtrCod		= F.facCtrCod
	--AND F.facVersion	= C.fclFacVersion
	--AND F.fclNumLinea	= C.fclFacLin
	--WHERE periodoRegistrado='201409' AND fclTrfSvCod=13;

	--SELECT *
	--FROM @FLS AS F
	-- WHERE facCtrCod=30254 AND facPerCod='000001' and fclTrfSvCod=13;

	--SELECT *
	--FROM #FPREV AS F
	--WHERE fclFacCtrCod=30254 AND fclFacPerCod='000001' and fclTrfSvCod=13;
		
	--SELECT * FROM #F WHERE periodoRegistrado='201804' AND desServTarifa='RSU';
	--SELECT * FROM #C WHERE periodoRegistrado='201804' AND desServTarifa='RSU';

	--xxxxxxxxxxxxxxxxxxxxxxxxx
	--xxxxxxxxxxxxxxxxxxxxxxxxx
	--xxxxxxxxxxxxxxxxxxxxxxxxx

	WITH BLOQUES AS(
	SELECT DISTINCT sblqCod, sblqDesc
	FROM dbo.serviciosBloques)

	SELECT F.BloqueId
	, BloqueNom = CASE	WHEN F.periodo='999999' THEN 'ENTREGAS A CUENTA'
						WHEN F.BloqueId IS NULL THEN '_'
						WHEN F.BloqueId=1		THEN 'CUATRIMESTRALES'
						WHEN F.BloqueId=2		THEN 'MENSUALES'
						ELSE B.sblqDesc END		
	, F.przTipo
	, F.periodo
	, F.periodoRegistrado
	, F.desServTarifa

	, facnFacturas		= F.Original
	--********* I N F O ************
	--Los decimales usan . y el money usa ,
	--Hacemos el CAST para que estas dos columnas nos la saque igual que el resto
	--SELECT D= CAST(1.5 AS decimal(12,2)), M= CAST(1.5 AS money)
	--********* * * * * ************
	, facCargoFijo		= CAST(F.facCargoFijo AS MONEY)
	, facConsumo		= CAST(F.facConsumo AS MONEY)
	, F.facBase
	, F.facImpuesto
	, F.factotal

	, anunFacturas		= F.Anulada	
	, anuCargoFijo		= CAST(F.anuCargoFijo AS MONEY)
	, anuConsumo		= CAST(F.anuConsumo	 AS MONEY)
	, F.anuBase	
	, F.anuImpuesto	
	, F.anuTotal

	, crenFacturas		= F.Creada
	, creCargoFijo		= CAST(F.creCargoFijo AS MONEY)
	, creConsumo		= CAST(F.creConsumo AS MONEY)
	, F.creBase
	, F.creImpuesto
	, F.creTotal

	, nCobBanco			= ISNULL(C.nCobBanco, 0)
	, cobBanCargoFijo	= ISNULL(C.cobBanCargoFijo, 0)
	, cobBanConsumo		= ISNULL(C.cobBanConsumo, 0)
	, cobBanBase		= ISNULL(C.cobBanBase, 0)
	, cobBanImpuesto	= ISNULL(C.cobBanImpuesto, 0)
	, cobBanTotal		= ISNULL(C.cobBanTotal, 0)

	, nCobOficina		= ISNULL(C.nCobOficina, 0)
	, cobOfiCargoFijo	= ISNULL(C.cobOfiCargoFijo, 0)
	, cobOfiConsumo		= ISNULL(C.cobOfiConsumo, 0)
	, cobOfiBase		= ISNULL(C.cobOfiBase, 0)
	, cobOfiImpuesto	= ISNULL(C.cobOfiImpuesto, 0)
	, cobOfiTotal		= ISNULL(C.cobOfiTotal, 0)
	
	, nDevBanco			= ISNULL(C.nDevBanco, 0)
	, DevBanCargoFijo	= ISNULL(C.DevBanCargoFijo, 0)	*-1
	, DevBanConsumo		= ISNULL(C.DevBanConsumo, 0)	*-1
	, DevBanBase		= ISNULL(C.DevBanBase, 0)		*-1
	, DevBanImpuesto	= ISNULL(C.DevBanImpuesto, 0)	*-1
	, DevBanTotal		= ISNULL(C.DevBanTotal, 0)		*-1
	
	, nDevOficina		= ISNULL(C.nDevOficina, 0)
	, DevOfiCargoFijo	= ISNULL(C.DevOfiCargoFijo, 0)	*-1
	, DevOfiConsumo		= ISNULL(C.DevOfiConsumo, 0)	*-1
	, DevOfiBase		= ISNULL(C.DevOfiBase, 0)		*-1
	, DevOfiImpuesto	= ISNULL(C.DevOfiImpuesto, 0)	*-1
	, DevOfiTotal		= ISNULL(C.DevOfiTotal, 0)		*-1
	FROM #F AS F
	LEFT JOIN #C AS C
	ON  F.BloqueId	= C.BloqueId 
	AND F.przTipo	= C.przTipo
	AND F.periodo	= C.periodo
	AND F.periodoRegistrado = C.periodoRegistrado
	AND F.desServTarifa		= C.desServTarifa
	LEFT JOIN BLOQUES AS B
	ON B.sblqCod= ISNULL(F.BloqueId, -1)
	WHERE F.BloqueId<=7 
	--*************************************************
	--Evitamos lineas que no representan ninguna factura
	AND ISNULL(numFacturas, 0) + ISNULL(numCobros, 0) > 0 
	ORDER BY  BloqueId, przTipo, periodo, periodoRegistrado, desServTarifa;
	
	
	
	--???????????????????????????????
	--???????????????????????????????
	--COMPROBAR: Coblindes no enlazados a una linea de factura.
	--SELECT * FROM @COBS WHERE fclFacVersion <> facVersion OR fclFacLin <> cldFacLin AND fclTotal IS NOT NULL
	--???????????????????????????????
	--???????????????????????????????
	
END TRY
BEGIN CATCH
	--SELECT ERROR_NUMBER() AS ErrorNumber  
	--  , ERROR_MESSAGE() AS ErrorMessage; 
END CATCH

IF OBJECT_ID('tempdb..#FPREV') IS NOT NULL	DROP TABLE #FPREV;

IF OBJECT_ID('tempdb..#F') IS NOT NULL		DROP TABLE #F;
IF OBJECT_ID('tempdb..#C') IS NOT NULL		DROP TABLE #C;

GO


