-- =============================================
-- Autor: CPO
-- Fecha de creación: 12/02/2008
-- Descripción: Cálculo de valores de tarifa
-- Código del módulo: CF006
-- =============================================
ALTER PROCEDURE [dbo].[Facturas_ObtenerValoresTarifa]

	--PARÁMETROS DE ENTRADA
	@codigoServicio SMALLINT,
	@codigoTarifa SMALLINT,
	@fechaPeriodoDesde DATETIME,
	@fechaPeriodoHasta DATETIME,
	@fechaInicio DATETIME,
	@fechaFin DATETIME,

	--PARÁMETROS DE SALIDA
	@precio1Out AS DECIMAL(10,6) OUTPUT, 
	@precio2Out AS DECIMAL(10,6) OUTPUT, 
	@precio3Out AS DECIMAL(10,6) OUTPUT, 
	@precio4Out AS DECIMAL(10,6) OUTPUT, 
	@precio5Out AS DECIMAL(10,6) OUTPUT,  
	@precio6Out AS DECIMAL(10,6) OUTPUT, 
	@precio7Out AS DECIMAL(10,6) OUTPUT, 
	@precio8Out AS DECIMAL(10,6) OUTPUT, 
	@precio9Out AS DECIMAL(10,6) OUTPUT, 
	@cuotaOut AS DECIMAL(10,4) OUTPUT,
	@conValorTarifa AS BIT=0 OUTPUT,
	@altaBajaPerActual BIT=NULL

AS

BEGIN

	SET NOCOUNT ON;

	--****DEBUG*********
	--IF (@codigoServicio=2)
	--SELECT 'OVT 1', codigoServicio=@codigoServicio , codigoTarifa= @codigoTarifa
	--, fechaPeriodoDesde=FORMAT(@fechaPeriodoDesde, 'dd-MM-yyyy'), fechaPeriodoHasta=FORMAT(@fechaPeriodoHasta, 'dd-MM-yyyy')
	--, DiasPeriodo= DATEDIFF(DAY, @fechaPeriodoDesde, @fechaPeriodoHasta)
	--, fechaInicio=FORMAT(@fechaInicio, 'dd-MM-yyyy'), fechaFin=FORMAT(@fechaFin, 'dd-MM-yyyy')
	--, DiasFechas= DATEDIFF(DAY, @fechaInicio, @fechaFin);
	--******************
	
	--******************
	--SYR-430531: 10/04/2023
	--Si no hay fecha en los datos del periodo lo inicializamos con la fecha actual
	DECLARE @ahora AS DATE = dbo.GetAcuamaDate();

	SELECT @fechaPeriodoDesde= @ahora
	     , @fechaPeriodoHasta= DATEADD(DAY, 1, @ahora)
	WHERE COALESCE(@fechaPeriodoDesde, @fechaPeriodoHasta) IS NULL
	--******************
	

	--************
	--Cambia de valor si existe al menos un valor de tarifa para el rango de fechas
	--DECLARE @conValorTarifa AS BIT;
	SET @conValorTarifa = 0;
	--************
	
	DECLARE @myError AS INT

	--INICIALIZO PARÁMETROS
	SET @precio1Out = 0 
	SET @precio2Out = 0 
	SET @precio3Out = 0 
	SET @precio4Out = 0 
	SET @precio5Out = 0 
	SET @precio6Out = 0 
	SET @precio7Out = 0
	SET @precio8Out = 0
	SET @precio9Out = 0

	SET @cuotaOut = 0
	SET @altaBajaPerActual=ISNULL(@altaBajaPerActual,0)

	--OBTENER PARÁMETROS
	DECLARE @prgCuotaP AS BIT = 0 --Cálculo Cuota Proporcional
	DECLARE @prgDiasP AS BIT = 0 --Cálculo Días Proporcional
	DECLARE @explotacion AS VARCHAR(50) = NULL

    SELECT @prgCuotaP = CAST(ISNULL(pgsvalor,0) AS BIT)
	FROM parametros
	WHERE pgsclave = 'PRGCUOTAP'

	SELECT @prgDiasP = CAST(ISNULL(pgsvalor,0) AS BIT)
	FROM parametros
	WHERE pgsclave = 'PRGDIASP'

	SELECT @explotacion = CAST(ISNULL(pgsvalor,'') AS VARCHAR)
	FROM parametros
	WHERE pgsclave = 'EXPLOTACION'

	--CÁLCULO DE DIASPER Y DIASINM
	DECLARE @diasPer AS INT
	DECLARE @diasInm AS INT

	IF @fechaFin IS NULL OR @fechaFin < CAST('01/01/1900' AS DATETIME) 
		SET @fechaFin = CAST('01/01/1900' AS DATETIME) 

	DECLARE @diasPorMeses INT = 0
	DECLARE @cambioTarifa BIT = 0

	--Solo para la explotación de Guadalajara
	IF (@explotacion = 'Guadalajara' AND
		--Se debe facturar el trimestre completo, si es un alta o baja a mitad de trimestre no entrará, en ese caso se cogerán los días correspondientes
		@altaBajaPerActual=0 AND
		--Condicionamos que se haya producido un cambio de código de tarifa a mitad de periodo
	   ((@fechaInicio > @fechaPeriodoDesde) OR (@fechaFin > CAST('01/01/1900' AS DATETIME) AND @fechaFin < @fechaPeriodoHasta)
	   )) 
		BEGIN

			SET @cambioTarifa = 1

			SET @diasPer = DATEDIFF(day,@fechaPeriodoDesde,@fechaPeriodoHasta) + 1 - ((DATEDIFF(day,@fechaPeriodoDesde,@fechaPeriodoHasta) + 1) - 90)
			
			IF (@fechaInicio > @fechaPeriodoDesde)
				SET @diasPorMeses = CASE WHEN DATEDIFF(day, @fechaInicio, @fechaPeriodoHasta) + 1 > 60 THEN 60 ELSE 30 END

			IF (@fechaFin > CAST('01/01/1900' AS DATETIME) AND @fechaFin < @fechaPeriodoHasta)
				SET @diasPorMeses = CASE WHEN DATEDIFF(day, @fechaPeriodoDesde, @fechaFin) + 1 > 60 THEN 60 ELSE 30 END
		END
	ELSE 

		BEGIN
			SET @diasPer = DATEDIFF(day,@fechaPeriodoDesde, @fechaPeriodoHasta) + 1

			IF (@fechaInicio > @fechaPeriodoDesde)
				SET @fechaPeriodoDesde = @fechaInicio
	
			IF(@fechaFin > CAST('01/01/1900' AS DATETIME) AND @fechaFin < @fechaPeriodoHasta)
				SET @fechaPeriodoHasta = @fechaFin
		END

	IF(@prgDiasP = 1)
		SET @diasInm = CASE WHEN @cambioTarifa=1 THEN @diasPorMeses ELSE DATEDIFF(day,@fechaPeriodoDesde,@fechaPeriodoHasta) + 1 END
	ELSE
		SET @diasInm = @diasPer
		   
	--RECORRO LOS VALORES DE TARIFA PARA CALCULAR LOS PRECIOS
	DECLARE @cuota AS DECIMAL(10,4)
	DECLARE @precio1 AS DECIMAL(10,6)
	DECLARE @precio2 AS DECIMAL(10,6)
	DECLARE @precio3 AS DECIMAL(10,6)
	DECLARE @precio4 AS DECIMAL(10,6)
	DECLARE @precio5 AS DECIMAL(10,6)
	DECLARE @precio6 AS DECIMAL(10,6)
	DECLARE @precio7 AS DECIMAL(10,6)
	DECLARE @precio8 AS DECIMAL(10,6)
	DECLARE @precio9 AS DECIMAL(10,6)
	DECLARE @fechaTarifaInicio AS DATETIME
	DECLARE @fechaTarifaFin AS DATETIME
	DECLARE @porce AS DECIMAL(16,2)
	DECLARE @diasTar AS INT

	--****DEBUG*********
	--IF @codigoServicio=2 
	--SELECT 'OVT 2', trvSrvCod, trvTrfCod,  trvCuota, trvFecha, trvFechaFin
	--, perDesde=FORMAT(@fechaPeriodoDesde, 'dd-MM-yyyy')
	--, perHasta=FORMAT(@fechaPeriodoHasta, 'dd-MM-yyyy')
	--, DiasPeriodo= DATEDIFF(DAY, @fechaPeriodoDesde, @fechaPeriodoHasta)
	--, [F.ini]=FORMAT(@fechaInicio, 'dd-MM-yyyy'), [F.fin]=FORMAT(@fechaFin, 'dd-MM-yyyy')
	--FROM tarval
	--WHERE trvSrvCod = @codigoServicio
	--  AND trvTrfCod = @codigoTarifa 
	--  AND (@cambioTarifa=1 OR (trvFechaFin >= @fechaPeriodoDesde OR trvFechaFin IS NULL)) 
	--  AND (trvFecha <= @fechaPeriodoHasta)
	--ORDER BY trvFecha
	--******************
	
	DECLARE c1 CURSOR FOR
	SELECT trvCuota, trvPrecio1, trvPrecio2, trvPrecio3, trvPrecio4, trvPrecio5,
			trvPrecio6, trvPrecio7, trvPrecio8, trvPrecio9, trvFecha, trvFechaFin
	FROM tarval
	WHERE trvSrvCod = @codigoServicio 
	  AND trvTrfCod = @codigoTarifa 
	  AND (@cambioTarifa=1 OR (trvFechaFin >= @fechaPeriodoDesde OR trvFechaFin IS NULL)) 
	  AND (trvFecha <= @fechaPeriodoHasta)
	ORDER BY trvFecha

	OPEN c1
	FETCH NEXT FROM c1 
	INTO @cuota, @precio1, @precio2, @precio3, @precio4, @precio5, @precio6,
		 @precio7, @precio8, @precio9, @fechaTarifaInicio, @fechaTarifaFin
	WHILE @@FETCH_STATUS = 0
	
	BEGIN
		--Hay al menos un valor de tarifa disponible en el rango de fechas
		SET @conValorTarifa = 1;

		IF (@fechaTarifaFin IS NULL OR @fechaTarifaFin < CAST('01/01/1900' AS DATETIME))
			BEGIN
				IF (@fechaPeriodoHasta IS NULL)	
					SET @fechaTarifaFin = CAST('31/12/2999' AS DATETIME)
				ELSE 
					SET @fechaTarifaFin = @fechaPeriodoHasta
			END
		
		IF (@cambioTarifa=1 OR (@fechaPeriodoHasta <= @fechaTarifaFin AND @cuotaOut = 0)) --PERIODO DE 1 SOLA TARIFA
	
			BEGIN
			--****DEBUG*********
			--IF @codigoServicio=1
			--SELECT diasInm = @diasInm, diasPer=@diasPer, codigoServicio=@codigoServicio, codigoTarifa=@codigoTarifa, cambioTarifa=@cambioTarifa, fechaPeriodoHasta=@fechaPeriodoHasta, fechaTarifaFin=@fechaTarifaFin;
			--******************
			IF(@diasInm < @diasPer)
			BEGIN
				IF(@diasInm > 0)
				BEGIN
					IF (@explotacion = 'Guadalajara' AND @cambioTarifa=1 AND @altaBajaPerActual=0) 
						SET @porce = @diasInm/30
					ELSE			
						SET @porce = (CONVERT(DECIMAL(16,2),@diasInm) * 100) / @diasPer
				END
				ELSE
				BEGIN
					SET @porce = 0
				END	
				
				IF (@explotacion = 'Guadalajara' AND @cambioTarifa=1 AND @altaBajaPerActual = 0) 
					SET @cuotaOut = (@cuota/(@diasPer/30))* @porce
				ELSE
					SET @cuotaOut = (@cuota * @porce) / 100


					--****DEBUG*********
					--IF @codigoServicio=2
					--SELECT diasInm = @diasInm, diasPer=@diasPer, codigoTarifa=@codigoTarifa, porce=@porce, cuotaOut=@cuotaOut, Cuota=@cuota;
					--******************
			END

			ELSE
			BEGIN
				SET @cuotaOut = @cuota
			END

				--Si es un cambio de tarifa para Guadalajara y la fecha de fin de la tarifa antigua es menor a la de inicio del periodo actual la cuota fija se queda a 0
				--ya que ya se facturó toda la cuota fija en la factura del periodo anterior al actual
				IF (@explotacion = 'Guadalajara' AND @cambioTarifa = 1 AND (@fechaTarifaFin IS NOT NULL AND @fechaTarifaFin < @fechaPeriodoDesde))
					SET @cuotaOut = 0

				SET @precio1Out = @precio1
				SET @precio2Out = @precio2
				SET @precio3Out = @precio3
				SET @precio4Out = @precio4
				SET @precio5Out = @precio5
				SET @precio6Out = @precio6
				SET @precio7Out = @precio7
				SET @precio8Out = @precio8
				SET @precio9Out = @precio9

			END

		ELSE --CÁLCULOS PROPORCIONALES SEGÚN DIAS DE TARIFA
		 
			BEGIN 
		
				IF(@prgCuotaP = 1)

					BEGIN
						--CAMBIO DE TARIFA DE GUADALAJARA 01/09/2017
						--LOS TERMINOS FIJOS (SERVICIOS 23 y 24) PRECIOS SE CALCULAN POR MESES, EN LUGAR DE POR DÍAS COMO SIEMPRE SE HABÍA HECHO
						--CONDICIÓN NECESARIA QUE SE PRODUZCA, AUNQUE NO SEA DE ESE SERVICIO TRATADO 23 o 24, 
						--UN CAMBIO DE TARIFA A MITAD DE PERIODO Y ADEMÁS SEA GUADALAJARA PORQUE ES ALGO TOTALMENTE PARTICULAR DE ESA EXPLOTACIÓN
						/*IF (@explotacion = 'Guadalajara' AND (@codigoServicio = 23 OR @codigoServicio=24)) BEGIN
							SET @diasPer = DATEDIFF(day,@fechaPeriodoDesde,@fechaPeriodoHasta) + 1 - ((DATEDIFF(day,@fechaPeriodoDesde,@fechaPeriodoHasta) + 1) - 90)
							SET @diasTar = CASE WHEN DATEDIFF(day,@fechaPeriodoDesde, @fechaTarifaFin) + 1 > 60 THEN 60 ELSE 30 END
						END
						ELSE*/
						SET @diasTar = DATEDIFF(day,@fechaPeriodoDesde,@fechaTarifaFin) + 1
					END
				ELSE
					SET @diasTar = @diasPer

				SET @fechaPeriodoDesde = DATEADD(day,1,@fechaTarifaFin)
				SET @cuotaOut = @cuotaOut + (@diasTar * (@cuota / @diasPer))
				SET @precio1Out = @precio1Out + (@diasTar * (@precio1 / @diasPer)) 
				SET @precio2Out = @precio2Out + (@diasTar * (@precio2 / @diasPer)) 
				SET @precio3Out = @precio3Out + (@diasTar * (@precio3 / @diasPer)) 
				SET @precio4Out = @precio4Out + (@diasTar * (@precio4 / @diasPer)) 
				SET @precio5Out = @precio5Out + (@diasTar * (@precio5 / @diasPer)) 
				SET @precio6Out = @precio6Out + (@diasTar * (@precio6 / @diasPer)) 
				SET @precio7Out = @precio7Out + (@diasTar * (@precio7 / @diasPer)) 
				SET @precio8Out = @precio8Out + (@diasTar * (@precio8 / @diasPer)) 
				SET @precio9Out = @precio9Out + (@diasTar * (@precio9 / @diasPer))

				IF (@fechaPeriodoHasta <= @fechaTarifaFin OR @prgCuotaP = 0)
					BREAK --FIN 
			END
			
			--****DEBUG*********
			--IF @codigoServicio=2
			--SELECT 'OVT 3', Servicio=@codigoServicio , tarifa= @codigoTarifa
			--, perDesde=FORMAT(@fechaPeriodoDesde, 'dd-MM-yyyy'), perHasta=FORMAT(@fechaPeriodoHasta, 'dd-MM-yyyy'), DiasPeriodo= DATEDIFF(DAY, @fechaPeriodoDesde, @fechaPeriodoHasta)
			--, cuota=@cuota, cuotaOut=@cuotaOut, porce=@porce, diasInm=@diasInm, diasPer=@diasPer, diasTar=@diasTar;
			--******************
		
		FETCH NEXT FROM c1 
		INTO @cuota, @precio1, @precio2, @precio3, @precio4, @precio5, @precio6,
			 @precio7, @precio8, @precio9, @fechaTarifaInicio, @fechaTarifaFin
	END

	CLOSE c1
	DEALLOCATE c1

	RETURN 0

HANDLE_ERROR:
	RETURN @myError
END


GO


