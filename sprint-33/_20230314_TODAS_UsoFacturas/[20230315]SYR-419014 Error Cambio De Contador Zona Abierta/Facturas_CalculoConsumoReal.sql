
DECLARE @facLecActFec DATETIME = '20230315' 
DECLARE @facLecInlCod VARCHAR(2) = '5' 
DECLARE @facLecAntFec DATETIME = '20220916 08:18:57.563'
DECLARE @facLecAnt INT = 3453 
DECLARE @facCtrCod INT = 22464
--*******************************************
DECLARE @consumoReal INT 
DECLARE @updateCamValidoFacturar BIT = 1 
DECLARE @lecturaAnterior INT 
DECLARE @consumoPagadoPrevio INT  
/*
CREATE PROCEDURE [dbo].[Facturas_CalculoConsumoReal1] 
( 
	@facLecActFec DATETIME = NULL,		--Fecha lectura actual
	@facLecInlCod VARCHAR(2) = NULL,	--Incidencia de lectura actual
	@facLecAntFec DATETIME = NULL,		--Fecha lectura anterior
	@facLecAnt INT,						--Lectura anterior
	@facCtrCod INT,						--Código del contrato
	@consumoReal INT OUT,				--Consumo real (acumulado)
	@updateCamValidoFacturar BIT = 1,	--SYR-303029 + Modificación para CC y lectura mismo día
	@lecturaAnterior INT OUT,			--Lectura anterior real
	@consumoPagadoPrevio INT OUT		--Consumo pagado previo
)

AS
*/

SET NOCOUNT OFF;
	
DECLARE @explotacion varchar(100) = NULL
SELECT @explotacion = pgsValor FROM parametros WHERE pgsClave = 'EXPLOTACION'

DECLARE @lecturaRetirada AS INT
DECLARE @lecturaInstalacion AS INT
DECLARE @consumoAFacturar AS INT
DECLARE @conCamFecha AS DATETIME
DECLARE @conCamOtNum AS INT = 0
DECLARE @conCamConID AS INT = 0
DECLARE @conCamConsumoPagadoPrevio AS INT = 0

--INICIALIZAR VARIABLES
SET @lecturaAnterior = @facLecAnt
SET @consumoReal = 0
SET @consumoPagadoPrevio = 0

--*********************************************
DECLARE @cnsRetirada INT;
DECLARE @difLectRetirada INT;

SELECT [@lecturaRetirada] = conCamLecRet
	, [@lecturaAnterior]=@lecturaAnterior
	, conCamLecIns
	, [@consumoAFacturar]= conCamConsumoAFacturar, conCamFecha
	, [@conCamOtNum] = conCamOtNum
	, conCamConID, conCamConsumoPagadoPrevio
	, [@explotacion] = @explotacion
	, [@facLecInlCod] = @facLecInlCod

	FROM contadorCambio 
	INNER JOIN ordenTrabajo ON otSerScd = conCamOtSerScd AND otSerCod = conCamOtSerCod AND otNum = conCamOtNum
	INNER JOIN contratos ON ctrCod = otCtrCod AND ctrVersion = otCtrVersion
	WHERE ctrCod = @facCtrCod 
			AND conCamFecha >= CAST(@facLecAntFec AS date) AND conCamFecha <= CAST(ISNULL(@facLecActFec,GETDATE()) as date)
		  AND (conCamFacturado = 0 OR conCamFacturado is null)
	ORDER BY conCamFecha
--*********************************************


--OBTENEMOS EN UN CURSOR LOS CAMBIOS DE CONTADOR DE LA ORDEN DE TRABAJO DEL CONTRATO DE LA FACTURA
--Modificación: También obtenemos cambios de contador del mismo día de la lectura anterior, ya que quedaría un consumo intermedio pendiente de facturar
--en caso de que no se hubiera marcado ya como facturado
DECLARE c1 CURSOR FOR
	SELECT conCamLecRet, conCamLecIns, conCamConsumoAFacturar, conCamFecha, conCamOtNum, conCamConID, conCamConsumoPagadoPrevio
	FROM contadorCambio 
	INNER JOIN ordenTrabajo ON otSerScd = conCamOtSerScd AND otSerCod = conCamOtSerCod AND otNum = conCamOtNum
	INNER JOIN contratos ON ctrCod = otCtrCod AND ctrVersion = otCtrVersion
	WHERE ctrCod = @facCtrCod AND
		  conCamFecha >= CAST(@facLecAntFec AS date) AND conCamFecha <= CAST(ISNULL(@facLecActFec,GETDATE()) as date)
		  AND (conCamFacturado = 0 OR conCamFacturado is null)
	ORDER BY conCamFecha

OPEN c1
FETCH NEXT FROM c1 INTO @lecturaRetirada, @lecturaInstalacion, @consumoAFacturar, @conCamFecha, @conCamOtNum, @conCamConID, @conCamConsumoPagadoPrevio
WHILE @@FETCH_STATUS = 0
BEGIN	

	--Puede darse el caso de CC-L-PL-PCC
	--Lo sabremos, si:
		--está pendiente de facturar, 
		--el consumo pagado previo es nulo, 
		--la incidencia actual no es CC
		--la lectura anterior es en la misma fecha del CC
		--la incidencia anterior sí era de tipo CC	
	IF (@explotacion IN ('Soria', 'Melilla') 
		AND @conCamConsumoPagadoPrevio IS NULL 
		AND (@facLecInlCod IS NULL OR @facLecInlCod <> '5') 
		AND CAST(@facLecAntFec AS DATE) = CAST(@conCamFecha AS DATE))
	BEGIN
		declare @lecAntAux int, @incLecAux varchar(2)
		
		--Obtengo la lectura anterior de la factura anterior
		SELECT @lecAntAux = facLecAnt, @incLecAux = facLecInlCod
		FROM facturas 
		WHERE 
			facFechaRectif is null AND
			facCtrCod = @facCtrCod AND
			facLecAct = @facLecAnt AND
			CAST(facLecActFec AS date) = CAST(@facLecAntFec AS date)
			
		IF(@incLecAux = '5')
		BEGIN
			SET @lecturaAnterior = @lecAntAux
		END
	END
	
	--****************************************************************************************
	--Diferencia entre la lectura anterior y la lectura de retirada
	SET @difLectRetirada = ISNULL(@lecturaRetirada, 0) - ISNULL(@lecturaAnterior, 0);
	--Consumo en el contador retirado
	SET @cnsRetirada =  ISNULL(@consumoAFacturar, @difLectRetirada);
	
	--Acumulamos porque puede que haya mas de un cambio de contador desde la ultima lectura 
	SET @consumoReal = @consumoReal + @cnsRetirada;
	
	--SET @consumoReal = @consumoReal + ISNULL(@consumoAFacturar, ISNULL(@lecturaRetirada, 0) - @lecturaAnterior)
	--****************************************************************************************
	
	SET @consumoPagadoPrevio = @consumoPagadoPrevio + ISNULL(@conCamConsumoPagadoPrevio, 0)
	SET @lecturaAnterior = @lecturaInstalacion
	
	--si llamo desde la subida de lectura, actualizo el cambio de contador como válido para facturar
	UPDATE contadorCambio
	SET conCamValidoParaFacturar = 1
	WHERE 
		conCamOtNum = @conCamOtNum AND conCamFecha = @conCamFecha AND conCamConID = @conCamConID 
		AND (conCamValidoParaFacturar = 0 OR conCamValidoParaFacturar is null) AND @updateCamValidoFacturar = 1
	
    FETCH NEXT FROM c1 INTO @lecturaRetirada, @lecturaInstalacion, @consumoAFacturar, @conCamFecha, @conCamOtNum, @conCamConID, @conCamConsumoPagadoPrevio
END
CLOSE c1
DEALLOCATE c1

--****************************************************************************************
--Ha terminado la iteración en todos los cambios de contador con al menos uno cambio 
--Si la incidencia de lectura es del tipo cambio de contador, sumamos según la lectura del lector
--IF(@conCamOtNum IS NOT NULL AND @facLecInlCod IS NOT NULL AND @facLecInlCod=5 AND @explotacion IN ('Soria', 'Melilla'))
--BEGIN
--  
--END
--****************************************************************************************

IF(@consumoReal < 0 OR @consumoReal IS NULL)
	SET @consumoReal = 0

IF(@consumoPagadoPrevio < 0 OR @consumoPagadoPrevio IS NULL)
	SET @consumoPagadoPrevio = 0

SET @lecturaAnterior = ISNULL(@lecturaAnterior,@facLecAnt)



SELECT [@consumoReal]=@consumoReal, [@lecturaAnterior]=@lecturaAnterior, [@consumoPagadoPrevio]=@consumoPagadoPrevio;

EXEC [dbo].[Facturas_CalculoConsumoReal] @facLecActFec,@facLecInlCod,@facLecAntFec, @facLecAnt, @facCtrCod, @consumoReal OUT, @updateCamValidoFacturar, @lecturaAnterior OUT, @consumoPagadoPrevio OUT;

SELECT [@consumoReal]=@consumoReal, [@lecturaAnterior]=@lecturaAnterior, [@consumoPagadoPrevio]=@consumoPagadoPrevio;
