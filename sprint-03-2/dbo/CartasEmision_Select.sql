/*
DECLARE @numPeriodosD INT = NULL,
@periodoD VARCHAR(6) = NULL,
@periodoH VARCHAR(6) = NULL,
@contratoD INT = 7829,
@contratoH INT = 7829,
@impDeudaD MONEY = NULL,
@impDeudaH MONEY = NULL,
@domiciliado BIT = NULL,
@esServicioMedido BIT = NULL,
@orden VARCHAR(50) = NULL,
@xmlIncLecUltFac VARCHAR(MAX) = NULL,
@xmlIncLecAlgunaFac VARCHAR(MAX) = NULL,
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
@incluirEfectosPendientes BIT = NULL,
@numPeriodosH INT = NULL,
@incluirClientesVip BIT = NULL,
@estado VARCHAR(10) = NULL,
@xmlSerCodArray VARCHAR(MAX) = NULL,
@importeMinimoDevolucion MONEY = NULL,
@bancoCodigo SMALLINT = NULL,
@cobroFecReg DATETIME = NULL,
@soloDevoluciones BIT = NULL,
@xmlRepresentantesArray VARCHAR(MAX) = NULL,
@listaContratos VARCHAR(MAX)= NULL

EXEC [dbo].[CartasEmision_Select] @numPeriodosD, @periodoD, @periodoH, @contratoD, @contratoH, @impDeudaD, @impDeudaH, @domiciliado
, @esServicioMedido, @orden
, @xmlIncLecUltFac, @xmlIncLecAlgunaFac, @zonaD, @zonaH, @ruta1D, @ruta1H, @ruta2D, @ruta2H, @ruta3D, @ruta3H
, @ruta4D, @ruta4H, @ruta5D, @ruta5H, @ruta6D, @ruta6H, @incluirEfectosPendientes, @numPeriodosH, @incluirClientesVip
, @estado, @xmlSerCodArray, @importeMinimoDevolucion, @bancoCodigo, @cobroFecReg, @soloDevoluciones
, @xmlRepresentantesArray, @listaContratos;

*/
CREATE PROCEDURE [dbo].[CartasEmision_Select]
	@numPeriodosD				INT			= NULL,
	@periodoD					VARCHAR(6)	= NULL,
	@periodoH					VARCHAR(6)	= NULL,
	@contratoD					INT			= NULL,
	@contratoH					INT			= NULL,
	@impDeudaD					MONEY		= NULL,
	@impDeudaH					MONEY		= NULL,
	@domiciliado				BIT			= NULL,
	@esServicioMedido			BIT			= NULL,
	@orden						VARCHAR(50) = NULL,
	@xmlIncLecUltFac			TEXT		= NULL,
	@xmlIncLecAlgunaFac			TEXT		= NULL,
	@zonaD						VARCHAR(4)	= NULL,
	@zonaH						VARCHAR(4)	= NULL,
	@ruta1D						VARCHAR(10) = NULL,
	@ruta1H						VARCHAR(10) = NULL,
	@ruta2D						VARCHAR(10) = NULL,
	@ruta2H						VARCHAR(10) = NULL,
	@ruta3D						VARCHAR(10) = NULL,
	@ruta3H						VARCHAR(10) = NULL,
	@ruta4D						VARCHAR(10) = NULL,
	@ruta4H						VARCHAR(10) = NULL,
	@ruta5D						VARCHAR(10) = NULL,
	@ruta5H						VARCHAR(10) = NULL,
	@ruta6D						VARCHAR(10) = NULL,
	@ruta6H						VARCHAR(10) = NULL,
	@incluirEfectosPendientes	BIT			= NULL, --Si su valor es 1 o NULL se incluirán todos los efectos pendientes a remesar, si es 0 no se incluirán
	@numPeriodosH				INT			= NULL,
	@incluirClientesVip			BIT			= NULL, --Si es 1 o NULL se incluirán todos los contratos Vip, si es 0 no se incluirán.
	@estado						VARCHAR(10) = NULL,
	@xmlSerCodArray				TEXT		= NULL,
	@importeMinimoDevolucion	MONEY		= NULL,
	@bancoCodigo				SMALLINT	= NULL,
	@cobroFecReg				DATETIME	= NULL,
	@soloDevoluciones			BIT			= NULL,
	@xmlRepresentantesArray		TEXT		= NULL,
	@listaContratos				VARCHAR(MAX)= NULL
AS 

	SET NOCOUNT ON;
	
	DECLARE @tableCtrs AS TABLE(id int);

	
	if @listaContratos IS NOT NULL
		
		BEGIN
			INSERT INTO @tableCtrs
			SELECT DISTINCT value 
			FROM dbo.Split(@listaContratos, ',')
		END
	

	DECLARE @idoc INT
	-- XML donde se indicas las incidencias de lectura para que solo salgan los contratos que tengan en la última factura las 
	-- incidencias indicadas.
	IF @xmlIncLecUltFac IS NOT NULL 
	
		BEGIN
			--Creamos una tabla en memoria donde se van a insertar todos los valores
			DECLARE @incidenciasLecturaUltimaFactura AS TABLE(incidenciaCodigo VARCHAR(2)) 
			--Leemos los parámetros del XML
			SET @idoc = NULL
			EXEC sp_xml_preparedocument @idoc OUTPUT, @xmlIncLecUltFac 
			--Insertamos en tabla temporal
			INSERT INTO @incidenciasLecturaUltimaFactura(incidenciaCodigo)	
			SELECT value 
			FROM OPENXML (@idoc, '/incidenciasCodigo_List/incidenciaCodigo', 2) WITH (value VARCHAR(2))	
			--Liberamos memoria
			EXEC  sp_xml_removedocument @idoc
		END

	-- XML donde se indicas las incidencias de lectura para que solo salgan los contratos que tengan en alguna factura las 
	-- incidencias indicadas.
	IF @xmlIncLecAlgunaFac IS NOT NULL 
	
		BEGIN
			--Creamos una tabla en memoria donde se van a insertar todos los valores
			DECLARE @incidenciasLecturaAlgunaFactura AS TABLE(incidenciaCodigo VARCHAR(2)) 
			--Leemos los parámetros del XML
			SET @idoc = NULL
			EXEC sp_xml_preparedocument @idoc OUTPUT, @xmlIncLecAlgunaFac 
			--Insertamos en tabla temporal
			INSERT INTO @incidenciasLecturaAlgunaFactura(incidenciaCodigo)	
			SELECT value
			FROM OPENXML (@idoc, '/incidenciasCodigo_List/incidenciaCodigo', 2) WITH (value VARCHAR(2))	
			--Liberamos memoria
			EXEC  sp_xml_removedocument @idoc
		END

	IF @xmlSerCodArray IS NOT NULL 
	
		BEGIN
			--Creamos una tabla en memoria donde se van a insertar todos los valores
			DECLARE @serviciosExcluidos AS TABLE(servicioCodigo SMALLINT) 
			--Leemos los parámetros del XML
			SET @idoc = NULL
			EXEC sp_xml_preparedocument @idoc OUTPUT, @xmlSerCodArray
			--Insertamos en tabla temporal
			INSERT INTO @serviciosExcluidos(servicioCodigo)
			SELECT value
			FROM   OPENXML (@idoc, '/servicioCodigo_List/servicioCodigo', 2) WITH (value SMALLINT)
			--Liberamos memoria
			EXEC  sp_xml_removedocument @idoc
		END

	IF @xmlRepresentantesArray IS NOT NULL 
	
		BEGIN
			--Creamos una tabla en memoria donde se van a insertar todos los valores
			DECLARE @representantesExcluidos AS TABLE(representante varchar(80)) 
			--Leemos los parámetros del XML
			SET @idoc = NULL
			EXEC sp_xml_preparedocument @idoc OUTPUT, @xmlRepresentantesArray
			--Insertamos en tabla temporal
			INSERT INTO @representantesExcluidos(representante)
			SELECT value
			FROM   OPENXML (@idoc, '/representante_List/representante', 2) WITH (value varchar(80))
			--Liberamos memoria
			EXEC  sp_xml_removedocument @idoc
		END

	--Obtener el código de la explotación
	DECLARE @expl VARCHAR(50) = NULL
	SET @expl = (SELECT pgsvalor FROM parametros WHERE pgsclave = 'EXPLOTACION')

	SELECT	C.ctrCod,
			NULL as facPerCod, --Solo para la emisión cuando viene de devoluciones
			NULL as perDes, --Solo para la emisión cuando viene de devoluciones
			ctrTitNom,ctrTitDir,ctrTitPob,ctrTitPrv,ctrTitDocIden,ctrTitCPos,ctrTitNac,
			ctrPagNom,ctrPagDir,ctrPagPob,ctrPagPrv,ctrPagDocIden,ctrPagCPos,ctrPagNac,
			ctrEnvCPos,ctrEnvNom,ctrEnvDir,ctrEnvPob,ctrEnvPrv,ctrEnvNac,
			inmdireccion, inmcpost,
			inmPrvCod, inmPobCod, inmMncCod, pobdes, pobcpos, prvdes, 
			mncdes, mncCpos, cllCpos,
			conNumSerie,conDiametro,
			ctrRuta1,ctrRuta2,ctrRuta3,ctrRuta4,ctrRuta5,ctrRuta6,
			(CASE WHEN LEN(ctrIBAN) >= 24 AND LEN(ctrIBAN) <= 34 THEN LEFT(ctrIBAN,4) + SUBSTRING(ctrIBAN,5,4) + SUBSTRING(ctrIBAN,9,4) + REPLICATE('*',2) + REPLICATE('*',6) + RIGHT(ctrIBAN,4) ELSE  '---' END) AS iban,
			getDate() as fecha,
			ISNULL(importeCobrado,0)	AS importeCobrado,
			ISNULL(importeFacturado,0)	AS importeFacturado,			
			NULL AS excNumExp,
			NULL AS excFechaCorte,
			ISNULL(numPeriodosDeuda,0) as periodosConDeudaPorContrato
	-- INICIO IMPORTES
	FROM (
			SELECT  ctrCod, sum(deuda) AS numPeriodosDeuda, sum(importeCobrado) as importeCobrado, 
					sum(importeFacturado) as importeFacturado, sum(importeFacturado) - sum(importeCobrado) AS importeDeuda   
			FROM (
					SELECT ctrcod
					, periodo = facPerCod 
					, importeCobrado = ISNULL(importeCobrado,0) 
					, importeFacturado = ROUND(ISNULL(importeFacturado,0), 2)
					, deuda = CASE 
								WHEN (ROUND(ISNULL(importeFacturado,0), 2) > ISNULL(importeCobrado,0))		AND @expl <> 'AVG'	THEN 1 
								WHEN (ROUND(ISNULL(importeFacturado,0), 2) > ISNULL(importeCobrado,0) + 1)	AND @expl = 'AVG'	THEN 1 -- para evitar céntimos de descuadre	
								ELSE 0 
								END
					FROM CONTRATOS C
					--INICIO Importe facturado para cada contrato (viene con 4 decimales)
					LEFT JOIN (	SELECT facCtrCod,round(ISNULL(sum(fclTotal),0) ,2)  AS importeFacturado, facPerCod, facCod, facSerScdCod
								FROM facturas f 
								INNER JOIN faclin fl ON fclFacPerCod	= facPerCod  
								                    AND fclFacCtrCod	= facCtrCod 
													AND fclFacVersion	= facVersion 
													AND fclFacCod		= facCod
								WHERE facSerCod		IS NOT NULL 
								  AND facSerScdCod	IS NOT NULL 
								  AND facNumero		IS NOT NULL 
								  AND facVersion = (SELECT MAX(facVersion) 
													FROM facturas fSub 
													WHERE f.facCtrCod = fSub.facCtrCod 
													  AND f.facPerCod = fSub.facPerCod 
													  AND f.facCod = fSub.facCod) 
								  AND (	   @esServicioMedido IS NULL 
										OR EXISTS (	SELECT fclNumLinea 
													FROM facLin
													INNER JOIN servicios ON fclTrfSvCod		= svcCod 
													                    AND fclFacPerCod	= f.facPerCod 
													                    AND fclFacCtrCod	= f.facCtrCod 
													                    AND fclFacVersion	= f.facVersion 
													                    AND fclFacCod		= f.facCod
												
													WHERE (@esServicioMedido = 1 AND svcTipo = 'M') OR (@esServicioMedido = 0 AND svcTipo <> 'M') 
												  )
									  ) 
								  AND (fclFecLiq		IS NULL AND fclUsrLiq IS NULL) 
								  AND (@contratoD		IS NULL	OR  facCtrcod >= @contratoD) 
								  AND (@contratoH		IS NULL	OR  facCtrcod <= @contratoH) 	
								  AND (@listaContratos	IS NULL	OR	facCtrcod IN (SELECT ID FROM @tableCtrs))
								  -- inicio and @xmlSerCodArray
								  AND (		@xmlSerCodArray IS NULL 									  
										OR	(  (SELECT round(ISNULL(sum(fclTotal),0) ,2) 
												FROM facturas f2 
												INNER JOIN faclin fl2 ON fclFacPerCod	= facPerCod  
																	 AND fclFacCtrCod	= facCtrCod 
																	 AND fclFacVersion	= facVersion 
																	 AND fclFacCod		= facCod
												WHERE f2.facCtrCod		= f.facCtrCod 
												  and f2.facPerCod		= f.facPerCod 
												  and f2.facCod			= f.facCod 
												  AND f2.facSerCod		IS NOT NULL 
												  AND f2.facSerScdCod	IS NOT NULL 
												  AND f2.facNumero		IS NOT NULL 
												  AND f2.facVersion = (	SELECT MAX(facVersion) 
																		FROM facturas fSub 
																		WHERE f2.facCtrCod = fSub.facCtrCod 
																		  AND f2.facPerCod = fSub.facPerCod 
																		  AND f2.facCod = fSub.facCod) 
												  AND (fl2.fclFecLiq IS NULL AND fl2.fclUsrLiq IS NULL)
												GROUP BY f2.facCtrCod
											    ) =(SELECT ISNULL(SUM(cblImporte),0)
													FROM cobros		
													INNER JOIN coblin ON cobScd	=cblScd 
																	 AND cobPpag=cblPpag 
																	 AND cobNum	=cblNum
													WHERE cobCtr	= f.facCtrCod 
													  and cblPer	= f.facPerCod 
													  and cblFacCod = f.facCod
													GROUP BY cobCtr)
											)
										OR EXISTS (	SELECT fclFacCod 
													FROM faclin flSub
													WHERE round(ISNULL(flSub.fcltotal,0) ,2)  = ((ISNULL((SELECT ISNULL(SUM(cblImporte),0)
																								FROM coblin 
																								INNER JOIN cobros ON cobScd=cblScd AND cobPpag=cblPpag AND cobNum=cblNum
																								WHERE cobCtr = flSub.fclFacCtrCod AND 
																									  cblFacCod = flSub.fclFacCod AND 
																									  cblPer = flSub.fclFacPerCod
																								 GROUP BY cobCtr, cblPer, cblFacCod), 0)
																								  * 
																								  ISNULL((SELECT round(ISNULL(sum(fclTotal),0) ,2) 
																												 FROM faclin fi
																												 WHERE fi.fclTrfSvCod = fl.fclTrfSvCod AND
																													   fi.fclFacCod = flSub.fclFacCod  AND
																													   fi.fclFacPerCod = flSub.fclFacPerCod AND
																													   fi.fclFacCtrCod = flSub.fclFacCtrCod AND
																													   fi.fclFacVersion = flSub.fclFacVersion
																										  ), 0)
																								 ) / NULLIF((SELECT round(ISNULL(sum(fclTotal),0) ,2) 
																													FROM faclin fs 
																													WHERE fs.fclFacCod = flSub.fclFacCod  AND
																														  fs.fclFacPerCod = flSub.fclFacPerCod AND
																														  fs.fclFacCtrCod = flSub.fclFacCtrCod AND
																														  fs.fclFacVersion = flSub.fclFacVersion), 0)
																								)
													  AND flSub.fclFacCod		= f.facCod 
													  AND flSub.fclFacPerCod	= f.facPerCod 
													  AND flSub.fclFacCtrCod	= f.facCtrCod 
													  AND flSub.fclFacVersion	= f.facVersion
											      ) 
										OR fl.fclTrfSvCod NOT IN (SELECT servicioCodigo FROM @serviciosExcluidos)
									  )
								    -- fin and @xmlSerCodArray
							    GROUP BY facCtrCod,facCtrVersion,facPerCod,facCod, facSerScdCod
							  ) AS tf ON tf.facCtrCod=c.CtrCod
				                     and (@estado IS NULL -- Todos 
				                      OR (@estado = 'Baja'		AND c.ctrBaja = 1) -- Baja
				                      OR (@estado = 'Activo'	AND c.ctrBaja = 0 AND c.ctrFecAnu IS NULL) -- Activo
				                      OR (@estado = 'Inactivo'	AND c.ctrBaja = 0 AND c.ctrFecAnu IS NOT NULL)) -- Inactivo
                    --FIN Importe facturado para cada contrato (viene con 4 decimales)				
					
					-- INICIO Importe cobrado para cada contrato (viene con 2 decimales)
					LEFT JOIN (	SELECT cobCtr
									 , cblPer
									 , cblFacCod
									--***************
									--Ante el aumento en la precisión el el coblin, redondeamos a 2 decimales.
									, importeCobrado = ROUND(
									    ISNULL(SUM(cblImporte),0) - 
										CASE 
											WHEN (@xmlSerCodArray IS NOT NULL AND (SELECT round(ISNULL(sum(fclTotal),0) ,2) 
																					FROM facturas f 
																					INNER JOIN faclin ON fclFacPerCod	= facPerCod  
																										AND fclFacCtrCod	= facCtrCod 
																										AND fclFacVersion	= facVersion 
																										AND fclFacCod		= facCod
																					WHERE facSerCod IS NOT NULL 
																						AND facSerScdCod IS NOT NULL 
																						AND facNumero IS NOT NULL 
																						AND facVersion = (SELECT MAX(facVersion) 
																										FROM facturas fSub 
																										WHERE f.facCtrCod	= fSub.facCtrCod 
																											AND f.facPerCod	= fSub.facPerCod 
																											AND f.facCod		= fSub.facCod) 
																						AND (@esServicioMedido IS NULL OR EXISTS (SELECT fclNumLinea 
																																FROM facLin
																																INNER JOIN servicios ON fclTrfSvCod		= svcCod 
																																					AND fclFacPerCod	= f.facPerCod 
																																					AND fclFacCtrCod	= f.facCtrCod 
																																					AND fclFacVersion	= f.facVersion 
																																					AND fclFacCod		= f.facCod
																																WHERE (@esServicioMedido = 1 AND svcTipo = 'M') OR (@esServicioMedido = 0 AND svcTipo <> 'M')
																																)
																							)
																						AND (fclFecLiq IS NULL AND fclUsrLiq IS NULL)
																						AND f.facCtrCod	= cobCtr 
																						AND f.facCod		= cblFacCod 
																						AND f.facPerCod	= cblPer
																					GROUP BY facCtrCod,facCtrVersion,facPerCod,facCod, facSerScdCod
																					) <>  
																					(	SELECT ISNULL(SUM(cblImporte),0) 
																					FROM cobros c2
																					INNER JOIN coblin cl2 ON cobScd=cblScd AND cobPpag=cblPpag AND cobNum=cblNum
																					WHERE c2.cobCtr = c.cobCtr 
																					AND cl2.cblPer = cl.cblPer 
																					AND cl2.cblFacCod = cl.cblFacCod
																					GROUP BY cobCtr, cblPer, cblFacCod
																					)
												 )
											THEN (	SELECT SUM(ISNULL(cobroRepartido,0)) 
													FROM (	SELECT ISNULL(ROUND(	(	(SELECT fclTotal
																						FROM faclin fl
																						WHERE fclFacCod = cblFacCod 
																						  AND fclFacPerCod = cblPer 
																						  and fclFacCtrCod = cobCtr 
																						  and fclfacVersion = ( SELECT MAX(facVersion) 
																						  						FROM facturas fSub 
																						  						WHERE fl.fclfacCtrCod	= fSub.facCtrCod 
																						  					      AND fl.fclfacPerCod	= fSub.facPerCod 
																						  					      AND fl.fclfacCod		= fSub.facCod) 
																						  AND (fclFecLiq IS NULL AND fclUsrLiq IS NULL) 
																						  AND fclTrfSvCod = servicioCodigo
																						) / 
																						(SELECT round(ISNULL(sum(fclTotal),0) ,2) 
																						FROM facturas f
																						INNER JOIN faclin fl ON fclFacPerCod = facPerCod  
																						                    AND fclFacCtrCod = facCtrCod 
																											AND fclFacVersion= facVersion 
																											AND fclFacCod	 = facCod
																						WHERE facNumero IS NOT NULL 
																						  AND facPerCod = cblPer 
																						  AND facCtrCod = cobCtr 
																						  AND facCod	= cblFacCod 
																						  AND facVersion= (SELECT MAX(facVersion) 
																											FROM facturas fSub 
																											WHERE f.facCtrCod	= fSub.facCtrCod 
																											AND f.facPerCod		= fSub.facPerCod 
																											AND f.facCod		= fSub.facCod)
																						  AND (fclFecLiq IS NULL AND fclUsrLiq IS NULL)
																						) 
																					) 
																					*
																					(SELECT ISNULL(SUM(cblImporte),0) 
																					FROM cobros c2
																					INNER JOIN coblin cl2 ON cobScd	=cblScd 
																					                     AND cobPpag=cblPpag 
																										 AND cobNum	=cblNum
																					WHERE c2.cobCtr		= c.cobCtr 
																					  AND cl2.cblPer	= cl.cblPer 
																					  AND cl2.cblFacCod = cl.cblFacCod
																					GROUP BY cobCtr, cblPer, cblFacCod)
																				, 2),0) AS cobroRepartido 
															FROM @serviciosExcluidos) AS T
													) 
											ELSE 0
											END
											, 2)
										--***************
										
								FROM cobros c
								INNER JOIN coblin cl ON cobScd	= cblScd 
								                    AND cobPpag	= cblPpag 
								                    AND cobNum	= cblNum
								GROUP BY cobCtr, cblPer, cblFacCod
							  ) AS tc ON tc.cobCtr		= ctrCod 
							         AND tc.cblPer		= tf.facPerCod 
									 AND tc.cblFacCod	= tf.facCod
									 and (		@estado IS NULL -- Todos 
											OR (@estado = 'Baja'	 AND c.ctrBaja = 1)									-- Baja
											OR (@estado = 'Activo'	 AND c.ctrBaja = 0 AND c.ctrFecAnu IS NULL)		-- Activo
											OR (@estado = 'Inactivo' AND c.ctrBaja = 0 AND c.ctrFecAnu IS NOT NULL) -- Inactivo
										  )
					-- FIN Importe cobrado para cada contrato (viene con 2 decimales)
		            WHERE (@contratoD		IS NULL OR	ctrCod		>= @contratoD)
		              AND (@contratoH		IS NULL OR	ctrCod		<= @contratoH)
					  AND (@listaContratos	IS NULL	OR	ctrCod		IN (SELECT ID FROM @tableCtrs))
		              AND (@periodoD		IS NULL OR	facPerCod	>= @periodoD)
		              AND (@periodoH		IS NULL OR	facPerCod	<= @periodoH)
		              AND (facpercod >= ISNULL((SELECT pgsValor FROM parametros WHERE pgsClave = 'PERIODO_INICIO'),'') OR facPerCod like '0000%')
		              AND ctrversion =(SELECT MAX(ctrversion) FROM CONTRATOS C1 WHERE C.ctrcod=C1.ctrcod)			
  		              AND (		@estado IS NULL -- Todos 
		            		OR (@estado = 'Baja'		AND c.ctrBaja = 1)								-- Baja
		            		OR (@estado = 'Activo'		AND c.ctrBaja = 0 AND c.ctrFecAnu IS NULL)		-- Activo
		            		OR (@estado = 'Inactivo'	AND c.ctrBaja = 0 AND c.ctrFecAnu IS NOT NULL)	-- Inactivo
		            	  )
	             ) AS CARTA
			GROUP BY ctrCod
		) AS IMPORTES
	RIGHT JOIN CONTRATOS C								ON C.ctrcod			= IMPORTES.ctrcod
	LEFT JOIN INMUEBLES									ON ctrinmcod		= inmcod 
	LEFT JOIN provincias								on inmPrvCod		= prvCod
	LEFT JOIN poblaciones								on inmPobCod		= pobCod 
													   and inmPrvCod		= pobPrv
	LEFT JOIN municipios								on inmMncCod		= mncCod 
													   and inmPobCod		= mncPobCod 
													   and inmPrvCod		= mncPobPrv
	LEFT JOIN calles									on inmcllcod		= cllcod 
													   and inmmnccod		= cllmnccod 
													   and inmPobCod		= cllPobCod 
													   and inmPrvCod		= cllPrvCod
	LEFT JOIN fContratos_ContadoresInstalados(NULL) v	ON IMPORTES.ctrcod	= v.ctcCtr
	
	WHERE ctrversion = (SELECT MAX(ctrversion) 
						FROM CONTRATOS C1 
						WHERE C.ctrcod=C1.ctrcod) 
	  AND (		@estado IS NULL															-- Todos 
			OR (@estado = 'Baja'		AND c.ctrBaja = 1)								-- Baja
			OR (@estado = 'Activo'		AND c.ctrBaja = 0 AND c.ctrFecAnu IS NULL)		-- Activo
			OR (@estado = 'Inactivo'	AND c.ctrBaja = 0 AND c.ctrFecAnu IS NOT NULL)	-- Inactivo
		  ) 
	AND (@contratoD			IS NULL OR	c.ctrCod		>= @contratoD) 
	AND (@contratoH			IS NULL OR	c.ctrCod		<= @contratoH)
	AND (@listaContratos	IS NULL	OR	c.ctrCod		IN (SELECT ID FROM @tableCtrs))
	AND (@numPeriodosD		IS NULL OR	@numPeriodosD	<= numPeriodosDeuda)
	AND (@numPeriodosH		IS NULL OR	@numPeriodosH	>= numPeriodosDeuda)
	AND (@impDeudaD			IS NULL OR	@impDeudaD		<= (importeFacturado-importeCobrado))
	AND (@impDeudaH			IS NULL OR	@impDeudaH		>= (importeFacturado-importeCobrado))
	AND (		@xmlIncLecUltFac IS NULL 
			OR EXISTS (	SELECT facLecInlCod 
						FROM facturas f	
						INNER JOIN @incidenciasLecturaUltimaFactura ON f.facLecInlCod = incidenciaCodigo
						WHERE f.facFecReg = (SELECT MAX(facFecReg) 
											FROM facturas f2 
											WHERE f2.facCtrCod = f.facCtrCod 
											AND facPerCod NOT LIKE '0%' 
											AND facPerCod NOT LIKE '9%')
					      AND f.facCtrCod = C.ctrcod
					      AND f.facPerCod NOT LIKE '0%' 
						  AND f.facPerCod NOT LIKE '9%'
					  )			    			
		 )
	AND (		@xmlIncLecAlgunaFac IS NULL 
			OR EXISTS (	SELECT facLecInlCod 
						FROM facturas f	INNER JOIN @incidenciasLecturaAlgunaFactura ON f.facLecInlCod = incidenciaCodigo
						WHERE (f.facPerCod >= @periodoD OR @periodoD IS NULL)
					      AND (f.facPerCod <= @periodoH OR @periodoH IS NULL)	
					      AND  f.facCtrCod = C.ctrcod)
		 )
	AND (		@incluirEfectosPendientes IS NULL 
			OR @incluirEfectosPendientes = 1 
			OR ( NOT EXISTS(SELECT facCod 
							FROM facturas f INNER JOIN efectosPendientes ON efePdteCtrCod	= f.facCtrCod 
							                                            AND efePdtePerCod	= f.facPerCod 
							                                            AND efePdteFacCod	= f.facCod 
							                                            AND efePdteScd		= f.facSerScdCod
							WHERE  (f.facPerCod >= @periodoD OR @periodoD IS NULL) 
							--Si el contrato tiene efectos pendientes en cualquier periodo de los seleccionados, ya no saldría dicho contrato
							AND (f.facPerCod <= @periodoH OR @periodoH IS NULL)	
							AND f.facCtrCod = c.ctrcod
							AND efePdteFecRechazado IS NULL)
			   )
		 )
	AND (	   @incluirClientesVip IS NULL
			OR @incluirClientesVip = 1 
			OR ( NOT EXISTS(SELECT clicod 
							FROM clientes
							INNER JOIN contratos c1 ON ctrTitCod = clicod 
												   AND ctrversion =(SELECT MAX(ctrversion) 
																	FROM contratos cSub 
																	WHERE c1.ctrcod = cSub.ctrcod)
							WHERE c.ctrcod = ctrcod 
							  AND cliTvipCodigo IS NOT NULL)
			    )
		)
		/*
		 * jcg 10/06/2019, Fernando me pie que se quite esta condicion para emitir cartas aun teniendo el campo ctrNoEmision = 1, 
		 * ya que almaden no le permitia emitir carta devoluciones
		 */
	--AND (ISNULL(ctrNoEmision, 0) = 0 or @expl ='Almadén')
	--AND ISNULL(ctrNoEmision, 0) = 0	
	AND (ctrzoncod >= @zonaD	OR @zonaD IS NULL)
	AND (ctrzoncod <= @zonaH	OR @zonaH IS NULL)
	AND	(@domiciliado IS NULL	OR (@domiciliado = 1 AND ctrIBAN IS NOT NULL AND ctrIBAN<>'') OR (@domiciliado = 0 AND (ctrIBAN IS NULL OR ctrIBAN='')))
	-- Rutas
	AND (ctrRuta1 >= @ruta1D	or @ruta1D is null)
	AND (ctrRuta1 <= @ruta1H	or @ruta1H is null)
	AND (ctrRuta2 >= @ruta2D	or @ruta2D is null)
	AND (ctrRuta2 <= @ruta2H	or @ruta2H is null)
	AND (ctrRuta3 >= @ruta3D	or @ruta3D is null)
	AND (ctrRuta3 <= @ruta3H	or @ruta3H is null)
	AND (ctrRuta4 >= @ruta4D	or @ruta4D is null)
	AND (ctrRuta4 <= @ruta4H	or @ruta4H is null)
	AND (ctrRuta5 >= @ruta5D	or @ruta5D is null)
	AND (ctrRuta5 <= @ruta5H	or @ruta5H is null)
	AND (ctrRuta6 >= @ruta6D	or @ruta6D is null)
	AND (ctrRuta6 <= @ruta6H	or @ruta6H is null)
	-- Representante
	AND (@xmlRepresentantesArray is null OR (ctrRepresent not in (select representante from @representantesExcluidos)) OR ctrRepresent is null)
	AND (		@soloDevoluciones IS NULL 
			OR  @soloDevoluciones = 0
			OR (	@soloDevoluciones = 1 
				AND EXISTS(	SELECT cobCtr, cblPer, cblFacCod
							FROM cobros
							INNER JOIN coblin cl ON cobScd	=cblScd 
												AND cobPpag	=cblPpag 
												AND cobNum	=cblNum
							WHERE cobCtr = c.ctrCod 
							  AND (@bancoCodigo IS NULL OR cobPpag = (SELECT banPpag FROM bancos WHERE banCod = @bancoCodigo)) 
							  AND (@cobroFecReg IS NULL OR CONVERT(date, cobfecreg) = @cobroFecReg) 
							  AND cobOrigen = 'Devolucion'
							GROUP BY cobCtr, cblPer, cblFacCod
						  ) 
				AND (@importeMinimoDevolucion IS NULL OR (importeFacturado-importeCobrado) >= ISNULL(@importeMinimoDevolucion,0))
			   )
		)
	ORDER BY CASE @orden 
				WHEN 'suministro'	THEN (	SELECT top 1 inmdireccion 
											FROM inmuebles INNER JOIN contratos cSum ON ctrCod	 = cSum.ctrcod 
																					AND ctrinmcod= inmcod)
				WHEN 'contrato'		THEN CAST(REPLICATE('0',10-LEN(CAST(C.ctrCod AS VARCHAR))) + CAST(C.ctrCod AS VARCHAR) AS VARCHAR)
				ELSE
					  REPLICATE('0',10-LEN(ISNULL(ctrRuta1,''))) + ISNULL(ctrRuta1,'') 
					+ REPLICATE('0',10-LEN(ISNULL(ctrRuta2,''))) + ISNULL(ctrRuta2,'')
					+ REPLICATE('0',10-LEN(ISNULL(ctrRuta3,''))) + ISNULL(ctrRuta3,'')
					+ REPLICATE('0',10-LEN(ISNULL(ctrRuta4,''))) + ISNULL(ctrRuta4,'')
					+ REPLICATE('0',10-LEN(ISNULL(ctrRuta5,''))) + ISNULL(ctrRuta5,'')
					+ REPLICATE('0',10-LEN(ISNULL(ctrRuta6,''))) + ISNULL(ctrRuta6,'')
		END

	--SELECT ID FROM @tableCtrs

/*

EXEC CartasEmision_Select @contratoD=9,@contratoH=90

EXEC CartasEmision_Select @contratoD=10,@contratoH=10

EXEC CartasEmision_Select @contratoD=9,@contratoH=11

EXEC CartasEmision_Select @listaContratos='105,355,357,606,1063,1122,1376,1571,2012,2479,2527,2532,2730,2821,3092,3840,4027,4180,4230,4623'
*/


GO


