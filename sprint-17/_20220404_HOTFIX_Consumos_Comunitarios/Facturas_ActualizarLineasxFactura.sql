--Recalcula las lineas con escalados
CREATE PROCEDURE [dbo].[Facturas_ActualizarLineasxFactura]
@facturas [dbo].[tFacturasPK] READONLY
AS
SET NOCOUNT ON; 
SET ANSI_WARNINGS OFF;

	--****** L O G **********
	DECLARE @starttime DATETIME =  GETDATE();
	DECLARE @spMessage VARCHAR(4000);
	DECLARE @spName VARCHAR(100) = FORMATMESSAGE('%s.%s', OBJECT_SCHEMA_NAME(@@PROCID), OBJECT_NAME(@@PROCID));
	DECLARE @msgParams VARCHAR(500) = FORMATMESSAGE('#facturasEnviadas=%i', (SELECT COUNT(1) FROM @facturas));
	DECLARE @count INT  = 0;	--Lineas procesadas
	DECLARE @countF INT = 0		--Facturas a procesar
	DECLARE @countFL INT  = 0;	--Lineas a procesar
	--......................

DECLARE @TRANCOUNT AS INT SET @TRANCOUNT = @@TRANCOUNT
IF @TRANCOUNT = 0 BEGIN TRANSACTION T ELSE SAVE TRANSACTION T 

--Contiene el código del error
DECLARE @myError int

DECLARE @consumoFact int	--almacenamos el consumo de cabecera de factura

DECLARE @uds1 decimal(12,2)
DECLARE @uds2 decimal(12,2)
DECLARE @uds3 decimal(12,2)
DECLARE @uds4 decimal(12,2)
DECLARE @uds5 decimal(12,2)
DECLARE @uds6 decimal(12,2)
DECLARE @uds7 decimal(12,2)
DECLARE @uds8 decimal(12,2)
DECLARE @uds9 decimal(12,2)

DECLARE @escala1 integer
DECLARE @escala2 integer
DECLARE @escala3 integer
DECLARE @escala4 integer
DECLARE @escala5 integer
DECLARE @escala6 integer
DECLARE @escala7 integer
DECLARE @escala8 integer
DECLARE @escala9 integer

DECLARE @precio1 decimal(10,6)
DECLARE @precio2 decimal(10,6)
DECLARE @precio3 decimal(10,6)
DECLARE @precio4 decimal(10,6)
DECLARE @precio5 decimal(10,6)
DECLARE @precio6 decimal(10,6)
DECLARE @precio7 decimal(10,6)
DECLARE @precio8 decimal(10,6)
DECLARE @precio9 decimal(10,6)

DECLARE @flUds DECIMAL(12,2)
DECLARE @flPrecio MONEY
DECLARE @porcImp DECIMAL(4,2)

DECLARE @flFacCod SMALLINT
DECLARE @flPerCod VARCHAR(6)
DECLARE @flCtrCod INT
DECLARE @flVersion SMALLINT
DECLARE @linea INT

--Escalado máximo
DECLARE @fclLecActFec AS DATE
DECLARE @fclServicio SMALLINT
DECLARE @fclTrfCod SMALLINT
DECLARE @trvCuota MONEY
DECLARE @trvprecio1 decimal(10,6)
DECLARE @trvprecio2 decimal(10,6)
DECLARE @trvprecio3 decimal(10,6)
DECLARE @trvprecio4 decimal(10,6)
DECLARE @trvprecio5 decimal(10,6)
DECLARE @trvprecio6 decimal(10,6)
DECLARE @trvprecio7 decimal(10,6)
DECLARE @trvprecio8 decimal(10,6)
DECLARE @trvprecio9 decimal(10,6)
DECLARE @escalado1 INT
DECLARE @escalado2 INT
DECLARE @escalado3 INT
DECLARE @escalado4 INT
DECLARE @escalado5 INT
DECLARE @escalado6 INT
DECLARE @escalado7 INT
DECLARE @escalado8 INT
DECLARE @escalado9 INT
DECLARE @trfAplicarEscMax BIT

--Escalado minimo
DECLARE @tramo1_escala INT;
DECLARE @tramo1_uds INT;
DECLARE @trfAplicarEscMin BIT;
DECLARE @fclAplicarEscMin BIT;
DECLARE @servicioAgua INT;
DECLARE @MAXESCALA INT = 999999999;

--Canon fijo AVG
DECLARE @FactorFechasLecturas DECIMAL(18,10)
DECLARE @facLecLectorFec AS DATE
DECLARE @fclLecAntFec AS DATE

--Precision
DECLARE @facePrecision INT; --FacE: Precisión del redondeo (facE: 2, default:4)
DECLARE @basePrecision INT; --Base: Precisión del redondeo (Base: 2, default:4)

DECLARE @trfMultiplicarConsumo BIT
DECLARE @explotacion AS VARCHAR(50) = NULL
DECLARE @editarSrv AS VARCHAR(200) = 'False'
DECLARE @fecLin2Dec DATE = DATEADD(YEAR, 10, GETDATE());

--**********************************
SELECT @editarSrv = ISNULL(pgsvalor, '') FROM dbo.parametros WHERE pgsclave = 'EDITAR_FACLIN';
SELECT @explotacion  = CAST(ISNULL(pgsvalor,'') AS VARCHAR) FROM dbo.parametros WHERE pgsclave = 'EXPLOTACION';
SELECT @servicioAgua = CAST(ISNULL(pgsvalor,'1') AS INT)	FROM dbo.parametros WHERE pgsclave = 'SERVICIO_AGUA';

--**********************************
--Partiendo de esta fecha se dejarán a 4 decimales únicamente los precios
--Redondeamos la BASE a 2 decimales, sobre esta base calculamos el importe del impuesto y el total
SELECT @fecLin2Dec = P.pgsvalor FROM dbo.parametros AS P WHERE P.pgsclave='LINEAS_2DECIMALES';

--**********************************
--Para servicios que se repiten en una misma factura: 
--Se hace una distribución del consumo de manera proporcional a los días que cubren sus tarifas
DECLARE @consumoxLinea INT;
DECLARE @DESGLOSECONSUMOS AS TABLE( 
  dcFacCod INT
, dcFacPerCod VARCHAR(6)
, dcFacCtrCod	INT
, dcFacVersion INT	
, dcFclNumLinea INT	
, svcTipo VARCHAR(1)
, dcFclTrfSvCod INT	
, dcFclTrfCod INT	
, dcTrvfecha	DATE
, dcTrvfechafin DATE
, dcTrvCuota DECIMAL(10, 4)
, diasEntreLecturas INT
, diasxLinea INT
, consumoxLinea INT
, tarifasxLinea INT);
	
INSERT INTO @DESGLOSECONSUMOS
EXEC Facturas_DesglosarConsumosxFactura @facturas;

--****** L O G **********
--Es la misma select del cursor para totalizar los registros a ser procesados
WITH DATOS AS(
SELECT FL.fclFacCtrCod, FL.fclFacPerCod, FL.fclFacVersion, FL.fclFacCod, Lineas = COUNT(FL.fclNumLinea)
FROM dbo.faclin AS FL 
INNER JOIN @facturas AS PK
	ON  FL.fclFacCtrCod = PK.facCtrcod
	AND FL.fclFacPerCod = PK.facPerCod
LEFT JOIN tarifas AS T
	ON T.[trfsrvcod] = FL.[fclTrfSvCod] AND T.[trfcod] = FL.[fclTrfCod]
LEFT JOIN @DESGLOSECONSUMOS AS D
	ON  D.dcFacCod = FL.fclFacCod
	AND D.dcFacPerCod = FL.fclFacPerCod
	AND D.dcFacCtrCod = FL.fclFacCtrCod
	AND D.dcFacVersion = FL.fclFacVersion
	AND D.dcFclNumLinea = FL.fclNumLinea
	AND D.dcFclTrfSvCod = FL.fclTrfSvCod
	AND D.dcFclTrfCod = FL.fclTrfCod
WHERE (FL.fclEscala1 > 0 OR FL.fclEscala2 > 0)
GROUP BY FL.fclFacCtrCod, FL.fclFacPerCod, FL.fclFacVersion, FL.fclFacCod)

SELECT @countF = COUNT(fclFacCtrCod) 
, @countFL = SUM(Lineas)
FROM DATOS;

SET @msgParams = FORMATMESSAGE('%s, #FacturasCursor=%i, #LineasCursor=%i', @msgParams, @countF, @countFL);
--......................


--**********************************
--Busco las lineas de factura con escalado
DECLARE curFacLin CURSOR FOR
	
	SELECT fclFacCod, fclFacPerCod, fclFacCtrCod, fclFacVersion, fclNumLinea, fclUnidades, fclPrecio, fclImpuesto
	, fclEscala1,fclEscala2,fclEscala3,fclEscala4,fclEscala5,fclEscala6,fclEscala7,fclEscala8,fclEscala9
	, fclPrecio1,fclPrecio2,fclPrecio3,fclPrecio4,fclPrecio5,fclPrecio6,fclPrecio7,fclPrecio8,fclPrecio9,ISNULL(F.facConsumoFactura,0)
	, fclUnidades1,fclUnidades2,fclUnidades3,fclUnidades4,fclUnidades5,fclUnidades6,fclUnidades7,fclUnidades8,fclUnidades9
	, F.[facLecLectorFec]
	, F.[facLecAntFec]
	, F.[facLecActFec]
	, FL.[fclTrfSvCod]
	, FL.[fclTrfCod]
	, T.[trfAplicarEscMax] --Escalado máximo
	, T.[trfAplicarEscMin] --Escalado mínimo
	, D.[consumoxLinea]	   --Consumo aplicable a lineas que se desglosan
	, [facePrecision] = IIF(C.ctrFace=1, 2, 4) 					--FacE: Precisión del redondeo (facE: 2, default:4)
	, [basePrecision] = IIF(F.facFecReg>= @fecLin2Dec, 2, 4)    --Base: Precisión del redondeo (Base: 2, default:4)
	FROM dbo.faclin AS FL 
	INNER JOIN facturas AS F 
		ON FL.fclFacCod=F.facCod AND 
		FL.fclFacPerCod=F.facPerCod AND 
		FL.fclFacCtrCod=F.facCtrCod AND 
		FL.fclFacVersion=F.facVersion
	INNER JOIN @facturas AS PK
		ON  F.facCtrCod = PK.facCtrcod
		AND F.facPerCod = PK.facPerCod
	INNER JOIN contratos AS C
		ON C.ctrcod = F.facCtrCod
		AND C.ctrversion = F.facCtrVersion
	LEFT JOIN tarifas AS T
		ON T.[trfsrvcod] = FL.[fclTrfSvCod] AND T.[trfcod] = FL.[fclTrfCod]
	--**********************************
	LEFT JOIN @DESGLOSECONSUMOS AS D
		ON  D.dcFacCod = F.facCod
		AND D.dcFacPerCod = F.facPerCod
		AND D.dcFacCtrCod = F.facCtrCod
		AND D.dcFacVersion = F.facVersion
		AND D.dcFclNumLinea = FL.fclNumLinea
		AND D.dcFclTrfSvCod = FL.fclTrfSvCod
		AND D.dcFclTrfCod = FL.fclTrfCod
	WHERE (FL.fclEscala1 > 0 OR FL.fclEscala2 > 0) -- por el tema del cambio de tarifa a mitad de periodo de Guadalajara pueden darse casos con el escalado 1 a 0
	ORDER BY F.facPerCod, F.facCtrCod, F.facVersion, fclNumLinea 
	
OPEN curFacLin

FETCH NEXT FROM curFacLin	
INTO @flFacCod,@flPerCod,@flCtrCod,@flVersion,@linea,@flUds,@flPrecio,@porcImp
, @escala1, @escala2, @escala3, @escala4, @escala5, @escala6, @escala7, @escala8, @escala9
, @precio1, @precio2, @precio3, @precio4, @precio5, @precio6, @precio7, @precio8, @precio9
, @consumoFact,@uds1,@uds2,@uds3,@uds4,@uds5,@uds6,@uds7,@uds8,@uds9
, @facLecLectorFec , @fclLecAntFec,@fclLecActFec, @fclServicio, @fclTrfCod
, @trfAplicarEscMax --Escalado máximo
, @trfAplicarEscMin --Escalado mínimo
, @consumoxLinea	--Consumo aplicable a lineas que se desglosan
, @facePrecision	--FacE: Precisión del redondeo (FacE: 2, default:4)
, @basePrecision	--Base: Precisión del redondeo (Base: 2, default:4)
WHILE @@FETCH_STATUS = 0
BEGIN
	
	--MultiplicarConsumo
	--BIAR => 2: CANON DE SANEO
	SET @trfMultiplicarConsumo = IIF(@explotacion='BIAR' AND @fclServicio=2, 1, 0);

	DECLARE @consumoRepartir INT
	SET @consumoRepartir = ISNULL(@consumoxLinea, @consumoFact);

	--Caso en el cual se edita el consumo de la cabecera se debe trasladar a las líneas siempre
	--Con esto obligamos a que solo entre aquí si se modifica el consumo en las líneas y NO en la cabecera
	IF (@flVersion > 1 AND @consumoFact=(SELECT ISNULL(facConsumoFactura,0) FROM facturas WHERE facCod=@flFacCod AND facPerCod=@flPerCod AND facCtrCod=@flCtrCod AND facVersion=(@flVersion-1)))
	BEGIN
		DECLARE @consumoLinea INT = CAST(@uds1 + @uds2 + @uds3 + @uds4 + @uds5 + @uds6 + @uds7 + @uds8 + @uds9 AS INT)
		--Si está habilitado el parámetro para editar los consumos y escalados de las líneas de factura-->condicionamos el consumo de la línea 
		--para que si se ha modificado no se machaque y lo mantenga en la rectificativa
		IF (@editarSrv = 'True' AND @consumoFact <> @consumoLinea)
			SET @consumoRepartir = @consumoLinea
	END
	
	IF (@trfMultiplicarConsumo = 1) 
	BEGIN
		--Todo el consumo se debe ir al primer escalado
		SET @escala1 = 999999999;

		--Omitimos las siguientes escalas
		SET @escala2 = 0; SET @precio2 = 0; 
		SET @escala3 = 0; SET @precio3 = 0; 
		SET @escala4 = 0; SET @precio4 = 0; 
		SET @escala5 = 0; SET @precio5 = 0;
		SET @escala6 = 0; SET @precio6 = 0;
		SET @escala7 = 0; SET @precio7 = 0;
		SET @escala8 = 0; SET @precio8 = 0;
		SET @escala9 = 0; SET @precio9 = 0;

		--Actualizamos la linea de la factura
		UPDATE faclin 
		SET fclEscala1 = @escala1, fclEscala2 = @escala2, fclEscala3 = @escala3, fclEscala4 = @escala4, fclEscala5 = @escala5, fclEscala6 = @escala6, fclEscala7 = @escala7, fclEscala8 = @escala8, fclEscala9 = @escala9
		  , fclPrecio1 = @precio1, fclPrecio2 = @precio2, fclPrecio3 = @precio3, fclPrecio4 = @precio4, fclPrecio5 = @precio5, fclPrecio6 = @precio6, fclPrecio7 = @precio7, fclPrecio8 = @precio8, fclPrecio9 = @precio9
		  , fclPrecio =  @flPrecio
		WHERE [fclFacCod]=@flFacCod 
		  AND [fclFacPerCod] = @flPerCod 
		  AND [fclFacCtrCod] = @flCtrCod 
		  AND [fclFacVersion] = @flVersion 
		  AND [fclNumLinea] = @linea;
	
	END 
	
	--Escalado máximo
	IF (@trfAplicarEscMax = 1) 
	BEGIN
		SET @escala1 = 999999999;
		SET @escala2 = 0;
		SET @escala3 = 0;
		SET @escala4 = 0;
		SET @escala5 = 0;
		SET @escala6 = 0;
		SET @escala7 = 0;
		SET @escala8 = 0;
		SET @escala9 = 0;

		--Obtener la cuota del servicio con escalado máximo
		SELECT @trvCuota = TV.trvcuota
			 , @trvprecio1 = TV.trvprecio1
			 , @trvprecio2 = TV.trvprecio2
			 , @trvprecio3 = TV.trvprecio3
			 , @trvprecio4 = TV.trvprecio4
			 , @trvprecio5 = TV.trvprecio5
			 , @trvprecio6 = TV.trvprecio6
			 , @trvprecio7 = TV.trvprecio7
			 , @trvprecio8 = TV.trvprecio8
			 , @trvprecio9 = TV.trvprecio9
			 , @escalado1 = T.trfescala1
			 , @escalado2 = T.trfescala2
			 , @escalado3 = T.trfescala3
			 , @escalado4 = T.trfescala4
			 , @escalado5 = T.trfescala5
			 , @escalado6 = T.trfescala6
			 , @escalado7 = T.trfescala7
			 , @escalado8 = T.trfescala8
			 , @escalado9 = T.trfescala9
		FROM tarval AS TV
		INNER JOIN tarifas AS T
			ON T.trfcod = TV.trvtrfcod AND T.trfsrvcod = TV.trvsrvcod
		WHERE TV.trvsrvcod = @fclServicio 
		AND TV.trvtrfcod = @fclTrfCod
		AND CAST(TV.trvfecha AS DATE) <= @fclLecActFec
		AND (TV.trvfechafin IS NULL OR CAST(TV.trvfechafin AS DATE) >= @fclLecActFec)
		--

		SET @flPrecio = CASE WHEN(@consumoRepartir<=@escalado1) THEN 0.00 ELSE @trvCuota END;
		SET @precio1 =  CASE WHEN(@consumoRepartir<=@escalado1) THEN @trvprecio1 ELSE @trvprecio2 END;
		--SET @precio1 = CASE WHEN(@consumoRepartir<=35) THEN 0.15 ELSE 0.50 END;

		IF (@explotacion = 'Ribadesella' AND @fclServicio = 7 AND @fclTrfCod = 3)
		BEGIN		
			SET @flPrecio = @trvCuota;
			--el precio1 vendrá determinado por el precio de la escala donde se encuentre
			SET @precio1 =  
				CASE 
					WHEN @consumoRepartir<=@escalado1 THEN @trvprecio1
					WHEN @consumoRepartir<=@escalado2 THEN @trvprecio2
					WHEN @consumoRepartir<=@escalado3 THEN @trvprecio3
					WHEN @consumoRepartir<=@escalado4 THEN @trvprecio4
					WHEN @consumoRepartir<=@escalado5 THEN @trvprecio5
					WHEN @consumoRepartir<=@escalado6 THEN @trvprecio6
					WHEN @consumoRepartir<=@escalado7 THEN @trvprecio7
					WHEN @consumoRepartir<=@escalado8 THEN @trvprecio8
					WHEN @consumoRepartir<=@escalado9 THEN @trvprecio9
				END
		END

		SET @precio2 = 0; 
		SET @precio3 = 0; 
		SET @precio4 = 0; 
		SET @precio5 = 0;
		SET @precio6 = 0; 
		SET @precio7 = 0; 
		SET @precio8 = 0; 
		SET @precio9 = 0;

		--Actualizamos la linea de la factura
		UPDATE faclin 
		SET fclEscala1 = @escala1, fclEscala2 = @escala2, fclEscala3 = @escala3, fclEscala4 = @escala4, fclEscala5 = @escala5, fclEscala6 = @escala6, fclEscala7 = @escala7, fclEscala8 = @escala8, fclEscala9 = @escala9
		  , fclPrecio1 = @precio1, fclPrecio2 = @precio2, fclPrecio3 = @precio3, fclPrecio4 = @precio4, fclPrecio5 = @precio5, fclPrecio6 = @precio6, fclPrecio7 = @precio7, fclPrecio8 = @precio8, fclPrecio9 = @precio9
		  , fclPrecio =  @flPrecio
		WHERE [fclFacCod]=@flFacCod 
		  AND [fclFacPerCod] = @flPerCod 
		  AND [fclFacCtrCod] = @flCtrCod 
		  AND [fclFacVersion] = @flVersion 
		  AND [fclNumLinea] = @linea;
	END 
	
	--CASO CANON FIJO AVG
	IF 'AVG' = @explotacion AND @fclServicio = 19 BEGIN			
		set  @consumoRepartir  = (SELECT [dbo].[FactorMesesEntreLecturas] (@fclLecAntFec, isnull( @facLecLectorFec,@fclLecActFec) ) )		
				--print @fclLecAntFec
				--print 		@facLecLectorFec
				--print @consumoRepartir 			
	END
	--CASO CANON Variable AVG se redondea en funcion de las fechas 
	IF 'AVG' = @explotacion AND (@fclServicio = 20) BEGIN	
	    SET  @FactorFechasLecturas = (SELECT [dbo].[FactorMesesEntreLecturas] (@fclLecAntFec,isnull( @facLecLectorFec,@fclLecActFec) ))
	    SET  @escala1  = ROUND( ( @FactorFechasLecturas *@escala1 /3),0)							
		SET  @escala2  = ROUND(  (@FactorFechasLecturas*@escala2 /3)	,0)
		SET  @escala3  = ROUND(  (@FactorFechasLecturas*@escala3 /3),0)
		
	END
	
		
	--Repartimos consumo
	EXEC Facturas_RepartirConsumo @consumoRepartir, @escala1, @escala2, @escala3, @escala4, @escala5, @escala6, @escala7, @escala8, @escala9, @uds1 OUT, @uds2 OUT, @uds3 OUT, @uds4 OUT, @uds5 OUT, @uds6 OUT, @uds7 OUT, @uds8 OUT, @uds9 OUT 

	--****************************
	--Calculamos el la base
	DECLARE @base DECIMAL(16,4)

	--***************
	--Escalado Mínimo: @tramo1_escala
	--Obtener la el valor de la primera escala en la tarifa
	--La escala debe multiplicarse por las unidades cuando está configurada asi la tarifa
	SELECT @tramo1_escala = 
	CASE T.trfescala1 --Controlamos que el escalado no sea el máximo configurable evitamos overflow de la variable INT
	WHEN @MAXESCALA THEN @MAXESCALA
	ELSE T.trfescala1 * IIF(T.trfUdsPorEsc = 0, 1, @flUds) END
	FROM tarval AS TV
	INNER JOIN tarifas AS T
	ON  T.trfcod = TV.trvtrfcod 
	AND T.trfsrvcod = TV.trvsrvcod
	WHERE TV.trvsrvcod = @fclServicio 
	AND TV.trvtrfcod = @fclTrfCod
	AND CAST(TV.trvfecha AS DATE) <= @fclLecActFec
	AND (TV.trvfechafin IS NULL OR CAST(TV.trvfechafin AS DATE) >= @fclLecActFec);

	--Si el consumo está dentro del primer tramo y la tarifa es de escalado minimo => 2 pasos 
	SET @fclAplicarEscMin = IIF(@trfAplicarEscMin = 1 AND @consumoRepartir<=@tramo1_escala, 1, 0);

	--La base se calcula con el consumo máximo para la primera escala.
	SET @tramo1_uds=IIF(@fclAplicarEscMin = 1, @tramo1_escala, @uds1);
	--***************
	
	SET @base= ROUND(@flUds * @flPrecio, @facePrecision) + 
			   ROUND(@tramo1_uds * @precio1, @facePrecision) + 
			   ROUND(@uds2 * @precio2, @facePrecision) + 
			   ROUND(@uds3 * @precio3, @facePrecision) + 
			   ROUND(@uds4 * @precio4, @facePrecision) + 
			   ROUND(@uds5 * @precio5, @facePrecision) + 
			   ROUND(@uds6 * @precio6, @facePrecision) + 
			   ROUND(@uds7 * @precio7, @facePrecision) + 
			   ROUND(@uds8 * @precio8, @facePrecision) + 
			   ROUND(@uds9 * @precio9, @facePrecision)
	
	--(19)CANON FIJO AVG 
	IF (@explotacion='AVG') AND (@fclServicio = 19) 
	BEGIN		
	    SET @uds1  = (SELECT [dbo].[FactorMesesEntreLecturas] (@fclLecAntFec, ISNULL(@facLecLectorFec, @fclLecActFec)));		
		SET @base= ROUND(@flUds * @precio1 * @uds1 , @facePrecision); 	
	END

	IF (@trfMultiplicarConsumo = 1)
	BEGIN
	--El calculo de la base será diferente: fclUnidades * Consumo:
	SET @base=  ROUND(@flUds * @flPrecio, @facePrecision) +			--Cuota
				ROUND(@flUds * @precio1 * @uds1 , @facePrecision);  --Consumo
	END

	--Calculamos el impuesto (base + ImporteImpuesto)
	DECLARE @impImpuesto DECIMAL(16,4)--Importe del impuesto
	SET @impImpuesto = ROUND(@base*@porcImp*0.01, 4)

	--Bajamos la precisión en los totales si es necesario...
	--Ocurre cuando no se trata de una factura electrónica
	IF(@facePrecision > @basePrecision)
	BEGIN
		SET @base = ROUND(@base, @basePrecision);
		SET @impImpuesto = ROUND(@base*@porcImp*0.01, 4);
	END
	
	--Actualizamos la linea
	UPDATE faclin SET 
	   [fclUnidades1] = @uds1
	  ,[fclUnidades2] = @uds2
	  ,[fclUnidades3] = @uds3
	  ,[fclUnidades4] = @uds4
	  ,[fclUnidades5] = @uds5
	  ,[fclUnidades6] = @uds6
	  ,[fclUnidades7] = @uds7
	  ,[fclUnidades8] = @uds8
	  ,[fclUnidades9] = @uds9

	  ,[fcltotal] = @base + @impImpuesto
	  ,[fclBase]= @base 
	  ,[fclImpImpuesto] = @impImpuesto 
	WHERE [fclFacCod]=@flFacCod and [fclFacPerCod] = @flPerCod and [fclFacCtrCod] = @flCtrCod and [fclFacVersion] = @flVersion and [fclNumLinea] = @linea;

	SET @myError = @@ERROR IF @myError <> 0 GOTO ERRORES
	
	--Si la línea tiene desglose...
	IF EXISTS (SELECT fldNumDesglose 
			   FROM faclinDesglose 
			   WHERE fldFacPerCod = @flPerCod AND fldFacCtrCod = @flCtrCod AND
					 fldFacVersion = @flVersion AND fldFacCod = @flFacCod AND
					 fldNumLinea = @linea)
	--o se lanzó el proceso de desglose sobre esa factura, tenemos que actualizar dicho desglose
	OR EXISTS (SELECT facCod 
			   FROM facturas 
			   INNER JOIN perzona ON przcodper = facPerCod AND przcodzon = facZonCod
			   WHERE przFecPrimerDesglose IS NOT NULL AND --Condición
			         facPerCod = @flPerCod AND facCtrCod = @flCtrCod AND facVersion = @flVersion AND facCod = @flFacCod --Enlace
	) BEGIN
		EXEC @myError = Tasks_Facturas_GenerarDesgloseLineas @flPerCod, NULL, @flCtrCod, @flVersion, @flFacCod, @linea
		IF @myError <> 0 GOTO ERRORES
	END
	
	SET @count= @count+ 1;
	FETCH NEXT FROM curFacLin
	INTO @flFacCod, @flPerCod, @flCtrCod, @flVersion, @linea ,@flUds , @flPrecio, @porcImp
	, @escala1,@escala2,@escala3,@escala4,@escala5,@escala6,@escala7,@escala8,@escala9
	, @precio1,@precio2,@precio3,@precio4,@precio5,@precio6,@precio7,@precio8,@precio9
	, @consumoFact,@uds1,@uds2,@uds3,@uds4,@uds5,@uds6,@uds7,@uds8,@uds9
	, @facLecLectorFec , @fclLecAntFec, @fclLecActFec, @fclServicio, @fclTrfCod
	, @trfAplicarEscMax --Escalado máximo
	, @trfAplicarEscMin --Escalado mínimo
	, @consumoxLinea	--Consumo aplicable a lineas que se desglosan
	, @facePrecision	--FacE: Precisión del redondeo (FacE: 2, default:4)
	, @basePrecision	--Base: Precisión del redondeo (Base: 2, default:4)
END
CLOSE curFacLin
DEALLOCATE curFacLin



IF @TRANCOUNT = 0  COMMIT TRANSACTION T;

--****** L O G **********
SET @spMessage = FORMATMESSAGE('#LineasProcesadas=%i=> Tiempo Ejecución: %s seg.', @count, FORMAT(DATEDIFF(SECOND, @starttime, GETDATE()), 'N0', 'es-ES')); 
EXEC Trabajo.errorLog_Insert  @spName=@spName, @spMessage=@spMessage, @spParams=@msgParams;
--......................	

RETURN 0;

ERRORES:
	CLOSE curFacLin
	DEALLOCATE curFacLin
	 
	--****** L O G **********
	SET @spMessage = FORMATMESSAGE('#LineasProcesadas=%i>FINALIZADO CON ERROR', @msgParams, @count); 
	EXEC Trabajo.errorLog_Insert  @spName=@spName, @spMessage=@spMessage, @spParams=@msgParams;
	--......................
	
	--print @myError
	ROLLBACK TRANSACTION T
	RETURN @myError





GO


