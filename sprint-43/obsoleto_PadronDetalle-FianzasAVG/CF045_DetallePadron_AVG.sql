--EXEC ReportingServices.CF045_DetallePadron_AVG @fechaD='20230101', @fechaH='20231004', @servicioAgua=1, @servicioAlcant=4, @servicioMttoCont=0, @verTodas=1, @preFactura=0, @orden='calle', @contratoD=32710, @contratoH=32710
--EXEC ReportingServices.CF045_DetallePadron_AVG @fechaD='20230101', @fechaH='20231004', @servicioAgua=1, @servicioAlcant=4, @servicioMttoCont=0, @verTodas=1, @preFactura=0, @orden='calle' WITH RECOMPILE; 

CREATE PROCEDURE ReportingServices.CF045_DetallePadron_AVG
  @periodoD VARCHAR(6) = NULL
, @periodoH VARCHAR(6) = NULL
, @xmlUsoCodArray nvarchar(4000)= NULL
, @servicioAgua VARCHAR(1)=NULL
, @servicioAlcant VARCHAR(1) = NULL
, @servicioMttoCont VARCHAR(1)= NULL
, @versionD INT = NULL
, @versionH INT = NULL
, @zonaD VARCHAR(4) = NULL
, @zonaH VARCHAR(4) = NULL
, @fechaD VARCHAR(50) = NULL
, @fechaH VARCHAR(50) = NULL
, @contratoD INT = NULL
, @contratoH INT = NULL
, @verTodas BIT = 0
, @preFactura BIT = 0
, @consuMin INT = NULL
, @consuMax INT = NULL
, @orden VARCHAR(5)= NULL
AS

IF @xmlUsoCodArray IS NOT NULL 
BEGIN
		--Creamos una tabla en memoria donde se van a insertar todos los valores
		DECLARE @usosExcluidos AS TABLE(usoCodigo INT) 
		--Leemos los parámetros del XML
		DECLARE @idoc INT
		EXEC sp_xml_preparedocument @idoc OUTPUT, @xmlUsoCodArray
		--Insertamos en tabla temporal
		INSERT INTO @usosExcluidos(usoCodigo)
		SELECT value
		FROM   OPENXML (@idoc, '/usoCodigo_List/usoCodigo', 2) WITH (value INT)
		--Liberamos memoria
		EXEC  sp_xml_removedocument @idoc
	END
	/*
	SELECT [facCod], [facCtrCod], [facversion], [facpercod], ISNULL(C.ctrPagNom, C.ctrTitNom) as nombre, [inmdireccion], 
	       ISNULL(C.ctrPagDocIden, C.ctrTitDocIden) as docIden, [facconsumoreal], [facconsumofactura], facLecAnt, facLecAct, 
	       facLecLector, facLecInspector, facLecInlCod, facInsInlCod, facLecLectorFec, facLecInspectorFec--Campos que indican si el tipo de lectura es Estimada al haberse pasado por proceso
	       --Buscamos el ultimo contador asociado al contrato
		   , CC.conDiametro 
	       , scdImpNombre, zonDes, usoDes, ISNULL(DATEDIFF(d,facLecAntFec,facLecActFec),0) AS NumDias,
	       fclAgua.fclBase AS BaseImpAgua, fclAlcantarillado.fclBase BaseImpAlcant, svcAgua.svcdes AS ServicioAgua, svcAlcantarillado.svcdes AS ServicioAlcant, 
	       fclMttoCont.fclBase AS BaseImpMttoCont, trfAgua.trfdes AS TarifaAgua, trfAlcantarillado.trfdes AS TarifaAlcantarillado,
               inlmc AS TipoLectura, ISNULL(ftfImporte, 0) AS TotalACobrar, inldes
	   FROM facturas
	   LEFT JOIN sociedades ON scdcod=ISNULL(facserscdcod,ISNULL((SELECT pgsvalor FROM parametros WHERE pgsclave='SOCIEDAD_POR_DEFECTO'),1))
	   INNER JOIN dbo.contratos AS C ON C.ctrcod = facctrcod AND C.ctrversion = facctrversion
	   INNER JOIN inmuebles ON inmcod = C.ctrinmcod
	   INNER JOIN zonas ON facZonCod = zonCod
	   INNER JOIN usos ON usoCod = C.ctrUsoCod
	   LEFT JOIN faclin fclAgua ON facCod = fclFacCod AND facPerCod = fclAgua.fclFacPerCod AND facCtrCod = fclAgua.fclFacCtrCod AND facVersion = fclAgua.fclFacVersion AND 
				        (fclAgua.fclTrfSvCod = @servicioAgua)
	   LEFT JOIN servicios svcAgua ON svcAgua.svccod = fclAgua.fclTrfSvCod
	   LEFT JOIN tarifas AS trfAgua ON trfAgua.trfcod = fclAgua.fclTrfCod AND trfAgua.trfsrvcod = svcAgua.svccod
	   LEFT JOIN faclin fclAlcantarillado ON facCod = fclAlcantarillado.fclFacCod AND facPerCod = fclAlcantarillado.fclFacPerCod AND facCtrCod = fclAlcantarillado.fclFacCtrCod AND 
					facVersion = fclAlcantarillado.fclFacVersion AND (fclAlcantarillado.fclTrfSvCod = @servicioAlcant)
	   LEFT JOIN servicios svcAlcantarillado ON svcAlcantarillado.svccod = fclAlcantarillado.fclTrfSvCod
	   LEFT JOIN faclin fclMttoCont ON facCod = fclMttoCont.fclFacCod AND facPerCod = fclMttoCont.fclFacPerCod AND facCtrCod = fclMttoCont.fclFacCtrCod AND 
					facVersion = fclMttoCont.fclFacVersion AND (fclMttoCont.fclTrfSvCod = @servicioMttoCont)
	   LEFT JOIN tarifas trfAlcantarillado ON trfAlcantarillado.trfcod=fclAlcantarillado.fclTrfCod AND trfAlcantarillado.trfsrvcod=svcAlcantarillado.svccod
	   
	   LEFT JOIN incilec ON inlcod = facLecInlCod
	   LEFT JOIN fFacturas_TotalFacturado(NULL, 0, NULL) ON ftfFacCod=facCod AND ftfFacPerCod=facPerCod  AND ftfFacCtrCod=facCtrCod AND ftfFacVersion=facVersion
	   --Buscamos el ultimo contador asociado al contrato
	   LEFT JOIN dbo.vCambiosContador AS CC  ON CC.ctrCod = facCtrCod AND CC.esUltimaInstalacion=1
	WHERE (facPerCod >= @periodoD OR @periodoD IS NULL) AND 
	      (facPerCod <= @periodoH OR @periodoH IS NULL) AND 
	      (facVersion >= @versionD  OR @versionD IS NULL) AND 
	      (facVersion <= @versionH OR @versionH IS NULL) AND 
	      (facZonCod >= @zonaD  OR @zonaD IS NULL) AND
	      (facZonCod <= @zonaH OR @zonaH IS NULL) and 
	      (facFecha>= @fechaD OR @fechaD IS NULL) and 
              (facFecha<= @fechaH OR @fechaH IS NULL) and 
	      (facCtrCod>= @contratoD OR @contratoD IS NULL) and 
	      (facCtrCod<= @contratoH OR @contratoH IS NULL) and 
 	      (facFechaRectif IS NULL OR (facFechaRectif >@fechaH) OR @verTodas=1)--verTodas junto con las rectificadas
	and ((facNumero is not null and @preFactura=0) OR  (@preFactura=1) )-- Si @preFactura es 0 entonces saca las facturas definitivas y si es 1 saca todas junto con las preFACTURAS
	and (@consuMin IS NULL OR @consuMin<=facConsumoFactura)
	and (@consuMax IS NULL OR @consuMax>=facConsumoFactura)
	AND NOT EXISTS(SELECT u.usoCod
			  FROM usos u 
			  INNER JOIN @usosExcluidos ON usoCodigo = u.usocod
			  WHERE u.usocod = C.ctrUsoCod
				   )
	AND EXISTS(SELECT fclFacCod FROM faclin WHERE fclFacCod = facCod AND fclFacPerCod = facPerCod AND fclFacCtrCod = facCtrCod AND fclFacVersion = facVersion)
	*/

	DECLARE @SCD AS INT = 1;
	SELECT @SCD = pgsvalor FROM parametros AS P WHERE P.pgsclave='SOCIEDAD_POR_DEFECTO' AND P.pgsvalor IS NOT NULL;
	
	DECLARE @FACS AS dbo.tFacturasPK;

	INSERT INTO @FACS(facCod, facCtrCod, facversion, facpercod)
	--Facturas con lineas que cumplen los filtros por los datos de factura
	SELECT DISTINCT F.facCod, F.facCtrCod, F.facversion, F.facpercod
	FROM dbo.facturas AS F 
	INNER JOIN faclin AS FL
	ON F.facCod = FL.fclFacCod
	AND F.facPerCod = FL.fclFacPerCod
	AND F.facCtrCod = FL.fclFacCtrCod
	AND F.facVersion = FL.fclFacVersion
	WHERE (F.facPerCod >= @periodoD OR @periodoD IS NULL) AND 
		  (F.facPerCod <= @periodoH OR @periodoH IS NULL) AND 
		  (F.facVersion >= @versionD  OR @versionD IS NULL) AND 
		  (F.facVersion <= @versionH OR @versionH IS NULL) AND 
		  (F.facZonCod >= @zonaD  OR @zonaD IS NULL) AND
		  (F.facZonCod <= @zonaH OR @zonaH IS NULL) AND 
		  (F.facFecha>= @fechaD OR @fechaD IS NULL) AND 
		  (F.facFecha<= @fechaH OR @fechaH IS NULL) AND 
		  (F.facCtrCod>= @contratoD OR @contratoD IS NULL) AND 
		  (F.facCtrCod<= @contratoH OR @contratoH IS NULL) AND 
		  --verTodas junto con las rectificadas
 		  (F.facFechaRectif IS NULL OR (F.facFechaRectif >@fechaH) OR @verTodas=1) AND
		  -- Si @preFactura es 0 entonces saca las facturas definitivas y si es 1 saca todas junto con las preFACTURAS
		  ((F.facNumero IS NOT NULL AND @preFactura=0) OR  (@preFactura=1)) AND
		  (@consuMin IS NULL OR @consuMin<=F.facConsumoFactura) AND 
		  (@consuMax IS NULL OR @consuMax>=facConsumoFactura);

	


	SELECT F.facCod, F.facCtrCod, F.facversion, F.facpercod
		, [nombre] = ISNULL(C.ctrPagNom, C.ctrTitNom)
		, I.inmdireccion 
	    , [docIden] = ISNULL(C.ctrPagDocIden, C.ctrTitDocIden)
		, F.facconsumoreal
		, F.facconsumofactura
		, F.facLecAnt
		, F.facLecAct
		--Campos que indican si el tipo de lectura es Estimada al haberse pasado por proceso
		, F.facLecLector
		, F.facLecInspector
		, F.facLecInlCod
		, F.facInsInlCod
		, F.facLecLectorFec
		, F.facLecInspectorFec
		--Buscamos el ultimo contador asociado al contrato
		, CC.conDiametro 
		, S.scdImpNombre
		, Z.zonDes
		, U.usoDes
		, [NumDias] = ISNULL(DATEDIFF(DAY, F.facLecAntFec, F.facLecActFec), 0)
		--*********************
		, [BaseImpAgua] = fclAgua.fclBase
		, [BaseImpAlcant] = fclAlcantarillado.fclBase 
		, [ServicioAgua] = svcAgua.svcdes
		, [ServicioAlcant] = svcAlcantarillado.svcdes
		, [BaseImpMttoCont] = fclMttoCont.fclBase
		, [TarifaAgua] = trfAgua.trfdes
		, [TarifaAlcantarillado] = trfAlcantarillado.trfdes
		--*********************
		, [TipoLectura] = IX.inlmc
		, [TotalACobrar] = ISNULL(T.ftfImporte, 0) 
		, IX.inldes
		FROM dbo.facturas AS F
		INNER JOIN @FACS AS FF 
		ON F.facCod = FF.facCod AND F.facPerCod= FF.facPerCod AND F.facCtrCod = FF.facCtrCod AND F.facVersion = FF.facVersion
		INNER JOIN dbo.contratos AS C 
		ON C.ctrcod = F.facctrcod AND C.ctrversion = F.facctrversion	   
		INNER JOIN dbo.inmuebles AS I 
		ON I.inmcod = C.ctrinmcod
		INNER JOIN dbo.zonas AS Z 
		ON F.facZonCod = Z.zonCod
		INNER JOIN dbo.usos AS U 
		ON U.usoCod = C.ctrUsoCod
		LEFT JOIN @usosExcluidos AS UX 
		ON UX.usoCodigo = C.ctrUsoCod
		LEFT JOIN dbo.incilec AS IX 
		ON IX.inlcod = F.facLecInlCod
		LEFT JOIN dbo.sociedades AS S 
		ON S.scdcod=ISNULL(F.facserscdcod, @SCD)
		--AGUA
		LEFT JOIN dbo.faclin AS fclAgua 
		ON F.facCod = fclAgua.fclFacCod 
		AND F.facPerCod = fclAgua.fclFacPerCod 
		AND F.facCtrCod = fclAgua.fclFacCtrCod 
		AND F.facVersion = fclAgua.fclFacVersion 
		AND fclAgua.fclTrfSvCod = @servicioAgua
	    LEFT JOIN dbo.servicios AS svcAgua 
		ON svcAgua.svccod = fclAgua.fclTrfSvCod
	    LEFT JOIN dbo.tarifas AS trfAgua 
		ON trfAgua.trfcod = fclAgua.fclTrfCod AND trfAgua.trfsrvcod = svcAgua.svccod	
		--ALCANTARILLADO
		LEFT JOIN dbo.faclin AS fclAlcantarillado 
		ON F.facCod = fclAlcantarillado.fclFacCod 
		AND F.facPerCod = fclAlcantarillado.fclFacPerCod 
		AND F.facCtrCod = fclAlcantarillado.fclFacCtrCod 
		AND F.facVersion = fclAlcantarillado.fclFacVersion 
		AND fclAlcantarillado.fclTrfSvCod = @servicioAlcant
		LEFT JOIN dbo.servicios AS svcAlcantarillado 
		ON svcAlcantarillado.svccod = fclAlcantarillado.fclTrfSvCod
		LEFT JOIN dbo.tarifas AS trfAlcantarillado 
		ON trfAlcantarillado.trfcod=fclAlcantarillado.fclTrfCod AND trfAlcantarillado.trfsrvcod=svcAlcantarillado.svccod
		--MTTO CONTADOR
		LEFT JOIN dbo.faclin AS fclMttoCont 
		ON F.facCod = fclMttoCont.fclFacCod 
		AND F.facPerCod = fclMttoCont.fclFacPerCod 
		AND F.facCtrCod = fclMttoCont.fclFacCtrCod 
		AND F.facVersion = fclMttoCont.fclFacVersion 
		AND fclMttoCont.fclTrfSvCod = @servicioMttoCont
		--Total Facturado
		LEFT JOIN dbo.fFacturas_TotalFacturado(NULL, 0, NULL) AS T
		ON T.ftfFacCod=F.facCod 
		AND T.ftfFacPerCod=F.facPerCod  
		AND T.ftfFacCtrCod=F.facCtrCod 
		AND T.ftfFacVersion=F.facVersion
		--Buscamos el ultimo contador asociado al contrato
		LEFT JOIN dbo.vCambiosContador AS CC  
		ON CC.ctrCod = F.facCtrCod AND CC.esUltimaInstalacion=1
	WHERE UX.usoCodigo IS NULL
	ORDER BY 
	CASE @orden WHEN 'calle' THEN inmdireccion END,	
	CASE @orden WHEN 'titular' THEN C.ctrTitCod END, 
	CASE @orden WHEN 'contratoCodigo' THEN C.ctrCod END
	, F.facCtrCod, F.facPerCod, F.facCod, F.facVersion
	, fclAgua.fclNumLinea, fclAlcantarillado.fclNumLinea, fclMttoCont.fclNumLinea;
	
GO