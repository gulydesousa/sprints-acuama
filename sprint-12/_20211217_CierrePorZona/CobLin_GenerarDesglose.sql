ALTER PROCEDURE [dbo].[CobLin_GenerarDesglose]
	--FORMA A (L�NEA DE COBRO EXISTENTE EN BASE DE DATOS)
	 @insertarDesgloseGenerado BIT = NULL 
	,@cblScd SMALLINT = NULL
	,@cblPpag SMALLINT = NULL
	,@cblNum INT = NULL
	,@cblLin SMALLINT = NULL
	
	--FORMA B (L�NEA DE COBRO INEXISTENTE EN BASE DE DATOS)
	,@cblImporte AS MONEY = NULL
	,@cobFecReg AS DATETIME = NULL --Puede ser null (en cuyo caso, tomaremos GETDATE() como valor)
	,@contrato AS INT = NULL
	,@periodo AS VARCHAR(6) = NULL
	,@facturaCodigo AS SMALLINT = NULL
	,@facturaVersion AS SMALLINT = NULL
	,@servicioLiquidado AS BIT = NULL
	,@lineaRectificada BIT = NULL -- Indica si la l�nea a generar los desgloses es de los cobros rectificados
	,@todasLasVersiones BIT = NULL -- Indica si se desglosa la l�nea de cobro mediante las liquidaciones o facturas anteriores 
								   -- si no se han creado los desgloses para la factura actual

AS
	SET NOCOUNT OFF;
	
	DECLARE @myError AS INT = 0
	DECLARE @facTotal2 AS DECIMAL(12, 2) -- Total facturado redondeado a 2 decimales
	
	--COMPROBAR QUE SE HA LLAMADO CORRECTAMENTE USANDO UNA DE LAS FORMAS ESPECIFICADAS
	IF (@cblScd IS NULL OR @cblPpag IS NULL OR @cblPpag IS NULL OR @cblNum IS NULL OR @cblLin IS NULL) AND
	   (@cblImporte IS NULL OR @contrato IS NULL OR @periodo IS NULL OR @facturaCodigo IS NULL OR @facturaVersion IS NULL)
	   RAISERROR ('Combinaci�n de par�metros incorrecta', 16, 1)
	
	--SI USAMOS LA FORMA A (l�nea de cobro existente) OBTENGO LOS DATOS DE LA FACTURA DE DICHA L�NEA DE COBRO
	IF @cblImporte IS NULL OR @contrato IS NULL OR @periodo IS NULL OR @facturaCodigo IS NULL OR @facturaVersion IS NULL BEGIN
		SELECT @cblImporte = cblImporte, @cobFecReg = cobFecReg, 
			   @contrato = cobCtr, @periodo = cblPer, @facturaCodigo = cblFacCod, @facturaVersion = cblFacVersion
		FROM coblin
		INNER JOIN cobros ON cobScd = cblScd AND cobPpag = cblPpag AND cobNum = cblNum
		WHERE cblScd = @cblScd AND cblPpag = @cblPpag AND cblNum = @cblNum AND cblLin = @cblLin
	END
	
	--SI NO ME PASAN LA FECHA DE REGISTRO, ESTABLEZCO LA FECHA ACTUAL
	SET @cobFecReg = ISNULL(@cobFecReg, GETDATE())
	--------------------------------------------------------------------------------------------------------------------------------
	
	--CREO LA TABLA TEMPORAL DONDE VOY A INSERTAR LOS REGISTROS DE COBLINDES, PARA LUEGO DEVOLVERLOS EN FORMA DE TABLA
	SELECT TOP 0 * INTO #cobLinDes FROM cobLinDes 
	
	--------------------------------------------------------------------------------------------------------------------------------
	DECLARE @esteCobroCuadraLaFactura AS BIT = 0 --Indica si con este cobro + los anteriores queda pagada la factura (y no se pasa)
	DECLARE @esteCobroAnulaTodo AS BIT = 0 --Indica que con este cobro el importe total cobrado se queda a 0
	DECLARE @cobrosAnteriores AS MONEY = 0 --Suma de los importes de los cobros anteriores a esta factura
	DECLARE @numCobrosAnteriores AS INT = 0 --N�mero de cobros anteriores a esta factura
	DECLARE @facTotal AS MONEY = 0 --Total de la factura
	DECLARE @facNumLineas AS INT = 0 --N�mero de l�neas de la factura
	DECLARE @facVersionOriginal AS SMALLINT = 0
	
	--Obtengo los cobros anteriores de esta factura
	SELECT @cobrosAnteriores = ISNULL(SUM(cblImporte), 0), @numCobrosAnteriores = COUNT(*) FROM cobros 
    INNER JOIN coblin ON cblScd = cobScd AND cblPpag = cobPpag AND cblNum = cobNum 
    WHERE /*l�neas de cobro de esta factura ->*/cobCtr = @contrato AND cblPer = @periodo AND cblFacVersion = @facturaVersion AND cblFacCod = @facturaCodigo AND
          /*s�lo cobros anteriores a este ->*/ cobFecReg <= @cobFecReg AND (cblScd <> ISNULL(@cblScd, -1) OR cblPpag <> ISNULL(@cblPpag, -1) OR cblNum <> ISNULL(@cblNum, -1) OR cblLin <> ISNULL(@cblLin, -1))
	
	-------------------------------------------------------------------------------------------
	SET @facVersionOriginal = @facturaVersion
	--PRINT '����������������@facturaVersion--->' + CAST(@facturaVersion AS VARCHAR)
	--PRINT '����������������@facturaCodigo--->' + CAST(@facturaCodigo AS VARCHAR)
	WHILE (@facturaVersion > 1 AND
		NOT EXISTS(SELECT fclNumLinea 
						  FROM faclin 
						  WHERE fclFacCod = @facturaCodigo AND 
								fclFacPerCod = @periodo AND 
								fclFacCtrCod = @contrato AND 
								fclFacVersion = @facturaVersion AND 
								fcltotal > 0) AND
		(SELECT ABS(SUM(ISNULL(cblImporte,0)))
				FROM cobros 
				INNER JOIN coblin ON cblScd = cobScd AND cblPpag = cobPpag AND cblNum = cobNum 
				WHERE /*l�neas de cobro de esta factura ->*/cobCtr = @contrato AND cblPer = @periodo AND cblFacVersion = @facturaVersion AND cblFacCod = @facturaCodigo AND
					 /*s�lo cobro actual->*/ cobFecReg = @cobFecReg
					 AND (@servicioLiquidado = 1 OR ((@servicioLiquidado IS NULL OR @servicioLiquidado = 0) AND cobOrigen <> 'Rectificativo'))
					 )>= 0)
		BEGIN
			--PRINT '!!!!!!!!!!!!!!!!!!!!!FACTURAS ANULADAS!!!!!!!!!!!!!!!!'
			SET @facturaVersion = (@facturaVersion - 1)
	END
	-------------------------------------------------------------------------------------------
	
	
	IF @servicioLiquidado IS NOT NULL BEGIN
	--Obtener total factura
	SELECT @facTotal = ISNULL(SUM(fclTotal),0) -- ******************* A�ADO ROUND PORQUE LO VA A COMPARAR CON EL COBRADO, QUE LLEVA 2 DECIMALES ***************
			FROM faclin fl
			WHERE fclFacCod = @facturaCodigo AND fclFacPerCod = @periodo AND fclFacCtrCod = @contrato AND fclFacVersion = @facturaVersion 
			AND (@servicioLiquidado IS NULL OR ((((@lineaRectificada IS NULL OR @lineaRectificada = 0) AND DATEADD(dd, DATEDIFF(dd, 0, fclFecLiq), 0) > DATEADD(dd, DATEDIFF(dd, 0, @cobFecReg), 0)) OR (@lineaRectificada = 1 AND DATEADD(dd, DATEDIFF(dd, 0, fclFecLiq), 0) >= DATEADD(dd, DATEDIFF(dd, 0, @cobFecReg), 0))) OR (fclFecLiq IS NULL AND fclUsrLiq IS NULL))) 
				   AND
				  (@servicioLiquidado IS NULL OR 
				   @servicioLiquidado = 0 OR 
				   EXISTS(SELECT fclTrfSvCod
								  FROM faclin fl1
								  WHERE  fl1.fclFacCod = fl.fclFacCod AND
										 fl1.fclFacPerCod = fl.fclFacPerCod AND
										 fl1.fclFacCtrCod = fl.fclFacCtrCod AND
										 fl1.fclFacVersion = fl.fclFacVersion AND
										 fl1.fclTrfSvCod = fl.fclTrfSvCod AND 
										(fl1.fclFecLiq IS NULL OR (fclFecLiq IS NOT NULL AND ((@lineaRectificada IS NULL OR @lineaRectificada = 0) AND fclFecLiq > @cobFecReg) OR (@lineaRectificada = 1 AND fclFecLiq >= @cobFecReg))) 
					      )   
				  )
	SELECT @facNumLineas = COUNT(*) 
			FROM faclin fl
			WHERE fclFacCod = @facturaCodigo AND fclFacPerCod = @periodo AND fclFacCtrCod = @contrato AND fclFacVersion = @facturaVersion AND 
				  (@servicioLiquidado IS NULL OR ((((@lineaRectificada IS NULL OR @lineaRectificada = 0) AND DATEADD(dd, DATEDIFF(dd, 0, fclFecLiq), 0) > DATEADD(dd, DATEDIFF(dd, 0, @cobFecReg), 0)) OR (@lineaRectificada = 1 AND DATEADD(dd, DATEDIFF(dd, 0, fclFecLiq), 0) >= DATEADD(dd, DATEDIFF(dd, 0, @cobFecReg), 0))) OR (fclFecLiq IS NULL AND fclUsrLiq IS NULL))) 
				   AND
				  (@servicioLiquidado IS NULL OR 
				   @servicioLiquidado = 0 OR 
				   EXISTS(SELECT fclTrfSvCod
								  FROM faclin fl1
								  WHERE  fl1.fclFacCod = fl.fclFacCod AND
										 fl1.fclFacPerCod = fl.fclFacPerCod AND
										 fl1.fclFacCtrCod = fl.fclFacCtrCod AND
										 fl1.fclFacVersion = fl.fclFacVersion AND
										 fl1.fclTrfSvCod = fl.fclTrfSvCod AND 
										(fl1.fclFecLiq IS NULL OR (fclFecLiq IS NOT NULL AND ((@lineaRectificada IS NULL OR @lineaRectificada = 0) AND fclFecLiq > @cobFecReg) OR (@lineaRectificada = 1 AND fclFecLiq >= @cobFecReg))) 
					      )   
				  )
	END
	ELSE BEGIN
			SELECT @facNumLineas = COUNT(*), @facTotal = ISNULL(SUM(fclTotal),0)  -- ******************* A�ADO ROUND PORQUE LO VA A COMPARAR CON EL COBRADO, QUE LLEVA 2 DECIMALES ***************
			FROM faclin fl
			WHERE fclFacCod = @facturaCodigo AND fclFacPerCod = @periodo AND fclFacCtrCod = @contrato AND fclFacVersion = @facturaVersion
	END
		
	SELECT @facTotal2 = CAST(ISNULL(@facTotal, 0) AS DECIMAL(12,2))
		  
	/*
	PRINT '@facNumLineas-->' + CAST(@facNumLineas AS VARCHAR)
	PRINT '@facTotal-->' + CAST(@facTotal AS VARCHAR)
	PRINT '@cobrosAnteriores-->' + CAST(@cobrosAnteriores AS VARCHAR)
	PRINT '@cblImporte-->' + CAST(@cblImporte AS VARCHAR)
	*/	
	--Comprobar si con este cobro el importe total cobrado se queda a 0
	IF (@cobrosAnteriores + @cblImporte = 0)  AND
	   (@facVersionOriginal > 1 AND
		 EXISTS(SELECT fclNumLinea 
					   FROM faclin 
					   WHERE fclFacCod = @facturaCodigo AND 
							 fclFacPerCod = @periodo AND 
							 fclFacCtrCod = @contrato AND 
							 fclFacVersion = @facVersionOriginal AND 
							 fcltotal > 0)
		)
		SET @esteCobroAnulaTodo = 1
	--Comprobar si la factura queda totalmente pagada con este cobro
	ELSE IF (@cobrosAnteriores + @cblImporte = @facTotal2) AND  -- Lo comparo redondeado a dos decimales, como las l�neas de cobro
			(@facVersionOriginal > 1 AND
			 EXISTS(SELECT fclNumLinea 
						   FROM faclin 
						   WHERE fclFacCod = @facturaCodigo AND 
								 fclFacPerCod = @periodo AND 
								 fclFacCtrCod = @contrato AND 
								 fclFacVersion = @facVersionOriginal AND 
								 fcltotal > 0)
			)
		SET @esteCobroCuadraLaFactura = 1
	
	/*
	PRINT 'Anterior-->' + CAST(@cobrosAnteriores AS VARCHAR)
	PRINT 'Cobro-->' + CAST(@cblImporte AS VARCHAR)
	PRINT 'Factura-->' + CAST(@facTotal AS VARCHAR)
	*//*
	PRINT '@esteCobroAnulaTodo-->' + CAST(@esteCobroAnulaTodo AS VARCHAR)
	PRINT '@esteCobroCuadraLaFactura-->' + CAST(@esteCobroCuadraLaFactura AS VARCHAR)
	*/
	--Si voy a hacer el reparto calculando las proporciones, necesito esta variable.
	--Es un acumulativo de importes proporcionales usados (al finalizar el cursor de l�neas, el valor de �ste ha de ser igual a cblImporte)
	DECLARE @sumCldImporte AS MONEY = 0
	
	--Variables para el cursor de factura
	DECLARE @fclNumLinea AS INT, @fclTotal AS MONEY, @fclTrfSvCod AS SMALLINT, @fclTrfCod AS SMALLINT, @numRegistro AS INT

	--Recorrer l�neas (servicios) de esta factura
	DECLARE cFaclin CURSOR FOR
	--ATENCI�N -> El ORDER BY de ROW_NUMBER() ha de ser el mismo que el de la SELECT:
	--    - Si @cblImporte>0 la �ltima fila ha de ser, de las que NO tienen organismo, la de mayor importe absoluto (es a la que le voy a sumar los c�ntimos que descuadren)
	--    - Si @cblImporte<0 la �ltima fila ha de ser, de las que tienen organismo, la de mayor importe absoluto (es a la que le voy a restar los c�ntimos que descuadren)
	SELECT ROW_NUMBER() OVER(ORDER BY (CASE WHEN ABS(@cblImporte) > 0 THEN svcOrgCod ELSE ISNULL(svcOrgCod, 32767) END) DESC, 
		   ABS(fclTotal)) AS numRegistro, fclNumLinea, fclTotal, fclTrfSvCod, fclTrfCod 
	FROM faclin fl
	INNER JOIN servicios ON fclTrfSvCod = svcCod
	WHERE fclFacPerCod = @periodo AND fclFacCtrCod = @contrato AND fclFacVersion = @facturaVersion AND fclFacCod = @facturaCodigo AND 
		(@servicioLiquidado IS NULL OR ((((@lineaRectificada IS NULL OR @lineaRectificada = 0) AND DATEADD(dd, DATEDIFF(dd, 0, fclFecLiq), 0) > DATEADD(dd, DATEDIFF(dd, 0, @cobFecReg), 0)) OR (@lineaRectificada = 1 AND DATEADD(dd, DATEDIFF(dd, 0, fclFecLiq), 0) >= DATEADD(dd, DATEDIFF(dd, 0, @cobFecReg), 0))) OR (fclFecLiq IS NULL AND fclUsrLiq IS NULL))) 
		AND (@servicioLiquidado IS NULL OR @servicioLiquidado = 0 OR 
				    EXISTS(SELECT fclTrfSvCod
								  FROM faclin fl1
								  WHERE fl1.fclFacCod = fl.fclFacCod AND
										fl1.fclFacPerCod = fl.fclFacPerCod AND
										fl1.fclFacCtrCod = fl.fclFacCtrCod AND
										fl1.fclFacVersion = fl.fclFacVersion AND
										fl1.fclTrfSvCod = fl.fclTrfSvCod AND 
										(fl1.fclFecLiq IS NULL OR (fclFecLiq IS NOT NULL AND ((@lineaRectificada IS NULL OR @lineaRectificada = 0) AND fclFecLiq > @cobFecReg) OR (@lineaRectificada = 1 AND fclFecLiq >= @cobFecReg))) 
					      )   
			)
	ORDER BY (CASE WHEN ABS(@cblImporte) > 0 THEN svcOrgCod ELSE ISNULL(svcOrgCod, 32767) END) DESC, ABS(fclTotal)
	
	--Comenzar cursor
	OPEN cFaclin
	FETCH NEXT FROM cFaclin INTO @numRegistro, @fclNumLinea, @fclTotal, @fclTrfSvCod, @fclTrfCod
	WHILE @@FETCH_STATUS = 0 BEGIN
		--Importe a insertar para este desglose
		DECLARE @cldImporte AS MONEY = 0
		--Si este cobro es el que va a dejar el total pagado = 0 -> el importe de esta l�nea es 
		--Si este cobro es el que va a dejar pagada la factura -> el importe de esta l�nea es lo que falta hasta llegar a pagar lo que se debe de ella
		--Adem�s, si es el �nico cobro que hay, y el importe del cobro es igual al importe de la factura, directamente @cldImporte = @fclTotal, as� me ahorro calcular proporciones tontamente, ya que la proporci�n es 1 a 1
		IF @esteCobroCuadraLaFactura = 1 OR @esteCobroAnulaTodo = 1 BEGIN
			--PRINT '***********ENTRA AL IF**********'
			--Almacena el importe de los cobros anteriores a este servicio, de esta factura
			DECLARE @cobradoServicio AS MONEY = 0
			
			--PRINT '@numCobrosAnteriores-->' + CAST(@numCobrosAnteriores AS VARCHAR)
			--PRINT '@cobFecReg-->' + CAST(@cobFecReg AS VARCHAR)
			--PRINT '@fclTrfSvCod-->' + CAST(@fclTrfSvCod AS VARCHAR)
			--PRINT '@fclTrfCod-->' + CAST(@fclTrfCod AS VARCHAR)
			
			--Si no hay cobros anteriores, dejo el importe a 0, y me ahorro buscar si s� que no hay
			IF @numCobrosAnteriores > 0 BEGIN
				DECLARE @existenServicioTarifaRepetidos INT = 1
				SELECT @cobradoServicio = ISNULL(SUM(cldImporte), 0), @existenServicioTarifaRepetidos = COUNT(1) 
				FROM cobros
					INNER JOIN coblin ON cblScd = cobScd AND cblPpag = cobPpag AND cblNum = cobNum
					INNER JOIN cobLinDes ON cldCblScd = cblScd AND cldCblPpag = cblPpag AND cldCblNum = cblNum AND cldCblLin = cblLin
				WHERE cobCtr = @contrato AND cblPer = @periodo AND cblFacVersion = @facturaVersion AND cblFacCod = @facturaCodigo AND cldTrfSrvCod = @fclTrfSvCod AND cldTrfCod = @fclTrfCod  AND --cldFacLin = @fclNumLinea AND
					  cobFecReg <= @cobFecReg AND (cblScd <> ISNULL(@cblScd, -1) OR cblPpag <> ISNULL(@cblPpag, -1) OR cblNum <> ISNULL(@cblNum, -1) OR cblLin <> ISNULL(@cblLin, -1))
				
				-- Si tiene m�s de una l�nea de factura para ese servicio/tarifa cogemos el de la l�nea de factura especificada en el desglose (cldFacLin = @fclNumLinea)
				IF @existenServicioTarifaRepetidos > 1 BEGIN
					SELECT @cobradoServicio = ISNULL(SUM(cldImporte), 0)
					FROM cobros
						INNER JOIN coblin ON cblScd = cobScd AND cblPpag = cobPpag AND cblNum = cobNum
						INNER JOIN cobLinDes ON cldCblScd = cblScd AND cldCblPpag = cblPpag AND cldCblNum = cblNum AND cldCblLin = cblLin
					WHERE cobCtr = @contrato AND cblPer = @periodo AND cblFacVersion = @facturaVersion AND cblFacCod = @facturaCodigo AND cldTrfSrvCod = @fclTrfSvCod AND cldTrfCod = @fclTrfCod  AND cldFacLin = @fclNumLinea AND
						  cobFecReg <= @cobFecReg AND (cblScd <> ISNULL(@cblScd, -1) OR cblPpag <> ISNULL(@cblPpag, -1) OR cblNum <> ISNULL(@cblNum, -1) OR cblLin <> ISNULL(@cblLin, -1))
				END					  
			END
			
			--PRINT '@fclTotal-->' + CAST(@fclTotal AS VARCHAR)
			--PRINT '@cobradoServicio-->' + CAST(@cobradoServicio AS VARCHAR)
			
			--Si este cobro "salda" la factura: el importe del cobro de este servicio ha de ser el total facturado del servicio, menos el cobrado a este servicio de las facturas anteriores
			IF @esteCobroCuadraLaFactura = 1 SET @cldImporte = @fclTotal - @cobradoServicio
			--Si este cobro deja todo lo cobrado del servicio a 0: el importe del cobro del servicio ha de ser -1*cobrado del servicio
			ELSE IF @esteCobroAnulaTodo = 1 SET @cldImporte = -@cobradoServicio --print 'anula todo++++++++++++++++'
		
		--Si no -> proporcional, y cuadrando el importe del cobro en la �ltima l�nea del desglose
		END ELSE BEGIN
			/*
			PRINT '!!!!!ENTRA AL ELSE!!!!!!!'
			PRINT '@cblImporte-->' + CAST(@cblImporte AS VARCHAR)
			PRINT '@facTotal-->' + CAST(@facTotal AS VARCHAR)
			*/
			
			SELECT @cobradoServicio = ISNULL(SUM(cldImporte), 0)
			FROM cobros
				INNER JOIN coblin ON cblScd = cobScd AND cblPpag = cobPpag AND cblNum = cobNum
				INNER JOIN cobLinDes ON cldCblScd = cblScd AND cldCblPpag = cblPpag AND cldCblNum = cblNum AND cldCblLin = cblLin
			WHERE cobCtr = @contrato AND cblPer = @periodo AND cblFacVersion = @facturaVersion AND cblFacCod = @facturaCodigo AND cldTrfSrvCod = @fclTrfSvCod AND cldTrfCod = @fclTrfCod  AND --cldFacLin = @fclNumLinea AND
				  cobFecReg <= @cobFecReg AND (cblScd <> ISNULL(@cblScd, -1) OR cblPpag <> ISNULL(@cblPpag, -1) OR cblNum <> ISNULL(@cblNum, -1) OR cblLin <> ISNULL(@cblLin, -1))
			
			--Si el importe del cobro es igual al importe de la factura -> El importe del desglose es igual al importe de la l�nea de factura
			IF ABS(@cblImporte) = @facTotal2 -- Lo comparo redondeado a dos decimales, como las l�neas de cobro
			  BEGIN 
				SET @cldImporte = @fclTotal * SIGN(@cblImporte)
			  END
			ELSE
			--Si no, lo repartimos asignando el c�ntimo que sobra a la �ltima l�nea, teniendo en cuenta el orden establecido
			  BEGIN
				IF @cobrosAnteriores + @cblImporte = @facTotal2 -- Lo comparo redondeado a dos decimales, como las l�neas de cobro
				  BEGIN -- Lo comparo redondeado a dos decimales, como el cobro
					SET @cldImporte = @fclTotal - @cobradoServicio
				  END 
				ELSE 
				  BEGIN
					--Obtener proporci�n
					--SET @cldImporte = CASE WHEN @facTotal = 0 THEN 0 ELSE ROUND((@fclTotal / @facTotal) * @cblImporte, 2) END
					SET @cldImporte = CASE WHEN @facTotal = 0 THEN 0 ELSE ROUND((CAST(@fclTotal AS DECIMAL(12,4)) / CAST(@facTotal AS DECIMAL(12,4))) * CAST(@cblImporte AS DECIMAL(12,2)),2) END
					SET @sumCldImporte = @sumCldImporte + @cldImporte
					
					--Si es la �ltima l�nea de factura, y sobra alg�n c�ntimo, vamos a meterlo aqu�
					IF @numRegistro = @facNumLineas AND @sumCldImporte <> @cblImporte BEGIN
						SET @cldImporte = @cldImporte + (@cblImporte - @sumCldImporte)
					END
				  END
			    END
		END
		
		--Insertar l�nea de desglose
		INSERT INTO #cobLinDes (cldCblScd, cldCblPpag, cldCblNum, cldCblLin, cldFacLin, cldTrfSrvCod, cldTrfCod, cldImporte)
		VALUES (@cblScd, @cblPpag, @cblNum, @cblLin, @fclNumLinea, @fclTrfSvCod, @fclTrfCod, @cldImporte)
 		--Siguiente l�nea de factura
		FETCH NEXT FROM cFaclin INTO @numRegistro, @fclNumLinea, @fclTotal, @fclTrfSvCod, @fclTrfCod
	END
	CLOSE cFaclin
	DEALLOCATE cFaclin
	
	--�Insertar desglose? (S�LO PARA LA FORMA A, SI NO SE PRODUCIR� UN ERROR PORQUE LA PK SER� NULL)
	IF @insertarDesgloseGenerado = 1 BEGIN
		BEGIN TRANSACTION
		
		--Borrar desglose existente
		DELETE cobLinDes WHERE cldCblScd = @cblScd AND cldCblPpag = @cblPpag AND cldCblNum = @cblNum AND cldCblLin = @cblLin
		SET @myError = @@ERROR IF @myError <> 0 GOTO ERROR
		
		--Insertar desglose generado
		INSERT INTO cobLinDes SELECT * FROM #cobLinDes
		SET @myError = @@ERROR IF @myError <> 0 GOTO ERROR
		
		IF ((@todasLasVersiones IS NULL OR @todasLasVersiones = 1) AND NOT EXISTS(SELECT cldCblNum FROM cobLinDes WHERE cldCblScd = @cblScd AND cldCblPpag = @cblPpag AND cldCblNum = @cblNum AND cldCblLin = @cblLin))
		BEGIN
			EXEC @myError = [dbo].[CobLin_GenerarDesglose_TodasVersiones] @cblScd, @cblPpag, @cblNum, @cblLin
			IF @myError <> 0 GOTO ERROR
		END
		
		COMMIT TRANSACTION
	END
	
	--FIN -> DEVOLVER TABLA
	--SELECT * FROM #cobLinDes
	DROP TABLE #cobLinDes
	
	RETURN 0
	
ERROR:
	DROP TABLE #cobLinDes
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION

GO


