/*
DECLARE @zona		AS VARCHAR(4) = 'AM01'
DECLARE @contrato	AS INT --= 50956
DECLARE @periodo	AS VARCHAR(6) = '202104'
DECLARE @fecha		AS DATETIME = '20211213'
DECLARE @sociedad	AS SMALLINT	= 1
DECLARE @serie		AS SMALLINT = 3
DECLARE @usuario	AS VARCHAR(10) = 'admin'
----***************************
DECLARE @actualizarVersionContrato	AS BIT = 1	--1: Actualiza en la factura la última versión del contrato
DECLARE @actualizarTipoImpuesto		AS BIT = 1		--1: Actualiza el tipo de impuesto de las prefacturas a cerrar
----***************************
DECLARE @tskUser	AS VARCHAR(10) = 'admin'
DECLARE @tskType	AS SMALLINT = '480'
DECLARE @tskNumber	AS INT = 1
----***************************
DECLARE @facturasCerradas	AS INT 
DECLARE @facturasError		AS INT 
DECLARE @otrosErrores		AS VARCHAR(5)

EXEC [dbo].[Tasks_Facturas_CierrePorContrato] @zona, @contrato, @periodo, @fecha, @sociedad, @serie, @usuario
, @actualizarVersionContrato, @actualizarTipoImpuesto, @tskUser, @tskType, @tskNumber
, @facturasCerradas, @facturasError, @otrosErrores

*/

CREATE PROCEDURE [dbo].[Tasks_Facturas_CierrePorContrato]
  @zona		AS VARCHAR(4) = NULL
, @contrato	AS INT = NULL
, @periodo	AS VARCHAR(6)
, @fecha		AS DATETIME
, @sociedad	AS SMALLINT
, @serie		AS SMALLINT
, @usuario	AS VARCHAR(10)
----***************************
, @actualizarVersionContrato	AS BIT = NULL	--1: Actualiza en la factura la última versión del contrato
, @actualizarTipoImpuesto		AS BIT = NULL	--1: Actualiza el tipo de impuesto de las prefacturas a cerrar
----***************************
, @tskUser	AS VARCHAR(10) = NULL
, @tskType	AS SMALLINT = NULL
, @tskNumber	AS INT = NULL
----***************************
, @facturasCerradas	AS INT OUTPUT
, @facturasError		AS INT  OUTPUT
, @otrosErrores		AS VARCHAR(5) OUTPUT
AS

	SET NOCOUNT ON;
	--******************
	--A diferencia de Tasks_Facturas_Cierre que hace toda la zona en una sola transacción
	--Este SP hace una transacción por factura/contrato 
	--Se registra en un fichero de log los resultados
	--Si un contrato falla la apertura continua se registra el fallo en el log y sigue con el siguiente
	--****************** 

	--**************
	--[0000]OUTPUT
	SELECT @facturasCerradas = 0, @facturasError=0, @otrosErrores=0;

	--**************
	--[0000]VARIABLES
	DECLARE @RESULT AS BIT = 0;
	DECLARE @tFacturasKO AS dbo.tFacturasPK;

	DECLARE @IMPUESTOS_ERROR AS INT = 0;
	DECLARE @SERIES_ERROR AS INT = 0;
	DECLARE @NUMERADOR_ERROR AS INT = 0;
	DECLARE @ENTREGACTA_ERROR AS INT = 0;
	DECLARE @PERZONA_ERROR AS INT = 0;
	DECLARE @ZONA_ERROR AS INT = 0;

	DECLARE @tskLog AS dbo.tLog;
	DECLARE @spLog VARCHAR(150);
	DECLARE @AHORA DATETIME = dbo.GetAcuamaDate();
	DECLARE @formatLog VARCHAR(20) =CONCAT('%0', (SELECT LEN(CAST(MAX(ctrCod) AS VARCHAR)) FROM dbo.Contratos), 'i:%s');
	
	DECLARE @explotacion AS INT = NULL;
	DECLARE @ppago AS SMALLINT = NULL;
	DECLARE @medpc AS SMALLINT = NULL;

	DECLARE @totalSteps AS INT = 0; --1Paso por cada factura
	DECLARE @tskStartedDate DATETIME;
	DECLARE @taskCall AS BIT = IIF(@tskUser IS NOT NULL AND @tskType IS NOT NULL AND @tskNumber IS NOT NULL, 1, 0);

	--**************
	DECLARE @numeradorSerie AS INT;
	DECLARE @facNumero AS VARCHAR(20);


	--**************
	--[0000]CURSOR
	DECLARE @CURSOR_ROWS AS INT = 0; 
	DECLARE @facCod			AS SMALLINT;
	DECLARE @facContrato	AS INT;
	DECLARE @facVersion		AS SMALLINT;
	DECLARE @facCtrVersion	AS SMALLINT;
	DECLARE @facCliCod		AS INT;
	DECLARE @totalFactura	AS MONEY;
	DECLARE @facLecturaFactura		AS INT;
	DECLARE @facFechaLecturaFactura AS DATETIME;
	
	--******************
	--[0000]EXPLOTACION
	SELECT @explotacion = CAST(ISNULL(P.pgsvalor,'0') AS INT)
	FROM dbo.parametros AS P
	WHERE P.pgsclave = 'EXPLOTACION_CODIGO';

	--******************
	--[0000]PUNTO_PAGO
	SELECT @ppago = CAST(ISNULL(P.pgsvalor,'0') AS INT)
	FROM dbo.parametros AS P
	WHERE P.pgsclave = 'PUNTO_PAGO_ENTREGAS_A_CTA';

	--******************
	--[0000]MEDIO_PAGO
	SELECT @medpc = CAST(ISNULL(P.pgsvalor,'0') AS INT)
	FROM dbo.parametros AS P
	WHERE P.pgsclave = 'MEDIO_PAGO_ENTREGAS_A_CTA';

	--******************
	--[0001]ERRORLOG: Inicio
	INSERT INTO @tskLog VALUES('INFO', 'INICIO', 'Cerrar periodo-zona',NULL, dbo.GetAcuamaDate());

	INSERT INTO @tskLog VALUES
	  ('INFO', '@zona', @zona, 'Parametro', NULL)
	, ('INFO', '@periodo', @periodo, 'Parametro', NULL)
	, ('INFO', '@fecha', FORMAT(@fecha, 'dd-MM-yyyy'), 'Parametro', NULL)
	, ('INFO', '@sociedad', CAST(@sociedad AS VARCHAR(5)), 'Parametro', NULL)
	, ('INFO', '@serie', CAST(@serie AS VARCHAR(5)), 'Parametro', NULL)
	, ('INFO', '@usuario', @usuario, 'Parametro', NULL)
	, ('INFO', '@actualizarVersionContrato', CAST(@actualizarVersionContrato AS VARCHAR(1)), 'Parametro', NULL)
	, ('INFO', '@actualizarTipoImpuesto', CAST(@actualizarTipoImpuesto AS VARCHAR(1)), 'Parametro', NULL)
	, ('INFO', 'EXPLOTACION_CODIGO', CAST(@explotacion AS VARCHAR(10)), 'Configuracion', NULL)
	, ('INFO', 'PUNTO_PAGO_ENTREGAS_A_CTA', CAST(@ppago AS VARCHAR(10)), 'Configuracion', NULL)
	, ('INFO', 'MEDIO_PAGO_ENTREGAS_A_CTA', CAST(@medpc AS VARCHAR(10)), 'Configuracion', NULL);


	IF @taskCall = 1 
	EXEC [dbo].[Task_Schedule_START] @tskUser, @tskType, @tskNumber, @tskStartedDate OUT; 
	
	--******************
	
	BEGIN TRY
		--**************
		--[1001]ANTES DE CERRAR, SI PROCEDE, SE ACTUALIZARÁ EL TIPO DE IMPUESTO
		SET @spLog = 'Tasks_Facturas_CambioImpuesto';
		
		IF @actualizarTipoImpuesto = 1
		BEGIN
			EXEC @IMPUESTOS_ERROR = dbo.Tasks_Facturas_CambioImpuesto @periodo, @zona, @fecha, NULL, NULL, NULL, NULL, NULL;

			IF(@IMPUESTOS_ERROR <> 0)
				THROW 51000, 'Ha ocurrido un error actualizando el tipo de impuesto', 0;
			ELSE
				INSERT INTO @tskLog VALUES('OK', @spLog,  'Se ha actualizado el tipo de impuesto', 'OK', NULL);
		END
		ELSE
		BEGIN
			INSERT INTO @tskLog VALUES('OK', @spLog,  'Actualizacion tipo de impuesto no requerida', 'OK', NULL);
		END
		--**************
		--[1002]ANTES DE CERRAR, SI PROCEDE, SE ACTUALIZARÁ EL NUMERADOR DE LA SERIE
		SET @spLog = 'Series_IniciarNumerador';
		EXEC @SERIES_ERROR = dbo.Series_IniciarNumerador @serie, @sociedad;
		
		IF(@SERIES_ERROR <> 0)
			THROW 51000, 'Ha ocurrido un error actualizando el numerador de la serie', 0;
		ELSE
			INSERT INTO @tskLog VALUES('OK', @spLog,  'Se ha actualizado el numerador de la serie', 'OK', NULL);	
		
		--**************
		--[2000]CURSOR
		DECLARE C1 CURSOR FOR
		SELECT facCod
			 , facCtrCod
			 , facVersion
			 , facCtrVersion = ctrVersion
			 , facCliCod	 = ctrTitCod
			 , facLecAct
			 , facLecActFec
			 , totalFactura  = SUM(fclTotal)
		 FROM dbo.facturas AS F
		 INNER JOIN dbo.contratos AS C 
		 ON  C.ctrCod = F.facCtrCod 
		 AND C.ctrVersion = (SELECT MAX(ctrVersion) FROM contratos WHERE ctrCod = facCtrCod)
		 --Sólo hace el cierre de facturas con líneas
		 INNER JOIN dbo.faclin AS FL 
		 ON  F.facCtrCod  = FL.fclFacCtrCod 
		 AND F.facPerCod  = FL.fclFacPerCod 
		 AND F.facVersion = FL.fclFacVersion 
		 AND F.facCod	  = FL.fclFacCod
		 WHERE F.facPerCod = @periodo 
		 AND (@zona IS NULL		OR F.facZonCod = @zona) 
		 AND (@contrato IS NULL OR F.facCtrCod = @contrato) 
		 AND ISNULL(F.facSerScdCod, 0) = 0 
		 AND ISNULL(F.facSerCod, 0) = 0 
		 AND F.facNumero IS NULL
		 GROUP BY F.facCod, F.facCtrCod, C.ctrVersion, F.facVersion
				, C.ctrTitCod
				, F.facLecAct, F.facLecActFec
				, C.ctrRuta1, C.ctrRuta2, C.ctrRuta3, C.ctrRuta4, C.ctrRuta5, C.ctrRuta6
		 HAVING SUM(fclTotal) > 0
		 ORDER BY ctrRuta1,ctrRuta2,ctrRuta3,ctrRuta4,ctrRuta5,ctrRuta6;

		 OPEN C1;

		 --**************
		--[2001]Actualizamos el nº de pasos de la tarea (1 por contrato)
		SET @CURSOR_ROWS = @@CURSOR_ROWS;
		SET @totalSteps = @totalSteps + @CURSOR_ROWS;
		EXEC @numeradorSerie = dbo.Series_IncrementarNumerador @serie, @sociedad, @CURSOR_ROWS;
		IF (@numeradorSerie < 0)
			THROW 51000, 'Ha ocurrido un error actualizando el numerador de la serie', 0;

		IF @taskCall = 1 
		EXEC Task_Schedule_SetTotalSteps @tskUser, @tskType, @tskNumber, @totalSteps;

		--**************
		--[2999]Num.Facturas
		INSERT INTO @tskLog VALUES('INFO', 'Num.Facturas', CAST(@CURSOR_ROWS AS VARCHAR), 'Contratos a facturar', dbo.GetAcuamaDate());	
		
		--**************
		--[3000]CURSOR	
		FETCH NEXT FROM c1 INTO @facCod, @facContrato, @facVersion, @facCtrVersion
							  , @facCliCod, @facLecturaFactura, @facFechaLecturaFactura, @totalFactura
		WHILE @@FETCH_STATUS = 0
		BEGIN
			BEGIN TRY
				--EXEC @numeradorSerie = dbo.Series_IncrementarNumerador @serie, @sociedad, 1;
				
				SET @facNumero = FORMATMESSAGE('%s%i%s', FORMAT(@AHORA, 'yy')
															 , @explotacion*100
															 , CAST(@numeradorSerie AS VARCHAR(15)));
				--****************
				BEGIN TRANSACTION;
				--[3011]dbo.facturas: Asignar sociedad, serie, número, fecha, versión del contrato y código del cliente
				UPDATE F SET
				  F.facSerScdCod	= @sociedad
				, F.facSerCod		= @serie
				, F.facFecha		= @fecha
				, F.facFecReg		= @AHORA
				, F.facCtrVersion	= IIF(@actualizarVersionContrato = 1, @facCtrVersion, F.facCtrVersion)
				, F.facCliCod		= IIF(@actualizarVersionContrato = 1, @facCliCod	, F.facCliCod)
				, F.facEnvSERES		= IIF(C.ctrFace = 1 AND C.ctrFaceMinimo < @totalFactura, 'P', NULL)
				, F.facNumero		= @facNumero
				FROM dbo.facturas AS F
				INNER JOIN dbo.contratos AS C
				ON	C.ctrcod		= F.facCtrCod 
				AND C.ctrVersion	= IIF(@actualizarVersionContrato = 1, @facCtrVersion, F.facCtrVersion)
				WHERE F.facCod		= @facCod
				  AND F.facCtrCod	= @facContrato 
				  AND F.facPerCod	= @periodo 
				  AND F.facVersion	= @facVersion;
				
				--[3012]dbo.contratos: Actualizar lectura en la ultima versión del contrato 
				UPDATE C SET  
					  C.ctrLecturaUlt = @facLecturaFactura
					, C.ctrLecturaUltFec = @facFechaLecturaFactura
				FROM dbo.contratos AS C
				WHERE C.ctrCod = @facContrato AND
						C.ctrVersion = @facCtrVersion;
				
				--[3013]Generar las entregas a cuentas 
				EXEC dbo.Cobros_EntregasCuentas @sociedad, @fecha, @periodo, @usuario, @ppago, @medpc, @facContrato, @totalFactura;

				--[3014]Llevamos al histórico los diferidos que se han aplicado a esta factura
				INSERT INTO dbo.diferidosHist
				SELECT difCtrCod
						, @facCtrVersion
						, difCodigo
						, difTrfSrvCod
						, difTrfCod
						, difOrigen
						, difOriSerCod
						, difOriSerScdCod
						, difOriNum
						, difBaseImp
						, difUds
						, difFechaGeneracion
						, difFechaAplicacion
						, difPeriodoAplicacion
						, @facVersion
						, difFacCod
				FROM dbo.diferidos AS D 
				WHERE D.difCtrCod = @facContrato 
					AND D.difPeriodoAplicacion = @periodo 
					AND D.difFacCod = @facCod;
				
				--[3015]Contabilizar el tipo de operación en la tabla facturas
				SET @facturasCerradas = @facturasCerradas + 1;

				--**************
				--[3900]CtrCod OK
				INSERT INTO @tskLog VALUES('OK', 'ctrCod', @facContrato, CONCAT('facNumero: ', @facNumero), NULL);				
			
				COMMIT TRANSACTION;	
				SET @numeradorSerie = @numeradorSerie+1;
				--****************	
				
			END TRY
			BEGIN CATCH
				--****************	
				IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
				--****************
				SET @RESULT = 1;
			
				--**************
				--[3900]Facturas KO
				INSERT INTO @tskLog VALUES('ERROR', 'ctrCod', CAST(@facContrato AS VARCHAR), ERROR_MESSAGE(), dbo.GetAcuamaDate());
				INSERT INTO @tFacturasKO VALUES(@facCod, @periodo, @facContrato, @facVersion);	
			END CATCH

			--[****]Actualizamos el avance
			IF @taskCall=1 EXEC Task_Schedule_PerformStep @tskUser, @tskType, @tskNumber;

			FETCH NEXT FROM C1 
			INTO @facCod, @facContrato, @facVersion, @facCtrVersion
			   , @facCliCod, @facLecturaFactura, @facFechaLecturaFactura, @totalFactura;
		END
		CLOSE C1;
		DEALLOCATE C1;
		
		--**************
		--[4000]FIN loop-contratos
		SELECT @facturasError = COUNT(1) FROM @tFacturasKO;
		
		DECLARE @tipoLog VARCHAR(15);  
		DECLARE @msgLog VARCHAR(250);  

		SET @tipoLog = CASE WHEN @facturasError=0 THEN 'OK'
							WHEN @facturasCerradas=0 THEN 'ERROR'
							ELSE 'AVISO' END;

		SET @msgLog = CASE @tipoLog WHEN 'OK' THEN 'Cierre completo'
									WHEN 'ERROR' THEN 'No ha sido posible cerrar ninguna factura'
									ELSE 'Hay facturas pendientes de cierre' END 	
		
		INSERT INTO @tskLog VALUES(@tipoLog
								, '#Facturas Cerradas'
								, CAST(@facturasCerradas AS VARCHAR)
								, @msgLog
								, NULL);
		
		INSERT INTO @tskLog VALUES(IIF(@facturasError > 0,  'ERROR', 'OK')
								, '#Facturas ERROR'
								, CAST(@facturasError AS VARCHAR)
								, @msgLog
								, NULL);
	
		--*************************
		--TABLAS RELACIONADAS	
		--*************************
		--[5001]PERZONA fecha de cierre	
		SET @spLog = 'UPDATE perzona';

		BEGIN TRY		
			UPDATE PZ
			SET PZ.przCierreReal = IIF(@facturasError = 0 ,@AHORA, NULL)
			 ,  PZ.przCierreNReg = ISNULL(PZ.przCierreNReg, 0) + @facturasCerradas
			FROM dbo.perzona AS PZ
			WHERE przcodzon = @zona AND przcodper = @periodo;
					
			--**************
			--[5099]perzona
			INSERT INTO @tskLog VALUES(IIF(@facturasError=0, 'OK', 'AVISO'), @spLog,  CONCAT(@periodo, ', ', @zona), IIF(@facturasError=0, 'OK', 'Cierre Pendiente'), NULL);
		END TRY
		BEGIN CATCH
			--**************
			--[5099]perzona
			SET @PERZONA_ERROR=1;
			INSERT INTO @tskLog VALUES('ERROR', @spLog,  CONCAT(@periodo, ', ', @zona), ERROR_MESSAGE(), NULL);	
		END CATCH
		--[****]Actualizamos el avance
		IF @taskCall=1 EXEC Task_Schedule_PerformStep @tskUser, @tskType, @tskNumber;

			
		--**************
		--[5100]zona
		SET @spLog = 'UPDATE Zona';
		BEGIN TRY
			UPDATE Z 
			SET Z.zonPerCod = @periodo
			FROM dbo.zonas AS Z
			WHERE Z.zonCod = @zona 
			AND @facturasError=0
			AND @facturasCerradas > 0;

			--**************
			--[5199]perzona
			INSERT INTO @tskLog VALUES(IIF(@facturasError=0, 'OK', 'AVISO'), @spLog,  CONCAT(@periodo, ', ', @zona), IIF(@facturasError=0, 'OK', 'Cierre Pendiente'), NULL);

		END TRY
		BEGIN CATCH
			--**************
			--[5199]perzona
			SET @ZONA_ERROR=1;
			INSERT INTO @tskLog VALUES('ERROR', @spLog,  CONCAT(@periodo, ', ', @zona), ERROR_MESSAGE(), NULL);		
		END CATCH	
		
	END TRY
	BEGIN CATCH
		INSERT INTO @tskLog VALUES('ERROR', 'ERROR', @spLog, ERROR_MESSAGE(), dbo.GetAcuamaDate());

		IF CURSOR_STATUS('global','C1') >= -1
		BEGIN
			IF CURSOR_STATUS('global','C1') > -1 CLOSE C1
			DEALLOCATE C1
		END
	END CATCH
	

	--******************
	--@otrosErrores>0: Han habido errores actualizando las tablas relacionadas (Actualizar Impuestos, perzonalote, perzona, perzona exists)
	
	SET @otrosErrores = CONCAT(IIF(@ZONA_ERROR<>0, 1, 0)
						     , IIF(@PERZONA_ERROR<>0, 1, 0)
							 , IIF(@SERIES_ERROR<>0, 1, 0)
							 , IIF(@IMPUESTOS_ERROR<>0, 1, 0));
	--Texto para conocer donde han habido fallos
	--@ZONA_ERROR		--Error en zona									(1000)
	--@PERZONA_ERROR	--Error en perzona								(0100)
	--@SERIES_ERROR		--Error actualizando el numerador de la serie	(0010) 
	--@IMPUESTOS_ERROR	--Error en el cambio de impuestos				(0001)
						
					  
	--******************
	INSERT INTO @tskLog VALUES(IIF(CAST(@otrosErrores AS INT) >0 OR @RESULT>0, 'ERROR', 'OK')
							, 'FIN'
							, 'Cierre Zona'
							, IIF(CAST(@otrosErrores AS INT)>0 OR @RESULT>0, 'Han ocurrido errores en el proceso de cierre', 'OK')
							, dbo.GetAcuamaDate());

	INSERT INTO @tskLog VALUES('INFO', '@RESULT', @RESULT,NULL, NULL);
	INSERT INTO @tskLog VALUES('INFO', '@OTROSERRORES', @OTROSERRORES, NULL, NULL);
	INSERT INTO @tskLog VALUES('INFO', '@IMPUESTOS_ERROR', @IMPUESTOS_ERROR, NULL, NULL);
	INSERT INTO @tskLog VALUES('INFO', '@SERIES_ERROR', @SERIES_ERROR, NULL, NULL);
	INSERT INTO @tskLog VALUES('INFO', '@PERZONA_ERROR', @PERZONA_ERROR, NULL, NULL);
	INSERT INTO @tskLog VALUES('INFO', '@ZONA_ERROR', @ZONA_ERROR, NULL, NULL);
	
	EXEC dbo.Task_Parameters_UpdateLog @tskLog, @tskUser, @tskType, @tskNumber;

	SELECT * FROM @tskLog

	--******************
	--[9999]ERRORLOG: FIN
	--Numero para saber si hubo error
	RETURN 	IIF(@RESULT<>0, 1, 0)
		  + IIF(@ZONA_ERROR<>0, 1, 0)
		  + IIF(@PERZONA_ERROR<>0, 1, 0)
		  + IIF(@SERIES_ERROR<>0, 1, 0)
		  + IIF(@IMPUESTOS_ERROR<>0, 1, 0);



GO