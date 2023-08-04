/*
DECLARE @xmlPortalCodArray NVARCHAR(MAX) = NULL;
DECLARE @periodoD VARCHAR(6)= '202104';
DECLARE @periodoH VARCHAR(6)= '202104';
DECLARE @versionD INT = NULL;
DECLARE @versionH INT = NULL;
DECLARE @zonaD VARCHAR(4) = NULL;
DECLARE @zonaH VARCHAR(4) = NULL;
DECLARE @fechaD DATE = NULL;
DECLARE @fechaH DATE = NULL;
DECLARE @contratoD INT = NULL;
DECLARE @contratoH INT = NULL;
DECLARE @consuMin INT = NULL;
DECLARE @consuMax INT = NULL;
DECLARE @clienteD INT = NULL;
DECLARE @clienteH  INT = NULL;
DECLARE @facFecEmisionSERESIni DATE = NULL
DECLARE @facFecEmisionSERESFinal DATE = NULL
DECLARE @uso INT= NULL;

DECLARE @verTodas BIT = 0;
DECLARE @preFactura BIT = 0;
DECLARE @mostrarFacturasE BIT = NULL;

DECLARE @series VARCHAR(MAX) = NULL;
DECLARE @impoMin MONEY = NULL;
DECLARE @impoMax MONEY = NULL

DECLARE @grupo VARCHAR(25) = NULL;
DECLARE @orden NVARCHAR(16) = 'periodoZonaFecha';
DECLARE @detallado BIT = 0;
EXEC [ReportingServices].[CF011_RelacionFacturas] @xmlPortalCodArray
, @periodoD, @periodoH, @versionD, @versionH, @zonaD, @zonaH, @fechaD, @fechaH, @contratoD, @contratoH
, @consuMin, @consuMax, @clienteD, @clienteH , @facFecEmisionSERESIni, @facFecEmisionSERESFinal, @uso
, @verTodas, @preFactura, @mostrarFacturasE
, @series, @impoMin, @impoMax
, @grupo, @orden, @detallado
*/

CREATE PROCEDURE [ReportingServices].[CF011_RelacionFacturas]
  @xmlPortalCodArray NVARCHAR(MAX) = NULL
, @periodoD VARCHAR(6)= '202104'
, @periodoH VARCHAR(6)= '202104'
, @versionD INT = NULL
, @versionH INT = NULL
, @zonaD VARCHAR(4) = NULL
, @zonaH VARCHAR(4) = NULL
, @fechaD DATE = NULL
, @fechaH DATE = NULL
, @contratoD INT = NULL
, @contratoH INT = NULL
, @consuMin INT = NULL
, @consuMax INT = NULL
, @clienteD INT = NULL
, @clienteH  INT = NULL
, @facFecEmisionSERESIni DATE = NULL
, @facFecEmisionSERESFinal DATE = NULL
, @uso INT= NULL

, @verTodas BIT = 0
, @preFactura BIT = 0
, @mostrarFacturasE BIT = NULL

, @series VARCHAR(MAX) = NULL
, @impoMin MONEY = NULL
, @impoMax MONEY = NULL

, @grupo VARCHAR(25) = NULL
, @orden NVARCHAR(16) = 'periodoZonaFecha'

AS
BEGIN TRY

	--*********
	--[01]VARIABLES
	DECLARE @facturasPK AS tFacturasPK;

	DECLARE @portalesExcluidos AS TABLE(portalCodigo VARCHAR(10));

	DECLARE @tablaComunitarios AS TABLE (ctrComuCod INT NOT NULL PRIMARY KEY);

	DECLARE @SCDxDEFECTO INT = 1;

	
	--*********
	--[02]INICIALIZAR VARIABLES
	--Esto es un poco raro, porque la pk de series es compuesta y aqui solo se está mandando el codigo (serCod, serScd)
	DECLARE @tablaSeries AS TABLE(idx SMALLINT, value VARCHAR(8000)); 
	INSERT INTO @tablaSeries
	SELECT DISTINCT idx, value FROM dbo.Split(@series, ';');

	--Sociedad Defecto
	SELECT @SCDxDEFECTO = P.pgsvalor 
	FROM dbo.parametros AS P
	WHERE P.pgsclave='SOCIEDAD_POR_DEFECTO';


	--Para comparar bien las fechas sin horas
	SELECT @fechaH = DATEADD(DAY, 1, @fechaH)
		 , @facFecEmisionSERESFinal = DATEADD(DAY, 1, @facFecEmisionSERESFinal);

	--Portales excluidos
	IF @xmlPortalCodArray IS NOT NULL 
	BEGIN
		--Leemos los parámetros del XML
		DECLARE @idoc INT;
		EXEC sp_xml_preparedocument @idoc OUTPUT, @xmlPortalCodArray; 
	
		--Insertamos en tabla temporal
		INSERT INTO @portalesExcluidos(portalCodigo)
		SELECT value
		FROM   OPENXML (@idoc, '/portalCodigo_List/portalCodigo', 2) WITH (value VARCHAR(10));

		--Liberamos memoria
		EXEC  sp_xml_removedocument @idoc;
	END

	--Contratos comunitarios
	INSERT INTO @tablacomunitarios
	SELECT DISTINCT ctrcomunitario
	FROM dbo.contratos 
	WHERE ctrcomunitario IS NOT NULL 
	AND ctrbaja = 0;

	
	--*********
	--[03]#FACS cabeceras de facturas con los filtros
	SELECT F.facCod
	, F.facCtrCod
	, F.facPerCod
	, F.facVersion
	, F.facFecha
	, F.facSerCod
	, facSerScdCod = ISNULL(F.facserscdcod, @SCDxDEFECTO)
	, F.facNumero
	, F.facConsumoFactura
	, F.facCtrVersion
	, F.facInsInlCod
	, F.facLecInlCod
	 --fctFacturado: A dos decimales
	, FT.fctFacturado
	, facZonCod = IIF(@grupo = 'sinZona', NULL, facZonCod)
	INTO #FACS

	FROM dbo.facturas AS F
	INNER JOIN dbo.contratos AS C
	ON  C.ctrcod=F.facCtrCod 
	AND C.ctrversion = F.facctrversion
	LEFT JOIN dbo.facTotales AS FT
	ON FT.fctCod = F.facCod
	AND FT.fctPerCod = F.facPerCod
	AND FT.fctCtrCod = F.facCtrCod
	AND FT.fctVersion = F.facVersion

	WHERE (@periodoD IS NULL OR F.facPerCod >= @periodoD)
	  AND (@periodoH IS NULL OR F.facPerCod <= @periodoH)
	  AND (@versionD IS NULL OR F.facVersion >= @versionD)
	  AND (@versionH IS NULL OR F.facVersion <= @versionH)
	  AND (@zonaD IS NULL OR F.facZonCod >= @zonaD)
	  AND (@zonaH IS NULL OR F.facZonCod <= @zonaH)
	  AND (@fechaD IS NULL OR F.facFecha>= @fechaD)
	  AND (@fechaH IS NULL OR F.facFecha < @fechaH)
	  AND (@contratoD IS NULL OR facCtrCod>= @contratoD)
	  AND (@contratoH IS NULL OR facCtrCod<= @contratoH)
	  AND (@consuMin IS NULL OR F.facConsumoFactura >= @consuMin)
	  AND (@consuMax IS NULL OR F.facConsumoFactura <= @consuMax)
	  AND (@clienteD IS NULL OR F.facClicod >= @clienteD)
	  AND (@clienteH IS NULL OR F.facClicod <= @clienteH) 
	  AND (@facFecEmisionSERESIni IS NULL OR F.facFecEmisionSERES >= @facFecEmisionSERESIni)
	  AND (@facFecEmisionSERESFinal IS NULL OR F.facFecEmisionSERES < @facFecEmisionSERESFinal)
	  AND (@uso IS NULL OR C.ctrusocod = @uso)
	  AND (@xmlPortalCodArray IS NULL OR C.ctrFacePortal NOT IN (SELECT portalCodigo FROM @portalesExcluidos))	
	  AND (@series IS NULL OR F.facSerCod IN (SELECT value FROM @tablaSeries))  
	  AND (@impoMin IS NULL OR FT.fctFacturado >= @impoMin) 
	  AND (@impoMax IS NULL OR FT.fctFacturado <= @impoMax)


	  AND (
		   (@verTodas IS NULL) OR
		   (@verTodas = 1) OR
		   (@verTodas = 0 AND (F.facFechaRectif IS NULL OR (@fechaH IS NOT NULL AND F.facFechaRectif >= @fechaH))) 
		  )
	
	  AND (
		   (@mostrarFacturasE IS NULL) OR 
		   (@mostrarFacturasE = 1 AND F.facEnvSERES IS NOT NULL) OR
		   (@mostrarFacturasE = 0 AND (C.ctrFaceTipoEnvio = 'POSTAL' OR (F.facEnvSERES IS NULL OR F.facEnvSERES NOT IN ('E', 'P', 'R')) )) 
		  )

	  AND (
		   (@preFactura IS NULL) OR
		   (@preFactura=1) OR		
		   (@preFactura=0 AND F.facNumero IS NOT NULL) 
		  );
 


	--*********
	--*********
	--*********
	--[99]RESULTADOS:
	--Lineas de facturas no liquidadas
	SELECT NumeroLinea = ROW_NUMBER() OVER(PARTITION BY FF.facCod, FF.facCtrCod, FF.facPerCod, FF.facVersion ORDER BY FL.fclNumLinea)
		 , FF.facCod
		 , FF.facPerCod
		 , FF.facCtrCod
		 , FF.facVersion
		 , FF.facSerCod
		 , FF.facNumero
		 , FF.facFecha
		 , FF.facConsumoFactura
		 , FF.facInsInlCod
		 , FF.facLecInlCod
		 , FF.facZonCod
		 , FF.fctFacturado
		 , Z.zondes
		 , P.perdes
		 , C.ctrPagNom
		 , C.ctrTitNom
		 , C.ctrTitDocIden
		 , C.ctrPagDocIden
		 , I.inmdireccion
		 , FL.fclNumLinea
		 , FL.fclEscala1, FL.fclPrecio1, FL.fclUnidades1
		 , FL.fclPrecio2, FL.fclUnidades2
		 , FL.fclPrecio3, FL.fclUnidades3 
		 , FL.fclPrecio4, FL.fclUnidades4 
		 , FL.fclPrecio5, FL.fclUnidades5 
		 , FL.fclPrecio6, FL.fclUnidades6	 
		 , FL.fclPrecio7, FL.fclUnidades7 
		 , FL.fclPrecio8, FL.fclUnidades8 
		 , FL.fclPrecio9, FL.fclUnidades9 
		 , FL.fclPrecio, FL.fclUnidades
		 , FL.fcltotal, FL.fclbase, FL.fclimpimpuesto
		 , FL.fclImpuesto
		 , FL.fclTrfSvCod, S.svcdes
		 , FL.fclTrfCod, T.trfdes
		 , SS.scdImpNombre
		 , comunitario = IIF(COM.ctrComuCod IS NOT NULL, 'comunitario', NULL) 
	INTO #RESULT	   
	FROM #FACS AS FF
	INNER JOIN dbo.periodos AS P
	ON P.percod = FF.facPerCod
	INNER JOIN contratos AS C
	ON  C.ctrCod = FF.facCtrCod
	AND C.ctrVersion = FF.facCtrVersion
	INNER JOIN dbo.zonas AS Z
	ON Z.zoncod = FF.facZonCod
	INNER JOIN dbo.inmuebles AS I 
	ON C.ctrinmcod = I.inmcod

	LEFT JOIN dbo.faclin AS FL
	ON  FF.facCod     = FL.fclFacCod 
	AND FF.facPerCod  = FL.fclFacPerCod 
	AND FF.facCtrCod  = FL.fclFacCtrCod 
	AND FF.facVersion = FL.fclFacVersion
	AND ((FL.fclFecLiq IS NULL AND FL.fclUsrLiq IS NULL) OR (@fechaH IS NOT NULL AND FL.fclFecLiq>=@fechaH))	
	LEFT JOIN dbo.servicios AS S
	ON FL.fclTrfSvCod = S.svccod
	LEFT JOIN dbo.tarifas AS T 
	ON T.trfsrvcod = FL.fclTrfSvCod 
	AND T.trfcod = FL.fclTrfCod
	LEFT JOIN @tablacomunitarios AS COM
	ON C.ctrcod = COM.ctrComuCod
	LEFT JOIN dbo.sociedades AS SS
	ON SS.scdcod = facSerScdCod;


	SELECT * 
	FROM #RESULT AS FF
	ORDER BY
	IIF(@orden='contrato', FF.facCtrCod, NULL),
	IIF(@orden='contrato', FF.facPerCod, NULL),
	IIF(@orden='contrato', FF.facCod, NULL),
	IIF(@orden='contrato', FF.facVersion, NULL),
	IIF(@orden='contrato', FF.fclNumLinea, NULL),

	IIF(@orden='periodoZonaFecha', FF.facPerCod, NULL),
	IIF(@orden='periodoZonaFecha', FF.facZonCod, NULL),
	IIF(@orden='periodoZonaFecha', FF.facFecha, NULL),
	IIF(@orden='periodoZonaFecha', FF.facCtrCod, NULL),
	IIF(@orden='periodoZonaFecha', FF.fclNumLinea, NULL);
END TRY

BEGIN CATCH

END CATCH

IF OBJECT_ID('tempdb..#FACS') IS NOT NULL
DROP TABLE #FACS;

IF OBJECT_ID('tempdb..#RESULT') IS NOT NULL
DROP TABLE #RESULT;

GO