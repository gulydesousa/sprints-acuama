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

ALTER PROCEDURE dbo.Tasks_Facturas_AperturaPorContrato   
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
	--[0001]ERRORLOG: Inicio
	INSERT INTO @tskLog VALUES('INICIO', 'Apertura',NULL, dbo.GetAcuamaDate());

	INSERT INTO @tskLog VALUES
	  ('@zona', @zona, 'Parametro', NULL)
	, ('@periodo', @periodo, 'Parametro', NULL)
	, ('@fechaPeriodoDesde', FORMAT(@fechaPeriodoDesde, 'dd-MM-yyyy'), 'Parametro', NULL)
	, ('@fechaPeriodoHasta', FORMAT(@fechaPeriodoHasta, 'dd-MM-yyyy'), 'Parametro', NULL)
	, ('@explotacion',@explotacion, 'Configuracion', NULL);
	
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
		
		DECLARE cContratos CURSOR STATIC FOR 
		SELECT ctrCod, ctrVersion, ctrTitCod, ctrFecIni, ctrFecAnu
		, lecturaAnterior = 0
		, fechaLecturaAnterior = NULL
		FROM contratos c
		WHERE ctrZonCod = @zona AND
		ctrFecIni <= @fechaPeriodoHasta AND
		(
			( (ctrFecAnu >= @fechaPeriodoDesde OR ctrFecAnu IS NULL) AND @explotacion <> 'AVG') OR --Sólo contratos dentro del periodo
			( (ctrbaja = 0) AND @explotacion = 'AVG')  --Sólo contratos vivos en AVG
		) 
		
		AND
		ctrVersion = (SELECT MAX(ctrVersion) FROM contratos cSub WHERE c.ctrCod = cSub.ctrCod) AND --Máxima versión del contrato
		EXISTS (SELECT ctsCtrCod FROM contratoServicio WHERE ctsCtrCod = c.ctrCod) AND --Sólo contratos que tengan líneas
		NOT EXISTS(SELECT facCod FROM facturas f WHERE facCtrCod = ctrCod AND (facPerCod = @periodo OR 
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
					) --Sólo contratos que no tengan ya factura (puede haberse creado una factura de baja, o puede que tenga factura porque se haya cambiado la zona del contrato)

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
	
		INSERT INTO @tskLog VALUES(@spLog, CONCAT(@periodo, ', ', @zona), 'OK', NULL);	
		
		--**************
		--[2999]Num.Facturas
		INSERT INTO @tskLog VALUES('Num.Facturas', CAST(@CURSOR_ROWS AS VARCHAR), 'Contratos a facturar', dbo.GetAcuamaDate());	
		
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
				EXEC Contratos_ObtenerUltimaLectura @codigoContrato, @versionContrato, @lecturaAnterior OUT, @fechaLecturaAnterior OUT;

				--[3012]Llamada al procedimiento que inserta una factura
				EXEC Facturas_InsertApertura 0, @periodo, @codigoContrato, @versionContrato, @codigoCliente, @zona, @lecturaAnterior, @fechaLecturaAnterior, @tskUser, @fechaAltaContrato, @fechaBajaContrato, @fechaPeriodoDesde, @fechaPeriodoHasta;

				--[3013]Contabilizar el tipo de operación en la tabla facturas
				SET @facturasInsertadas = @facturasInsertadas + 1;

				--**************
				--[3900]CtrCod OK
				INSERT INTO @tskLog VALUES('ctrCod', CAST(@codigoContrato AS VARCHAR), 'OK', NULL);
				
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
				INSERT INTO @tskLog VALUES('ctrCod', CAST(@codigoContrato AS VARCHAR), 'ERROR: '+ ERROR_MESSAGE(), dbo.GetAcuamaDate());
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
		INSERT INTO @tskLog VALUES('Num.Facturas OK', CAST(@facturasInsertadas AS VARCHAR), 'OK', NULL);
		INSERT INTO @tskLog VALUES('Num.Facturas ERROR', CAST(@facturasError AS VARCHAR), IIF(@facturasError>0, 'ERROR', 'OK'), NULL);
	
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
				INSERT INTO @tskLog VALUES(@spLog,  CONCAT(@periodo, ', ', @zona), 'OK', NULL);
			END TRY
			BEGIN CATCH
				--**************
				--[5099]perzona
				SET @PERZONA_ERROR=1;
				INSERT INTO @tskLog VALUES(@spLog,  CONCAT(@periodo, ', ', @zona), 'ERROR: ' + ERROR_MESSAGE(), NULL);		
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
			INSERT INTO @tskLog VALUES(@spLog,  CONCAT(@periodo, ', ', @zona), IIF(@LOTES_ERROR=0, 'OK', 'ERROR'), NULL);
		END
		--[****]Actualizamos el avance
		IF @taskCall=1 EXEC Task_Schedule_PerformStep @tskUser, @tskType, @tskNumber;

	END TRY

	BEGIN CATCH
		INSERT INTO @tskLog VALUES('ERROR', @spLog, ERROR_MESSAGE(), dbo.GetAcuamaDate());	

		IF CURSOR_STATUS('global','cContratos') >= -1
		BEGIN
			IF CURSOR_STATUS('global','cContratos') > -1 CLOSE cContratos
			DEALLOCATE cContratos
		END
	END CATCH

	--******************
	--@otrosErrores>0: Han habido errores actualizando las tablas relacionadas (perzona, perzonalote, perzona, perzona exists)

	SET @otrosErrores = CONCAT(@LOTES_ERROR, @PERZONA_ERROR, @PERZONA_EXISTS);
						--Texto para conocer donde han habido fallos
						--@LOTES_ERROR		--Algo falló en los lotes(100)
						--@PERZONA_ERROR	--Algo falló en perzona	 (010) 
						--@PERZONA_EXISTS	--Ya está en perzona	 (001)
						
					  
	--******************
	INSERT INTO @tskLog VALUES('FIN', 'Apertura', IIF(@otrosErrores>0 OR @RESULT>0, 'ERROR', 'OK'), dbo.GetAcuamaDate());
	EXEC dbo.Task_Parameters_UpdateLog @tskLog, @tskUser, @tskType, @tskNumber;
	

	--******************
	--[9999]ERRORLOG: FIN
	--Numero para saber si hubo error
	RETURN (CAST(@RESULT AS TINYINT) 
		  + CAST(@LOTES_ERROR AS TINYINT)
		  + CAST(@PERZONA_ERROR AS TINYINT)
		  + CAST(@PERZONA_EXISTS AS TINYINT));
GO