 /*
DECLARE @grupo VARCHAR(50) = NULL
 , @orden VARCHAR(50) 
 , @preFactura BIT = 1
 , @verTodas BIT = 1 
 , @mostrarFacturasE BIT = NULL 
 , @impoMin FLOAT = NULL
 , @impoMax FLOAT = NULL 
 , @versionH INT = NULL
 , @versionD INT = NULL
 , @uso INT = NULL
 , @contratoD INT = 3660376 
 , @contratoH INT = 3660376 
 , @consuMin INT = NULL
 , @consuMax INT = NULL
 , @clienteD INT = NULL
 , @clienteH INT = NULL
 , @fechaD DATETIME = NULL
 , @fechaH DATETIME = NULL
 , @facFecEmisionSERESIni DATETIME = NULL
 , @facFecEmisionSERESFinal DATETIME = NULL
 , @zonaD VARCHAR(4) = NULL
 , @zonaH VARCHAR(4) = NULL
 , @periodoD VARCHAR(6) = NULL 
 , @periodoH VARCHAR(6) = NULL
 , @series VARCHAR(max)= NULL
 , @xmlPortalCodArray VARCHAR(max)= NULL
 , @noDetallado BIT =0
 , @incluirLiquidadas BIT = 1


EXEC [ReportingServices].[InformeRelacionFacturas] @grupo, @orden, @preFactura, @verTodas, @mostrarFacturasE 
, @impoMin, @impoMax, @versionH, @versionD, @uso, @contratoD, @contratoH, @consuMin, @consuMax 
, @clienteD, @clienteH, @fechaD, @fechaH, @facFecEmisionSERESIni, @facFecEmisionSERESFinal 
, @zonaD, @zonaH, @periodoD, @periodoH, @series, @xmlPortalCodArray, @noDetallado, @incluirLiquidadas


--DROP PROCEDURE [dbo].[InformeRelacionFacturas]	
*/		
	

CREATE PROCEDURE [ReportingServices].[InformeRelacionFacturas]
   @grupo VARCHAR(50) = NULL
 , @orden VARCHAR(50) 
 , @preFactura BIT = NULL
 , @verTodas BIT = 1 
 , @mostrarFacturasE BIT = NULL 
 , @impoMin FLOAT = NULL
 , @impoMAX FLOAT = NULL 
 , @versionH INT = NULL
 , @versionD INT = NULL
 , @uso INT = NULL
 , @contratoD INT = NULL
 , @contratoH INT = NULL
 , @consuMin INT = NULL
 , @consuMAX INT = NULL
 , @clienteD INT = NULL
 , @clienteH INT = NULL
 , @fechaD DATETIME = NULL
 , @fechaH DATETIME = NULL
 , @facFecEmisionSERESIni DATETIME = NULL
 , @facFecEmisionSERESFinal DATETIME = NULL
 , @zonaD VARCHAR(4) = NULL
 , @zonaH VARCHAR(4) = NULL
 , @periodoD VARCHAR(6) = NULL
 , @periodoH VARCHAR(6) = NULL
 , @series VARCHAR(MAX)= NULL
 , @xmlPortalCodArray VARCHAR(MAX)= NULL
 , @noDetallado BIT = NULL
 , @incluirLiquidadas BIT = 0
AS


	SET NOCOUNT ON; 

	SET @incluirLiquidadas = ISNULL(@incluirLiquidadas, 0);
	SET @noDetallado = ISNULL(@noDetallado, 0);

	--Cambio la variable para no hacerme lio con la doble negacion
	DECLARE @detallado BIT = IIF(@noDetallado = 0, 1, 0);

	DECLARE @valor VARCHAR(200) = 1;
	SELECT @valor=P.pgsvalor FROM dbo.parametros AS P WHERE P.pgsclave='SOCIEDAD_POR_DEFECTO';
	
	IF @xmlPortalCodArray IS NOT NULL 
	BEGIN
 		--Creamos una tabla en memoria donde se van a insertar todos los valores
 		DECLARE @portalesExcluidos AS TABLE(portalCodigo VARCHAR(10)) 
 		--Leemos los parámetros del XML
 		DECLARE @idoc INT
 		EXEC sp_xml_preparedocument @idoc OUTPUT, @xmlPortalCodArray
 		--Insertamos en tabla temporal
 		INSERT INTO @portalesExcluidos(portalCodigo)
 		SELECT value
 		FROM OPENXML (@idoc, '/portalCodigo_List/portalCodigo', 2) WITH (value VARCHAR(10))
 		--Liberamos memoria
 		EXEC sp_xml_removedocument @idoc
	END

	BEGIN TRY

 	SELECT NumeroLinea = ROW_NUMBER() OVER(PARTITION BY F.facPerCod, F.facCtrCod, F.facCod, F.facVersion ORDER BY FL.fclNumLinea)
	, F.facCod
 	, F.facPerCod
 	, F.facCtrCod
 	, F.facVersion
	, FL.fclNumLinea
	, F.facSerCod
	, F.facNumero
	, F.facFecha
 	, F.facConsumoFactura
 	, facZonCod = IIF(@grupo = 'sinZona', NULL, facZonCod) 	

 	, P.perdes
 	, C.ctrPagNom
 	, C.ctrTitNom
 	, C.ctrTitDocIden
 	, C.ctrPagDocIden
 	, Z.zondes
 	, I.inmdireccion
 	, S.svcdes
 	, T.trfdes
 	, SCD.scdImpNombre
 	, FL.fclEscala1
 	, FL.fclPrecio1,  FL.fclUnidades1
 	, FL.fclPrecio2,  FL.fclUnidades2
 	, FL.fclPrecio3,  FL.fclUnidades3 
 	, FL.fclPrecio4,  FL.fclUnidades4 
 	, FL.fclPrecio5,  FL.fclUnidades5 
 	, FL.fclPrecio6,  FL.fclUnidades6
 	, FL.fclPrecio7,  FL.fclUnidades7 
 	, FL.fclPrecio8,  FL.fclUnidades8 
 	, FL.fclPrecio9,  FL.fclUnidades9
	, FL.fclUnidades, FL.fclPrecio
	, FL.fclbase
	, FL.fclimpimpuesto
 	, FL.fclTrfSvCod
 	, FL.fclTrfCod
	, FL.fclImpuesto
 	---------------------------------------------
 	, fcltotal  = ROUND(FL.fcltotal * IIF(fclFecLiq IS NULL, 1, 0),2)
	, _total	 = SUM(FL.fcltotal  * IIF(fclFecLiq IS NULL, 1, 0))		OVER(PARTITION BY facPerCod, facCtrCod, facCod, facVersion)
	, base		 = SUM(FL.fclbase   * IIF(fclFecLiq IS NULL, 1, 0))		OVER(PARTITION BY facPerCod, facCtrCod, facCod, facVersion)
	, impuesto	 = SUM(fclimpimpuesto * IIF(fclFecLiq IS NULL, 1, 0))	OVER(PARTITION BY facPerCod, facCtrCod, facCod, facVersion)
	, ftfImporte 
	--, SUM((FL.fclbase+fclimpimpuesto)*IIF(fclFecLiq IS NULL, 1, 0))OVER(PARTITION BY facPerCod, facCtrCod, facCod, facVersion)
 	---------------------------------------------
 	, FL.fclFecLiq
	, CountLineas = COUNT(FL.fclNumLinea) OVER(PARTITION BY F.facPerCod, F.facCtrCod, F.facCod, F.facVersion)
	, CountLiq = SUM(IIF(FL.fclFecLiq IS NULL, 0, 1)) OVER(PARTITION BY F.facPerCod, F.facCtrCod, F.facCod, F.facVersion)
	, _facFecLiq = MAX(FL.fclFecLiq) OVER(PARTITION BY facPerCod, facCtrCod, facCod, facVersion)
 	
	INTO #RESULT
	FROM dbo.facturas AS F

 	INNER JOIN dbo.Split(@series, ';') AS SS
	ON (@series IS NULL OR SS.value = F.facSerCod)
	INNER JOIN dbo.faclin AS FL 
	ON  facCod = fclFacCod 
    AND facPerCod	= fclFacPerCod 
 	AND facCtrCod	= fclFacCtrCod 
 	AND facVersion	= fclFacVersion
	INNER JOIN dbo.contratos AS C 
	ON  C.ctrcod = F.facCtrCod 
	AND C.ctrversion = F.facctrversion	
	INNER JOIN dbo.periodos AS P
	ON F.facpercod = P.percod
	INNER JOIN dbo.zonas AS Z
	ON F.facZonCod = Z.zoncod
	INNER JOIN dbo.inmuebles AS I 
	ON C.ctrinmcod = I.inmcod
 	INNER JOIN dbo.servicios AS S 
	ON FL.fclTrfSvCod = S.svccod
 	INNER JOIN dbo.tarifas AS T 
	ON T.trfsrvcod = FL.fclTrfSvCod 
 	 AND trfcod = fclTrfCod
	LEFT JOIN dbo.sociedades AS SCD 
	ON SCD.scdcod = ISNULL(F.facserscdcod, @valor)
 	INNER JOIN fFacturas_TotalFacturado(NULL, 0, NULL) AS FTF	
	ON FTF.ftfFacCod = F.facCod 
 	AND FTF.ftfFacPerCod = F.facPerCod
 	AND FTF.ftfFacCtrCod = F.facCtrCod 
 	AND FTF.ftfFacVersion= facVersion
	WHERE (@periodoD IS NULL OR F.facPerCod  >= @periodoD)
	  AND (@periodoH IS NULL OR F.facPerCod  <= @periodoH)
	  AND (@versionD IS NULL OR F.facVersion >= @versionD)
	  AND (@versionH IS NULL OR F.facVersion <= @versionH)
	  AND (@zonaD IS NULL OR F.facZonCod >= @zonaD)
	  AND (@zonaH IS NULL OR F.facZonCod 	<= @zonaH)
	  AND (@fechaD IS NULL OR F.facFecha >= @fechaD)
	  AND (@fechaH 	IS NULL OR F.facFecha <= @fechaH)
	  AND (@contratoD IS NULL OR F.facCtrCod 	>= @contratoD)
	  AND (@contratoH IS NULL OR F.facCtrCod 	<= @contratoH)
	  AND (@consuMin IS NULL OR F.facConsumoFactura	>= @consuMin)
	  AND (@consuMax IS NULL OR F.facConsumoFactura	<= @consuMax)
	  AND (@clienteD IS NULL OR F.facClicod 	>= @clienteD)
	  AND (@clienteH IS NULL OR F.facClicod 	<= @clienteH) 
	  AND (@facFecEmisionSERESIni	IS NULL OR F.facFecEmisionSERES	>= @facFecEmisionSERESIni)
 	  AND (@facFecEmisionSERESFinal IS NULL OR F.facFecEmisionSERES	<= @facFecEmisionSERESFinal)
 	  AND ((@verTodas = 1) OR (F.facFechaRectif IS NULL OR F.facFechaRectif > @fechaH))
	  AND ((@incluirLiquidadas=1) OR ((FL.fclFecLiq IS NULL AND FL.fclUsrLiq IS NULL) OR (FL.fclFecLiq >= @fechaH)))
	  AND (@preFactura=1 OR F.facNumero IS NOT NULL)
	  ------------
	  AND (@uso IS NULL OR C.ctrusocod = @uso)
	  AND (@xmlPortalCodArray IS NULL OR C.ctrFacePortal NOT IN (SELECT PP.portalCodigo FROM @portalesExcluidos AS PP))
	  AND ((@mostrarFacturasE IS NULL) OR 
		   (@mostrarFacturasE = 1 AND F.facEnvSERES IS NOT NULL) OR
		   (@mostrarFacturasE = 0 AND (C.ctrFaceTipoEnvio='POSTAL' OR F.facEnvSERES IS NULL OR F.facEnvSERES NOT IN ('E', 'P' , 'R'))) )  
	  ------------
	  AND (@impoMin IS NULL OR FTF.ftfImporte >= @impoMin) 
	  AND (@impoMax IS NULL OR FTF.ftfImporte <= @impoMax); 
	
	SELECT * 
	, total = ROUND(_total, 2)
	, facFecLiq = IIF(CountLineas=CountLiq, _facFecLiq, NULL)
	FROM #RESULT AS F
	WHERE (@Detallado = 1) OR (@Detallado = 0 AND NumeroLinea=1)
	ORDER BY 
	  IIF(@orden='periodoZonaFecha', F.facPerCod, FORMAT(facCtrCod, 'D12'))
	, IIF(@orden='periodoZonaFecha' AND @grupo <> 'sinZona', F.facZonCod, F.facPerCod)
	, IIF(@orden='periodoZonaFecha', F.facFecha, F.facCod)
	, IIF(@orden='periodoZonaFecha', NULL, F.facVersion)
	, IIF(@orden='periodoZonaFecha', NULL, F.fclNumLinea);

	
	END TRY
	BEGIN CATCH

	END CATCH

	IF OBJECT_ID('tempdb.dbo.#RESULT', 'U') IS NOT NULL 
	DROP TABLE #RESULT;



GO


