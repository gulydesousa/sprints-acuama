/*
DECLARE @ctrZonCod AS VARCHAR(4) = '53';
DECLARE @facPerCod AS VARCHAR(6) = '202201';
DECLARE @usarYActualizarFacCtrVersion BIT = 1;
DECLARE @ctrRaizCod INT = NULL;

DECLARE @tskUser VARCHAR(10) = NULL;
DECLARE @tskType SMALLINT = NULL;
DECLARE @tskNumber INT = NULL;
DECLARE @arbolesComunitariosAfectados AS INT = NULL;

EXEC [dbo].[Tasks_Facturas_AplicarConsumosComunitarios] @ctrZonCod, @facPerCod, @usarYActualizarFacCtrVersion, @ctrRaizCod, @tskUser, @tskType, @tskNumber, @arbolesComunitariosAfectados OUT;
*/


ALTER PROCEDURE [dbo].[Tasks_Facturas_AplicarConsumosComunitarios]
	@ctrZonCod AS VARCHAR(4),
	@facPerCod AS VARCHAR(6),
	@usarYActualizarFacCtrVersion BIT,
	@ctrRaizCod INT = NULL, --contrato raíz, solo aplica los consumos comunitarios en esa raíz y sus hijos
	
	/*El servicio windows ha de establecer los siguientes parámetros.
	  Si se desea llamar a este procedimiento desde otro lugar que no sea el servicio windows
	  no se ha de pasar los siguientes parámetros*/
	@tskUser VARCHAR(10) = NULL, --Usuario que ejecuta la tarea
	@tskType SMALLINT = NULL, --Tipo de tarea
	@tskNumber INT = NULL, --Número de tarea
	@arbolesComunitariosAfectados AS INT = NULL OUT
AS

BEGIN

SET NOCOUNT ON;

--*************************
--VARIABLES PARA GESTIONAR LOS CONSUMOS DE LAS FACTURAS
--@facConsumoFactura	: "Cns."			: Consumos del padre (Cambia al aplicar consumos comunitarios)	
DECLARE @facConsumoFactura INT;
--@c			: "Consumo final"	: Consumo del padre antes de consumos comunitarios
DECLARE @facCnsFinal INT;
--@facCnsComunitario	: "Cns.comunitario"	: Sumatoria de los consumos de los hijos
DECLARE @facCnsComunitario INT;
--@VERSION_CNS_COMUNITARIOS: Para condicionar la ejecucion
DECLARE @VERSION_CNS_COMUNITARIOS VARCHAR(12) = '1.0.0';
--Fecha en la que se lanzó la tarea de consumo comunitarios la primera vez
DECLARE @przFecIniCnsCom DATETIME = NULL;

SELECT @VERSION_CNS_COMUNITARIOS = P.pgsvalor 
FROM dbo.parametros AS P 
WHERE P.pgsclave='VERSION_CNS_COMUNITARIOS';

SELECT @przFecIniCnsCom = PZ.przFecIniCnsCom
FROM dbo.perzona AS PZ
WHERE PZ.przcodper = @facPerCod 
  AND PZ.przcodzon = @ctrZonCod;

--*************************

--*************************
--APLAZAMOS Y MEDIMOS EL TIEMPO DE LA ACTUALIZACION
-----------------------------
DECLARE @F AS tFacturasPK;
DECLARE @ROWS INT;
DECLARE @PERZONAROWS INT;

DECLARE @spMessage VARCHAR(4000);
DECLARE @starttime DATETIME =  GETDATE();
DECLARE @FAC_APERTURA VARCHAR(25) = '1.0';
SELECT  @FAC_APERTURA = pgsValor FROM dbo.parametros WHERE pgsclave = 'FAC_APERTURA';
DECLARE @spName VARCHAR(100) = FORMATMESSAGE('%s.%s', OBJECT_SCHEMA_NAME(@@PROCID), OBJECT_NAME(@@PROCID));
DECLARE @msgParams VARCHAR(500) = FORMATMESSAGE('PARAMS: @ctrZonCod=%s, @facPerCod=%s, @usarYActualizarFacCtrVersion=%i, @ctrRaizCod=%i', @ctrZonCod, @facPerCod, CAST(@usarYActualizarFacCtrVersion AS INT), @ctrRaizCod) 
--*************************

DECLARE @tablaAuxiliar as TABLE
(
	periodo  varchar(6),
	zona  varchar(4), 
	nivel int,
	raiz int,
	contrato int,
	ctrVersion smallint,
	padre int,
	nHijos int, 
	consumoFactura int,
	consumoComunitario int,
	consumoFinal int,
	metodoCalculo smallint,		
	primary key (contrato)
)

SET @arbolesComunitariosAfectados = 0

DECLARE @nivel as int = 0
DECLARE @contrato as int
DECLARE @ctrVersion as smallint
DECLARE @periodo as varchar(6)
DECLARE @zona as varchar(4)
DECLARE @raiz as int 

DECLARE @fechaProceso DATETIME = GETDATE()

--Si es 1 entonces la tarea se debe cancelar
DECLARE @CANCEL AS BIT

DECLARE @myError int

DECLARE @servicioAgua AS INT = (SELECT pgsvalor FROM parametros WHERE pgsclave='SERVICIO_AGUA')

DECLARE @MCalculoDescontar AS INT = 1
DECLARE @MCalculoRepartir AS INT = 2

DECLARE @nivelMaxHijosComunitarios AS INT = (SELECT pgsvalor FROM parametros WHERE pgsclave like 'MAX_NIVEL_CTRCOMUNITARIOS')

DECLARE @i AS INT = 0

INSERT INTO @tablaAuxiliar(
	periodo, zona, nivel, raiz, contrato, ctrVersion, padre,
	nHijos, consumoFactura, consumoComunitario, consumoFinal, metodoCalculo)
SELECT 
	facPerCod, facZonCod, 0, facCtrCod, facCtrCod,facCtrVersion, ctrComunitario,
	(SELECT ISNULL(COUNT(*),0) FROM facturas INNER JOIN contratos c3 ON facCtrCod=ctrcod AND ctrversion=CASE WHEN @usarYActualizarFacCtrVersion = 1 THEN (SELECT MAX(ctrVersion) FROM contratos WHERE ctrCod = facCtrCod) ELSE facCtrVersion END WHERE c3.ctrComunitario = c.ctrcod AND facNumero IS NULL),
	ISNULL(facCnsFinal, facConsumoFactura), 0, ISNULL(facCnsFinal, facConsumoFactura),
	ctrCalculoComunitario
FROM facturas
	INNER JOIN contratos c ON ctrcod=facCtrCod AND ctrComunitario IS NULL
	AND ctrVersion = CASE WHEN @usarYActualizarFacCtrVersion = 1 THEN (SELECT MAX(ctrVersion) FROM contratos WHERE ctrCod = facCtrCod) ELSE facCtrVersion END
WHERE
	EXISTS(SELECT c2.ctrcod FROM contratos c2 WHERE c2.ctrComunitario = c.ctrcod)
	AND facNumero IS NULL
	AND (@ctrRaizCod IS NULL OR ctrcod=@ctrRaizCod)
	AND (@facPerCod IS NULL OR facPerCod=@facPerCod) 
	AND (@ctrZonCod IS NULL OR ctrzoncod=@ctrZonCod)

SET @myError = @@ERROR 
IF @myError <> 0 GOTO insertTablaAuxiliar_ERROR

WHILE @i < @nivelMaxHijosComunitarios
BEGIN
	DECLARE cComun CURSOR FAST_FORWARD READ_ONLY FOR
	SELECT periodo, zona, contrato, nivel, raiz from @tablaAuxiliar where nivel = @i and nHijos > 0
	OPEN cComun 
	FETCH NEXT FROM cComun 
	INTO  @periodo, @zona, @contrato, @nivel, @raiz
	WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @nivel = @nivel + 1
			
			INSERT INTO @tablaAuxiliar(periodo, zona, nivel, raiz, contrato, ctrVersion, padre, nHijos, consumoFactura, consumoComunitario, consumoFinal, metodoCalculo)
			SELECT 
				facPerCod, facZonCod, @nivel, @raiz, facCtrCod,facCtrVersion, ctrComunitario,
				(SELECT ISNULL(COUNT(*),0) FROM facturas INNER JOIN contratos c3 ON facCtrCod=ctrcod AND ctrversion=CASE WHEN @usarYActualizarFacCtrVersion = 1 THEN (SELECT MAX(ctrVersion) FROM contratos WHERE ctrCod = facCtrCod) ELSE facCtrVersion END WHERE c3.ctrComunitario = c.ctrcod AND facNumero IS NULL),
				ISNULL(facCnsFinal,facConsumoFactura), 0, ISNULL(facCnsFinal,facConsumoFactura),
				ctrCalculoComunitario
			FROM facturas
				INNER JOIN contratos c ON ctrcod=facCtrCod and c.ctrComunitario = @contrato
				AND ctrVersion = CASE WHEN @usarYActualizarFacCtrVersion = 1 THEN (SELECT MAX(ctrVersion) FROM contratos WHERE ctrCod = facCtrCod) ELSE facCtrVersion END
			WHERE
				facNumero IS NULL AND facPerCod=@periodo AND ctrzoncod=@zona
				AND EXISTS(SELECT facCtrCod FROM faclin 
								WHERE fclFacCod=facCod 
									  AND fclFacCtrCod=facCtrCod 
									  AND fclFacPerCod=facPerCod 
									  AND fclFacVersion=facVersion
									  AND fclTrfSvCod=@servicioAgua
				)
	       
			SET @myError = @@ERROR 
			IF @myError <> 0 GOTO cComun_ERROR
	       
			FETCH NEXT FROM cComun 
			INTO  @periodo, @zona, @contrato, @nivel, @raiz
		END
	CLOSE cComun 
	DEALLOCATE cComun 
	
	SET @i = @i + 1
END

--SELECT * FROM @tablaAuxiliar ORDER BY raiz, nivel, padre, contrato

DECLARE @cnsTotalDescontar INT = 0;
DECLARE @cnsTotalRepartir INT = 0;
DECLARE @totalHijosRepartir INT = 0;
DECLARE @cnsHijoRepartir INT = 0;
DECLARE @padre AS INT;

--*************************
--APLAZAMOS LA ACTUALIZACION: 
--Facturas por periodo y zona 
--Porque al final de todo esta llamando a Facturas_ActualizarLineas
-----------------------------
WITH PZ AS(
SELECT DISTINCT periodo, zona 
FROM @tablaAuxiliar)

INSERT INTO @F(facCod, facPerCod, facCtrCod, facVersion) 
SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion
FROM dbo.facturas AS F
INNER JOIN PZ
ON  F.facPerCod = PZ.periodo
AND F.facZonCod = PZ.zona
INNER JOIN dbo.parametros AS P
ON P.pgsclave='FAC_APERTURA' AND pgsvalor>='2.1.2';

EXEC dbo.FacTotalesTrab_InsertFacturas @F;

SELECT @ROWS = COUNT(*) FROM @tablaAuxiliar;
SELECT @PERZONAROWS = COUNT(*) FROM @F;

--*************************

--Desde la Raiz a las hojas Descontamos y Repartimos
DECLARE cCalcularConsumos CURSOR FOR
SELECT periodo, contrato from @tablaAuxiliar ORDER BY nivel
OPEN cCalcularConsumos

--Actualizamos el nº de pasos de la tarea
IF @tskUser IS NOT NULL AND @tskType IS NOT NULL AND @tskNumber IS NOT NULL
	EXEC Task_Schedule_SetTotalSteps @tskUser, @tskType, @tskNumber, @@CURSOR_ROWS

BEGIN TRANSACTION

	FETCH NEXT FROM cCalcularConsumos 
	INTO  @periodo, @contrato
																																																																																													WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @cnsTotalDescontar = 0

		--PRINT 'El padre donde se va a descontar el consumo de los hijos o repartir a los hijos es: ' + CAST(@contrato AS VARCHAR)
		SELECT @cnsTotalDescontar = SUM(ISNULL(consumoFactura,0)) 
		FROM @tablaAuxiliar 
		WHERE metodoCalculo=@MCalculoDescontar 
		AND padre = @contrato
		--PRINT 'Consumo a descontar al padre ' + CAST(@contrato AS VARCHAR) + ' es: ' + CAST(@cnsTotalDescontar AS VARCHAR)
	
		--***********************
		--DESCONTAR	
		--***********************	
		IF @cnsTotalDescontar>=0
		BEGIN
			--***********************
			--En previsión de correcciones de emergencia condicionamos este cambios para la version 2.0.0
			--De la manera que está implementado es posible, según estén los datos, que se entre en DESCONTAR y REPARTIR
			--Por esta razón condicionamos el cambio a los casos en los que solo es posible DESCONTAR (@totalHijosRepartir = 0)
			--***********************
			SELECT @totalHijosRepartir = COUNT(T.metodoCalculo) 
			FROM @tablaAuxiliar AS T 
			WHERE T.metodoCalculo = @MCalculoRepartir 
			AND T.padre = @contrato;

			IF(@VERSION_CNS_COMUNITARIOS >='2.0.0') AND (@totalHijosRepartir = 0)
			BEGIN 
				--***********************
				--Comportamiento esperado al aplicar consumos comunitarios:
				--@facConsumoFactura (Cns.):   Si es menor al cosumo de todos los hijos de deja en 0. 
				--							   Si es mayor se deja en este campo a diferencia con el consumo de los hijos
				--@facCnsFinal(Consumo final): Se guarda el consumo de la factura antes de aplicar los consumos comunitarios. 
				--***********************
				
				--[00]Inicializamos las variables
				SELECT @facConsumoFactura = ISNULL(F.facConsumoFactura, 0)
					 , @facCnsFinal = ISNULL(F.facCnsFinal, 0)
					 --Suma de los consumos de los hijos
					, @facCnsComunitario  = @cnsTotalDescontar 
				FROM dbo.facturas AS F
				WHERE F.facCtrCod = @contrato 
				AND   F.facPerCod = @periodo
				AND   F.facNumero IS NULL;

				--SELECT [@facConsumoFactura]=@facConsumoFactura, [@facCnsFinal]=@facCnsFinal, [@przFecIniCnsCom]=@przFecIniCnsCom, [@contrato]=@contrato;

				IF (@przFecIniCnsCom IS NULL)
				BEGIN
					--[01]Si es la primera vez que lanzamos la actualización de consumos comunitarios => Mantenemos el criterio original de acuama
					SELECT @facConsumoFactura = CASE WHEN COALESCE(facCnsFinal, facConsumoFactura, 0) < @cnsTotalDescontar THEN 0 
											 ELSE COALESCE(facCnsFinal, facConsumoFactura, 0) - @cnsTotalDescontar END
						 , @facCnsFinal = COALESCE(facCnsFinal, facConsumoFactura, 0)
					FROM dbo.facturas AS F
					WHERE F.facCtrCod = @contrato 
					  AND F.facPerCod = @periodo
					  AND F.facNumero IS NULL
					  AND @przFecIniCnsCom IS NULL;
				END
				ELSE
				BEGIN
					--[02] Si se han aplicado ya los consumos comunitarios una primera vez, usamos la lógica para ver que ha pasado para no perder los consumos
					SELECT @facConsumoFactura =
								CASE WHEN F.facConsumoFactura = 0 
									 THEN 0
									 WHEN F.facConsumoFactura <> (F.facCnsFinal-@facCnsComunitario)
									 THEN IIF(F.facConsumoFactura <= @facCnsComunitario, 0, F.facConsumoFactura-@facCnsComunitario)
									 ELSE @facConsumoFactura END

						 , @facCnsFinal =
								CASE WHEN F.facConsumoFactura = 0 
									 THEN IIF(F.facCnsFinal <= @facCnsComunitario, F.facCnsFinal, 0)
									 WHEN F.facConsumoFactura <> (F.facCnsFinal-@facCnsComunitario)
									 THEN F.facConsumoFactura
									 ELSE F.facCnsFinal END
					FROM dbo.facturas AS F
					WHERE F.facCtrCod = @contrato 
					AND   F.facPerCod = @periodo
					AND   F.facNumero IS NULL
					AND   @przFecIniCnsCom IS NOT NULL;
				END
				
				--SELECT [@facConsumoFactura]=@facConsumoFactura, [@facCnsFinal]=@facCnsFinal, [@przFecIniCnsCom]=@przFecIniCnsCom, [@contrato]=@contrato;

				--***********************
				--Version Nueva: 2.0.0
				UPDATE F SET
				  facCnsFinal		= @facCnsFinal
				, facConsumoFactura = @facConsumoFactura
				, facCnsComunitario = @facCnsComunitario
				, facCtrVersion		= ISNULL(C.ctrVersion, facCtrVersion) 
				FROM dbo.facturas AS F
				LEFT JOIN dbo.vContratosUltimaVersion AS C
				ON  C.ctrCod = F.facCtrCod
				AND @usarYActualizarFacCtrVersion = 1
				WHERE F.facCtrCod = @contrato 
				AND   F.facPerCod = @periodo
				AND   F.facNumero IS NULL;
			END

			ELSE
			BEGIN 
				--***********************
				--Version Original: 1.0.0
				--Actualizar la factura			
				UPDATE facturas SET
				facCnsFinal=ISNULL(facCnsFinal,facConsumoFactura),
				facConsumoFactura=CASE WHEN (ISNULL(facCnsFinal,facConsumoFactura)<@cnsTotalDescontar) THEN 0 ELSE (ISNULL(facCnsFinal,facConsumoFactura) - @cnsTotalDescontar) END,
				facCnsComunitario=@cnsTotalDescontar,
				facCtrVersion = CASE WHEN @usarYActualizarFacCtrVersion = 1 THEN (SELECT MAX(ctrVersion) FROM contratos WHERE ctrCod = facCtrCod) ELSE facCtrVersion END 
				WHERE facCtrCod=@contrato 
				  AND facNumero IS NULL 
				  AND facPerCod=@periodo
			END



			SET @myError = @@ERROR 
			IF @myError <> 0 GOTO cCalcularConsumos_ERROR
		END
	
		SET @totalHijosRepartir = 0
	
		SELECT @totalHijosRepartir = ISNULL(COUNT(*),0) 
		FROM @tablaAuxiliar 
		WHERE metodoCalculo=@MCalculoRepartir AND padre = @contrato
		--PRINT 'El número de hijos a repartir en el padre ' + CAST(@contrato AS VARCHAR) + ' es: ' + CAST(@totalHijosRepartir AS VARCHAR)
	
		--***********************
		--REPARTIR
		--***********************
		IF(@totalHijosRepartir>0)
		BEGIN
			SET @cnsHijoRepartir = 0	
	
			SELECT @cnsTotalRepartir = ISNULL(consumoFactura,0) FROM @tablaAuxiliar WHERE contrato=@contrato
			SET @cnsHijoRepartir = @cnsTotalRepartir / @totalHijosRepartir
			SET @cnsTotalRepartir = @cnsHijoRepartir * @totalHijosRepartir
		
			--PRINT 'El consumo para cada hijo de repartir es de: ' + CAST(@cnsHijoRepartir AS VARCHAR)
			--PRINT 'El consumo para restar al padre después de repartir es de: ' + CAST(@cnsTotalRepartir AS VARCHAR)
		
			--Se actualiza la factura del padre quitandole el consumo a repartir
			UPDATE facturas SET
			facCnsFinal=ISNULL(facCnsFinal,facConsumoFactura),
			facConsumoFactura=CASE WHEN (facConsumoFactura < @cnsTotalRepartir) THEN 0 ELSE (facConsumoFactura - @cnsTotalRepartir) END,
			facCtrVersion = CASE WHEN @usarYActualizarFacCtrVersion = 1 THEN (SELECT MAX(ctrVersion) FROM contratos WHERE ctrCod = facCtrCod) ELSE facCtrVersion END
			WHERE facCtrCod=@contrato 
			  AND facNumero IS NULL 
			  AND facPerCod=@periodo
		
			SET @myError = @@ERROR 
			IF @myError <> 0 GOTO cCalcularConsumos_ERROR
		
			--Actualizar las facturas con los hijos que se les deba repartir
			UPDATE facturas SET
			facCnsFinal = ISNULL(facCnsFinal,facConsumoFactura),
			facConsumoFactura = @cnsHijoRepartir,
			facCtrVersion = CASE WHEN @usarYActualizarFacCtrVersion = 1 THEN (SELECT MAX(ctrVersion) FROM contratos WHERE ctrCod = facCtrCod) ELSE facCtrVersion END
			WHERE facNumero IS NULL 
			  AND facPerCod=@periodo 
			  AND facCtrCod IN (SELECT contrato FROM @tablaAuxiliar WHERE metodoCalculo=@MCalculoRepartir AND padre=@contrato)
		
			SET @myError = @@ERROR 
			IF @myError <> 0 GOTO cCalcularConsumos_ERROR
		END
	
		--OPERACIONES EN MODO TAREA (ejecución desde el servicio windows):
		IF @tskUser IS NOT NULL AND @tskType IS NOT NULL AND @tskNumber IS NOT NULL
		BEGIN
			--EN CADA ITERACIÓN DEBEMOS COMPROBAR SI EL USUARIO DESEA CANCELAR LA OPERACIÓN
			EXEC @CANCEL = Task_Schedule_CHECK_STOP @tskUser, @tskType, @tskNumber
			IF @CANCEL = 1 BEGIN 
				CLOSE cCalcularConsumos
				DEALLOCATE cCalcularConsumos
				GOTO CANCEL 
			END
		
			--ANTES DE PASAR AL SIGUIENTE REGISTRO, AUMENTO EL NÚMERO DE PASO DE LA TAREA
			EXEC Task_Schedule_PerformStep @tskUser, @tskType, @tskNumber
		END
	
		FETCH NEXT FROM cCalcularConsumos 
		INTO  @periodo, @contrato
	END
	
	CLOSE cCalcularConsumos
	DEALLOCATE cCalcularConsumos

	--Actualizar laS fechas de la aplicación de consumos comunitarios
	UPDATE perzona SET
	przFecIniCnsCom = CASE WHEN przFecIniCnsCom IS NULL THEN @fechaProceso ELSE przFecIniCnsCom END,
	przFecCnsCom = @fechaProceso
	WHERE  przcodper=@facPerCod AND przcodzon=@zona

	SET @myError = @@ERROR 
	IF @myError <> 0 GOTO cActualizarPerZona_ERROR


	--*************************
	--AL FINAL RESULTA QUE ACTUALIZA TODAS LAS LINEAS DE TODA LA ZONA
	IF EXISTS (SELECT * FROM @tablaAuxiliar)
	BEGIN
		EXEC @myError = dbo.Facturas_ActualizarLineas NULL,@periodo,NULL,NULL,@ctrZonCod,NULL,NULL
	END
	--*************************

	IF @myError <> 0 GOTO cActualizarLineasFacturas_ERROR

	--Antes de hacer el COMMIT debemos comprobar si el usuario desea cancelar la operación
	IF @tskUser IS NOT NULL AND @tskType IS NOT NULL AND @tskNumber IS NOT NULL
	BEGIN
		EXEC @CANCEL = Task_Schedule_CHECK_STOP @tskUser, @tskType, @tskNumber
		IF @CANCEL = 1 GOTO CANCEL
	END

	--Si todo ha ido bien indicamos los árboles que han sido afectados, osea los contratos padres de esos árboles
	SET @arbolesComunitariosAfectados = (SELECT COUNT(*) FROM @tablaAuxiliar WHERE padre IS NULL)

COMMIT TRANSACTION

--*************************
--LANZAMOS LA ACTUALIZACION
SET @spMessage = FORMATMESSAGE('%s=> Tiempo Ejecución antes de factotales: %s seg.', @msgParams, FORMAT(DATEDIFF(SECOND, @starttime, GETDATE()), 'N0', 'es-ES')); 
EXEC Trabajo.errorLog_Insert @spName= @spName, @spMessage=@spMessage;

EXEC dbo.FacTotalesTrab_DeleteFacturas @F;
-----------------------------
SET @spMessage = FORMATMESSAGE('%s=> #Fac.Comunitarias: %i, #Fac.PerZona: %i, FAC_APERTURA:%s, Tiempo Ejecución: %s seg.', @msgParams, @ROWS, @PERZONAROWS, @FAC_APERTURA, FORMAT(DATEDIFF(SECOND, @starttime, GETDATE()), 'N0', 'es-ES')); 
EXEC Trabajo.errorLog_Insert @spName= @spName, @spMessage=@spMessage;
--*************************

RETURN 0

insertTablaAuxiliar_ERROR:
	GOTO rollback_ERROR

cComun_ERROR:
	CLOSE cComun
	DEALLOCATE cComun
	GOTO rollback_ERROR
	
cCalcularConsumos_ERROR:
	CLOSE cCalcularConsumos
	DEALLOCATE cCalcularConsumos
	GOTO rollback_ERROR

cActualizarPerZona_ERROR:
	GOTO rollback_ERROR
	
cActualizarLineasFacturas_ERROR:
	GOTO rollback_ERROR

rollback_ERROR:
	IF @@TRANCOUNT > 0 --Si hay transacción activa y ha habido error --> hacemos el rollback
		ROLLBACK TRANSACTION
	
	--*************************
	--LANZAMOS LA ACTUALIZACION
	SET @spMessage = FORMATMESSAGE('%s=> Tiempo Ejecución antes de factotales: %s seg.', @msgParams, FORMAT(DATEDIFF(SECOND, @starttime, GETDATE()), 'N0', 'es-ES')); 
	EXEC Trabajo.errorLog_Insert @spName= @spName, @spMessage=@spMessage;

	EXEC dbo.FacTotalesTrab_DeleteFacturas @F;
	-----------------------------
	SET @spMessage = FORMATMESSAGE('%s=> #Fac.Comunitarias: %i, #Fac.PerZona: %i, FAC_APERTURA:%s, Tiempo Ejecución: %s seg.', @msgParams, @ROWS, @PERZONAROWS, @FAC_APERTURA, FORMAT(DATEDIFF(SECOND, @starttime, GETDATE()), 'N0', 'es-ES')); 
	EXEC Trabajo.errorLog_Insert @spName= @spName, @spMessage=@spMessage;
	--*************************
	RETURN @myError
	
CANCEL:
	IF @@TRANCOUNT > 0 
		ROLLBACK TRANSACTION
	
	--*************************
	--LANZAMOS LA ACTUALIZACION
	SET @spMessage = FORMATMESSAGE('%s=> Tiempo Ejecución antes de factotales: %s seg.', @msgParams, FORMAT(DATEDIFF(SECOND, @starttime, GETDATE()), 'N0', 'es-ES'));  
	EXEC Trabajo.errorLog_Insert @spName= @spName, @spMessage=@spMessage;

	EXEC dbo.FacTotalesTrab_DeleteFacturas @F;
	-----------------------------
	SET @spMessage = FORMATMESSAGE('%s=> #Fac.Comunitarias: %i, #Fac.PerZona: %i, FAC_APERTURA:%s, Tiempo Ejecución: %s seg.', @msgParams, @ROWS, @PERZONAROWS, @FAC_APERTURA, FORMAT(DATEDIFF(SECOND, @starttime, GETDATE()), 'N0', 'es-ES')); 
	EXEC Trabajo.errorLog_Insert @spName= @spName, @spMessage=@spMessage;
	--*************************
	RETURN 0
	
END


