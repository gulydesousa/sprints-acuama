/*
DECLARE @zona VARCHAR(4) = 'RO03'
DECLARE @periodo VARCHAR(6) = '202104'
DECLARE @fechaPeriodoDesde DATETIME = '20211001'
DECLARE @fechaPeriodoHasta DATETIME = '20211231'
----***************************
DECLARE @tskUser VARCHAR(10) = 'admin'	
DECLARE @tskType SMALLINT = 40
DECLARE @tskNumber INT = 6
----***************************
DECLARE @facturasInsertadas AS INT
DECLARE @facturasError AS INT

EXEC dbo.Tasks_Facturas_AperturaPorContrato @zona, @periodo, @fechaPeriodoDesde, @fechaPeriodoHasta, @tskUser, @tskType, @tskNumber, @facturasInsertadas OUT 
*/

ALTER PROCEDURE [dbo].[Tasks_Facturas_AperturaPorContrato]   
  @zona VARCHAR(4)
, @periodo VARCHAR(6)
, @fechaPeriodoDesde DATETIME
, @fechaPeriodoHasta DATETIME
----***************************
, @tskUser VARCHAR(10)	= NULL	
, @tskType SMALLINT		= NULL
, @tskNumber INT		= NULL
----***************************
, @facturasInsertadas AS INT OUT
, @facturasError AS INT OUT
, @otrosErrores AS VARCHAR(3) OUT
AS
	SET NOCOUNT ON;
	--******************
	--A diferencia de Tasks_Facturas_Apertura que hace todo en una sola transacción
	--Este SP hace una transacción por factura/contrato 
	--Se registra en un fichero de log los resultados
	--Si un contrato falla la apertura continua se registra el fallo en el log y sigue con el siguiente
	--****************** 

	--**************
	--[0000]OUTPUT
	SELECT @facturasInsertadas = 0, @facturasError=0, @otrosErrores=0;

	--**************
	--[0000]VARIABLES	
	DECLARE @RESULT AS BIT = 0;
	
	DECLARE @PERZONA_EXISTS AS BIT = 0;
	DECLARE @PERZONA_ERROR AS BIT = 0;
	DECLARE @LOTES_ERROR AS BIT = 0;

	DECLARE @tskLog AS dbo.tLog;
	DECLARE @AHORA DATETIME = dbo.GetAcuamaDate();
	DECLARE @explotacion AS VARCHAR(50) = NULL;
	DECLARE @facApertura AS VARCHAR(50) = NULL;
	DECLARE @CURSOR_ROWS AS INT = 0; 
	DECLARE @totalSteps AS INT = 0 + 1 +1; --1Paso por cada factura + 1Paso UPDATE perzona.przFAperNReg, +1Paso PerzonaLote_AsignarLote
	DECLARE @tFacturasKO AS dbo.tFacturasPK;
	DECLARE @tskStartedDate DATETIME;
	DECLARE @taskCall AS BIT = IIF(@tskUser IS NOT NULL AND @tskType IS NOT NULL AND @tskNumber IS NOT NULL, 1, 0);
	DECLARE @spLog VARCHAR(150);

	--**************
	--[0000]CURSOR
	DECLARE @codigoContrato AS INT;
	DECLARE @versionContrato AS INT;
	DECLARE @codigoCliente AS INT;
	DECLARE @fechaAltaContrato AS DATETIME;
	DECLARE @fechaBajaContrato AS DATETIME;
	
	DECLARE @lecturaAnterior AS INT;
	DECLARE @fechaLecturaAnterior AS DATETIME;

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
	--[0001]ERRORLOG: Inicio
	INSERT INTO @tskLog VALUES('INFO', 'INICIO', 'Apertura', NULL, dbo.GetAcuamaDate());

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
		--[1010]PERZONA
		--Comprobamos que la zona no existe antes de continuar
		SET @spLog = 'perzona';

		IF EXISTS(SELECT 1 FROM dbo.perzona AS PZ WHERE PZ.przcodzon = @zona AND PZ.przcodper = @periodo)
		BEGIN
			SET @PERZONA_EXISTS = 1;
			THROW 51000, 'La apertura ya se ha realizado para esta zona y periodo', 0;
		END

		--**************
		--[2000]CURSOR
		--Busco la última versión de cada contrato que esté dentro de las fechas
		SET @spLog = 'facturas';

		
		--Buscamos los contratos con contadores instalados
		DECLARE @CTRCON AS TABLE(ctrCod INT);
		INSERT INTO @CTRCON
		SELECT DISTINCT ctrCod FROM vCambiosContador WHERE esUltimaInstalacion=1 AND opRetirada IS NULL;

		
		DECLARE cContratos CURSOR STATIC FOR 
		SELECT C.ctrCod, C.ctrVersion, C.ctrTitCod, C.ctrFecIni, C.ctrFecAnu
		, lecturaAnterior = 0
		, fechaLecturaAnterior = NULL
		FROM dbo.contratos AS C 
		INNER JOIN @CTRCON AS CC
		ON CC.ctrCod = C.ctrcod
		WHERE C.ctrZonCod = @zona AND
		C.ctrFecIni <= @fechaPeriodoHasta AND
		(
			( (C.ctrFecAnu >= @fechaPeriodoDesde OR C.ctrFecAnu IS NULL) AND @explotacion <> 'AVG') OR --Sólo contratos dentro del periodo
			( (C.ctrbaja = 0) AND @explotacion = 'AVG')  --Sólo contratos vivos en AVG
		) 
		
		AND
		ctrVersion = (SELECT MAX(ctrVersion) FROM contratos cSub WHERE C.ctrCod = cSub.ctrCod) AND --Máxima versión del contrato
		EXISTS (SELECT ctsCtrCod FROM contratoServicio WHERE ctsCtrCod = c.ctrCod) AND --Sólo contratos que tengan líneas
		NOT EXISTS(SELECT facCod FROM facturas f WHERE facCtrCod = C.ctrCod AND facPerCod = @periodo)
					 --Sólo contratos que no tengan ya factura (puede que tenga factura porque se haya cambiado la zona del contrato)

		ORDER BY ctrRuta1, ctrRuta2, ctrRuta3, ctrRuta4, ctrRuta5, ctrRuta6, ctrCod
		OPEN cContratos

		--**************
		--[2001]Actualizamos el nº de pasos de la tarea (1 por contrato)
		SET @CURSOR_ROWS = @@CURSOR_ROWS;
		SET @totalSteps = @totalSteps + @CURSOR_ROWS;
	
		IF @taskCall = 1 
		EXEC Task_Schedule_SetTotalSteps @tskUser, @tskType, @tskNumber, @totalSteps;

		--**************
		--[2002]Perzona
		SET @spLog = 'INSERT perzona';
	
		INSERT INTO dbo.perzona(przcodzon, przcodper, przfaperreal, przfPeriodoD, przfPeriodoH) 
		VALUES (@zona, @periodo, @AHORA, @fechaPeriodoDesde, @fechaPeriodoHasta);
	
		INSERT INTO @tskLog VALUES('OK', @spLog, CONCAT(@periodo, ', ', @zona), 'OK', NULL);	
		
		--**************
		--[2999]Num.Facturas
		INSERT INTO @tskLog VALUES('INFO', 'Num.Facturas', CAST(@CURSOR_ROWS AS VARCHAR), 'Contratos a facturar', dbo.GetAcuamaDate());	
		
		--**************
		--[3000]CURSOR	
		FETCH NEXT FROM cContratos
		INTO @codigoContrato, @versionContrato, @codigoCliente, @fechaAltaContrato, @fechaBajaContrato
		, @lecturaAnterior, @fechaLecturaAnterior

		WHILE @@FETCH_STATUS = 0
		BEGIN
			BEGIN TRY
				--****************
				BEGIN TRANSACTION;
				
				--[3011]Obtengo la lectura anterior y la fecha de la lectura anterior
				EXEC dbo.Contratos_ObtenerUltimaLecturaFacturacion @codigoContrato, @versionContrato, @lecturaAnterior OUT, @fechaLecturaAnterior OUT;

				--[3012]Llamada al procedimiento que inserta una factura
				EXEC Facturas_InsertApertura 0, @periodo, @codigoContrato, @versionContrato, @codigoCliente, @zona, @lecturaAnterior, @fechaLecturaAnterior, @tskUser, @fechaAltaContrato, @fechaBajaContrato, @fechaPeriodoDesde, @fechaPeriodoHasta;

				--[3013]Contabilizar el tipo de operación en la tabla facturas
				SET @facturasInsertadas = @facturasInsertadas + 1;

				--**************
				--[3900]CtrCod OK
				INSERT INTO @tskLog VALUES('OK', 'ctrCod', CAST(@codigoContrato AS VARCHAR), 'OK', NULL);
				
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
		INTO @codigoContrato, @versionContrato, @codigoCliente, @fechaAltaContrato, @fechaBajaContrato
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
							WHEN @facturasInsertadas=0 THEN 'ERROR'
							ELSE 'AVISO' END;

		SET @msgLog = CASE @tipoLog WHEN 'OK' THEN 'Apertura completa'
									WHEN 'ERROR' THEN 'No ha sido posible aperturar ninguna factura'
									ELSE 'Hay facturas pendientes de apertura' END 	


		INSERT INTO @tskLog VALUES(@tipoLog
								, '#Facturas Creadas'
								, CAST(@facturasInsertadas AS VARCHAR)
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
		--[5001]PERZONA el nº de registros insertados	
		SET @spLog = 'UPDATE perzona';
		IF @facturasInsertadas > 0 
		BEGIN
			BEGIN TRY
				UPDATE PZ
				SET PZ.przFAperNReg = @facturasInsertadas
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
		SET @spLog = 'perzonalote';
		IF @facturasInsertadas > 0 
		BEGIN			
			EXEC @LOTES_ERROR = [dbo].[PerzonaLote_AsignarLote] @zona, @periodo;

			--**************
			--[5199]perzonalote
			INSERT INTO @tskLog VALUES(IIF(@LOTES_ERROR=0, 'OK', 'ERROR'), @spLog,  CONCAT(@periodo, ', ', @zona), IIF(@LOTES_ERROR=0, 'OK', 'ERROR'), NULL);
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

	--******************
	--@otrosErrores>0: Han habido errores actualizando las tablas relacionadas (perzona, perzonalote, perzona, perzona exists)
	SET @otrosErrores = CONCAT(IIF(@LOTES_ERROR<>0, 1, 0)
						     , IIF(@PERZONA_ERROR<>0, 1, 0)
							 , IIF(@PERZONA_EXISTS<>0, 1, 0));
						--Texto para conocer donde han habido fallos
						--@LOTES_ERROR		--Algo falló en los lotes(100)
						--@PERZONA_ERROR	--Algo falló en perzona	 (010) 
						--@PERZONA_EXISTS	--Ya está en perzona	 (001)
						
					  
	--******************
	INSERT INTO @tskLog VALUES(IIF(CAST(@otrosErrores AS INT) >0 OR @RESULT>0, 'ERROR', 'OK')
							, 'FIN'
							, 'Apertura'
							, IIF(CAST(@otrosErrores AS INT)>0 OR @RESULT>0, 'Han ocurrido errores en el proceso de apertura', 'OK')
							, dbo.GetAcuamaDate());
	
	INSERT INTO @tskLog VALUES('INFO', '@RESULT', @RESULT,NULL, NULL);
	INSERT INTO @tskLog VALUES('INFO', '@OTROSERRORES', @OTROSERRORES, NULL, NULL);
	INSERT INTO @tskLog VALUES('INFO', '@LOTES_ERROR', @LOTES_ERROR, NULL, NULL);
	INSERT INTO @tskLog VALUES('INFO', '@PERZONA_ERROR', @PERZONA_ERROR, NULL, NULL);
	INSERT INTO @tskLog VALUES('INFO', '@PERZONA_EXISTS', @PERZONA_EXISTS, NULL, NULL);


	EXEC dbo.Task_Parameters_UpdateLog @tskLog, @tskUser, @tskType, @tskNumber;
	

	--******************
	--[9999]ERRORLOG: FIN
	--Numero para saber si hubo error
	RETURN 	IIF(@RESULT<>0, 1, 0)
		  + IIF(@LOTES_ERROR<>0, 1, 0)
		  + IIF(@PERZONA_ERROR<>0, 1, 0)
		  + IIF(@PERZONA_EXISTS<>0, 1, 0);
GO


