-- =============================================
-- Autor: CPO
-- Fecha de creaci�n: 08/02/2008
-- Descripci�n:	Proceso de Calculo del consumo real
-- C�digo del m�dulo:
-- =============================================

ALTER PROCEDURE [dbo].[Facturas_CalculoConsumoReal] 
( 
	@facLecActFec DATETIME = NULL, --Fecha lectura actual
	@facLecInlCod VARCHAR(2) = NULL, --Incidencia de lectura actual
	@facLecAntFec DATETIME = NULL, --Fecha lectura anterior
	@facLecAnt INT, --Lectura anterior
	@facCtrCod INT, --C�digo del contrato
	@consumoReal INT OUT, --Consumo real (acumulado)
	@updateCamValidoFacturar BIT = 1, --SYR-303029 + Modificaci�n para CC y lectura mismo d�a
	@lecturaAnterior INT OUT, --Lectura anterior real
	@consumoPagadoPrevio INT OUT --Consumo pagado previo
)
AS
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

--OBTENEMOS EN UN CURSOR LOS CAMBIOS DE CONTADOR DE LA ORDEN DE TRABAJO DEL CONTRATO DE LA FACTURA
--Modificaci�n: Tambi�n obtenemos cambios de contador del mismo d�a de la lectura anterior, ya que quedar�a un consumo intermedio pendiente de facturar
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
		--est� pendiente de facturar, 
		--el consumo pagado previo es nulo, 
		--la incidencia actual no es CC
		--la lectura anterior es en la misma fecha del CC
		--la incidencia anterior s� era de tipo CC	
	IF ((@explotacion = 'Soria' OR @explotacion = 'Melilla') AND @conCamConsumoPagadoPrevio is null AND (@facLecInlCod is null OR @facLecInlCod <> '5') AND CAST(@facLecAntFec AS date) = CAST(@conCamFecha AS date))
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
	
	SET @consumoReal = @consumoReal + ISNULL(@consumoAFacturar, ISNULL(@lecturaRetirada, 0) - @lecturaAnterior)
	SET @consumoPagadoPrevio = @consumoPagadoPrevio + ISNULL(@conCamConsumoPagadoPrevio, 0)
	SET @lecturaAnterior = @lecturaInstalacion
	
	--si llamo desde la subida de lectura, actualizo el cambio de contador como v�lido para facturar
	UPDATE contadorCambio
	SET conCamValidoParaFacturar = 1
	WHERE 
		conCamOtNum = @conCamOtNum AND conCamFecha = @conCamFecha AND conCamConID = @conCamConID 
		AND (conCamValidoParaFacturar = 0 OR conCamValidoParaFacturar is null) AND @updateCamValidoFacturar = 1
	
    FETCH NEXT FROM c1 INTO @lecturaRetirada, @lecturaInstalacion, @consumoAFacturar, @conCamFecha, @conCamOtNum, @conCamConID, @conCamConsumoPagadoPrevio
END
CLOSE c1
DEALLOCATE c1

IF(@consumoReal < 0 OR @consumoReal IS NULL)
	SET @consumoReal = 0

IF(@consumoPagadoPrevio < 0 OR @consumoPagadoPrevio IS NULL)
	SET @consumoPagadoPrevio = 0

SET @lecturaAnterior = ISNULL(@lecturaAnterior,@facLecAnt)
GO


