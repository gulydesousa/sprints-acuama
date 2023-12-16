
--=============================================================================================================
 --Autor: Carlos Díaz
 --Fecha de creación: 10/11/2021
 --Descripción:	Se modifican los cursores para que contemplen un cobro parcial por apremio
--=============================================================================================================
 --Autor: Carlos Díaz
 --Fecha de creación: 23/04/2020
 --Descripción:	Se modifica prácticamente todo el procedimiento para que funcione correctamente y 
 --				contemple entregas a cuenta
 --=============================================================================================================
 --Autor: Pablo Abad
 --Fecha de creación: 23/04/2018
 --Descripción:	Proceso que actualiza los apremios cobrados
 --Parámetros:
 --		@p_lineas: líneas que componen los apremios a actualizar
 --=============================================================================================================
ALTER PROCEDURE [dbo].[CobrosApremios_Ods_Upload]
	 @p_lineas NVARCHAR(MAX),
	 @p_generarCobro INT,
	 @p_Usuario VARCHAR(10)
AS
BEGIN
	SET NOCOUNT ON;

		/* Ej. XML
		<NodoXML>
			<LI>
				<Periodo>200903</Periodo>
				<Numero>25509</Numero>
				<Anio>2010</Anio>
				<Titular>ABAD RICOTE PABLO</Titular>
				<Importe>25</Importe>
				<Fecha>10/04/2015</Fecha>
				<Contrato>123456</Contrato>
            </LI>
		</NodoXML>
		*/
	
	BEGIN TRY

		--BEGIN TRAN
		
		-- Creamos una tabla con todos las facturas
		DECLARE @xml AS XML = @p_lineas

		DECLARE @cobroApremios TABLE
			(periodo varchar(6),
			 numero varchar(100),
			 anio VARCHAR(6),
			 titular varchar(max),
			 importe DECIMAL(18, 2) NULL,
			 fecha varchar(10) NULL,
			 contrato int
			 )
			
	     DECLARE @resultado TABLE
			(periodo varchar(6),
			 numero varchar(100),
			 anio VARCHAR(6),
			 titular varchar(max),
			 importe DECIMAL(18, 2) NULL,
			 ctrcod varchar(10),
			 fecha datetime,
			 actualizado smallint,
			 cobrado smallint,
			 fechaRegAyto datetime,
			 fechaRegAcuama datetime
			 )

		/* Insertamos los datos del xml a la tabla temporal */
		INSERT INTO @cobroApremios (periodo, numero, anio, titular, importe, fecha, contrato)
			 SELECT M.Item.value('Periodo[1]', 'VARCHAR(6)'),
				    M.Item.value('Numero[1]', 'VARCHAR(100)'),
				    M.Item.value('Anio[1]', 'INT'),	
				    M.Item.value('Titular[1]', 'VARCHAR(max)'),		   
				    M.Item.value('Importe[1]', 'DECIMAL(18,2)'),
				    M.Item.value('Fecha[1]', 'VARCHAR(10)'),
				    M.Item.value('Contrato[1]', 'INT')
			   FROM @xml.nodes('NodoXML/LI')AS M(Item) 		
	
		DECLARE @fechaAct as Datetime = Getdate();
		DECLARE @restante as money = 0
		DECLARE @apremioCompletado as bit = 0


		--************************************
		--Por si se ha deshabilitado el trigger:
		--Actualizamos los totales por factura
		DECLARE @FAC AS dbo.tFacturasPK;
		INSERT INTO @FAC(facCod, facPerCod, facCtrCod, facVersion)
		
		SELECT DISTINCT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion
		FROM @cobroApremios AS C
		INNER JOIN dbo.facturas AS F
		ON F.facPerCod = C.periodo AND C.numero = F.facNumero AND C.contrato = F.facCtrCod;


		EXEC FacTotales_Update @FAC;
		
		--************************************
		--Con el importe de los cobros se salda el apremio de cada factura?
		WITH TOTALES AS(
		SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion
		, Total = SUM(Importe)
		FROM @cobroApremios AS C
		INNER JOIN dbo.facturas  AS F
		ON F.facPerCod = C.periodo AND C.numero = F.facNumero AND C.contrato = F.facCtrCod
		GROUP BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion)

		UPDATE A SET aprCobrado=1, aprFechaFichCobrado= @fechaAct
		FROM  dbo.apremios AS A
		INNER JOIN TOTALES AS T
		ON  T.facCod = A.aprFacCod
		AND T.facPerCod = A.aprFacPerCod
		AND T.facCtrCod = A.aprFacCtrCod
		AND T.facVersion = A.aprFacVersion	
		INNER JOIN dbo.facTotales AS FT
		ON  FT.fctCod = T.facCod
		AND FT.fctVersion = T.facVersion
		AND FT.fctCtrCod = T.facCtrCod
		AND FT.fctPerCod = T.facPerCod
		--El total de los apremios cubre la deuda
		AND FT.fctDeuda <= T.Total
		--************************************

		--necesito traer a los cursores tmb las facturas con importe superior a los apremios cobrados, para realizar cobros parciales
		/* Actualizamos los apremios correspondientes a las facturas */
		--sólo pongo cobrado a 1 si se ha cobrado el total o más de la factura
		/*
		UPDATE apremios
		   SET aprCobrado=1,
			   aprFechaFichCobrado= @fechaAct
				FROM
				(
				SELECT a.aprFacPerCod,a.aprFacCtrCod, a.aprNumero, a.aprFacVersion, ca.importe,sum(l.fcltotal) total, facCod 
				from facturas f
				INNER JOIN apremios a
				ON a.aprFacPerCod= facPerCod and a.aprFacCtrCod = facCtrCod and a.aprFacCod = facCod and a.aprFacVersion = facVersion
				INNER JOIN @cobroApremios ca 
				ON a.aprFacPerCod = ca.periodo and ca.numero = f.facNumero and a.aprFacCtrCod = ca.contrato
				INNER JOIN faclin l 
				ON f.facpercod = l.fclFacPerCod and f.facCod = l.fclFacCod and f.facCtrCod = l.fclFacCtrCod and f.facVersion = l.fclFacVersion
				WHERE f.facnumero= ca.numero
				and f.facPerCod= ca.periodo
				and a.aprFacVersion = (SELECT max(facVersion) FROM facturas 
										WHERE FacPerCod= f.facPerCod 
										  and facCod=f.facCod
										  and facCtrCod=f.facCtrCod
									   )
				GROUP BY a.aprFacPerCod,a.aprFacCtrCod, a.aprNumero, a.aprFacVersion, ca.importe, facCod
				HAVING ca.importe >= SUM(l.fcltotal)
				) t
				WHERE apremios.aprFacPerCod= t.aprFacPerCod 
				and apremios.aprFacCtrCod= t.aprFacCtrCod
				and apremios.aprNumero= t.aprNumero
				and apremios.aprFacCod = t.facCod
				and apremios.aprCobrado=0

		*/

		--tabla temporal donde indicaré si cada registro que me llega está en apremio o no previamente
		SELECT ca.*, f.facNumero, f.facFecha, f.facCod, f.facCtrCod, f.facPerCod, f.facVersion, 
			aprNumero, cast(aprCobrado as int) aprCobrado, cast(aprCobradoAcuama as int) aprCobradoAcuama, aprFecRegCobrado, aprFecRegCobradoAcuama,
			CAST(NULL AS int) as cobradoSinApremio, 
			CAST(NULL AS int) as cobradoAnteriorSinApremio, 
			CAST(NULL AS datetime) as fecCobradoSinApremio
		INTO #cobroApremiosFichero
		from @cobroApremios ca 
		LEFT JOIN facturas f
			ON f.facPerCod = ca.periodo and ca.numero = f.facNumero and ca.contrato = f.facCtrCod
		LEFT JOIN apremios a
			ON a.aprFacPerCod = f.facPerCod and a.aprFacCtrCod = facCtrCod and a.aprFacCod = f.facCod and a.aprFacVersion = facVersion


		/* Traemos el Importe Cobrado */
		IF @p_generarCobro=1
		BEGIN
		
			DECLARE @numero varchar(100)
			DECLARE @contrato int
			DECLARE	@periodo varchar(6) = NULL
			DECLARE	@fec varchar(10) = NULL
			DECLARE	@codigo smallint = NULL --código de la factura
			--	@fecRegistroMaxima datetime = NULL,
			--	@periodosSaldo BIT = NULL,
			--	@medioPago SMALLINT = NULL,
			--	@puntoPago SMALLINT = NULL,
			DECLARE	@facturaVersion SMALLINT = NULL
			--	@lineaFactura INT = NULL,
			--	@lineaCobro SMALLINT = NULL,
			DECLARE @imp decimal(11,2) = NULL
			DECLARE @impCobr decimal(11,2) = NULL
			DECLARE @impFact DECIMAL(11,2)  = NULL
			DECLARE @numApremio INT = NULL
			DECLARE @sociedad SMALLINT= NULL
					
			DECLARE @pPago AS SMALLINT  = (SELECT pgsvalor FROM parametros WHERE pgsclave = 'PUNTO_PAGO_APREMIOS')
			DECLARE @medPago AS SMALLINT = (SELECT pgsvalor FROM parametros WHERE pgsclave = 'MEDIO_PAGO_APREMIOS')
			DECLARE @pPagoEACuenta AS SMALLINT = (SELECT pgsvalor FROM parametros WHERE pgsclave = 'PUNTO_PAGO_ENTREGAS_A_CTA')
			DECLARE @medPagoEACuenta AS SMALLINT = (SELECT pgsvalor FROM parametros WHERE pgsclave = 'MEDIO_PAGO_ENTREGAS_A_CTA')
			DECLARE @periodoEACuenta varchar(6) = '999999'
			DECLARE @cobNumero AS INTEGER
			DECLARE @linea AS INTEGER
			DECLARE @myError AS INT
			DECLARE @importe AS MONEY -- Facturado - cobrado
			DECLARE @serie AS SMALLINT
			DECLARE @facContrato AS INT 
			DECLARE @facPerCod AS VARCHAR(6) 
			DECLARE @facCod SMALLINT 
			DECLARE @facVersion SMALLINT -- Los de la factura
			DECLARE @concepto AS VARCHAR(100)  -- 'Apremio: #NÚM APREMIO#. Fecha: #LA DEL DÍA DD/MM/YYYY#'
			declare @EACuentaAnterior int = 0
			declare @CobroFicheroApremioAnterior int = 0
			

			-- Primer cursor para facturas en apremios
			DECLARE cActualizados CURSOR FOR
					SELECT ca.numero,
						   periodo,
						   facCtrCod ctrcod,
						   ca.importe as importe,
						   ca.fecha as fecha,
						   facVersion as vers,
						   faccod as codigo,
						   aprNumero,
						   facSerScdCod sociedad 
					  FROM @cobroApremios ca  
					  INNER JOIN facturas
					  ON facturas.facnumero= ca.numero and facturas.facPerCod= ca.periodo and facturas.facCtrCod = ca.contrato
					  INNER JOIN apremios 
					  ON facCod=aprFacCod AND facPerCod=aprFacPerCod AND facCtrCod=aprFacCtrCod AND facVersion=aprFacVersion and ((aprCobrado=1 /*and aprFechaFichCobrado=@fechaAct*/) OR (aprCobrado=0 and aprFechaFichCobrado is null))	
					  INNER JOIN fFacturas_TotalFacturado(NULL, 0, NULL) ON ftfFacCod=facCod AND ftfFacPerCod=facPerCod  AND ftfFacCtrCod=facCtrCod AND ftfFacVersion=facVersion
				   --ahora contemplo cobros parciales, así como cobro + EAC
				   --where ftfImporte >= ca.importe	
					--AND aprCobradoAcuama = 0 --De esta forma me aseguro no realizar un cobro duplicado (o entrega a cuenta) de una factura en apremio
					AND facFechaRectif IS NULL
				ORDER BY  ca.numero, periodo, facCtrCod

				OPEN cActualizados
				FETCH NEXT FROM cActualizados
				INTO @numero, @periodo,@contrato,@imp, @fec, @facturaVersion,@codigo, @numApremio, @sociedad
				WHILE @@FETCH_STATUS = 0
				BEGIN
				
				--Importe Cobrado
				  Exec [dbo].[Cobros_ImporteCobrado] @contrato, @periodo, @codigo, null, null,null, null, null, null, null, @impCobr output

				--Importe facturado
				  Exec [dbo].[Facturas_ImporteFacturado] @codigo,@contrato, @periodo, null ,NULL,0, NULL, @impFact output			
				
				-- Valoramos posibles cobros parciales
				-- Si el cobro del apremio + cobrado es menor que la factura
				IF(@impFact >= (@imp + isnull(@impCobr, 0)))
				BEGIN 
					SET @concepto = 'Apremio parcial: '  + CONVERT(VARCHAR, @numApremio) + '.Fecha:' + @fec
					SET @importe = @imp  
					                                                                
					--Insertamos la cabecera del cobro
					EXEC @myError = Cobros_Insert @sociedad, @pPago, @p_Usuario, @fechaAct, @contrato, NULL, NULL, @importe, @medPago, 
								NULL, NULL, NULL, NULL, NULL, NULL, @concepto, NULL, NULL, NULL, NULL, @cobNumero OUTPUT, 'Apremio', @fechaAct
                                        
					--Insertamos la línea 
					EXEC @myError = CobLin_Insert @sociedad, @ppago, @cobNumero, @codigo, @periodo, @facturaVersion, @importe, @linea OUTPUT
					
					--Si todo ha ido bien, actualizamos el campo aprCobradoAcuama=2 de la tabla Apremios, para indicar cobro parcial
					IF @myError=0		
					BEGIN	
						--Actualizo mi tabla temporal
						update #cobroApremiosFichero
						set 
							aprCobradoAcuama=2,
							aprFecRegCobradoAcuama=@fechaAct
						WHERE facCod=@codigo
							AND facCtrCod=@contrato
							AND facPerCod=@periodo
							AND facVersion=@facturaVersion
							--AND aprCobrado=0
							--AND aprCobradoAcuama=0
					END	
				END
				ELSE
				BEGIN
					-- Esta opción implica que ya estaba cobrado en Acuama y también se ha cobrado en el ayuntamiento, por lo que se genera un cobro de entrega a cuenta
					-- Actualizamos el campo aprCobradoAcuama=1 de la tabla Apremios
					IF (@impFact <= isnull(@impCobr, 0))	
					BEGIN

						set @EACuentaAnterior = 0
					
						--SET @EACuentaAnterior = (SELECT count(cobNum)
						--						FROM cobros INNER JOIN
						--							coblin ON cobros.cobScd = coblin.cblScd AND cobros.cobPpag = coblin.cblPpag AND cobros.cobNum = coblin.cblNum
						--						WHERE cobCtr = @contrato and cblPer = @periodoEACuenta and cobPpag = @pPagoEACuenta and cobMpc = @medPagoEACuenta
						--								and cobConcepto like '%EAC apr:%' + CONVERT(VARCHAR, @numApremio) + ' ' + @periodo +'%')
					
						IF (@EACuentaAnterior = 0) --sólo inserto entrega a cuenta si no existe ya una IMPORTANTE -> y si actualmente aprCobradoAcuama=0 OR !apremio
						BEGIN
							                							
							SET @concepto = 'EAC apr: '  + CONVERT(VARCHAR, @numApremio) + ' ' + @periodo + '. Fec: ' + @fec
							SET @importe = @imp -- si es una EAC, ingreso lo que le cobró el ayuntamiento
					                                                                
							--Insertamos la cabecera del cobro
							EXEC @myError = Cobros_Insert @sociedad, @pPagoEACuenta, @p_Usuario, @fechaAct, @contrato, NULL, NULL, @importe, @medPagoEACuenta, 
										NULL, NULL, NULL, NULL, NULL, NULL, @concepto, NULL, NULL, NULL, NULL, @cobNumero OUTPUT, 'Apremio', @fechaAct
                                        
							--Insertamos la línea 
							EXEC @myError = CobLin_Insert @sociedad, @pPagoEACuenta, @cobNumero, @codigo, @periodoEACuenta, @facturaVersion, @importe, @linea OUTPUT
									
							--Si todo ha ido bien, actualizamos el campo aprCobradoAcuama=1 de la tabla Apremios
							--Si no había apremio no se actualizará
							IF @myError=0		
							BEGIN

								UPDATE apremios
								SET aprCobradoAcuama=1,
									aprFechaCobradoAcuama=@fechaAct										
								WHERE aprFacCod=@codigo
									AND aprFacCtrCod=@contrato
									AND aprFacPerCod=@periodo
									AND aprFacVersion=@facturaVersion
									AND aprCobrado=1
									AND aprCobradoAcuama=0					
						
								--Y actualizo mi tabla temporal
								update #cobroApremiosFichero
								set 
									aprCobradoAcuama=1,
									aprFecRegCobradoAcuama=@fechaAct
								WHERE facCod=@codigo
									AND facCtrCod=@contrato
									AND facPerCod=@periodo
									AND facVersion=@facturaVersion
									--AND aprCobrado=1
									--AND aprCobradoAcuama=0	
							
							END
						END
					END

					--Generar Cobro										
					--Esta opción implica que quedaba pendiente por pagar una parte de la factura (o el total), por lo que generaremos un cobro a la factura + una EAC con lo restante
					IF (@impFact > isnull(@impCobr, 0))
					BEGIN							                
						SET @restante = 0
						SET @apremioCompletado = 0

						SET @concepto = 'Apremio: '  + CONVERT(VARCHAR, @numApremio) + '.Fecha:' + @fec

						IF((@impFact - isnull(@impCobr,0)) > @imp)
						BEGIN
							SET @importe = @imp
							SET @apremioCompletado = 0
						END
						ELSE
						BEGIN
							SET @importe = @impFact - isnull(@impCobr,0)
							SET @restante = @imp - @importe
							SET @apremioCompletado = 1
						END
					                                                                
						--Insertamos la cabecera del cobro
						EXEC @myError = Cobros_Insert @sociedad, @pPago, @p_Usuario, @fechaAct, @contrato, NULL, NULL, @importe, @medPago, 
									NULL, NULL, NULL, NULL, NULL, NULL, @concepto, NULL, NULL, NULL, NULL, @cobNumero OUTPUT, 'Apremio', @fechaAct
                                        
						--Insertamos la línea 
						EXEC @myError = CobLin_Insert @sociedad, @ppago, @cobNumero, @codigo, @periodo, @facturaVersion, @importe, @linea OUTPUT
					   
					   	--si existía previamente un cobro, tenemos que meter la diferencia como entrega a cuenta
						IF(@myError=0 AND isnull(@restante, 0) > 0)
						BEGIN
							SET @concepto = 'EAC parcial apr: '  + CONVERT(VARCHAR, @numApremio) + ' ' + @periodo + '. Fec: ' + @fec
							SET @importe = isnull(@restante, 0) -- si es una EAC, ingreso lo que le cobró el ayuntamiento - @imp  
					                                                                
							--Insertamos la cabecera del cobro
							EXEC @myError = Cobros_Insert @sociedad, @pPagoEACuenta, @p_Usuario, @fechaAct, @contrato, NULL, NULL, @importe, @medPagoEACuenta, 
										NULL, NULL, NULL, NULL, NULL, NULL, @concepto, NULL, NULL, NULL, NULL, @cobNumero OUTPUT, 'Apremio', @fechaAct
                                        
							--Insertamos la línea 
							EXEC @myError = CobLin_Insert @sociedad, @pPagoEACuenta, @cobNumero, @codigo, @periodoEACuenta, @facturaVersion, @importe, @linea OUTPUT
						END

						--Si todo ha ido bien, actualizamos el campo aprCobradoAcuama=1 de la tabla Apremios
						IF @myError=0 AND @apremioCompletado = 1
						BEGIN

							UPDATE apremios
								SET aprCobradoAcuama=1,
									aprFechaCobradoAcuama=@fechaAct									
								WHERE aprFacCod=@codigo
								AND aprFacCtrCod=@contrato
								AND aprFacPerCod=@periodo
								AND aprFacVersion=@facturaVersion
								AND aprCobrado=1
								AND aprCobradoAcuama=0									
						END

						--Y actualizo mi tabla temporal
						update #cobroApremiosFichero
						set 
							aprCobradoAcuama=1,
							aprFecRegCobradoAcuama=@fechaAct
						WHERE facCod=@codigo
							AND facCtrCod=@contrato
							AND facPerCod=@periodo
							AND facVersion=@facturaVersion
							--AND aprCobrado=1
							--AND aprCobradoAcuama=0	
					END
				END

			 FETCH NEXT FROM cActualizados
			 INTO  @numero, @periodo,@contrato,@imp, @fec, @facturaVersion,@codigo, @numApremio, @sociedad
			END

			CLOSE cActualizados
			DEALLOCATE cActualizados


			--Segundo cursor para facturas que no están en apremios
			DECLARE cActualizadosSinApremio CURSOR FOR
					SELECT ca.numero,
						   periodo,
						   facCtrCod ctrcod,
						   ca.importe as importe,
						   ca.fecha as fecha,
						   facVersion as vers,
						   faccod as codigo,
						   aprNumero,
						   facSerScdCod sociedad 
					  FROM @cobroApremios ca  
					  INNER JOIN facturas
					  ON facturas.facnumero= ca.numero and facturas.facPerCod= ca.periodo and facturas.facCtrCod = ca.contrato
					  INNER JOIN fFacturas_TotalFacturado(NULL, 0, NULL) ON ftfFacCod=facCod AND ftfFacPerCod=facPerCod  AND ftfFacCtrCod=facCtrCod AND ftfFacVersion=facVersion
					  LEFT JOIN apremios 
					  ON facCod=aprFacCod AND facPerCod=aprFacPerCod AND facCtrCod=aprFacCtrCod AND facVersion=aprFacVersion
				   --ahora contemplo cobros parciales, así como cobro + EAC
				   --where ftfImporte >= ca.importe		
				   where aprNumero is null --De esta forma me aseguro de quedarme con los registros de la tabla A que no están en B
					AND facFechaRectif IS NULL
				ORDER BY  ca.numero, periodo, facCtrCod

				OPEN cActualizadosSinApremio
				FETCH NEXT FROM cActualizadosSinApremio
				INTO @numero, @periodo,@contrato,@imp, @fec, @facturaVersion,@codigo, @numApremio, @sociedad
				WHILE @@FETCH_STATUS = 0
				BEGIN

				--Importe Cobrado
				  Exec [dbo].[Cobros_ImporteCobrado] @contrato, @periodo, @codigo, null, null,null, null, null, null, null, @impCobr output

				--Importe facturado
				  Exec [dbo].[Facturas_ImporteFacturado] @codigo,@contrato, @periodo, null ,NULL,0, NULL, @impFact output			

				-- Valoramos posibles cobros parciales
				-- Si el cobro del apremio + cobrado es menor que la factura
				IF(@impFact > (@imp + isnull(@impCobr, 0)))
				BEGIN 
					SET @concepto = 'Por apr ayto, no apr par' + '.Fecha:' + @fec
					SET @importe = @imp  
					                                                                
					--Insertamos la cabecera del cobro
					EXEC @myError = Cobros_Insert @sociedad, @pPago, @p_Usuario, @fechaAct, @contrato, NULL, NULL, @importe, @medPago, 
								NULL, NULL, NULL, NULL, NULL, NULL, @concepto, NULL, NULL, NULL, NULL, @cobNumero OUTPUT, 'Manual', @fechaAct
                                        
					--Insertamos la línea 
					EXEC @myError = CobLin_Insert @sociedad, @ppago, @cobNumero, @codigo, @periodo, @facturaVersion, @importe, @linea OUTPUT
					   
					--Si todo ha ido bien, actualizamos el campo aprCobradoAcuama=2 de la tabla Apremios, para indicar cobro parcial
					IF @myError=0		
					BEGIN	
						--Actualizo mi tabla temporal
						update #cobroApremiosFichero
						set 
							aprCobradoAcuama=2,
							aprFecRegCobradoAcuama=@fechaAct
						WHERE facCod=@codigo
							AND facCtrCod=@contrato
							AND facPerCod=@periodo
							AND facVersion=@facturaVersion
							--AND aprCobrado=0
							--AND aprCobradoAcuama=0								
					END	
				END
				ELSE
				BEGIN
					-- Esta opción implica que ya estaba cobrado en Acuama y también se ha cobrado en el ayuntamiento, por lo que se genera un cobro de entrega a cuenta (si no existe uno ya)
					IF (@impFact - isnull(@impCobr, 0) = 0)	
					BEGIN

						set @EACuentaAnterior = 0

						SET @EACuentaAnterior = (SELECT count(cobNum)
												FROM cobros INNER JOIN
													coblin ON cobros.cobScd = coblin.cblScd AND cobros.cobPpag = coblin.cblPpag AND cobros.cobNum = coblin.cblNum
												WHERE cobCtr = @contrato and cblPer = @periodoEACuenta and cobPpag = @pPagoEACuenta and cobMpc = @medPagoEACuenta
														and cobConcepto like '%EAC apr ayto, no apr%'+ @periodo +'%')

						SET @CobroFicheroApremioAnterior = (SELECT count(cobNum)
												FROM cobros INNER JOIN
													coblin ON cobros.cobScd = coblin.cblScd AND cobros.cobPpag = coblin.cblPpag AND cobros.cobNum = coblin.cblNum
												WHERE cobCtr = @contrato and cblPer = @periodo and cobPpag = @pPago and cobMpc = @medPago)
					
						IF (@EACuentaAnterior = 0 AND @CobroFicheroApremioAnterior = 0) --sólo inserto entrega a cuenta si no existe ya una y si no ha habido un cobro por apremios previo
						BEGIN							                							
							SET @concepto = 'EAC apr ayto, no apr ' + @periodo + '.Fecha:' + @fec
							SET @importe = @imp -- si es una EAC, ingreso lo que le cobró el ayuntamiento
					                                                                
							--Insertamos la cabecera del cobro
							EXEC @myError = Cobros_Insert @sociedad, @pPagoEACuenta, @p_Usuario, @fechaAct, @contrato, NULL, NULL, @importe, @medPagoEACuenta, 
										NULL, NULL, NULL, NULL, NULL, NULL, @concepto, NULL, NULL, NULL, NULL, @cobNumero OUTPUT, 'Manual', @fechaAct
                                        
							--Insertamos la línea 
							EXEC @myError = CobLin_Insert @sociedad, @pPagoEACuenta, @cobNumero, @codigo, @periodoEACuenta, @facturaVersion, @importe, @linea OUTPUT

							IF @myError=0		
							BEGIN		
						
								--Actualizo mi tabla temporal
								update #cobroApremiosFichero
								set
									cobradoSinApremio = cast (1 as int),
									fecCobradoSinApremio = cast(@fechaAct as datetime)
								WHERE facCod=@codigo
									AND facCtrCod=@contrato
									AND facPerCod=@periodo
									AND facVersion=@facturaVersion
									--AND aprNumero is null
							END									
						END
						ELSE --indico que ya estaba cobrado con anterioridad
						BEGIN
							--Actualizo mi tabla temporal
							update #cobroApremiosFichero
							set
								cobradoSinApremio = NULL,
								cobradoAnteriorSinApremio = cast (1 as int),
								fecCobradoSinApremio = NULL
							WHERE facCod=@codigo
								AND facCtrCod=@contrato
								AND facPerCod=@periodo
								AND facVersion=@facturaVersion
								--AND aprNumero is null
						END
					END

					--Generar Cobro		
					--Esta opción implica que quedaba pendiente por pagar una parte de la factura, por lo que generaremos un cobro a la factura + una EAC con lo restante								
					IF (@impFact - isnull(@impCobr, 0) > 0)
					BEGIN								
						SET @restante = 0
						SET @apremioCompletado = 0

						--Obtenemos los valores del medio de pago y punto de pago de la tabla parámetros
						SET @pPago = (SELECT pgsvalor FROM parametros WHERE pgsclave = 'PUNTO_PAGO_APREMIOS')
						SET @medPago = (SELECT pgsvalor FROM parametros WHERE pgsclave = 'MEDIO_PAGO_APREMIOS')
						SET @concepto = 'Por apr ayto, no apr' + '.Fecha:' + @fec
						
						IF((@impFact - isnull(@impCobr,0)) > @imp)
						BEGIN
							SET @importe = @imp
							SET @apremioCompletado = 0
						END
						ELSE
						BEGIN
							SET @importe = @impFact - isnull(@impCobr,0)
							SET @restante = @imp - @importe
							SET @apremioCompletado = 1
						END
					                                                                
						--Insertamos la cabecera del cobro
						EXEC @myError = Cobros_Insert @sociedad, @pPago, @p_Usuario, @fechaAct, @contrato, NULL, NULL, @importe, @medPago, 
									NULL, NULL, NULL, NULL, NULL, NULL, @concepto, NULL, NULL, NULL, NULL, @cobNumero OUTPUT, 'Manual', @fechaAct
                                        
						--Insertamos la línea 
						EXEC @myError = CobLin_Insert @sociedad, @ppago, @cobNumero, @codigo, @periodo, @facturaVersion, @importe, @linea OUTPUT	
												
											   
					   	--si existía previamente un cobro, tenemos que meter la diferencia como entrega a cuenta
						IF(@myError=0 AND isnull(@restante, 0) > 0)
						BEGIN
							SET @concepto = 'EAC parc apr ayto no apr ' + @periodo + '.Fecha:' + @fec
							SET @importe = isnull(@restante, 0)
					                                                                
							--Insertamos la cabecera del cobro
							EXEC @myError = Cobros_Insert @sociedad, @pPagoEACuenta, @p_Usuario, @fechaAct, @contrato, NULL, NULL, @importe, @medPagoEACuenta, 
										NULL, NULL, NULL, NULL, NULL, NULL, @concepto, NULL, NULL, NULL, NULL, @cobNumero OUTPUT, 'Manual', @fechaAct
                                        
							--Insertamos la línea 
							EXEC @myError = CobLin_Insert @sociedad, @pPagoEACuenta, @cobNumero, @codigo, @periodoEACuenta, @facturaVersion, @importe, @linea OUTPUT
						END

						IF @myError=0		
						BEGIN								
							--Actualizo mi tabla temporal
							update #cobroApremiosFichero
							set 
								cobradoSinApremio = 1,
								fecCobradoSinApremio = @fechaAct
							WHERE facCod=@codigo
								AND facCtrCod=@contrato
								AND facPerCod=@periodo
								AND facVersion=@facturaVersion
								--AND aprNumero is null
						END		
					END
				END

			 FETCH NEXT FROM cActualizadosSinApremio
			 INTO  @numero, @periodo,@contrato,@imp, @fec, @facturaVersion,@codigo, @numApremio, @sociedad
			END

			CLOSE cActualizadosSinApremio
			DEALLOCATE cActualizadosSinApremio
		END

		
	--devolvemos nuevo resultado
	
	--	/* Devolvemos el resultado */	
	INSERT INTO @resultado (numero , periodo,ctrcod  ,fecha, importe, titular, actualizado ,cobrado , fechaRegAyto , fechaRegAcuama )
	    OUTPUT INSERTED.*
		SELECT 
			numero, periodo, 
			case when facNumero is not null then facCtrCod else -1 end as ctrcod, 
			facFecha, importe, titular,
			case when facNumero is not null then (ISNULL(aprCobrado,0)) else -1 end as actualizado,
			case when facNumero is not null then (case when aprNumero is not null then ISNULL(aprCobradoAcuama,0) else ISNULL(cobradoSinApremio,ISNULL(cobradoAnteriorSinApremio,0)) end) else -1 end as cobrado,
			case when facNumero is not null then (case when aprNumero is not null then aprFecRegCobrado else fecCobradoSinApremio end) else null end as fechaRegAyto,			
			case when facNumero is not null then (case when aprNumero is not null then aprFecRegCobradoAcuama else fecCobradoSinApremio end) else null end as fechaRegAcuama
		FROM #cobroApremiosFichero		
		ORDER BY actualizado, periodo, facCtrCod, numero	
		
		drop table #cobroApremiosFichero
		
		--COMMIT
	END TRY
	
	BEGIN CATCH

		--ROLLBACK		
		DECLARE @erlNumber INT = (SELECT ERROR_NUMBER());
		DECLARE @erlSeverity INT = (SELECT ERROR_SEVERITY());
		DECLARE @erlState INT = (SELECT ERROR_STATE());
		DECLARE @erlProcedure nvarchar(128) = (SELECT ERROR_PROCEDURE());
		DECLARE @erlLine int = (SELECT ERROR_LINE());
		DECLARE @erlMessage nvarchar(4000) = (SELECT ERROR_MESSAGE());
	
		DECLARE @erlParams varchar(500) = NULL;
		
		DECLARE @expl VARCHAR(20) = NULL
		SET @expl = (SELECT pgsvalor FROM parametros WHERE pgsclave = 'EXPLOTACION')

		--BEGIN TRAN
			EXEC dbo.ErrorLog_Insert  @expl, 'dbo.CobrosApremios_Ods_Upload', @erlNumber, @erlSeverity, @erlState, @erlProcedure, @erlLine, @erlMessage, @erlParams	
		--COMMIT TRAN	

	END CATCH
END
GO


