--DROP PROCEDURE [ReportingServices].[CF052_InformeSituacionTrfDetalle_SORIA]
/*
DECLARE @cvFecIni DATE = '20210101';
DECLARE @cvFecFin DATE = '20220104';
DECLARE @periodoD VARCHAR(6) = '202101';
DECLARE @periodoH VARCHAR(6) = '202104';
DECLARE @filtrar INT = 0;
DECLARE @xmlSerCodArray VARCHAR(MAX) = '';

--SELECT @xmlSerCodArray = CONCAT(@xmlSerCodArray, '<servicioCodigo><value>') + CAST(svccod AS VARCHAR(5))+ '</value></servicioCodigo>'
--FROM dbo.servicios
--WHERE svccod NOT IN  (3, 99, 100 , 103, 104, 105, 106, 107);

--SET @xmlSerCodArray = FORMATMESSAGE('<servicioCodigo_List>%s</servicioCodigo_List>', @xmlSerCodArray)

EXEC [ReportingServices].[CF052_InformeSituacionTrf_SORIA] @cvFecIni, @cvFecFin, @periodoD, @periodoH, @filtrar, @xmlSerCodArray;
*/


ALTER PROCEDURE [ReportingServices].[CF052_InformeSituacionTrf_SORIA]
(
	@cvFecIni		DATE = NULL,
	@cvFecFin		DATE = NULL,
	@periodoD		VARCHAR(6) = NULL,
	@periodoH		VARCHAR(6) = NULL,
	@filtrar		INT = 0,
	@xmlSerCodArray TEXT = NULL
)
AS

SET NOCOUNT ON;


--****************************************
--Evolutivo SPRINT#18
--Creado sobre la base de:
--[ReportingServices].[CF052_InformeSituacionTrf_SORIA_OLD] renombrado
--****************************************

BEGIN TRY

	--***** P A R A M E T R O S *****
	SELECT @cvFecIni = ISNULL(@cvFecIni, '19010101')
		 , @cvFecFin = DATEADD(DAY, 1, ISNULL(@cvFecFin, GETDATE()))
		 , @filtrar  = ISNULL(@filtrar, 0);

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
	DECLARE @COB AS dbo.tCobrosPK_info;

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


	--**** D E B U G ***********
	DECLARE @svcs AS VARCHAR(MAX);
	SELECT  @svcs = COALESCE(@svcs + ', ' + CAST(servicioCodigo AS VARCHAR),  CAST(servicioCodigo AS VARCHAR)) FROM @SERVICIOSINCLUIDOS;
	
	DECLARE @sp_Name AS VARCHAR(150) = (SELECT NAME FROM tempdb.sys.procedures WHERE OBJECT_ID = @@PROCID);
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

	/**
	/////////////////////////////////////////////////////
	**  ESTRATEGIA PARA SACAR LOS DATOS:
	1-00. @FAC: tabla en la que tenemos las PK de las facturas que formarán parte del informe
	1-01. Facturas Creadas o Rectificadas segun los filtros
	1-02. De estas, tenemos que identificar las que  son Originales, Anuladas ó Creadas.
	1-03. Borramos las que no caen en ninguna categoria.
	----------------
	2-01. @COB: Tabla en la que tenemos las PK de los coblindes que formarán parte del informe
	2-02. Se necesitan los cobros según los filtros.
	2-03. Las ENTREGAS A CUENTA son cobros que pertenecen al periodo 999999 y no tienen coblindes,
		De ahí que las buscamos en un segundo Select.
	2-04. Como harán falta los datos de sus respectivas facturas, 
		  insertamos en @FAC las PK de facturas de los cobros que no estén 
	----------------
	3-01. #FLS:	  Sacamos información mas detallada de todas las lineas de facturas en @FAC
	3-02. #FPREV: Version anterior de las lineas de factura con importe 0
	3-03. #COBS: Sacamos información mas detallada de todos los desgloses de cobros en @COBS
	----------------
	4-01. #FLS:	  Actualizamos las columnas calculadas de las lineas de facturas
	4-02. #COB:	  Actualizamos las columnas calculadas de las lineas de cobros
	----------------
	5-01. #F:	  Agrupación de facturas
	5-02. #C:	  Agrupación de cobros
	
	/////////////////////////////////////////////////////
	**/
	

	--//////////////////////////////////////////////////////
	--[01] PKs FACTURAS QUE NECESITAREMOS PARA CONSTRUIR EL INFORME
	--//////////////////////////////////////////////////////

	--*****************
	--***** @FAC******
	--Para clasificar las facturas (Original, Anulada, Creada)  
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
	FROM dbo.facturas AS F
	INNER JOIN dbo.faclin AS FL 
	ON  FL.fclfaccod = F.faccod 
	AND FL.fclfacpercod = F.facpercod 
	AND FL.fclfacctrcod = F.facctrcod 
	AND FL.fclfacversion = F.facversion 
	AND F.facNumero IS NOT NULL
	AND F.facFecha IS NOT NULL
	INNER JOIN @SERVICIOSINCLUIDOS AS SI
	ON FL.fclTrfSvCod= SI.servicioCodigo
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
	

	--//////////////////////////////////////////////////////
	--[02] PK DE LOS COBROS y sus respectivas facturas
	--//////////////////////////////////////////////////////
	
	--*****************
	--***** @COB ******
	--Solo  a servicios incluidos
	INSERT INTO @COB(cobScd, cobPpag, cobNum, cblLin, cldFacLin, cldImporte
				   , facCod, facPerCod, facCtrCod, facVersion
				   , cobfecreg, ppebca)
	SELECT C.cobScd, C.cobPpag, C.cobNum, CL.cblLin, CLD.cldFacLin, CLD.cldImporte
	, CL.cblFacCod, CL.cblPer, C.cobCtr, CL.cblFacVersion
	, C.cobfecreg, E.ppebca 
	FROM dbo.cobros AS C
	INNER JOIN dbo.coblin AS CL 
	ON  CL.cblScd  = C.cobScd
	AND	CL.cblPpag = C.cobPpag
	AND	CL.cblNum  = C.cobnum
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
	AND CLD.cldImporte <> 0
	INNER JOIN dbo.ppagos AS PP 
	ON PP.ppagcod = C.cobppag
	INNER JOIN dbo.ppentidades AS E 
	ON E.ppecod = PP.ppagppcppeCod
	INNER JOIN @SERVICIOSINCLUIDOS AS SI
	ON CLD.cldTrfSrvCod= SI.servicioCodigo;
	

	--************************************
	--***** ENTREGAS A CUENTA: 		******
	--***** Insertamos los cobros   ******
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
	FROM dbo.cobros AS C
	INNER JOIN dbo.coblin AS CL 
	ON  CL.cblScd  = C.cobScd
	AND	CL.cblPpag = C.cobPpag
	AND	CL.cblNum  = C.cobnum
	INNER JOIN dbo.ppagos AS PP 
	ON PP.ppagcod = C.cobppag
	INNER JOIN dbo.ppentidades AS E 
	ON E.ppecod = PP.ppagppcppeCod
	WHERE CL.cblPer='999999'
	AND C.cobfecreg >=  @cvFecIni AND  C.cobfecreg <  @cvFecFin;

	--*************************************
	--***** FACTURAS EN @COB 		 ******
	--***** QUE NO EXISTEN EN @FAC   ******
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
	LEFT JOIN dbo.facturas AS T
	ON T.faccod		= F.facCod
	AND T.facPerCod = F.facPerCod
	AND T.facCtrCod = F.facCtrCod
	AND T.facVersion= F.facVersion;


	--//////////////////////////////////////////////////////
	--[03] DETALLES FACTURAS, FACTURA PREVIA y COBROS
	--//////////////////////////////////////////////////////

	--*****************
	--***** #FLS ******
	--Lineas de factura (solo servicios incluidos)
	SELECT [FAC_ID]			 = DENSE_RANK() OVER(ORDER BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion)
		 , [LineasxSvcTarifa]= COUNT(fclNumLinea) OVER(ORDER BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, FL.fclTrfSvCod, FL.fclTrfCod)
		 , [facCod]		= FL.fclFacCod
		 , [facPerCod]	= FL.fclFacPerCod
		 , [facCtrCod]	= FL.fclFacCtrCod
		 , [facVersion] = FL.fclFacVersion
		 , FL.fclNumLinea
	 	
		 , [periodoMensual]		= CAST(NULL AS VARCHAR(6))
		 , [periodoRegistrado]	= CAST(NULL AS VARCHAR(6))
		 , [periodo]			= CAST(NULL AS VARCHAR(6))
		 	
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
		, [desServTarifa]	= CAST(NULL AS VARCHAR(50))


		, F.facZonCod
		, [przTipo]			= CAST(NULL AS VARCHAR(50))

		, F.facFechaRectif
		, F.facFecha
		, facFechaV1		= IIF(fclFacVersion=1, CAST(F.facFecha AS DATE), F1.facFecha)
	 
	 	, FL.fclBase
		, FL.fclImpuesto
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

		, [Original]	= CAST(V.Original AS TINYINT)
		, [Anulada]	= CAST(V.Anulada AS TINYINT)
		, [Creada]		= CAST(V.Creada AS TINYINT)
		, [Cobrada]	= CAST(V.Cobrada AS TINYINT)
	INTO #FLS
	FROM @FAC AS V
	INNER JOIN dbo.facturas AS F
	ON F.facCod		 = V.facCod
	AND F.facPerCod  = V.facPerCod
	AND F.facCtrCod  = V.facCtrCod
	AND F.facVersion = V.facVersion
	INNER JOIN dbo.faclin AS FL 
	ON  FL.fclfaccod = F.faccod 
	AND FL.fclfacpercod = F.facpercod 
	AND FL.fclfacctrcod = F.facctrcod 
	AND FL.fclfacversion = F.facversion
	INNER JOIN @SERVICIOSINCLUIDOS AS SI
	ON SI.servicioCodigo = FL.fclTrfSvCod
	LEFT JOIN dbo.serviciosBloques AS B
	ON B.sblqSvcCod = FL.fclTrfSvCod
	LEFT JOIN dbo.facturas AS F1
	ON  F.facCod	 = F1.facCod
	AND F.facPerCod  = F1.facPerCod
	AND F.facCtrCod  = F1.facCtrCod
	AND F.facVersion <> 1
	AND F1.facVersion = 1;

	--************************************
	--***** ENTREGAS A CUENTA		******
	--***** Insertamos las lineas de factura ficticia	
	--************************************
	INSERT INTO #FLS
	SELECT [FAC_ID]				= (-1)*ROW_NUMBER() OVER(ORDER BY facCod, facPerCod, facCtrCod, facVersion)
		 , [LineasxSvcTarifa]	= 1
		 , [facCod]			= facCod
		 , [facPerCod]		= facPerCod
		 , [facCtrCod]		= facCtrCod
		 , [facVersion]		= facVersion
		 , fclNumLinea		= 1
	 
		 , [periodoMensual]		= CAST(NULL AS VARCHAR(6))
		 , [periodoRegistrado]	= CAST(NULL AS VARCHAR(6))
		 , [periodo]			= CAST(NULL AS VARCHAR(6))

		 , [cuatrimestre]	= 0
		 , [BloqueId]		= IIF(c.ctrzoncod<> '0010', 1, 2)
						 
		 , fclTrfSvCod		= '9999'
		 , fclTrfCod		= 1

		 , [servTarifa]		= FORMATMESSAGE('%04i-%03i', 9999, 1)
		 , [esServicio]		= 0
		 , [desServTarifa]	= CAST(NULL AS VARCHAR(50))

		 
		 , facZonCod		= C.ctrzoncod
		 , [przTipo]		= CAST(NULL AS VARCHAR(50))

		 , facFechaRectif	= NULL
		 , facFecha			= NULL
		 , facFechaV1		= NULL

		 , fclBase			= F.cldImporte
		 , fclImpuesto		= 0
		 , fclImpImpuesto	= 0
		 , fcltotal			= F.cldImporte
	 
		 , [cargoFijo]		= 0
		 , [consumo]		= 0

		 , [Original]		= 0
		 , [Anulada]		= 0
		 , [Creada]			= 0
		 , [Cobrada]		= 1
	FROM @COB AS F
	INNER JOIN dbo.vContratosUltimaVersion AS C
	ON  C.ctrCod = F.facCtrCod
	AND F.facpercod='999999';


	--******************
	--***** #FPREV *****
	--******************
	--Si hay lineas de factura con factotal 0 buscamos la versión anterior que tenga un importe
	--Lo necesitaremos para desglosar el importe de los cobros
	
	SELECT  FL.fclFacCod
	, FL.fclFacPerCod
	, FL.fclFacCtrCod
	, FL.fclFacVersion
	, FL.fclNumLinea
	
	, L.fclTrfCod
	, L.fclTrfSvCod	
	
	, fclBase			= (FL.fclBase)
	, fclImpImpuesto	= (FL.fclImpImpuesto)
	, fcltotal			= (FL.fcltotal)

	, [cargoFijo]	= (CAST(ROUND(FL.fclUnidades*FL.fclPrecio, 4) AS DECIMAL(12,4)))
	, [consumo]		= (CAST((ROUND(FL.fclunidades1 * FL.fclprecio1, 4) + 
							ROUND(FL.fclunidades2 * FL.fclprecio2, 4) + 
							ROUND(FL.fclunidades3 * FL.fclprecio3, 4) + 
							ROUND(FL.fclunidades4 * FL.fclprecio4, 4) + 
							ROUND(FL.fclunidades5 * FL.fclprecio5, 4) +
							ROUND(FL.fclunidades6 * FL.fclprecio6, 4) + 
							ROUND(FL.fclunidades7 * FL.fclprecio7, 4) + 
							ROUND(FL.fclunidades8 * FL.fclprecio8, 4) + 
							ROUND(FL.fclunidades9 * FL.fclprecio9, 4)) AS DECIMAL(12,4)))
	
	--RN=1: Será la version mas reciente de la linea por factura, servicio y tarifa
	, RN = ROW_NUMBER() OVER (PARTITION BY FL.fclFacCod, FL.fclFacPerCod, FL.fclFacCtrCod, L.fclTrfCod, L.fclTrfSvCod ORDER BY  FL.fclFacVersion DESC, FL.fclNumLinea ASC)
	INTO #FPREV
	FROM #FLS AS L
	INNER JOIN dbo.faclin AS FL
	ON  L.fclTotal = 0
	AND L.facCod	  = FL.fclFacCod
	AND L.facPerCod   = FL.fclFacPerCod
	AND L.facCtrCod   = FL.fclFacCtrCod
	AND L.fclTrfSvCod = FL.fclTrfSvCod
	AND L.fclTrfCod   = FL.fclTrfCod
	--Versiones de factura previas con importe en la linea
	AND FL.fclFacVersion  <= L.facVersion
	AND FL.fcltotal <> 0;
	
	--******************
	--***** #COBS* *****
	--******************
	SELECT [COB_ID] = DENSE_RANK() OVER(ORDER BY V.cobScd, V.cobPpag, V.cobNum)
	, V.cobScd
	, V.cobPpag
	, V.cobNum
	, V.cblLin
	, V.cldFacLin
	, V.cobFecReg
	
	, V.facCod
	, V.facCtrCod
	, V.facPerCod
	, V.facVersion
	
	, cldTrfSrvCod	= IIF(V.facPerCod = '999999', '9999', CLD.cldTrfSrvCod)
	, cldTrfCod		= IIF(V.facPerCod = '999999', 1, CLD.cldTrfCod)

	, cldImporte	= IIF(V.facPerCod = '999999', CL.cblImporte, CLD.cldImporte)
	, CL.cblImporte
	
	, esCobro		= IIF(CL.cblImporte > 0, 1, 0) 
	, esDevolucion	= IIF(CL.cblImporte > 0, 0, 1) 
	, esBanco		= IIF(V.ppebca=1 , 1, 0)
	, esOficina		= IIF(V.ppebca=1 , 0, 1)
	--***********************************
	, [cargoFijo]	= CAST (NULL AS MONEY)  
	, [consumo]		= CAST (NULL AS MONEY)  
	, [base]		= CAST (NULL AS MONEY)  
	, [impuesto]	= CAST (NULL AS MONEY) 
	--***********************************
	--Factura usada para calcular cargoFijo, consumo, base, impuesto
	, [fclFacVersion] = CAST(NULL AS INT)
	, [fclTotal]	  = CAST (NULL AS MONEY)
	INTO #COBS
	FROM @COB AS V
	INNER JOIN dbo.coblin AS CL
	ON  CL.cblScd =  V.cobScd
	AND CL.cblPpag = V.cobPPag
	AND CL.cblNum =  V.cobNum
	AND CL.cblLin =  V.cblLin
	LEFT JOIN dbo.cobLinDes AS CLD
	ON  CLD.cldCblScd =  V.cobScd
	AND CLD.cldCblPpag = V.cobPPag
	AND CLD.cldCblNum =  V.cobNum
	AND CLD.cldCblLin =  V.cblLin
	AND CLD.cldFacLin =  V.cldFacLin;

	
	--//////////////////////////////////////////////////////
	--[04] Asignamos VALORES DE LAS COLUMNAS CALCULADAS 
	--//////////////////////////////////////////////////////
	
	--*****************
	--***** #FLS  *****
	UPDATE F SET
	  [periodoMensual]		= PZ.przCodPer
	, [periodoRegistrado] = CASE WHEN F.facPerCod= '000002' 
								THEN FORMATMESSAGE('%i%02i', YEAR(F.facfecha), F.cuatrimestre*4) 
								WHEN F.facPerCod LIKE '0%'
								THEN PZ.przCodPer 
								ELSE F.facPerCod END
	, [periodo]	= IIF(F.facPerCod= '000002', FORMATMESSAGE('%i%02i', YEAR(F.facfecha), F.cuatrimestre*4), F.facPerCod)
	
	, [przTipo] = CASE  F.facPerCod
						WHEN '999999' THEN 'ENTREGAS A CUENTA'
						WHEN '000002' THEN 'Cuatrimestral'	
						ELSE ISNULL(Z.przTipo, '') END

	, [desServTarifa] = CASE WHEN F.esServicio=1 THEN S.svcdes
							 WHEN F.fclTrfSvCod = @SERV_AGUA AND T.trfcod IN (1, 3) THEN 'USO DOMÉSTICO' 
							 WHEN F.fclTrfSvCod = @SERV_AGUA AND T.trfcod IN (2, 6, 5, 8) THEN 'USO INDUSTRIAL' 
							 WHEN F.facpercod='999999' THEN 'ENTREGAS A CUENTA'
							 ELSE T.trfdes END
	FROM #FLS AS F
	LEFT JOIN dbo.perzona AS Z
	ON  Z.przcodzon = F.facZonCod
	AND Z.przcodper = F.facPerCod
	LEFT JOIN dbo.tarifas AS T
	ON T.trfcod		= F.fclTrfCod
	AND T.trfsrvcod = F.fclTrfSvCod
	LEFT JOIN dbo.servicios AS S
	ON S.svccod = F.fclTrfSvCod
	LEFT JOIN dbo.vPerzonaMensual AS PZ
	ON  F.facPerCod LIKE '0%'
	AND F.facPerCod <> '000002'
	AND F.facFechaV1 >= PZ.przfPeriodoD
	AND F.facFechaV1 <= PZ.przfPeriodoH;

	--****************
	--***** #COB *****
	UPDATE C SET
	  [cargoFijo]	 =  CASE WHEN  F1.fcltotal<>0 
							 THEN (F1.cargoFijo  *C.cldImporte)/F1.fcltotal
							 WHEN ISNULL(F0.fcltotal, 0)<> 0 
							 THEN (F0.cargoFijo  *C.cldImporte)/F0.fcltotal
							 ELSE NULL END

	, [consumo]		 =  CASE WHEN  F1.fcltotal<>0 
							 THEN (F1.consumo   *C.cldImporte)/F1.fcltotal
							 WHEN ISNULL(F0.fcltotal, 0)<> 0  
							 THEN (F0.consumo   *C.cldImporte)/F0.fcltotal
							 ELSE NULL END

	, [base]		 =  CASE WHEN  F1.fcltotal<>0 
							 THEN (F1.fclBase   *C.cldImporte)/F1.fcltotal
							 WHEN ISNULL(F0.fcltotal, 0)<> 0 
							 THEN (F0.fclBase   *C.cldImporte)/F0.fcltotal
							 ELSE NULL END

	, [impuesto]	 = CASE WHEN F1.fcltotal<>0 THEN (F1.fclImpImpuesto  *C.cldImporte)/F1.fcltotal
							WHEN F0.fcltotal<>0 THEN (F0.fclImpImpuesto  *C.cldImporte)/F0.fcltotal
							ELSE NULL END
	--Factura usada para obtener el cargofijo, consumo, base e impuesto
	, [fclTotal]	 = IIF(F1.fcltotal<>0, F1.fcltotal	, F0.fcltotal)
	, [fclFacVersion]= IIF(F1.fcltotal<>0, F1.facVersion, F0.fclFacVersion)
	FROM #COBS AS C
	INNER JOIN #FLS AS F1
	ON  C.facCod	  = F1.facCod
	AND C.facCtrCod   = F1.facCtrCod
	AND C.facPerCod   = F1.facPerCod
	AND C.facVersion  = F1.facVersion
	AND C.cldFacLin	  = F1.fclNumLinea
	LEFT JOIN #FPREV AS F0
	ON  F1.fcltotal = 0 
	AND C.facCod	  = F0.fclFacCod
	AND C.facPerCod   = F0.fclFacPerCod
	AND C.facCtrCod   = F0.fclFacCtrCod
	AND C.cldTrfSrvCod = F0.fclTrfSvCod
	AND C.cldTrfCod   = F0.fclTrfCod
	AND F0.RN=1;

	
	--//////////////////////////////////////////////////////
	--[05] RESULTADO 
	--//////////////////////////////////////////////////////
	--***************
	--***** #C  *****
	SELECT  BloqueId	= ISNULL(F.BloqueId, '')
	, F.przTipo 
	, F.periodo
	, periodoRegistrado = ISNULL(F.periodoRegistrado, '')
	, desServTarifa		= MAX(F.desServTarifa) 

	, nCobBanco			= SUM(esBanco*esCobro)
	, cobBanCargoFijo	= SUM(C.cargoFijo	*esBanco*esCobro)
	, cobBanConsumo		= SUM(C.consumo		*esBanco*esCobro)
	, cobBanBase		= SUM(C.base		*esBanco*esCobro)
	, cobBanImpuesto	= SUM(C.impuesto	*esBanco*esCobro)
	, cobBanTotal		= SUM(C.cldImporte	*esBanco*esCobro)

	, nCobOficina		= SUM(esOficina*esCobro)
	, cobOfiCargoFijo	= SUM(C.cargoFijo	*esOficina*esCobro)
	, cobOfiConsumo		= SUM(C.consumo		*esOficina*esCobro)
	, cobOfiBase		= SUM(C.base		*esOficina*esCobro)
	, cobOfiImpuesto	= SUM(C.impuesto	*esOficina*esCobro)
	, cobOfiTotal		= SUM(C.cldImporte	*esOficina*esCobro)

	, nDevBanco			= SUM(esBanco*esDevolucion)
	, DevBanCargoFijo	= SUM(C.cargoFijo	*esBanco*esDevolucion)
	, DevBanConsumo		= SUM(C.consumo		*esBanco*esDevolucion)
	, DevBanBase		= SUM(C.base		*esBanco*esDevolucion)
	, DevBanImpuesto	= SUM(C.impuesto	*esBanco*esDevolucion)
	, DevBanTotal		= SUM(C.cldImporte	*esBanco*esDevolucion)

	, nDevOficina		= SUM(esOficina*esDevolucion)
	, DevOfiCargoFijo	= SUM(C.cargoFijo	*esOficina*esDevolucion)
	, DevOfiConsumo		= SUM(C.consumo		*esOficina*esDevolucion)
	, DevOfiBase		= SUM(C.base		*esOficina*esDevolucion)
	, DevOfiImpuesto	= SUM(C.impuesto	*esOficina*esDevolucion)
	, DevOfiTotal		= SUM(C.cldImporte	*esOficina*esDevolucion)

	INTO #C
	FROM #COBS AS C
	LEFT JOIN #FLS AS F
	ON  C.facCod		= F.facCod
	AND C.facPerCod		= F.facPerCod
	AND C.facCtrCod		= F.facCtrCod
	AND C.facVersion	= F.facVersion
	AND C.cldFacLin		= F.fclNumLinea
	GROUP BY  F.BloqueId, F.przTipo, F.periodo, F.periodoRegistrado, F.servTarifa

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
	
	INTO #F
	FROM #FLS AS F
	GROUP BY  F.BloqueId, F.przTipo, F.periodo, F.periodoRegistrado, F.servTarifa;
	
	--**********************
	--***** RESULTADO  *****
	WITH BLOQUES AS(
	SELECT DISTINCT sblqCod, sblqDesc
	FROM dbo.serviciosBloques)

	SELECT F.BloqueId
	, BloqueNom = CASE	WHEN F.BloqueId IS NULL THEN '_' 
						WHEN F.BloqueId=1 THEN 'CUATRIMESTRALES'
						WHEN F.BloqueId=2 THEN 'MENSUALES'
						ELSE B.sblqDesc END		
	, F.przTipo
	, F.periodo
	, F.periodoRegistrado
	, F.desServTarifa

	, facnFacturas		= F.Original
	, F.facCargoFijo
	, F.facConsumo
	, F.facBase
	, F.facImpuesto
	, F.factotal

	, anunFacturas		= F.Anulada	
	, F.anuCargoFijo	
	, F.anuConsumo	
	, F.anuBase	
	, F.anuImpuesto	
	, F.anuTotal

	, crenFacturas		= F.Creada
	, F.creCargoFijo
	, F.creConsumo
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
	ORDER BY  BloqueId, przTipo, periodo, periodoRegistrado, desServTarifa;
	
	
	
	--???????????????????????????????
	--???????????????????????????????
	--COMPROBAR: Coblindes no enlazados a una linea de factura.
	--SELECT * FROM #COBS WHERE [fclFacVersion] IS NULL
	--???????????????????????????????
	--???????????????????????????????
	
END TRY
BEGIN CATCH
  SELECT ERROR_NUMBER() AS ErrorNumber  
	   , ERROR_MESSAGE() AS ErrorMessage; 
END CATCH

IF OBJECT_ID('tempdb..#FLS') IS NOT NULL	DROP TABLE #FLS;   
IF OBJECT_ID('tempdb..#FPREV') IS NOT NULL	DROP TABLE #FPREV;
IF OBJECT_ID('tempdb..#F') IS NOT NULL		DROP TABLE #F;

IF OBJECT_ID('tempdb..#COBS') IS NOT NULL	DROP TABLE #COBS;
IF OBJECT_ID('tempdb..#C') IS NOT NULL		DROP TABLE #C;

GO