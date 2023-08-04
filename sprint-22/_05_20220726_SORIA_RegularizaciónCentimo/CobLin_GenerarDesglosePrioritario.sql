/*
DECLARE  @insertarDesgloseGenerado BIT = 0 
	,@cblScd SMALLINT = 1
	,@cblPpag SMALLINT = 10003
	,@cblNum INT = 26
	,@cblLin SMALLINT = 1
	
	--FORMA B (LÍNEA DE COBRO INEXISTENTE EN BASE DE DATOS)
	,@cblImporte AS MONEY = NULL
	,@cobFecReg AS DATETIME = NULL --Puede ser null (en cuyo caso, tomaremos GETDATE() como valor)
	,@contrato AS INT = NULL
	,@periodo AS VARCHAR(6) = NULL
	,@facturaCodigo AS SMALLINT = NULL
	,@facturaVersion AS SMALLINT = NULL
	,@servicioLiquidado AS BIT = 1
	,@lineaRectificada BIT = NULL -- Indica si la línea a generar los desgloses es de los cobros rectificados
	,@todasLasVersiones BIT = NULL -- Indica si se desglosa la línea de cobro mediante las liquidaciones o facturas anteriores 
								   -- si no se han creado los desgloses para la factura actual


	EXEC [dbo].[CobLin_GenerarDesglosePrioritario]
	--FORMA A (LÍNEA DE COBRO EXISTENTE EN BASE DE DATOS)
	 @insertarDesgloseGenerado
	,@cblScd
	,@cblPpag
	,@cblNum
	,@cblLin
	
	--FORMA B (LÍNEA DE COBRO INEXISTENTE EN BASE DE DATOS)
	,@cblImporte
	,@cobFecReg
	,@contrato
	,@periodo
	,@facturaCodigo
	,@facturaVersion
	,@servicioLiquidado
	,@lineaRectificada
	--,@todasLasVersiones

*/


ALTER PROCEDURE [dbo].[CobLin_GenerarDesglosePrioritario]
	--FORMA A (LÍNEA DE COBRO EXISTENTE EN BASE DE DATOS)
	 @insertarDesgloseGenerado BIT = NULL 
	,@cblScd SMALLINT = NULL
	,@cblPpag SMALLINT = NULL
	,@cblNum INT = NULL
	,@cblLin SMALLINT = NULL
	
	--FORMA B (LÍNEA DE COBRO INEXISTENTE EN BASE DE DATOS)
	,@cblImporte AS MONEY = NULL
	,@cobFecReg AS DATETIME = NULL --Puede ser null (en cuyo caso, tomaremos GETDATE() como valor)
	,@contrato AS INT = NULL
	,@periodo AS VARCHAR(6) = NULL
	,@facturaCodigo AS SMALLINT = NULL
	,@facturaVersion AS SMALLINT = NULL
	,@servicioLiquidado AS BIT = NULL
	,@lineaRectificada BIT = NULL -- Indica si la línea a generar los desgloses es de los cobros rectificados
	,@todasLasVersiones BIT = NULL -- Indica si se desglosa la línea de cobro mediante las liquidaciones o facturas anteriores 
								   -- si no se han creado los desgloses para la factura actual

AS
	SET NOCOUNT ON;
	DECLARE @fclImportePte MONEY;

	DECLARE @myError AS INT = 0
	DECLARE @facTotal2 AS DECIMAL(12, 2) -- Total facturado redondeado a 2 decimales
	
	--COMPROBAR QUE SE HA LLAMADO CORRECTAMENTE USANDO UNA DE LAS FORMAS ESPECIFICADAS
	IF (@cblScd IS NULL OR @cblPpag IS NULL OR @cblPpag IS NULL OR @cblNum IS NULL OR @cblLin IS NULL) AND
	   (@cblImporte IS NULL OR @contrato IS NULL OR @periodo IS NULL OR @facturaCodigo IS NULL OR @facturaVersion IS NULL)
	   RAISERROR ('Combinación de parámetros incorrecta', 16, 1)
	
	--SI USAMOS LA FORMA A (línea de cobro existente) OBTENGO LOS DATOS DE LA FACTURA DE DICHA LÍNEA DE COBRO
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
	DECLARE @numCobrosAnteriores AS INT = 0 --Número de cobros anteriores a esta factura
	DECLARE @facTotal AS MONEY = 0 --Total de la factura
	DECLARE @facNumLineas AS INT = 0 --Número de líneas de la factura
	DECLARE @facVersionOriginal AS SMALLINT = 0
		
	--*********************************************
	--Obtengo los cobros anteriores de esta factura
	SELECT @cobrosAnteriores = ISNULL(SUM(ROUND(CL.cblImporte, 2)), 0)
		 , @numCobrosAnteriores = COUNT(*) 
	FROM dbo.cobros AS C 
    INNER JOIN dbo.coblin AS CL 
	ON  CL.cblScd = C.cobScd 
	AND CL.cblPpag = C.cobPpag 
	AND CL.cblNum = C.cobNum 
    WHERE C.cobCtr = @contrato 
	  AND CL.cblPer = @periodo 
	  AND CL.cblFacVersion = @facturaVersion 
	  AND CL.cblFacCod = @facturaCodigo 
	  --Solo cobros anteriores a este
	  AND (C.cobFecReg <= @cobFecReg) 
	  AND (CL.cblScd  <> ISNULL(@cblScd, -1)  OR 
	       CL.cblPpag <> ISNULL(@cblPpag, -1) OR 
		   CL.cblNum  <> ISNULL(@cblNum, -1)  OR 
		   CL.cblLin  <> ISNULL(@cblLin, -1));
	--*********************************************
	
	SET @facVersionOriginal = @facturaVersion
	--PRINT '¡¡¡¡¡¡¡¡¡¡¡¿¿¿¿¿@facturaVersion--->' + CAST(@facturaVersion AS VARCHAR)
	--PRINT '¡¡¡¡¡¡¡¡¡¡¡¿¿¿¿¿@facturaCodigo--->' + CAST(@facturaCodigo AS VARCHAR)
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
				WHERE /*líneas de cobro de esta factura ->*/cobCtr = @contrato AND cblPer = @periodo AND cblFacVersion = @facturaVersion AND cblFacCod = @facturaCodigo AND
					 /*sólo cobro actual->*/ cobFecReg = @cobFecReg
					 AND (@servicioLiquidado = 1 OR ((@servicioLiquidado IS NULL OR @servicioLiquidado = 0) AND cobOrigen <> 'Rectificativo'))
					 )>= 0)
		BEGIN
			--PRINT '!!!!!!!!!!!!!!!!!!!!!FACTURAS ANULADAS!!!!!!!!!!!!!!!!'
			SET @facturaVersion = (@facturaVersion - 1)
	END
	-------------------------------------------------------------------------------------------
	
	
	IF @servicioLiquidado IS NOT NULL BEGIN
	--Obtener total factura
	SELECT @facTotal = ISNULL(SUM(fclTotal),0) -- ******************* AÑADO ROUND PORQUE LO VA A COMPARAR CON EL COBRADO, QUE LLEVA 2 DECIMALES ***************
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
			SELECT @facNumLineas = COUNT(*), @facTotal = ISNULL(SUM(fclTotal),0)  -- ******************* AÑADO ROUND PORQUE LO VA A COMPARAR CON EL COBRADO, QUE LLEVA 2 DECIMALES ***************
			FROM faclin fl
			WHERE fclFacCod = @facturaCodigo AND fclFacPerCod = @periodo AND fclFacCtrCod = @contrato AND fclFacVersion = @facturaVersion
	END
		
	SELECT @facTotal2 = CAST(ISNULL(@facTotal, 0) AS DECIMAL(12,2))
		  
	
	--*********************************************
	--30774-BUGFIX: DESGLOSE PRIORITARIO EN LIQUIDACIONES
	--Veo que @esteCobroAnulaTodo se setea solo cuando la version de la factura > 1
	--SET @esteCobroAnulaTodo = IIF(@cobrosAnteriores + ROUND(@cblImporte, 2) = 0, 1, 0);
	DECLARE @cobrosAnterioresxScdxPag MONEY;
	DECLARE @numCobrosAnterioresxScdxPag INT;
	DECLARE @esteCobroAnulaxScdxPpag BIT = 0;
	
	SELECT @cobrosAnterioresxScdxPag = ISNULL(SUM(ROUND(CL.cblImporte, 2)), 0)
		 , @numCobrosAnterioresxScdxPag = COUNT(*) 
	FROM dbo.cobros AS C 
    	INNER JOIN dbo.coblin AS CL 
	ON  CL.cblScd = C.cobScd 
	AND CL.cblPpag = C.cobPpag 
	AND CL.cblNum = C.cobNum 
    	WHERE C.cobCtr = @contrato 
	  AND CL.cblPer = @periodo 
	  AND CL.cblFacVersion = @facturaVersion 
	  AND CL.cblFacCod = @facturaCodigo 
	  --Solo cobros inmediatamente anteriores a este
	  AND C.cobFecReg < @cobFecReg
	  AND C.cobScd = @cblScd
	  AND C.cobPpag = @cblPpag;


	SET @esteCobroAnulaxScdxPpag = IIF(@cobrosAnterioresxScdxPag + ROUND(@cblImporte, 2) = 0 AND @numCobrosAnterioresxScdxPag > 0, 1, 0);

	SELECT [facCodigo] = CL.cblFacCod 
		 , [facCtrCod] = C.cobCtr
		 , [facPerCod] = CL.cblPer 
		 , [facVersion] = CL.cblFacVersion
		 , [fclNumLinea] = CLD.cldFacLin
		 , [fclCobrado] = SUM(CLD.cldImporte)
	INTO #COBRADO
	FROM dbo.cobros AS C
	INNER JOIN dbo.coblin AS CL
	ON CL.cblScd = C.cobScd
	AND CL.cblPpag = C.cobPpag
	AND CL.cblNum = C.cobNum
	INNER JOIN dbo.cobLinDes AS CLD
	ON CLD.cldCblScd = CL.cblScd
	AND CLD.cldCblPpag = CL.cblPpag
	AND CLD.cldCblNum = CL.cblNum
	AND CLD.cldCblLin = CL.cblLin
	WHERE C.cobCtr = @contrato 
	  AND CL.cblPer = @periodo 
	  AND CL.cblFacVersion = @facturaVersion 
	  AND CL.cblFacCod = @facturaCodigo 
	  AND cobFecReg < @cobFecReg
	GROUP BY CL.cblFacCod, C.cobCtr, CL.cblPer, CL.cblFacVersion, CLD.cldFacLin;
	
	--SELECT @esteCobroAnulaxScdxPpag, [@cobrosAnterioresxScdxPag] = @cobrosAnterioresxScdxPag, @cblImporte
	--*********************************************
	
	--Comprobar si con este cobro el importe total cobrado se queda a 0
	IF  (@cobrosAnteriores + ROUND(@cblImporte, 2) = 0)  
		--** 30774-BUGFIX  ** Condicion que hace que no desglose bien si la version de la factura es 1
		--AND (@facVersionOriginal > 1)  
		--*******************
		AND (EXISTS(SELECT FL.fclNumLinea 
			    FROM  dbo.faclin AS FL
			    WHERE FL.fclFacCod = @facturaCodigo 
			    AND FL.fclFacPerCod = @periodo 
			    AND FL.fclFacCtrCod = @contrato 
			    AND FL.fclFacVersion = @facVersionOriginal 
			    AND FL.fcltotal > 0))

	SET @esteCobroAnulaTodo = 1;
	
	--Comprobar si la factura queda totalmente pagada con este cobro
	ELSE IF  (@cobrosAnteriores + ROUND(@cblImporte, 2) = @facTotal2) -- Lo comparo redondeado a dos decimales, como las líneas de cobro
		 AND (@facVersionOriginal > 1) 
		 AND (EXISTS(SELECT FL.fclNumLinea 
					 FROM  dbo.faclin AS FL 
					 WHERE FL.fclFacCod = @facturaCodigo 
					  AND  FL.fclFacPerCod = @periodo 
					  AND  FL.fclFacCtrCod = @contrato 
					  AND  FL.fclFacVersion = @facVersionOriginal 
					  AND  FL.fcltotal > 0))

	SET @esteCobroCuadraLaFactura = 1;

	--*****************
	--*** D E B U G ***
	--SELECT [@cobrosAnteriores] = @cobrosAnteriores, [@cblImporte] = @cblImporte, [@facTotal] = @facTotal, [@esteCobroAnulaTodo] = @esteCobroAnulaTodo, [@esteCobroCuadraLaFactura] = @esteCobroCuadraLaFactura
	--*****************
	
	--Si voy a hacer el reparto calculando las proporciones, necesito esta variable.
	--Es un acumulativo de importes proporcionales usados (al finalizar el cursor de líneas, el valor de éste ha de ser igual a cblImporte)
	DECLARE @sumCldImporte AS MONEY = 0
	DECLARE @totalQueda AS MONEY = 0

	DECLARE @facLineasImporte AS DECIMAL(12, 4) = @facTotal;
	
	--Variables para el cursor de factura
	DECLARE @fclNumLinea AS INT, @fclTotal AS MONEY, @fclTrfSvCod AS SMALLINT, @fclTrfCod AS SMALLINT, @numRegistro AS INT, @svcOrgCod AS INT


	DECLARE @fclOrgTotal AS MONEY;
	DECLARE @orgAnterior AS INT;
	DECLARE @orgRepartir AS MONEY;
	DECLARE @fclCobrado AS MONEY;
	
	--Recorrer líneas (servicios) de esta factura
	DECLARE cFaclin CURSOR FOR
	--*********************************************************************************
	--ATENCIÓN -> El ORDER BY de ROW_NUMBER() ha de ser el mismo que el de la SELECT:
	--Primero seleccionamos los servicios de Acuama, es decir, cuyo organismo es NULL. 
	--En un mismo organismo ordenamos primero los que su importe pendiente comparte signo con el importe del cobro
	--Entre los que comparten el mismo signo, ordenamos por el codigo del servicio 
	--Los últimos serán los servicios de terceros.	
	--*********************************************************************************
	SELECT  [numRegistro] = ROW_NUMBER() OVER(ORDER BY IIF(S.svcOrgCod IS NULL, 1,  9999) ASC
													 , IIF(SIGN(@cblImporte) = SIGN(FL.fclTotal-ISNULL(CB.fclCobrado, 0)), 0, 1) ASC
													 , S.svccod)
			, FL.fclNumLinea
			, FL.fclTotal
			, FL.fclTrfSvCod
			, FL.fclTrfCod
			, S.svcOrgCod 
		    --Sumatoria de las lineas por organismo
			, fclOrgTotal =  SUM(fclTotal) OVER(PARTITION BY IIF(svcOrgCod IS NULL, 0, 1))
		    --Organismo en la linea de factura anterior
			, orgAnterior = LAG(svcOrgCod) OVER(ORDER BY  IIF(svcOrgCod IS NULL, svccod, 9999), svccod)
			, fclCobrado = ISNULL(CB.fclCobrado, 0)		
	FROM dbo.faclin AS fl
	INNER JOIN dbo.servicios AS S 
	ON FL.fclTrfSvCod = S.svcCod	
	LEFT JOIN #COBRADO AS CB
	ON  CB.facCodigo   = fl.fclFacCod
	AND CB.facPerCod   = fl.fclFacPerCod
	AND CB.facCtrCod   = fl.fclfacCtrCod
	AND CB.facVersion  = fl.fclFacVersion
	AND CB.fclNumLinea = fl.fclNumLinea
	
	WHERE FL.fclFacPerCod = @periodo 
	  AND FL.fclFacCtrCod = @contrato 
	  AND FL.fclFacVersion = @facturaVersion 
	  AND FL.fclFacCod = @facturaCodigo 
	  AND 
		(@servicioLiquidado IS NULL OR ((((@lineaRectificada IS NULL OR @lineaRectificada = 0) AND DATEADD(dd, DATEDIFF(dd, 0, FL.fclFecLiq), 0) > DATEADD(dd, DATEDIFF(dd, 0, @cobFecReg), 0)) OR (@lineaRectificada = 1 AND DATEADD(dd, DATEDIFF(dd, 0, FL.fclFecLiq), 0) >= DATEADD(dd, DATEDIFF(dd, 0, @cobFecReg), 0))) OR (FL.fclFecLiq IS NULL AND FL.fclUsrLiq IS NULL))) 
		AND (@servicioLiquidado IS NULL OR @servicioLiquidado = 0 OR 
				    EXISTS(SELECT FL.fclTrfSvCod
								  FROM dbo.faclin AS fl1
								  WHERE fl1.fclFacCod = fl.fclFacCod AND
										fl1.fclFacPerCod = fl.fclFacPerCod AND
										fl1.fclFacCtrCod = fl.fclFacCtrCod AND
										fl1.fclFacVersion = fl.fclFacVersion AND
										fl1.fclTrfSvCod = fl.fclTrfSvCod AND 
										(fl1.fclFecLiq IS NULL OR (FL.fclFecLiq IS NOT NULL AND ((@lineaRectificada IS NULL OR @lineaRectificada = 0) AND FL.fclFecLiq > @cobFecReg) OR (@lineaRectificada = 1 AND FL.fclFecLiq >= @cobFecReg))) 
					      )   
			)
	
	--*********************************************************************************
	--ATENCIÓN -> El ORDER BY de la select ha de ser el mismo que el del ROW_NUMBER
	--*********************************************************************************
	ORDER BY IIF(S.svcOrgCod IS NULL, 1,  9999) ASC
	, IIF(SIGN(@cblImporte) = SIGN(FL.fclTotal-ISNULL(CB.fclCobrado, 0)), 0, 1) ASC
	, S.svccod

	--Comenzar cursor
	OPEN cFaclin
	FETCH NEXT FROM cFaclin INTO @numRegistro, @fclNumLinea, @fclTotal, @fclTrfSvCod, @fclTrfCod, @svcOrgCod
							   , @fclOrgTotal, @orgAnterior, @fclCobrado
	
	WHILE @@FETCH_STATUS = 0 BEGIN
		--Importe a insertar para este desglose
		DECLARE @cldImporte AS MONEY = 0
		--Si este cobro es el que va a dejar el total pagado = 0 -> el importe de esta línea es 
		--Si este cobro es el que va a dejar pagada la factura -> el importe de esta línea es lo que falta hasta llegar a pagar lo que se debe de ella
		--Además, si es el único cobro que hay, y el importe del cobro es igual al importe de la factura, directamente @cldImporte = @fclTotal, así me ahorro calcular proporciones tontamente, ya que la proporción es 1 a 1
		
		--*****************
		--*** D E B U G ***
		--SELECT [@esteCobroCuadraLaFactura] = @esteCobroCuadraLaFactura, [@esteCobroAnulaTodo] = @esteCobroAnulaTodo, [@esteCobroAnulaxScdxPpag]=@esteCobroAnulaxScdxPpag;
		--*****************
		
		IF @esteCobroCuadraLaFactura = 1 OR @esteCobroAnulaTodo = 1 
		BEGIN
			--PRINT '***********ENTRA AL IF**********'
			--Almacena el importe de los cobros anteriores a este servicio, de esta factura
			DECLARE @cobradoServicio AS MONEY = 0
			
			--PRINT '@numCobrosAnteriores-->' + CAST(@numCobrosAnteriores AS VARCHAR)
			--PRINT '@cobFecReg-->' + CAST(@cobFecReg AS VARCHAR)
			--PRINT '@fclTrfSvCod-->' + CAST(@fclTrfSvCod AS VARCHAR)
			--PRINT '@fclTrfCod-->' + CAST(@fclTrfCod AS VARCHAR)
			
			--Si no hay cobros anteriores, dejo el importe a 0, y me ahorro buscar si sé que no hay
			IF @numCobrosAnteriores > 0 
			BEGIN
				DECLARE @existenServicioTarifaRepetidos INT = 1

				SELECT @cobradoServicio = ISNULL(SUM(cldImporte), 0), @existenServicioTarifaRepetidos = COUNT(1) 
				FROM cobros
					INNER JOIN coblin ON cblScd = cobScd AND cblPpag = cobPpag AND cblNum = cobNum
					INNER JOIN cobLinDes ON cldCblScd = cblScd AND cldCblPpag = cblPpag AND cldCblNum = cblNum AND cldCblLin = cblLin
				WHERE cobCtr = @contrato AND cblPer = @periodo AND cblFacVersion = @facturaVersion AND cblFacCod = @facturaCodigo AND cldTrfSrvCod = @fclTrfSvCod AND cldTrfCod = @fclTrfCod  AND --cldFacLin = @fclNumLinea AND
					  cobFecReg <= @cobFecReg AND (cblScd <> ISNULL(@cblScd, -1) OR cblPpag <> ISNULL(@cblPpag, -1) OR cblNum <> ISNULL(@cblNum, -1) OR cblLin <> ISNULL(@cblLin, -1))
				
				
				-- Si tiene más de una línea de factura para ese servicio/tarifa cogemos el de la línea de factura especificada en el desglose (cldFacLin = @fclNumLinea)
				IF @existenServicioTarifaRepetidos > 1 
				BEGIN
					SELECT @cobradoServicio = ISNULL(SUM(cldImporte), 0)
					FROM cobros
						INNER JOIN coblin ON cblScd = cobScd AND cblPpag = cobPpag AND cblNum = cobNum
						INNER JOIN cobLinDes ON cldCblScd = cblScd AND cldCblPpag = cblPpag AND cldCblNum = cblNum AND cldCblLin = cblLin
					WHERE cobCtr = @contrato AND cblPer = @periodo AND cblFacVersion = @facturaVersion AND cblFacCod = @facturaCodigo AND cldTrfSrvCod = @fclTrfSvCod AND cldTrfCod = @fclTrfCod  AND cldFacLin = @fclNumLinea AND
						  cobFecReg <= @cobFecReg AND (cblScd <> ISNULL(@cblScd, -1) OR cblPpag <> ISNULL(@cblPpag, -1) OR cblNum <> ISNULL(@cblNum, -1) OR cblLin <> ISNULL(@cblLin, -1))
				END					  
			END
			
			--*****************
			--*** D E B U G ***
			--SELECT [@fclTotal] = @fclTotal,  [@cobradoServicio] = @cobradoServicio; 
			--*****************
			
			--Si este cobro "salda" la factura: el importe del cobro de este servicio ha de ser el total facturado del servicio, menos el cobrado a este servicio de las facturas anteriores
			IF @esteCobroCuadraLaFactura = 1 SET @cldImporte = @fclTotal - @cobradoServicio
			--Si este cobro deja todo lo cobrado del servicio a 0: el importe del cobro del servicio ha de ser -1*cobrado del servicio
			ELSE IF @esteCobroAnulaTodo = 1 SET @cldImporte = -@cobradoServicio --print 'anula todo++++++++++++++++'
		--Si no -> proporcional, y cuadrando el importe del cobro en la última línea del desglose
		END 
		
		--*********************************************
		--30774-BUGFIX: DESGLOSE PRIORITARIO EN LIQUIDACIONES
		ELSE IF @esteCobroAnulaxScdxPpag = 1
		BEGIN	
			SELECT @cldImporte = ISNULL(SUM(cldImporte), 0) 
			FROM dbo.cobros AS C
			INNER JOIN dbo.coblin AS CL 
			ON  CL.cblScd = C.cobScd 
			AND CL.cblPpag = C.cobPpag 
			AND CL.cblNum  = C.cobNum
			INNER JOIN dbo.cobLinDes AS CLD 
			ON  CLD.cldCblScd = CL.cblScd 
			AND CLD.cldCblPpag = CL.cblPpag 
			AND CLD.cldCblNum = CL.cblNum 
			AND CLD.cldCblLin = CL.cblLin
			WHERE C.cobCtr = @contrato 
			  AND CL.cblPer = @periodo 
			  AND CL.cblFacVersion = @facturaVersion 
			  AND CL.cblFacCod = @facturaCodigo 
			  AND CLD.cldFacLin = @fclNumLinea
			  AND CLD.cldTrfCod = @fclTrfCod  
			  AND CL.cblScd = @cblScd 
			  AND CL.cblPpag = @cblPpag
			  AND C.cobFecReg < @cobFecReg;
			 
			 SET @cldImporte = -1 * @cldImporte; 
		END
		--*********************************************

		ELSE 
		BEGIN
		
			/*
			PRINT '!!!!!ENTRA AL ELSE!!!!!!!'
			PRINT '@cblImporte-->' + CAST(@cblImporte AS VARCHAR)
			PRINT '@facTotal-->' + CAST(@facTotal AS VARCHAR)
			*/

			SELECT @cobradoServicio = ISNULL(SUM(cldImporte), 0)
			FROM cobros
				INNER JOIN coblin ON cblScd = cobScd AND cblPpag = cobPpag AND cblNum = cobNum
				INNER JOIN cobLinDes ON cldCblScd = cblScd AND cldCblPpag = cblPpag AND cldCblNum = cblNum AND cldCblLin = cblLin
			WHERE cobCtr = @contrato AND cblPer = @periodo AND cblFacVersion = @facturaVersion AND cblFacCod = @facturaCodigo AND cldTrfSrvCod = @fclTrfSvCod AND cldTrfCod = @fclTrfCod  
					  AND cldFacLin = @fclNumLinea 
					  AND cobFecReg <= @cobFecReg AND (cblScd <> ISNULL(@cblScd, -1) OR cblPpag <> ISNULL(@cblPpag, -1) OR cblNum <> ISNULL(@cblNum, -1) OR cblLin <> ISNULL(@cblLin, -1))

			
			--Si el importe del cobro es igual al importe de la factura -> El importe del desglose es igual al importe de la línea de factura
			IF ABS(ROUND(@cblImporte, 2)) = @facTotal2 -- Lo comparo redondeado a dos decimales, como las líneas de cobro
			  BEGIN 
				SET @cldImporte = @fclTotal * SIGN(@cblImporte)
			  END
			ELSE
			--Si no, lo repartimos asignando el céntimo que sobra a la última línea, teniendo en cuenta el orden establecido
			  BEGIN
				IF @cobrosAnteriores + ROUND(@cblImporte, 2) = @facTotal2 -- Lo comparo redondeado a dos decimales, como las líneas de cobro
				BEGIN -- Lo comparo redondeado a dos decimales, como el cobro
					
					--*****************
					--*** D E B U G ***
					--SELECT [@cldImporte] = @cldImporte, [@fclTotal] = @fclTotal,  [@cobradoServicio] = @cobradoServicio , [@fclTotal - @cobradoServicio] = @fclTotal - @cobradoServicio;
					--*****************
					SET @cldImporte = @fclTotal - @cobradoServicio
				END 
				ELSE 
				BEGIN
	
					--Repartimos el cobro entre los distintos servicios activos
					SET @totalQueda =  @cblImporte - @sumCldImporte;
					
					--**************************
					--Si hay cambio de Organismo el restante lo repartimos proporcionalmente
					IF(@orgAnterior IS NULL OR @orgAnterior<>@svcOrgCod)
					BEGIN
						SET @orgRepartir = @totalQueda; 
					END
					--**************************
					SET @fclImportePte = @fclTotal-@cobradoServicio;
					
					DECLARE @factor AS DECIMAL(12, 4);

					IF(@svcOrgCod IS NULL AND @totalQueda <> 0)
					BEGIN
						SET @facLineasImporte -= @fclTotal;
					END		
					
					DECLARE @DEVOLUCION_PDTE INT = -1;
					DECLARE @COBRO_PDTE INT = 1;
					DECLARE @COBRADO INT = 0;

					DECLARE @cobroTipo INT = CASE WHEN(@fclImportePte < 0) THEN @DEVOLUCION_PDTE
											      WHEN(@fclImportePte > 0) THEN @COBRO_PDTE
											      WHEN(@fclImportePte = 0) THEN @COBRADO END
				
					--Primero repartimos el cobro entre los servicios de Acuama de más a menos importante.
					--El cobro total se reparte en primer lugar entre el servicio de acuama hasta el total del importe del servicio.
					--Si hay más cobro Total, se reparte entre el siguiente servicio de Acuama...  
					--Si aún sobra cobro Total, lo repartimos entre los servicios de terceros de manera proporcional		
					IF (@facTotal = 0 OR @fclTotal=0 OR @totalQueda=0 )
						SET @cldImporte = 0
					
					ELSE IF(@cobroTipo = @COBRADO AND @totalQueda < 0 AND @svcOrgCod IS NULL) 
						SET @cldImporte = IIF(ABS(@totalQueda) >= @fclTotal, @fclTotal * SIGN(@totalQueda) , @totalQueda);

					ELSE IF(@cobroTipo = @COBRO_PDTE AND @fclCobrado=0 AND @totalQueda < 0 AND @svcOrgCod IS NULL) 
						SET @cldImporte = 0;
					
					ELSE IF(@cobroTipo = @COBRO_PDTE AND @svcOrgCod IS NULL) 
						SET @cldImporte = IIF(ABS(@totalQueda) >= @fclImportePte, @fclImportePte * SIGN(@totalQueda) , @totalQueda);
											
					ELSE IF(@cobroTipo = @DEVOLUCION_PDTE AND SIGN(@fclImportePte) <> SIGN(@totalQueda)  AND @svcOrgCod IS NULL) 
						SELECT @cldImporte = @fclImportePte, @totalQueda = @totalQueda - @fclImportePte;
					
					ELSE IF(@cobroTipo = @DEVOLUCION_PDTE AND @fclImportePte <= @totalQueda AND @svcOrgCod IS NULL) 
						SET @cldImporte = @totalQueda;
					
					ELSE IF(@cobroTipo = @DEVOLUCION_PDTE AND @fclImportePte > @totalQueda AND @svcOrgCod IS NULL)
						SET @cldImporte = @fclImportePte;

			    	ELSE IF (@svcOrgCod IS NOT NULL)
					BEGIN
						--El resto del importe se distribuye proporcionalmente a las lineas que quedan pendiente de desglose
						SET @factor = CAST(@fclTotal AS DECIMAL(12, 4)) / @fclOrgTotal;
						
						SET @cldImporte = (@factor * @orgRepartir);
					END	
					ELSE
					BEGIN
						SET @cldImporte = 0										
					END

					SET @sumCldImporte =  @sumCldImporte + @cldImporte;
					 					
				
					--Si es la última línea de factura, y sobra algún céntimo, vamos a meterlo aquí
					IF @numRegistro = @facNumLineas AND @sumCldImporte <> @cblImporte 
					BEGIN
						SET @cldImporte = @totalQueda;
					END

					--*****************
					--*** D E B U G ***
					--Hay segun el valor del organismo:
					--IS NULL:  Se empieza repartiendo el importe de cobro entre las lineas por orden de servicio.
					--NOT NULL: Una vez saldadas las lineas, se reparte el resto proporcionalmente 
					--*****************

					--SELECT [@fclOrgTotal] = @fclOrgTotal
					--	 , [@cobroTipo] = @cobroTipo
					--	 , [@facTotal] = @facTotal
					--	 , [@facTotal2] =@facTotal2
					--	 , [@numCobrosAnteriores] = @numCobrosAnteriores
					--	 , [@cobrosAnteriores]=@cobrosAnteriores
					--	 , [@esteCobroCuadraLaFactura] = @esteCobroCuadraLaFactura
					--	 , [@esteCobroAnulaTodo] = @esteCobroAnulaTodo
					--	 , [@cobradoServicio] = @cobradoServicio
					--	 , [@cblImporte]=@cblImporte
					--	 , [@sumCldImporte]=@sumCldImporte
					--	 , [@svcOrgCod] = @svcOrgCod
					--	 , [@orgRepartir] = @orgRepartir
					--	 , [@totalQueda]=@totalQueda
					--	 , [@fclImportePte] = @fclImportePte
					--	 , [@fclTotal] = @fclTotal
					--	 , [@facLineasImporte] = @facLineasImporte
					--	 , [@cldImporte] = @cldImporte		
					--	 , [@factor] = @factor
					--	 , [@fclImportePte] = @fclImportePte
					--	 , [@fclCobrado] = @fclCobrado;
						 
						
				  END
			    END
		END
		
		
		--Insertar línea de desglose
		INSERT INTO #cobLinDes (cldCblScd, cldCblPpag, cldCblNum, cldCblLin, cldFacLin, cldTrfSrvCod, cldTrfCod, cldImporte)
		VALUES (@cblScd, @cblPpag, @cblNum, @cblLin, @fclNumLinea, @fclTrfSvCod, @fclTrfCod, @cldImporte)
 		--Siguiente línea de factura
		FETCH NEXT FROM cFaclin INTO @numRegistro, @fclNumLinea, @fclTotal, @fclTrfSvCod, @fclTrfCod, @svcOrgCod
								   , @fclOrgTotal, @orgAnterior, @fclCobrado
	END
	CLOSE cFaclin
	DEALLOCATE cFaclin
	
	--¿Insertar desglose? (SÓLO PARA LA FORMA A, SI NO SE PRODUCIRÁ UN ERROR PORQUE LA PK SERÁ NULL)
	IF @insertarDesgloseGenerado = 1 BEGIN
		BEGIN TRANSACTION
		
		--Borrar desglose existente
		DELETE cobLinDes WHERE cldCblScd = @cblScd AND cldCblPpag = @cblPpag AND cldCblNum = @cblNum AND cldCblLin = @cblLin
		SET @myError = @@ERROR IF @myError <> 0 GOTO ERROR
		
		--Insertar desglose generado
		INSERT INTO cobLinDes 
		SELECT * FROM #cobLinDes
		
		SET @myError = @@ERROR IF @myError <> 0 GOTO ERROR
		
		IF ((@todasLasVersiones IS NULL OR @todasLasVersiones = 1) AND NOT EXISTS(SELECT cldCblNum FROM cobLinDes WHERE cldCblScd = @cblScd AND cldCblPpag = @cblPpag AND cldCblNum = @cblNum AND cldCblLin = @cblLin))
		BEGIN
			EXEC @myError = [dbo].[CobLin_GenerarDesglose_TodasVersiones] @cblScd, @cblPpag, @cblNum, @cblLin
			IF @myError <> 0 GOTO ERROR
		END
		
		COMMIT TRANSACTION
	END
	
	--*********************
	--FIN -> DEVOLVER TABLA: 
	--[SYR-316305]Es requerido cuando haces editar consumo de la factura
	SELECT * FROM #cobLinDes
	--*********************

	DROP TABLE #cobLinDes;

	IF OBJECT_ID(N'tempdb..#COBRADO') IS NOT NULL DROP TABLE #COBRADO;
	RETURN 0
	
ERROR:

	IF OBJECT_ID(N'tempdb..#cobLinDes') IS NOT NULL DROP TABLE #cobLinDes;
	IF OBJECT_ID(N'tempdb..#COBRADO') IS NOT NULL DROP TABLE #COBRADO;
	
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION

	
	


GO


