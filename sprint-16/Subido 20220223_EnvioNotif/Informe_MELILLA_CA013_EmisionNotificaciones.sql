--EXEC ReportingServices.Informe_MELILLA_CA013_EmisionNotificaciones @tipo=N'lectura',@cartaTipo=1,@periodo=N'202104',@tieneEmail=1

ALTER PROCEDURE [ReportingServices].[Informe_MELILLA_CA013_EmisionNotificaciones]
(
	@tipo VARCHAR(20),
	@cartaTipo INT,
	@periodo VARCHAR(6),
	@contratoD INT = NULL,
	@contratoH INT = NULL,
	@zonaD VARCHAR(4) = NULL,
	@zonaH VARCHAR(4) = NULL,
	@ruta1D VARCHAR(10) = NULL,
	@ruta1H VARCHAR(10) = NULL,
	@ruta2D VARCHAR(10) = NULL,
	@ruta2H VARCHAR(10) = NULL,
	@ruta3D VARCHAR(10) = NULL,
	@ruta3H VARCHAR(10) = NULL,
	@ruta4D VARCHAR(10) = NULL,
	@ruta4H VARCHAR(10) = NULL,
	@ruta5D VARCHAR(10) = NULL,
	@ruta5H VARCHAR(10) = NULL,
	@ruta6D VARCHAR(10) = NULL,
	@ruta6H VARCHAR(10) = NULL,
	@orden VARCHAR(20) = NULL,
	@filtro VARCHAR(500) = NULL,
	@forzarTipoCarta BIT = NULL,
	@legal VARCHAR(20) = NULL,
	@listado BIT = NULL -- Si es un listado le a�adimos a ciertos campos espacios en blanco al inicio o al final.
	, @tieneEmail BIT = NULL
)
AS
	SET NOCOUNT OFF;

BEGIN

	DECLARE @bitListado AS VARCHAR(1) = ISNULL(@listado, 0);

	DECLARE @sqlTieneEmail AS VARCHAR(250) = ' JOIN dbo.vEmailNotificaciones AS E ON E.[contrato.ctrCod] = C.[ctrCod] AND E.[contrato.ctrVersion] = C.[ctrVersion] ';
	
	SELECT @sqlTieneEmail = CASE WHEN @tieneEmail IS NULL THEN 'LEFT '  + @sqlTieneEmail 
								 WHEN @tieneEmail = 1	  THEN 'INNER ' + @sqlTieneEmail + 'AND LEN(E.[emailTo*])>0 '
								 WHEN @tieneEmail = 0	  THEN 'INNER ' + @sqlTieneEmail + 'AND LEN(E.[emailTo*])=0 '
								 END;

	
	DECLARE @where_or_and as varchar(6) --Ponemos la palabra "WHERE" o "AND" seg�n sea necesario
	IF CHARINDEX('WHERE', @filtro) = 0 SET @where_or_and = ' WHERE ' ELSE SET @where_or_and = ' AND '
	DECLARE @sql AS VARCHAR(MAX)

	SET @sql = ( 'SELECT 	
				CASE WHEN '+ ISNULL(CAST(@listado AS VARCHAR),'NULL') +' = 1 THEN
					REPLICATE('' '', 6 - LEN(C.ctrCod)) + CAST(C.ctrCod AS VARCHAR) 
				ELSE C.ctrCod END
				AS ctrCod,
				facPerCod,
				CASE WHEN '+ ISNULL(CAST(@listado AS VARCHAR),'NULL') +' = 1 THEN
					REPLICATE('' '', 4 - LEN(inlcod)) + inlcod 
				ELSE inlcod END	
				AS inlcod, 
				inldes, 
				facLecAnt, facLecAct, facConsumoFactura,
				CASE WHEN '+ ISNULL(CAST(@listado AS VARCHAR),'NULL') +' = 1 THEN
					ctrTitNom + REPLICATE('' '', 40 - LEN(ctrTitNom))
				ELSE ctrTitNom END	
				AS ctrTitNom,
				ctrTitDir,ctrTitPob,ctrTitPrv,
				CASE WHEN '+ ISNULL(CAST(@listado AS VARCHAR),'NULL') +' = 1 THEN
					ctrTitDocIden + REPLICATE('' '', 12 - LEN(ctrTitDocIden)) 
				ELSE ctrTitDocIden END		
				AS ctrTitDocIden,
				ctrTitCPos,ctrTitNac,
				CASE WHEN '+ ISNULL(CAST(@listado AS VARCHAR),'NULL') +' = 1 THEN
					ctrPagNom + REPLICATE('' '', 40 - LEN(ctrPagNom))
				ELSE ctrPagNom END		
				AS ctrPagNom,
				ctrPagDir,ctrPagPob,ctrPagPrv,
				CASE WHEN '+ ISNULL(CAST(@listado AS VARCHAR),'NULL') +' = 1 THEN
					ctrPagDocIden + REPLICATE('' '', 12 - LEN(ctrPagDocIden))
				ELSE ctrPagDocIden END		
				AS ctrPagDocIden,
				ctrPagCPos,ctrPagNac,
				ctrEnvCPos,ctrEnvNom,ctrEnvDir,ctrEnvPob,ctrEnvPrv,ctrEnvNac,
				CASE WHEN '+ ISNULL(CAST(@listado AS VARCHAR),'NULL') +' = 1 THEN
					inmdireccion + REPLICATE('' '', 100 - LEN(inmdireccion))
				ELSE inmdireccion END		
				AS inmdireccion,
				inmcpost,
				mncdes, pobdes, pobcpos, prvdes
				
				, ctrRuta1,ctrRuta2,ctrRuta3,ctrRuta4,ctrRuta5,ctrRuta6,
				GETDATE() as fecha,
				ctaCarta AS cartaTexto,
				ctrzoncod AS zona,
				ctrRepresent,
				ctravisolector,
				ctaTitulo,
				ctrTlf1, ctrTlfRef1, ctrTlf2, ctrTlfRef2, ctrTlf3, ctrTlfRef3, ctrEmail
				--**********************
				, E.[contrato.ctrRuta]
				, F.facLecAntFec
				, F.facLecActFec
				, V.[I.ctcFec]
				, V.[R.ctcFec]
				, V.[conId]
				, V.[esUltimaInstalacion]
				, V.[conDiametro]
				, [conNumSerie] = 
				  CASE WHEN '+ @bitListado + ' = 1 
				  THEN CAST(V.conNumSerie AS CHAR(20))
				  ELSE V.conNumSerie END 
				--RN=1: Para asegurarnos de retornar un contador por factura (en caso de datos inconsistentes)
				, [RN] = ROW_NUMBER() OVER(PARTITION BY facCtrCod, facPerCod, facCod, facVersion ORDER BY V.[I.ctcFec] DESC)
				--**********************
				
				, ctrVersion
				, ctrTitCod
				, emailName
				, emailTo
				, emailTo_Real = [emailTo*]
				, ctaCodigo
				, ctaDescripcion
				--**********************
				INTO #RPT
				--**********************
				FROM dbo.facturas AS F
				INNER JOIN dbo.contratos AS C ON C.ctrcod= F.facCtrCod AND C.ctrversion = F.facCtrVersion '
				+
				@sqlTieneEmail
				+
			   'LEFT JOIN INMUEBLES ON ctrinmcod = inmcod 
				
				LEFT JOIN provincias on inmPrvCod = prvCod
				LEFT JOIN poblaciones on inmPobCod = pobCod and inmPrvCod = pobPrv
				LEFT JOIN municipios on inmMncCod = mncCod and inmPobCod = mncPobCod and inmPrvCod = mncPobPrv
				
				--**********************
				--Se busca el contador instalado a la fecha de la lectura actual
				--Si se realiza un cambio de contador el mismo d�a de la lectura, siempre se procesa en el periodo siguiente									
				LEFT JOIN dbo.vCambiosContador AS V 
				ON  (C.ctrcod = V.ctrCod) 
				AND 
				(	--Si tiene lectura actual, buscamos el cambio de contador a la fecha
				    (
					 (F.facLecActFec IS NOT NULL) AND 
					 (CAST(V.[I.ctcFec] AS DATE) < CAST(F.facLecActFec AS DATE)) AND 
					 (V.[R.ctcFec] IS NULL OR CAST(V.[R.ctcFec] AS DATE) >= CAST(F.facLecActFec AS DATE))
					)
					OR
					--Si no tiene lectura actual, buscamos el ultimo contador
					(
					 (F.facLecActFec IS NULL) AND 
					 (V.opRetirada IS NULL) AND 
					 (V.esUltimaInstalacion=1)
					)
				)
				--**********************
				INNER JOIN incilec ON inlcod = CASE '''+ ISNULL(CAST(@tipo AS VARCHAR),'NULL') +'''
														 WHEN ''lectura'' THEN facLecInlCod  
														 WHEN ''inspeccion'' THEN facInsInlCod
		           							   END 
				INNER JOIN cartaTipos ON ctaCodigo = CASE WHEN '+ ISNULL(CAST(@forzarTipoCarta AS VARCHAR),'NULL') +' = 0
									THEN ISNULL(inlcarta, '+ ISNULL(CAST(@cartaTipo AS VARCHAR),'NULL') +')        					   
									ELSE '+ISNULL(CAST(@cartaTipo AS VARCHAR),'NULL')+'
									 END
							'+ ISNULL(@filtro, '') + @where_or_and +'		           						   
						 ('+ ISNULL(CAST(''''+ @periodo +'''' AS VARCHAR),'NULL') +' = facPerCod OR '+ ISNULL(CAST(''''+ @periodo +'''' AS VARCHAR),'NULL') +' IS NULL) AND
						 (C.ctrCod>= '+ ISNULL(CAST(@contratoD AS VARCHAR),'NULL') +' OR '+ ISNULL(CAST(@contratoD AS VARCHAR),'NULL') +' IS NULL) AND 
						 (C.ctrCod<= '+ ISNULL(CAST(@contratoH AS VARCHAR),'NULL') +' OR '+ ISNULL(CAST(@contratoH AS VARCHAR),'NULL') +' IS NULL) AND 
						 (ctrzoncod >= '+ ISNULL(CAST(''''+ @zonaD +'''' AS VARCHAR),'NULL') +' OR '+ ISNULL(CAST(''''+ @zonaD +'''' AS VARCHAR),'NULL') +' IS NULL) AND 
						 (ctrzoncod <= '+ ISNULL(CAST(''''+ @zonaH +'''' AS VARCHAR),'NULL') +' OR '+ ISNULL(CAST(''''+ @zonaH +'''' AS VARCHAR),'NULL') +' IS NULL) 
						 AND ISNULL(ctrNoEmision, 0) = 0 
						 
						 AND ('+ ISNULL(CAST('''' + @legal + '''' AS VARCHAR),'NULL') +' IS NULL OR 
							  '+ ISNULL(CAST('''' + @legal + '''' AS VARCHAR),'NULL') +' = ''Indiferente'' OR
							 ('+ ISNULL(CAST('''' + @legal + '''' AS VARCHAR),'NULL') +' = ''Si'' AND ctrRepresent IS NOT NULL AND ctrRepresent<>'''') OR 
							 ('+ ISNULL(CAST('''' + @legal + '''' AS VARCHAR),'NULL') +' = ''No'' AND (ctrRepresent IS NULL OR ctrRepresent=''''))
							)

						 AND (ctrRuta1 >= '+ ISNULL(CAST(''''+ @ruta1D +'''' AS VARCHAR),'NULL') +' OR '+ ISNULL(CAST(''''+ @ruta1D +'''' AS VARCHAR),'NULL') +' IS NULL)
						 AND (ctrRuta1 <= '+ ISNULL(CAST(''''+ @ruta1H +'''' AS VARCHAR),'NULL') +' OR '+ ISNULL(CAST(''''+ @ruta1H +'''' AS VARCHAR),'NULL') +' IS NULL)
						 AND (ctrRuta2 >= '+ ISNULL(CAST(''''+ @ruta2D +'''' AS VARCHAR),'NULL') +' OR '+ ISNULL(CAST(''''+ @ruta2D +'''' AS VARCHAR),'NULL') +' IS NULL)
						 AND (ctrRuta2 <= '+ ISNULL(CAST(''''+ @ruta2H +'''' AS VARCHAR),'NULL') +' OR '+ ISNULL(CAST(''''+ @ruta2H +'''' AS VARCHAR),'NULL') +' IS NULL)
						 AND (ctrRuta3 >= '+ ISNULL(CAST(''''+ @ruta3D +'''' AS VARCHAR),'NULL') +' OR '+ ISNULL(CAST(''''+ @ruta3D +'''' AS VARCHAR),'NULL') +' IS NULL)
						 AND (ctrRuta3 <= '+ ISNULL(CAST(''''+ @ruta3H +'''' AS VARCHAR),'NULL') +' OR '+ ISNULL(CAST(''''+ @ruta3H +'''' AS VARCHAR),'NULL') +' IS NULL)
						 AND (ctrRuta4 >= '+ ISNULL(CAST(''''+ @ruta4D +'''' AS VARCHAR),'NULL') +' OR '+ ISNULL(CAST(''''+ @ruta4D +'''' AS VARCHAR),'NULL') +' IS NULL)
						 AND (ctrRuta4 <= '+ ISNULL(CAST(''''+ @ruta4H +'''' AS VARCHAR),'NULL') +' OR '+ ISNULL(CAST(''''+ @ruta4H +'''' AS VARCHAR),'NULL') +' IS NULL)
						 AND (ctrRuta5 >= '+ ISNULL(CAST(''''+ @ruta5D +'''' AS VARCHAR),'NULL') +' OR '+ ISNULL(CAST(''''+ @ruta5D +'''' AS VARCHAR),'NULL') +' IS NULL)
						 AND (ctrRuta5 <= '+ ISNULL(CAST(''''+ @ruta5H +'''' AS VARCHAR),'NULL') +' OR '+ ISNULL(CAST(''''+ @ruta5H +'''' AS VARCHAR),'NULL') +' IS NULL)
						 AND (ctrRuta6 >= '+ ISNULL(CAST(''''+ @ruta6D +'''' AS VARCHAR),'NULL') +' OR '+ ISNULL(CAST(''''+ @ruta6D +'''' AS VARCHAR),'NULL') +' IS NULL)
						 AND (ctrRuta6 <= '+ ISNULL(CAST(''''+ @ruta6H +'''' AS VARCHAR),'NULL') +' OR '+ ISNULL(CAST(''''+ @ruta6H +'''' AS VARCHAR),'NULL') +' IS NULL)
						 AND facFechaRectif IS NULL;
						 
						 
			SELECT * 
			FROM #RPT			 
			WHERE RN=1			  
			ORDER BY '
			+
			CASE @orden 
			WHEN 'suministro' THEN 'inmdireccion'
			WHEN 'ruta' THEN '[contrato.ctrRuta]'
			WHEN 'sujeto pasivo' THEN 'LTRIM(ISNULL(ctrPagNom, ctrTitNom))'
			WHEN 'doc.iden' THEN 'LTRIM(ISNULL(ctrPagDocIden, ctrTitDocIden)'
			WHEN 'Representante' THEN 'ctrRepresent'
			ELSE 'ctrCod, facPerCod'
			END)


	EXEC(@sql)

	IF OBJECT_ID('tempdb.dbo.#RPT', 'U') IS NOT NULL 
	DROP TABLE #RPT;


END

GO


