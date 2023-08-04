/*
DECLARE @zona VARCHAR(4) = 'RO02'
DECLARE @periodo VARCHAR(6) = '202104'
DECLARE @contratoCodigo INT = NULL
----***************************
DECLARE @anadirContratosNuevos BIT = 1			--Añade contratos nuevos a la apertura
DECLARE @anadirServiciosNuevos BIT = 1			--Añade servicios nuevos a la apertura
DECLARE @reinsertarServiciosExistentes BIT = 0	--Reinserta las líneas de las prefacturas existentes
----***************************
DECLARE @tskUser VARCHAR(10)= 'gmdesousa'
DECLARE @tskType SMALLINT= 50
DECLARE @tskNumber INT= 2
----***************************
DECLARE @facturasAfectadas AS INT
DECLARE @facturasError AS INT 
DECLARE @otrosErrores AS VARCHAR(3) 

DECLARE @T INT;
EXEC @T = [dbo].[Tasks_Facturas_AmpliacionAperturaPorContrato] @zona, @periodo, @contratoCodigo, @anadirContratosNuevos
														, @anadirServiciosNuevos, @reinsertarServiciosExistentes
														, @tskUser, @tskType, @tskNumber, @facturasAfectadas OUT, @facturasError OUT, @otrosErrores OUT

SELECT facturasAfectadas=@facturasAfectadas, facturasError=@facturasError, otrosErrores=@otrosErrores, RESULT= @T

*/
ALTER PROCEDURE [dbo].[Tasks_Facturas_AmpliacionAperturaPorContrato]
----***************************
  @zona VARCHAR(4)
, @periodo VARCHAR(6)
, @contratoCodigo INT = NULL
----***************************
, @anadirContratosNuevos BIT = NULL			--Añade contratos nuevos a la apertura
, @anadirServiciosNuevos BIT = NULL			--Añade servicios nuevos a la apertura
, @reinsertarServiciosExistentes BIT = NULL	--Reinserta las líneas de las prefacturas existentes
----***************************
, @tskUser VARCHAR(10)= NULL
, @tskType SMALLINT= NULL
, @tskNumber INT= NULL
----***************************
, @facturasAfectadas AS INT OUT
, @facturasError AS INT OUT
, @otrosErrores AS VARCHAR(3) OUT
AS
	SET NOCOUNT ON;

	--**************
	--[0000]OUTPUT
	SELECT @facturasAfectadas = 0
		 , @anadirContratosNuevos = ISNULL(@anadirContratosNuevos, 0)
		 , @anadirServiciosNuevos = ISNULL(@anadirServiciosNuevos, 0)
		 , @reinsertarServiciosExistentes = ISNULL(@reinsertarServiciosExistentes, 0);
	
	--**************
	--[0000]VARIABLES
	DECLARE @RESULT AS BIT = 0;
	
	DECLARE @PARAMS_ERROR AS BIT = 0;
	DECLARE @PERZONA_ERROR AS BIT = 0;
	DECLARE @LOTES_ERROR AS BIT = 0;

	DECLARE @facturasInsertadas AS INT = 0;
	DECLARE @loteNuevasFacturas AS INT = 9999;
	
	DECLARE @tskLog AS dbo.tLog;
	DECLARE @AHORA DATETIME = (SELECT dbo.GetAcuamaDate());
	DECLARE @explotacion AS VARCHAR(50) = NULL;
	DECLARE @facApertura AS VARCHAR(50) = NULL;
	DECLARE @CURSOR_ROWS AS INT = 0; 
	DECLARE @totalSteps AS INT = 0 + 1 +1; --1Paso por cada factura + 1Paso UPDATE perzona.przFAperNReg, +1Paso PerzonaLote_AsignarLote
	DECLARE @tFacturasKO AS dbo.tFacturasPK;
	DECLARE @tskStartedDate DATETIME;
	DECLARE @taskCall AS BIT = IIF(@tskUser IS NOT NULL AND @tskType IS NOT NULL AND @tskNumber IS NOT NULL, 1, 0);
	DECLARE @spLog VARCHAR(150);
	
	DECLARE @facInserted BIT;
	DECLARE @facUpdated BIT;
	DECLARE @facOperacion VARCHAR(15);

	DECLARE @fechaPeriodoDesde AS DATETIME;
	DECLARE @fechaPeriodoHasta AS DATETIME;

	--**************
	--[0000]CURSOR
	DECLARE @codigoContrato AS INT;
	DECLARE @versionContrato AS SMALLINT;
	DECLARE @codigoCliente AS INT;
	DECLARE @fechaAltaContrato AS DATETIME;
	DECLARE @fechaBajaContrato AS DATETIME;

	DECLARE @ctrbaja AS BIT;
	DECLARE @existePrefactura AS BIT;
	
	DECLARE @lecturaAnterior AS INT;
	DECLARE @fechaLecturaAnterior AS DATETIME;
	
	DECLARE @serviciosInsertados AS INT;
	DECLARE @facturaInsertada AS BIT;

	--******************
	--[0000]EXPLOTACION
	SELECT @explotacion = CAST(ISNULL(P.pgsvalor,'') AS VARCHAR)
	FROM dbo.parametros AS P
	WHERE P.pgsclave = 'EXPLOTACION';

	--******************
	--[0000]FAC_APERTURA
	SELECT @facApertura = CAST(ISNULL(P.pgsvalor,'') AS VARCHAR)
	FROM dbo.parametros AS P
	WHERE P.pgsclave = 'FAC_APERTURA';

	--******************
	--[0000]PERZONA: Fechas de la apertura del periodo/zona
	SELECT @fechaPeriodoDesde = P.przfPeriodoD
		 , @fechaPeriodoHasta = P.przfPeriodoH
	FROM dbo.perzona AS P
	WHERE P.przCodZon = @zona 
	  AND P.przCodPer = @periodo;

	--******************
	--[0001]ERRORLOG: Inicio
	INSERT INTO @tskLog VALUES('INFO', 'INICIO', 'Ampliacion de apertura', NULL, dbo.GetAcuamaDate());

	INSERT INTO @tskLog VALUES
	  ('INFO', '@zona', @zona, 'Parametro', NULL)
	, ('INFO', '@periodo', @periodo, 'Parametro', NULL)
	, ('INFO', '@fechaPeriodoDesde', FORMAT(@fechaPeriodoDesde, 'dd-MM-yyyy'), 'Parametro', NULL)
	, ('INFO', '@fechaPeriodoHasta', FORMAT(@fechaPeriodoHasta, 'dd-MM-yyyy'), 'Parametro', NULL)
	, ('INFO', '@explotacion',@explotacion, 'Configuracion', NULL)
	, ('INFO', 'FAC_APERTURA', @facApertura, 'Configuracion', NULL);
	
	IF @taskCall = 1 
	EXEC [dbo].[Task_Schedule_START] @tskUser, @tskType, @tskNumber, @tskStartedDate OUT; 
	--******************

	BEGIN TRY
		--**************
		--[1001]PARAMETROS
		--Comprobamos que las variables requeridas estan inicializadas antes de continuar
		SET @spLog = 'Inicializando Parametros';
		IF ((@anadirContratosNuevos = 0 AND @anadirServiciosNuevos = 0 AND @reinsertarServiciosExistentes = 0) 
			OR @periodo IS NULL 
			OR @zona IS NULL 
			OR @fechaPeriodoDesde IS NULL 
			OR @fechaPeriodoHasta IS NULL)
		BEGIN
			SET @PARAMS_ERROR = 1;
			THROW 51000, 'No ha sido posible inicializar los parametros requeridos.', 0;
		END

		--**************
		--[1002]CONTRATOS
		SET @spLog = 'Seleccionando Contratos';
		WITH CTR AS(
		SELECT C.ctrcod
			 , C.ctrVersion
			 , C.ctrBaja
			 , C.ctrFecAnu
			--Sólo contratos dentro del periodo
			, CtrActivo =
			  CASE	WHEN @explotacion = 'AVG' AND (C.ctrbaja = 0) THEN 1
					WHEN @explotacion <>'AVG' AND (C.ctrFecAnu IS NULL OR C.ctrFecAnu >= @fechaPeriodoDesde) THEN 1
					ELSE 0 END  
			--RN=1: Ultima version del contrato
			, RN = ROW_NUMBER() OVER (PARTITION BY  C.ctrcod ORDER BY C.ctrVersion DESC) 
		FROM dbo.contratos AS C)
		
		SELECT *
		INTO #CTR
		FROM CTR WHERE RN=1;
		
		--**************
		--[1003]REINSERTAR SERVICIOS: Borrar las lineas
		SET @spLog = 'REINSERTAR SERVICIOS: Borrar las lineas';
		DELETE FL
		FROM dbo.facturas AS F
		INNER JOIN dbo.faclin AS FL
		ON  F.facCod = FL.fclFacCod 
		AND F.facCtrCod = FL.fclFacCtrCod 
		AND F.facVersion = FL.fclFacVersion 
		AND F.facPerCod = FL.fclFacPerCod
		AND F.facPerCod = @periodo
		AND F.facZonCod = @zona
		AND (@contratoCodigo IS NULL OR F.facctrcod = @contratoCodigo)
		AND F.facNumero IS NULL 
		AND F.facFechaRectif IS NULL
		INNER JOIN #CTR AS C
		ON  C.ctrCod = F.facCtrCod
		--Incluimos la opcion ctrActivo para evitar borrar lineas que luego no se van a reinsertar.
		AND C.CtrActivo = 1
		AND @reinsertarServiciosExistentes = 1;

		--**************
		--[2000]CURSOR
		--Selección de contratos
		SET @spLog = 'facturas';
		DECLARE cContratos CURSOR STATIC FOR
		SELECT ctrCod, ctrVersion, ctrTitCod, ctrFecIni, ctrFecAnu,ctrbaja, existePrefactura
		 , lecturaAnterior = 0
		 , fechaLecturaAnterior=NULL
		FROM(
			SELECT ctrCod, ctrVersion, ctrZonCod, ctrTitCod, ctrFecIni, ctrFecAnu,ctrbaja, 0 AS existePrefactura
			FROM contratos c
			WHERE @anadirContratosNuevos = 1 AND
				  NOT EXISTS (SELECT facCtrCod 
									FROM facturas f 
									WHERE facCtrCod = ctrCod AND 
										 (facPerCod = @periodo OR 
										    ( 
												(SELECT ISNULL(SUM(fcltotal),0)
													 FROM faclin 
													 INNER JOIN facturas ON fclFacCod = facCod and fclFacPerCod = facPerCod and fclFacCtrCod = facCtrCod and fclFacVersion = facVersion
													 WHERE fclFacPerCod = '000002' AND
														   fclFacCtrCod = f.facCtrCod AND
														   facFechaRectif IS NULL
												 ) > 0
											 )
										  )
							  ) --no tiene pre/factura creada, o se facturó la baja
					AND (@contratoCodigo IS NULL OR ctrcod = @contratoCodigo)
			UNION
			SELECT ctrCod, ctrVersion, ctrZonCod, ctrTitCod, ctrFecIni, ctrFecAnu,ctrbaja, 1 AS existePrefactura
			FROM contratos c
			WHERE (@anadirServiciosNuevos = 1 OR @reinsertarServiciosExistentes = 1) AND 
				  EXISTS (SELECT facCtrCod FROM facturas WHERE facCtrCod = ctrCod AND facPerCod = @periodo AND facNumero IS NULL AND facFechaRectif IS NULL) --Tiene prefactura creada
				  AND (@contratoCodigo IS NULL OR ctrcod = @contratoCodigo)
		 ) AS c
		 WHERE ctrZonCod = @zona AND
			   ctrFecIni <= @fechaPeriodoHasta AND
			 -- (ctrFecAnu >= @fechaPeriodoDesde OR ctrFecAnu IS NULL) AND
			  (
				  ( (ctrFecAnu >= @fechaPeriodoDesde OR ctrFecAnu IS NULL) AND @explotacion <> 'AVG') OR --Sólo contratos dentro del periodo
				  ( (ctrbaja = 0  ) AND @explotacion = 'AVG')  				  
              ) 
		
		AND

			   ctrVersion = (SELECT MAX(ctrVersion) FROM contratos cSub WHERE c.ctrCod = cSub.ctrCod) AND --última versión del contrato
			   EXISTS (SELECT ctsCtrCod FROM contratoServicio WHERE ctsCtrCod = c.ctrCod) --debe tener servicios
			   AND (@contratoCodigo IS NULL OR ctrcod = @contratoCodigo)
		OPEN cContratos
	
		--**************
		--[2001]Actualizamos el nº de pasos de la tarea (1 por contrato)
		SET @CURSOR_ROWS = @@CURSOR_ROWS;
		SET @totalSteps = @totalSteps + @CURSOR_ROWS;
	
		IF @taskCall = 1 
		EXEC Task_Schedule_SetTotalSteps @tskUser, @tskType, @tskNumber, @totalSteps;
		
		--**************
		--[2999]Num.Facturas
		INSERT INTO @tskLog VALUES('INFO', 'Num.Facturas', CAST(@CURSOR_ROWS AS VARCHAR), 'Contratos a facturar', dbo.GetAcuamaDate());		
		
		--**************
		--[3000]CURSOR		
		FETCH NEXT FROM cContratos
		INTO @codigoContrato, @versionContrato, @codigoCliente, @fechaAltaContrato, @fechaBajaContrato, @ctrbaja, @existePrefactura
		  , @lecturaAnterior, @fechaLecturaAnterior;

		WHILE @@FETCH_STATUS = 0
		BEGIN
			BEGIN TRY
				--****************
				BEGIN TRANSACTION;
				
				--[3011]Si no existe la prefactura de este contrato => Tengo que insertar la cabecera
				--Obtengo la lectura anterior y la fecha de la lectura anterior
				IF @existePrefactura = 0 OR @explotacion ='AVG' 
					EXEC Contratos_ObtenerUltimaLectura @codigoContrato, NULL, @lecturaAnterior OUT, @fechaLecturaAnterior OUT
				ELSE 
					SELECT @lecturaAnterior = NULL, @fechaLecturaAnterior = NULL;
				
				--[3012]Llamada al procedimiento que inserta una factura (o sus líneas)
				EXEC Facturas_InsertApertura  @existePrefactura, @periodo, @codigoContrato, @versionContrato, @codigoCliente, @zona, @lecturaAnterior, @fechaLecturaAnterior, @tskUser, @fechaAltaContrato, @fechaBajaContrato, @fechaPeriodoDesde, @fechaPeriodoHasta
											, @serviciosInsertados OUT, @facturaInsertada OUT;

				--[3013]Contabilizar el tipo de operación en la tabla facturas
				SELECT @facInserted = IIF(@existePrefactura = 0 AND @facturaInsertada = 1, 1, 0)
					 , @facUpdated	= IIF(@existePrefactura = 1 AND @serviciosInsertados > 0, 1, 0);
				
				SELECT @facturasInsertadas = @facturasInsertadas + IIF(@facInserted=1, 1, 0)
					 , @facturasAfectadas  = @facturasAfectadas  + IIF(@facInserted=1 OR @facUpdated=1, 1, 0);
				
				--[3014]Si la prefactura no existía tengo que poner el lote
				-- **** Se ha insertado la factura, o se le han insertado servicios => Marcar factura como modificada por la ampliación
				UPDATE F SET
				  F.facLote = IIF(@facInserted = 1, @loteNuevasFacturas, F.facLote) 
				, F.facUsrAmplApertura = @tskUser
				, F.facNumTareaAmplApertura = @tskNumber 
				FROM dbo.facturas AS F
				WHERE (@facInserted=1 OR @facUpdated=1) --Se ha insertado la factura, o se le han insertado servicios 
				  AND (F.facCtrCod = @codigoContrato AND F.facPerCod = @periodo AND F.facVersion = 1 AND F.facCod = 1);	 				
				
				--**************
				--[3900]CtrCod OK
				SELECT @facOperacion = CASE WHEN @facInserted = 1 THEN 'OK: Nueva'
											WHEN @facUpdated = 1  THEN 'OK: Actualizada'
											ELSE 'OK' END
				INSERT INTO @tskLog VALUES('OK', 'ctrCod', CAST(@codigoContrato AS VARCHAR), @facOperacion, NULL);	
				
				COMMIT TRANSACTION;	
				--****************	
			END TRY
			BEGIN CATCH
				--****************	
				ROLLBACK TRANSACTION;
				--****************	
				SET @RESULT = 1;

				--**************
				--[3900]CtrCod KO
				INSERT INTO @tskLog VALUES('ERROR', 'ctrCod', CAST(@codigoContrato AS VARCHAR), 'ERROR: '+ ERROR_MESSAGE(), dbo.GetAcuamaDate());
				INSERT INTO @tFacturasKO VALUES(0, @periodo, @codigoContrato, 0);	
			END CATCH	

			--[****]Actualizamos el avance
			IF @taskCall=1 EXEC Task_Schedule_PerformStep @tskUser, @tskType, @tskNumber;

		FETCH NEXT FROM cContratos
		INTO @codigoContrato, @versionContrato, @codigoCliente, @fechaAltaContrato, @fechaBajaContrato, @ctrbaja, @existePrefactura
		  , @lecturaAnterior, @fechaLecturaAnterior;
		END
		CLOSE cContratos;
		DEALLOCATE cContratos;

		--**************
		--[4000]FIN loop-contratos
		SELECT @facturasError = COUNT(1) FROM @tFacturasKO;

		DECLARE @tipoLog VARCHAR(15);  
		DECLARE @msgLog VARCHAR(250);  

		SET @tipoLog = CASE WHEN @facturasError=0 THEN 'OK'
							WHEN @facturasInsertadas + @facturasAfectadas=0 THEN 'ERROR'
							ELSE 'AVISO' END;

		SET @msgLog = CASE @tipoLog WHEN 'OK' THEN 'Ampliación apertura completa'
									WHEN 'ERROR' THEN 'No ha sido posible ampliar la apertura de ninguna factura'
									ELSE 'Hay facturas con fallos en la ampliacion' END 	

		
		INSERT INTO @tskLog VALUES(@tipoLog
								, '#Facturas Insertadas'
								, CAST(@facturasInsertadas AS VARCHAR)
								,  @msgLog
								, NULL);
		
		INSERT INTO @tskLog VALUES(@tipoLog
								, '#Facturas Actualizadas'
								, CAST(@facturasAfectadas AS VARCHAR)
								,  @msgLog
								, NULL);
		INSERT INTO @tskLog VALUES(IIF(@facturasError > 0,  'ERROR', 'OK')
								,'#Facturas ERROR'
								, CAST(@facturasError AS VARCHAR)
								, @msgLog
								, NULL);

		--*************************
		--TABLAS RELACIONADAS	
		--*************************
		--[5001]PERZONA el nº de registros insertados	
		
		SET @spLog = 'UPDATE perzona';
		IF @facturasInsertadas > 0  AND  @anadirContratosNuevos = 1
		BEGIN
			BEGIN TRY

				UPDATE PZ
				SET PZ.przFAperNReg = @facturasInsertadas + ISNULL(PZ.przFAperNReg, 0)
				FROM dbo.perzona AS PZ
				WHERE przcodzon = @zona AND przcodper = @periodo;
				
				--**************
				--[5099]perzona
				INSERT INTO @tskLog VALUES('OK', @spLog,  CONCAT(@periodo, ', ', @zona), 'OK', NULL);
			END TRY
			BEGIN CATCH
				--**************
				--[5099]perzona
				SET @PERZONA_ERROR=1;
				INSERT INTO @tskLog VALUES('ERROR', @spLog,  CONCAT(@periodo, ', ', @zona), 'ERROR: ' + ERROR_MESSAGE(), NULL);		
			END CATCH	
		END

		--[****]Actualizamos el avance
		IF @taskCall=1 EXEC Task_Schedule_PerformStep @tskUser, @tskType, @tskNumber;

		--*************************
		--[5100]Asignamos lotes a las facturas
		--SET @spLog = 'perzonalote';
		IF @facturasInsertadas > 0  AND  @anadirContratosNuevos = 1
		BEGIN 
			BEGIN TRY	
				IF EXISTS(SELECT PL.przlcodzon FROM dbo.perzonalote AS PL WHERE PL.przlcodzon = @zona AND PL.przlcodper = @periodo AND PL.przllote = @loteNuevasFacturas)	
				BEGIN
					INSERT INTO @tskLog VALUES('INSERT', @spLog,  CONCAT(@periodo, ', ', @zona), 'OK', NULL);	
					INSERT INTO dbo.perzonalote(przlcodzon, przlcodper, przllote, przlnreg)
					VALUES (@zona, @periodo, @loteNuevasFacturas, @facturasInsertadas);
				END
				ELSE
				BEGIN	 
					INSERT INTO @tskLog VALUES('UPDATE', @spLog,  CONCAT(@periodo, ', ', @zona), 'OK', NULL);	
					UPDATE PL SET PL.przlnreg = ISNULL(przlnreg,0) + @facturasInsertadas 
					FROM dbo.perzonalote AS PL
					WHERE PL.przlcodzon = @zona AND PL.przlcodper = @periodo AND PL.przllote = @loteNuevasFacturas;
				END
				--**************
				--[5199]perzonalote
				INSERT INTO @tskLog VALUES('OK', @spLog,  CONCAT(@periodo, ', ', @zona), 'OK', NULL);	
			END TRY			
			BEGIN CATCH
				
				SET @LOTES_ERROR = 1;

				--**************
				--[5199]perzonalote
				INSERT INTO @tskLog VALUES('ERROR', @spLog,  CONCAT(@periodo, ', ', @zona), 'ERROR: ' + ERROR_MESSAGE(), NULL);	
			END CATCH
			
			--**************
			
		END
		--[****]Actualizamos el avance
		IF @taskCall=1 EXEC Task_Schedule_PerformStep @tskUser, @tskType, @tskNumber;

	END TRY
	BEGIN CATCH
		INSERT INTO @tskLog VALUES('ERROR', @spLog,  CONCAT(@periodo, ', ', @zona), 'ERROR: ' + ERROR_MESSAGE(), NULL);

		IF CURSOR_STATUS('global','cContratos') >= -1
		BEGIN
			IF CURSOR_STATUS('global','cContratos') > -1 CLOSE cContratos
			DEALLOCATE cContratos
		END
	END CATCH

	IF OBJECT_ID(N'tempdb..#CTR') IS NOT NULL
	DROP TABLE #CTR;

	--******************
	--@otrosErrores>0: Han habido errores actualizando las tablas relacionadas (perzona, perzonalote, perzona, error en los parametros)
	SET @otrosErrores = CONCAT(IIF(@LOTES_ERROR<>0, 1, 0)
						     , IIF(@PERZONA_ERROR<>0, 1, 0)
							 , IIF(@PARAMS_ERROR<>0, 1, 0));

						--Texto para conocer donde han habido fallos
						--@LOTES_ERROR		--Algo falló en los lotes(100) 
						--@PERZONA_ERROR	--Algo falló en perzona	 (010)
						--@PARAMS_ERROR		--Ya está en perzona	 (001)
						
	--******************
	INSERT INTO @tskLog VALUES(IIF(CAST(@otrosErrores AS INT) >0 OR @RESULT>0, 'ERROR', 'OK')
						, 'FIN'
						, 'Ampliacion Apertura'
						, IIF(CAST(@otrosErrores AS INT)>0 OR @RESULT>0, 'Han ocurrido errores en el proceso de ampliación de apertura', 'OK')
						, dbo.GetAcuamaDate());
	
	INSERT INTO @tskLog VALUES('INFO', '@RESULT', @RESULT,NULL, NULL);
	INSERT INTO @tskLog VALUES('INFO', '@OTROSERRORES', @OTROSERRORES, NULL, NULL);
	INSERT INTO @tskLog VALUES('INFO', '@LOTES_ERROR', @LOTES_ERROR, NULL, NULL);
	INSERT INTO @tskLog VALUES('INFO', '@PERZONA_ERROR', @PERZONA_ERROR, NULL, NULL);
	INSERT INTO @tskLog VALUES('INFO', '@PARAMS_ERROR', @PARAMS_ERROR, NULL, NULL);


	EXEC dbo.Task_Parameters_UpdateLog @tskLog, @tskUser, @tskType, @tskNumber;
	
	--******************
	--[9999]ERRORLOG: FIN
	--Numero para saber si hubo error
	RETURN 	IIF(@RESULT<>0, 1, 0)
		  + IIF(@LOTES_ERROR<>0, 1, 0)
		  + IIF(@PERZONA_ERROR<>0, 1, 0)
		  + IIF(@PARAMS_ERROR<>0, 1, 0);
GO


