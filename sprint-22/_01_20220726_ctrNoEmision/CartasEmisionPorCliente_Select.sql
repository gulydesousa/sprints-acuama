ALTER PROCEDURE [dbo].[CartasEmisionPorCliente_Select]
	@numPeriodosD INT = NULL,
	@periodoD VARCHAR(6) = NULL,
	@periodoH VARCHAR(6) = NULL,
	@clienteD INT = NULL,
	@clienteH INT = NULL,
	@impDeudaD MONEY = NULL,
	@impDeudaH MONEY = NULL,
	@domiciliado BIT = NULL,
	@esServicioMedido BIT = NULL,
	@numPeriodosH INT = NULL,
	@xmlSerCodArray TEXT = NULL,
	@importeMinimoDevolucion MONEY = NULL,
	@bancoCodigo SMALLINT = NULL,
	@cobroFecReg DATETIME = NULL,
	@soloDevoluciones BIT = NULL,
	@xmlRepresentantesArray	TEXT = NULL
	
  , @excluirNoEmitir BIT= 1	--@excluirNoEmitir=1: Para sacar solo las cartas a los contratos con ctrNoEmision=0
AS 
	SET NOCOUNT ON;


DECLARE @idoc INT
IF @xmlSerCodArray IS NOT NULL BEGIN
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



SELECT  clicod, ctrRepresent,
		clinom, clidociden, clidomicilio, clicpostal, clipoblacion, cliprovincia, clinacion,
		clicnombre, clicdomicilio, cliccpostal, clicpoblacion, clicprovincia, clicnacion,
		pobdes, pobcpos, prvdes, 
		(CASE WHEN LEN(cliIban) >= 24 AND LEN(cliIban) <= 34 THEN LEFT(cliIban,4) + SUBSTRING(cliIban,5,4) + SUBSTRING(cliIban,9,4) + REPLICATE('*',2) + REPLICATE('*',6) + RIGHT(cliIban,4) ELSE  '---' END) AS iban,
		GETDATE() as fecha,
		ISNULL(importeCobrado,0) AS importeCobrado,
		ISNULL(importeFacturado,0) AS importeFacturado,
		ISNULL(numPeriodosDeuda,0) as periodosConDeudaPorCliente
FROM 
(
SELECT ctrtitcod, ctrRepresent, sum(deuda) AS numPeriodosDeuda, sum(importeCobrado) as importeCobrado, sum(importeFacturado) as importeFacturado, 
	   sum(importeFacturado) - sum(importeCobrado) AS importeDeuda   
	   FROM
		( SELECT   ctrTitCod,
					ctrcod,
					ctrRepresent,
					facPerCod as periodo,
					ISNULL(importeCobrado,0) AS importeCobrado,
					ROUND(ISNULL(importeFacturado,0), 2) AS importeFacturado,
					CASE WHEN ROUND(ISNULL(importeFacturado,0), 2) > ROUND(ISNULL(importeCobrado,0),2) THEN 1 ELSE 0 END as deuda
				FROM CONTRATOS AS C
				--Importe facturado para cada contrato (viene con precision de 4 decimales)
				LEFT JOIN	(SELECT facCtrCod,facCliCod,ROUND(ISNULL(sum(fclTotal),0),2) AS importeFacturado, facPerCod, facCod, facSerScdCod
									FROM facturas f 
									INNER JOIN faclin fl ON fclFacPerCod = facPerCod  AND fclFacCtrCod = facCtrCod AND fclFacVersion = facVersion AND fclFacCod = facCod
									INNER JOIN contratos ON ctrcod = facCtrCod AND ctrversion = facCtrVersion
									WHERE facSerCod IS NOT NULL AND facSerScdCod IS NOT NULL AND facNumero IS NOT NULL AND
										  facVersion = (SELECT MAX(facVersion) FROM facturas fSub WHERE f.facCtrCod = fSub.facCtrCod AND f.facPerCod = fSub.facPerCod AND f.facCod = fSub.facCod) AND
										  (@esServicioMedido IS NULL OR EXISTS 
											  (SELECT fclNumLinea 
												FROM 
													facLin
													INNER JOIN servicios ON fclTrfSvCod = svcCod AND 
													fclFacPerCod = f.facPerCod AND 
													fclFacCtrCod = f.facCtrCod AND 
													fclFacVersion = f.facVersion AND
													fclFacCod = f.facCod
													
												WHERE 
													(@esServicioMedido = 1 AND svcTipo = 'M') OR 
													(@esServicioMedido = 0 AND svcTipo <> 'M') 
												)) AND 
										 (fclFecLiq IS NULL AND fclUsrLiq IS NULL) AND 
										 (ctrTitCod>= @clienteD OR @clienteD IS NULL) AND 
										 (ctrTitCod<= @clienteH OR @clienteH IS NULL) AND
										 (
											@xmlSerCodArray IS NULL 									  
											OR
										   (
											(SELECT ROUND(ISNULL(SUM(fl2.fclTotal),0),2)
												   FROM facturas f2 
												   INNER JOIN faclin fl2 ON fclFacPerCod = facPerCod  AND fclFacCtrCod = facCtrCod AND fclFacVersion = facVersion AND fclFacCod = facCod
												   WHERE f2.facCtrCod = f.facCtrCod and f2.facPerCod = f.facPerCod and f2.facCod = f.facCod AND
														 f2.facSerCod IS NOT NULL AND f2.facSerScdCod IS NOT NULL AND f2.facNumero IS NOT NULL AND
														 f2.facVersion = (SELECT MAX(facVersion) FROM facturas fSub WHERE f2.facCtrCod = fSub.facCtrCod AND f2.facPerCod = fSub.facPerCod AND f2.facCod = fSub.facCod) AND
														 
														(fl2.fclFecLiq IS NULL AND fl2.fclUsrLiq IS NULL)
											   GROUP BY f2.facCtrCod
											  ) 
											  = 
											  (SELECT ROUND(ISNULL(SUM(cblImporte),0),2)
													FROM cobros 
													INNER JOIN coblin ON cobScd=cblScd AND cobPpag=cblPpag AND cobNum=cblNum
													WHERE cobCtr = f.facCtrCod and cblPer = f.facPerCod and cblFacCod = f.facCod
												GROUP BY cobCtr
											   )
											)
											OR 
											EXISTS (SELECT fclFacCod 
														 FROM faclin flSub
														 WHERE ROUND(ISNULL(flSub.fcltotal,0),2) = (
																				(ISNULL((SELECT  ROUND(ISNULL(SUM(cblImporte),0),2)
																								FROM coblin 
																								INNER JOIN cobros ON cobScd=cblScd AND cobPpag=cblPpag AND cobNum=cblNum
																								WHERE cobCtr = flSub.fclFacCtrCod AND 
																									  cblFacCod = flSub.fclFacCod AND 
																									  cblPer = flSub.fclFacPerCod
																								 GROUP BY cobCtr, cblPer, cblFacCod), 0)
																				  * 
																				  ISNULL((SELECT ROUND(ISNULL(SUM(fcltotal),0),2)
																								 FROM faclin fi
																								 WHERE fi.fclTrfSvCod = fl.fclTrfSvCod AND
																									   fi.fclFacCod = flSub.fclFacCod  AND
																									   fi.fclFacPerCod = flSub.fclFacPerCod AND
																									   fi.fclFacCtrCod = flSub.fclFacCtrCod AND
																									   fi.fclFacVersion = flSub.fclFacVersion
																						  ), 0)
																				 ) / NULLIF((SELECT ROUND(ISNULL(SUM(fclTotal),0) ,2)
																									FROM faclin fs 
																									WHERE fs.fclFacCod = flSub.fclFacCod  AND
																										  fs.fclFacPerCod = flSub.fclFacPerCod AND
																										  fs.fclFacCtrCod = flSub.fclFacCtrCod AND
																										  fs.fclFacVersion = flSub.fclFacVersion), 0)
																				) AND
															  flSub.fclFacCod = f.facCod AND
															  flSub.fclFacPerCod = f.facPerCod AND
															  flSub.fclFacCtrCod = f.facCtrCod AND
															  flSub.fclFacVersion = f.facVersion
											   ) OR fl.fclTrfSvCod NOT IN (SELECT servicioCodigo 
																				  FROM @serviciosExcluidos)
										  )
							 GROUP BY facCtrCod, facCliCod, facCtrVersion, facPerCod, facCod, facSerScdCod) AS tf
							 ON tf.facCtrCod=c.CtrCod AND tf.facCliCod = c.ctrTitCod
				--Importe cobrado para cada contrato (viene con precision de 2 decimales)
				LEFT JOIN 	(SELECT cobCtr,ROUND(ISNULL(SUM(cblImporte),0),2) - 
									CASE WHEN (@xmlSerCodArray IS NOT NULL AND 
											  (SELECT ROUND(ISNULL(SUM(fclTotal),0),2)	
															FROM facturas f 
															INNER JOIN faclin ON fclFacPerCod = facPerCod  AND fclFacCtrCod = facCtrCod AND fclFacVersion = facVersion AND fclFacCod = facCod
															WHERE facSerCod IS NOT NULL AND facSerScdCod IS NOT NULL AND facNumero IS NOT NULL AND
																  facVersion = (SELECT MAX(facVersion) FROM facturas fSub WHERE f.facCtrCod = fSub.facCtrCod AND f.facPerCod = fSub.facPerCod AND f.facCod = fSub.facCod) AND
																 (@esServicioMedido IS NULL OR 
																  EXISTS (SELECT fclNumLinea 
																				FROM facLin
																				INNER JOIN servicios ON fclTrfSvCod = svcCod AND fclFacPerCod = f.facPerCod AND fclFacCtrCod = f.facCtrCod AND fclFacVersion = f.facVersion AND fclFacCod = f.facCod
																				WHERE (@esServicioMedido = 1 AND svcTipo = 'M') OR 
															 						  (@esServicioMedido = 0 AND svcTipo <> 'M') 
																		)
																 ) AND (fclFecLiq IS NULL AND fclUsrLiq IS NULL)
																	 AND f.facCtrCod = cobCtr 
																	 AND f.facCod = cblFacCod 
																	 AND f.facPerCod = cblPer
													GROUP BY facCtrCod,facCtrVersion,facPerCod,facCod, facSerScdCod) 
													<>  (SELECT ROUND(ISNULL(SUM(cblImporte),0),2) 
																FROM cobros c2
																INNER JOIN coblin cl2 ON cobScd=cblScd AND cobPpag=cblPpag AND cobNum=cblNum
																WHERE c2.cobCtr = c.cobCtr AND
																	  cl2.cblPer = cl.cblPer AND
																	  cl2.cblFacCod = cl.cblFacCod
															GROUP BY cobCtr, cblPer, cblFacCod
														)
													)
													THEN ( SELECT ROUND(SUM(ISNULL(cobroRepartido,0)),2) FROM 
																	(SELECT ISNULL(ROUND(
																			 (
																			 (SELECT ROUND(ISNULL(SUM(fclTotal),0),2)
																					 FROM faclin fl
																					 WHERE fclFacCod = cblFacCod AND 
																						   fclFacPerCod = cblPer and
																						   fclFacCtrCod = cobCtr and
																						   fclfacVersion = (SELECT MAX(facVersion) FROM facturas fSub WHERE fl.fclfacCtrCod = fSub.facCtrCod AND fl.fclfacPerCod = fSub.facPerCod AND fl.fclfacCod = fSub.facCod) AND
																						  (fclFecLiq IS NULL AND fclUsrLiq IS NULL) AND
																						   fclTrfSvCod = servicioCodigo
																			 )
																			 / 
																			(SELECT ROUND(ISNULL(SUM(fclTotal),0),2)
																					FROM facturas f
																					INNER JOIN faclin fl ON fclFacPerCod = facPerCod  AND fclFacCtrCod = facCtrCod AND fclFacVersion = facVersion AND fclFacCod = facCod
																					WHERE facNumero IS NOT NULL AND	
																						  facPerCod = cblPer AND
																						  facCtrCod = cobCtr AND
																						  facCod = cblFacCod AND
																						  facVersion = (SELECT MAX(facVersion) FROM facturas fSub WHERE f.facCtrCod = fSub.facCtrCod AND f.facPerCod = fSub.facPerCod AND f.facCod = fSub.facCod) AND
																						 (fclFecLiq IS NULL AND fclUsrLiq IS NULL)
																			)
																			)*(SELECT ROUND(ISNULL(SUM(cblImporte),0),2) 
																					FROM cobros c2
																					INNER JOIN coblin cl2 ON cobScd=cblScd AND cobPpag=cblPpag AND cobNum=cblNum
																					WHERE c2.cobCtr = c.cobCtr AND
																						  cl2.cblPer = cl.cblPer AND
																						  cl2.cblFacCod = cl.cblFacCod
																				GROUP BY cobCtr, cblPer, cblFacCod), 2),0) AS cobroRepartido 
																		FROM @serviciosExcluidos) AS T
														) 
												ELSE 0
												END AS importeCobrado, cblPer, cblFacCod
					FROM cobros c
					INNER JOIN coblin cl ON cobScd=cblScd AND cobPpag=cblPpag AND cobNum=cblNum
				GROUP BY cobCtr, cblPer, cblFacCod) AS tc
				ON tc.cobCtr = ctrCod AND tc.cblPer = tf.facPerCod AND tc.cblFacCod = tf.facCod
				WHERE   (facpercod >= ISNULL((SELECT pgsValor FROM parametros WHERE pgsClave = 'PERIODO_INICIO'),'') OR facPerCod like '0000%')
						AND ctrversion =(SELECT MAX(ctrversion) FROM CONTRATOS C1 WHERE C.ctrcod=C1.ctrcod)
						AND (facPerCod>= @periodoD OR @periodoD IS NULL)
						AND (facPerCod<= @periodoH OR @periodoH IS NULL)	
						AND (ctrTitCod>= @clienteD OR @clienteD IS NULL)
						AND (ctrTitCod<= @clienteH OR @clienteH IS NULL)
						AND (@soloDevoluciones IS NULL OR  @soloDevoluciones = 0
							 OR (@soloDevoluciones = 1 AND EXISTS(SELECT cobCtr, cblPer, cblFacCod
																		FROM cobros
																		INNER JOIN coblin cl ON cobScd=cblScd AND cobPpag=cblPpag AND cobNum=cblNum
																		WHERE  cobCtr = ctrcod AND
																			  (@bancoCodigo IS NULL OR cobPpag = (SELECT banPpag FROM bancos WHERE banCod = @bancoCodigo)) AND 
																			  (@cobroFecReg IS NULL OR CONVERT(date, cobfecreg) = @cobroFecReg) AND
																			   cobOrigen = 'Devolucion'
																		GROUP BY cobCtr, cblPer, cblFacCod
																) AND (@importeMinimoDevolucion IS NULL OR (importeFacturado-importeCobrado) >= ISNULL(@importeMinimoDevolucion,0)) 
								)
							) 
			) AS CARTA
			GROUP BY ctrtitcod, ctrRepresent
) AS IMPORTES
	INNER JOIN clientes ON clicod = ctrtitcod
	LEFT JOIN provincias on cliprovincia = prvCod
	LEFT JOIN poblaciones on clipoblacion = pobCod and cliprovincia = pobPrv
WHERE (clicod>= @clienteD OR @clienteD IS NULL) AND 
	  (clicod<= @clienteH OR @clienteH IS NULL) AND 
	  (@numPeriodosD IS NULL OR @numPeriodosD <= numPeriodosDeuda) AND 
	  (@numPeriodosH IS NULL OR @numPeriodosH >= numPeriodosDeuda) AND 
	  (@impDeudaD IS NULL OR @impDeudaD <= (importeFacturado-importeCobrado)) AND 
	  (@impDeudaH IS NULL OR @impDeudaH >= (importeFacturado-importeCobrado)) AND	
	  (@domiciliado IS NULL OR (@domiciliado = 1 AND cliIban IS NOT NULL AND cliIban<>'') OR (@domiciliado = 0 AND (cliIban IS NULL OR cliIban='')))
	  -- Representante 
	  AND (@xmlRepresentantesArray is null OR (ctrRepresent not in (select representante from @representantesExcluidos)) OR ctrRepresent is null)
ORDER BY clicod 

GO


