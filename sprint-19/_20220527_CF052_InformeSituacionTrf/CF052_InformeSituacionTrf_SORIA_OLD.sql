/*
DECLARE @cvFecIni DATE = '20180101';
DECLARE @cvFecFin DATE = '20220228';
DECLARE @periodoD VARCHAR(6) = '201808';
DECLARE @periodoH VARCHAR(6) = '201808';
DECLARE @filtrar INT = 1;
DECLARE @xmlSerCodArray VARCHAR(MAX) = '';


SELECT @xmlSerCodArray = CONCAT(@xmlSerCodArray, '<servicioCodigo><value>') + CAST(svccod AS VARCHAR(5))+ '</value></servicioCodigo>'
FROM dbo.servicios
WHERE svccod NOT IN  (3, 99, 100 , 103, 104, 105, 106, 107);


SET @xmlSerCodArray = FORMATMESSAGE('<servicioCodigo_List>%s</servicioCodigo_List>', @xmlSerCodArray)

EXEC [ReportingServices].[CF052_InformeSituacionTrf_SORIA] @cvFecIni, @cvFecFin, @periodoD, @periodoH, @filtrar, @xmlSerCodArray 
*/

ALTER PROCEDURE [ReportingServices].[CF052_InformeSituacionTrf_SORIA_OLD]
(
	@cvFecIni DATE = NULL,
	@cvFecFin DATE = NULL,
	@periodoD varchar(6) = NULL,
	@periodoH varchar(6) = NULL,
	@filtrar int = 0,
	@xmlSerCodArray TEXT = NULL
)
AS

	SET NOCOUNT OFF;
	
-- TODO: RECORDATORIO, SI SE INSERTA UN NUEVO SERVICIO HAY QUE MIRAR LOS PROCEDIMIENTOS ALMACENADOS PARA PONER EL CB AL NUEVO SERVICIO


--***** P A R A M E T R O S *****
SELECT @cvFecIni = ISNULL(@cvFecIni, '19010101')
	 , @cvFecFin = DATEADD(DAY, 1, ISNULL(@cvFecFin, GETDATE()));

--SELECT @cvFecIni, @cvFecFin;

--******************************
--Periodos que debemos omitir si existe PERIODO_INICIO
--Todos los periodos de consumo en el rango [@PERIODO_INICIO, @PERIODO_FIN]
DECLARE @OMITIR_INICIO VARCHAR(6) = NULL;
DECLARE @OMITIR_FIN VARCHAR(6) = NULL;

--Minimo periodo de consumo por defecto
SELECT @OMITIR_INICIO = MIN(P.percod) 
FROM dbo.periodos AS P 
WHERE P.percod  NOT LIKE '0000%'

--Periodo por configuración
SELECT @OMITIR_FIN = P.pgsValor
FROM dbo.parametros AS P
WHERE P.pgsClave = 'PERIODO_INICIO';

SELECT @OMITIR_FIN = ISNULL(@OMITIR_FIN, @OMITIR_INICIO);

--@OMITIR_FIN este periodo debe incluirse
--SELECT [@OMITIR_INICIO]= @OMITIR_INICIO, [@OMITIR_FIN]=@OMITIR_FIN;
--*******************************

DECLARE @filtro VARCHAR(10)= null 
DECLARE @filtro2 VARCHAR(50)= null 

--NEW MARINA
--Creamos una tabla en memoria donde se van a insertar todos los valores
DECLARE @serviciosExcluidos AS TABLE(servicioCodigo SMALLINT) 

DECLARE @idoc INT

IF @xmlSerCodArray IS NOT NULL 
BEGIN
	--Leemos los parámetros del XML
	SET @idoc = NULL
	EXEC sp_xml_preparedocument @idoc OUTPUT, @xmlSerCodArray
	--Insertamos en tabla temporal
	INSERT INTO @serviciosExcluidos(servicioCodigo)
	SELECT value
	FROM   OPENXML (@idoc, '/servicioCodigo_List/servicioCodigo', 2) WITH (value SMALLINT)
	--Liberamos memoria
	EXEC  sp_xml_removedocument @idoc
END
--END NEW MARINA


DECLARE @tablaAuxiliar as 
		TABLE (
		periodo varchar(6),
		periodoRegistrado varchar(6),
		zona varchar(4),
		servicio int ,
		tarifa int,
		desTarifa varchar(60),
		ppago int,
		tipImpuesto int,
		desServicio varchar(60),
		facnFacturas int,
		facCargoFijo money,
		facConsumo money,
		facBase money,
		facImpuesto money,
		facTotal money,

		anunFacturas int,
		anuCargoFijo money,
		anuConsumo money,
		anuBase money,
		anuImpuesto money,
		anuTotal money,
		crenFacturas int,
		creCargoFijo money,
		creConsumo money,
		creBase money,
		creImpuesto money,
		creTotal money,

		nCobBanco int default 0,
		cobBanCargoFijo money default 0,
		cobBanConsumo money default 0,
		cobBanBase money default 0,
		cobBanImpuesto money default 0,
		cobBanTotal money default 0,
		nCobOficina int default 0,
		cobOfiCargoFijo money default 0,
		cobOfiConsumo money default 0,
		cobOfiBase money default 0,
		cobOfiImpuesto money default 0,
		cobOfiTotal money default 0,

		nDevBanco int default 0,
		devBanCargoFijo money default 0,
		devBanConsumo money default 0,
		devBanBase money default 0,
		devBanImpuesto money default 0,
		devBanTotal money default 0,
		nDevOficina int default 0,
		devOfiCargoFijo money default 0,
		devOfiConsumo money default 0,
		devOfiBase money default 0,
		devOfiImpuesto money default 0,
		devOfiTotal money default 0,

           
        primary key(periodo, periodoRegistrado, Zona, Servicio, Tarifa, ppago, tipImpuesto))
		
DECLARE @tablaInforme as 
		TABLE (
		bloqueId tinyint,
		bloqueNom varchar(60),
		
		periodo  varchar(6), 
		periodoRegistrado varchar(6),
		zona varchar(4),
		servTarifa int,
		desServTarifa varchar(60),
		
		facnFacturas int,
		facCargoFijo money,
		facConsumo money,
		facBase money,
		facImpuesto money,
		facTotal money,

		anunFacturas int,
		anuCargoFijo money,
		anuConsumo money,
		anuBase money,
		anuImpuesto money,
		anuTotal money,
		crenFacturas int,
		creCargoFijo money,
		creConsumo money,
		creBase money,
		creImpuesto money,
		creTotal money,

		nCobBanco int default 0,
		cobBanCargoFijo money default 0,
		cobBanConsumo money default 0,
		cobBanBase money default 0,
		cobBanImpuesto money default 0,
		cobBanTotal money default 0,
		nCobOficina int default 0,
		cobOfiCargoFijo money default 0,
		cobOfiConsumo money default 0,
		cobOfiBase money default 0,
		cobOfiImpuesto money default 0,
		cobOfiTotal money default 0,

		nDevBanco int default 0,
		devBanCargoFijo money default 0,
		devBanConsumo money default 0,
		devBanBase money default 0,
		devBanImpuesto money default 0,
		devBanTotal money default 0,
		nDevOficina int default 0,
		devOfiCargoFijo money default 0,
		devOfiConsumo money default 0,
		devOfiBase money default 0,
		devOfiImpuesto money default 0,
		devOfiTotal money default 0)	
		

 DECLARE @sociedad as smallint	
 DECLARE @facVersion as SMALLINT	
 DECLARE @lineaCobro as SMALLINT	
 DECLARE @cobNum as int        
 DECLARE @periodo as varchar(6)
 DECLARE @periodoRegistrado as varchar(6)
 DECLARE @Zona as varchar(4)
 DECLARE @Servicio as int
 DECLARE @Tarifa as int
 DECLARE @ppago as int
 DECLARE @tipImpuesto as int
 DECLARE @DesServicio as varchar(60)
 DECLARE @DesTarifa as varchar(60)
 DECLARE @nFacturas as int
 DECLARE @CargoFijo as money
 DECLARE @Consumo as money
 DECLARE @Base as money
 DECLARE @Impuesto as money
 DECLARE @Total as money
 DECLARE @CobLinDesTotal as money
 DECLARE @TotalLinea as money
 DECLARE @cobrado as money
 DECLARE @facturado as money
 DECLARE @facturadoAnt as money
 DECLARE @tipo as int
 DECLARE @contrato as int
 DECLARE @fecCob as datetime
 DECLARE @version as int
 DECLARE @codigo as smallint
 DECLARE @totalServicios as int = 0
 DECLARE @totalServiciosAnt as int = 0
 DECLARE @servicioBorrado AS SMALLINT = 0

DECLARE @explotacion varchar(100) = NULL
SELECT @explotacion = pgsValor FROM parametros WHERE pgsClave = 'EXPLOTACION'

DECLARE @servicioFianza INT = NULL
IF 'Soria' <> @explotacion BEGIN
	 SELECT @servicioFianza = pgsValor FROM parametros WHERE pgsClave='SERVICIO_FIANZA'
END


--*************************************
-- ORIGINALES: facVersion = 1
-- En dos pasos [1]Las del 000002 
--				[2]periodos del consumo
--*************************************

--[01]Insertamos Bajas-> Periodo='000002'
INSERT INTO @tablaAuxiliar(periodo, zona, servicio, tarifa, ppago, tipImpuesto, desServicio, desTarifa, facnFacturas,facCargoFijo,facConsumo,facBase,facImpuesto,facTotal, periodoRegistrado)
SELECT
	"Periodo", faczoncod, "Servicio", fcltrfcod, SUM(ppag), fclImpuesto, "Des. Servicio", "Des. Tarifa", 
	SUM("N. Facturas"), SUM("Cargo Fijo"), SUM("Consumo"),	SUM("Base"), SUM("Impuesto"), SUM("Total"), ISNULL(periodoRegistrado,'')
FROM
(
	SELECT fclfacpercod AS "Periodo", f1.faczoncod, fcltrfsvcod AS "Servicio", fcltrfcod, 0 AS ppag, fclImpuesto, svcdes AS "Des. Servicio", trfdes AS "Des. Tarifa",
		COUNT(*) AS "N. Facturas",
		CAST(SUM(ROUND(fclunidades*fclprecio, 4)) as decimal(12,4)) as "Cargo Fijo",
		CAST(SUM(ROUND(fclunidades1*fclprecio1, 4) + ROUND(fclunidades2*fclprecio2, 4) + ROUND(fclunidades3*fclprecio3, 4) + ROUND(fclunidades4*fclprecio4, 4) + ROUND(fclunidades5*fclprecio5, 4)) AS DECIMAL(12,4)) AS "Consumo",
		SUM(fclbase) AS "Base",
		SUM(fclimpimpuesto) AS "Impuesto",
		SUM(fcltotal) AS "Total",
		(CASE WHEN fclfacpercod='000002' AND month(f1.facfecha)<=4 THEN convert( VARCHAR, year (f1.facfecha)) ++ '04'
			  WHEN fclfacpercod='000002' AND month(f1.facfecha)> 4 and month(f1.facfecha)<= 8 THEN  convert( VARCHAR, year (f1.facfecha)) ++ '08'
	          WHEN fclfacpercod='000002' AND month(f1.facfecha)> 8 THEN convert( VARCHAR, year (f1.facfecha) ) ++ '12'
	          WHEN (fclfacpercod<>'000002'  AND fclfacpercod LIKE '0%') 
			     THEN (SELECT TOP 1 przCodPer FROM perzona WHERE MONTH(przfPeriodoH) - MONTH(przfPeriodoD) + 1 = 1 AND f2.facFecha>=przfPeriodoD AND f2.facFecha<=przfPeriodoH) 
	     ELSE fclfacpercod END) AS periodoRegistrado
	FROM dbo.faclin AS FL 
	INNER JOIN dbo.facturas AS F1 
	ON  FL.fclfaccod = F1.faccod 
	AND FL.fclfacpercod = F1.facpercod 
	AND FL.fclfacctrcod = F1.facctrcod 
	AND FL.fclfacversion = F1.facversion 
	AND F1.facpercod ='000002'
	AND F1.facversion = 1
	AND F1.facNumero IS NOT NULL
	AND F1.facFecha IS NOT NULL
	--********************
	AND F1.facFecha >=  @cvFecIni
	AND F1.facFecha <   @cvFecFin
	--********************
	INNER JOIN dbo.servicios AS S
	ON S.svccod = FL.fcltrfsvcod
	INNER JOIN dbo.tarifas AS T 
	ON  T.trfsrvcod = FL.fcltrfsvcod 
	AND T.trfCod = FL.fcltrfcod
	INNER JOIN dbo.facturas AS F2 
	ON F1.faccod = F2.faccod 
	AND F1.facpercod = F2.facpercod 
	AND F1.facctrcod = F2.facctrcod 
	AND F2.facversion = 1
	WHERE ((fclFecLiq IS NULL AND fclUsrLiq IS NULL) OR fclFecLiq>=@cvFecFin) 
	  AND (@servicioFianza IS NULL OR fclTrfSvCod <> @servicioFianza)
	--NEW MARINA
	AND (@xmlSerCodArray IS NULL OR (FL.fclTrfSvCod NOT IN (SELECT servicioCodigo FROM @serviciosExcluidos)))
	--END NEW
	GROUP BY fclfacpercod, f1.faczoncod, fcltrfsvcod, fcltrfcod, fclimpuesto, svcdes, trfdes, f2.facFecha, f1.facFecha
) AS tabla
GROUP BY "Periodo", faczoncod, "Servicio", fcltrfcod, fclimpuesto, "Des. Servicio", "Des. Tarifa", periodoRegistrado
ORDER BY "Periodo", faczoncod, "Servicio", fcltrfcod, fclimpuesto, "Des. Servicio", "Des. Tarifa";


--SELECT * FROM @tablaAuxiliar

--[02]Insertamos Bajas-> Periodo de consumo
 INSERT INTO @tablaAuxiliar (periodo, zona, servicio, tarifa, ppago, tipImpuesto, desServicio, desTarifa, facnFacturas,facCargoFijo,facConsumo,facBase,facImpuesto,facTotal, periodoRegistrado)
SELECT
	"Periodo", faczoncod, "Servicio", fcltrfcod, SUM(ppag), fclImpuesto, "Des. Servicio", "Des. Tarifa", 
	SUM("N. Facturas"), SUM("Cargo Fijo"), SUM("Consumo"),	SUM("Base"), SUM("Impuesto"), SUM("Total"), ISNULL(periodoRegistrado,'')
FROM
(
	SELECT fclfacpercod AS "Periodo", f1.faczoncod, fcltrfsvcod AS "Servicio", fcltrfcod, 0 AS ppag, fclImpuesto, svcdes AS "Des. Servicio", trfdes AS "Des. Tarifa",
		COUNT(*) AS "N. Facturas",
		CAST(SUM(ROUND(fclunidades*fclprecio, 4)) as decimal(12,4)) as "Cargo Fijo",
		CAST(SUM(ROUND(fclunidades1*fclprecio1, 4) + ROUND(fclunidades2*fclprecio2, 4) + ROUND(fclunidades3*fclprecio3, 4) + ROUND(fclunidades4*fclprecio4, 4) + ROUND(fclunidades5*fclprecio5, 4)) AS DECIMAL(12,4)) AS "Consumo",
		SUM(fclbase) AS "Base",
		SUM(fclimpimpuesto) AS "Impuesto",
		SUM(fcltotal) AS "Total",
		(CASE WHEN fclfacpercod='000002' AND month(f1.facfecha)<=4 THEN convert( VARCHAR, year (f1.facfecha)) ++ '04'
			  WHEN fclfacpercod='000002' AND month(f1.facfecha)> 4 and month(f1.facfecha)<= 8 THEN  convert( VARCHAR, year (f1.facfecha)) ++ '08'
	          WHEN fclfacpercod='000002' AND month(f1.facfecha)> 8 THEN convert( VARCHAR, year (f1.facfecha) ) ++ '12'
	          WHEN (fclfacpercod<>'000002'  AND fclfacpercod LIKE '0%') 
			       THEN (SELECT TOP 1 przCodPer FROM perzona WHERE MONTH(przfPeriodoH) - MONTH(przfPeriodoD) + 1 = 1 AND f2.facFecha>=przfPeriodoD AND f2.facFecha<=przfPeriodoH) 
	          ELSE fclfacpercod END) AS periodoRegistrado
	FROM dbo.faclin  AS FL
	INNER JOIN dbo.facturas AS F1 
	ON  FL.fclfaccod	= F1.faccod 
	AND FL.fclfacpercod = F1.facpercod 
	AND FL.fclfacctrcod = F1.facctrcod 
	AND FL.fclfacversion = F1.facversion
	AND F1.facPerCod <>'000002'
	AND F1.facVersion = 1
	AND F1.facNumero IS NOT NULL	
	AND F1.facFecha IS NOT NULL
	--********************
	AND F1.facFecha >=  @cvFecIni
	AND F1.facFecha <  @cvFecFin
	--****************
	--Rango de periodos
	AND (F1.facpercod < @OMITIR_INICIO OR F1.facpercod >= @OMITIR_FIN) --Rango de exclusión
	AND (@periodoD IS NULL OR f1.facpercod >= @periodoD OR F1.facpercod LIKE '0000%')			   
	AND (@periodoH IS NULL OR f1.facpercod <= @periodoH OR F1.facpercod LIKE '0000%')
	--********************
	INNER JOIN dbo.servicios AS S 
	ON S.svccod = FL.fcltrfsvcod
	INNER JOIN dbo.tarifas AS T 
	ON T.trfsrvcod = FL.fcltrfsvcod 
	AND T.trfCod = FL.fcltrfcod
	INNER JOIN dbo.facturas AS F2 
	ON  F1.faccod = F2.faccod 
	AND F1.facpercod = F2.facpercod 
	AND F1.facctrcod = F2.facctrcod 
	AND F2.facversion = 1
	WHERE ((FL.fclFecLiq IS NULL AND FL.fclUsrLiq IS NULL) OR fclFecLiq>=@cvFecFin) 
	  AND (@servicioFianza IS NULL OR fclTrfSvCod <> @servicioFianza)
	--NEW MARINA
	AND (@xmlSerCodArray IS NULL OR (FL.fclTrfSvCod NOT IN (SELECT servicioCodigo FROM @serviciosExcluidos)))
	--END NEW
	GROUP BY fclfacpercod, f1.faczoncod, fcltrfsvcod, fcltrfcod, fclimpuesto, svcdes, trfdes, f2.facFecha, f1.facFecha
) AS tabla
GROUP BY "Periodo", faczoncod, "Servicio", fcltrfcod, fclimpuesto, "Des. Servicio", "Des. Tarifa", periodoRegistrado
ORDER BY "Periodo", faczoncod, "Servicio", fcltrfcod, fclimpuesto, "Des. Servicio", "Des. Tarifa"




 SET @nFacturas = 0 
 SET @CargoFijo = 0 
 SET @Consumo = 0
 SET @Base = 0 
 SET @Impuesto = 0
 SET @Total = 0

 --*************************************
-- ANULADAS: facFechaRectif IS NOT NULL
--*************************************
    DECLARE cAnulado CURSOR FOR
    SELECT
		"Periodo", faczoncod, "Servicio", fcltrfcod, fclImpuesto, "Des. Servicio", "Des. Tarifa", 
		SUM("N. Facturas"), SUM("Cargo Fijo"), SUM("Consumo"),	SUM("Base"), SUM("Impuesto"), SUM("Total"), periodoRegistrado
	FROM
	(
		SELECT fclfacpercod AS "Periodo", f1.faczoncod, fcltrfsvcod AS "Servicio", fcltrfcod, fclImpuesto ,svcdes AS "Des. Servicio", trfdes AS "Des. Tarifa",
			COUNT(*) AS "N. Facturas",
			CAST(SUM(ROUND(fclunidades*fclprecio, 4)) AS DECIMAL(12,4)) AS "Cargo Fijo",
			CAST(SUM(ROUND(fclunidades1*fclprecio1, 4) + ROUND(fclunidades2*fclprecio2, 4) + ROUND(fclunidades3*fclprecio3, 4) + ROUND(fclunidades4*fclprecio4, 4) + ROUND(fclunidades5*fclprecio5, 4) ) AS DECIMAL(12,4)) AS "Consumo", 
			SUM(fclbase) AS "Base", 
			SUM(fclimpimpuesto) AS "Impuesto" ,
			SUM(fcltotal) AS "Total",
			--CASE WHEN fclfacpercod LIKE '0%' THEN (SELECT TOP 1 przCodPer FROM perzona WHERE MONTH(przfPeriodoH) - MONTH(przfPeriodoD) + 1 = 1 AND f2.facFecha>=przfPeriodoD AND f2.facFecha<=przfPeriodoH) ELSE fclfacpercod END AS periodoRegistrado
				(CASE WHEN fclfacpercod='000002' AND month(f1.facFechaRectif)<=4 THEN convert( VARCHAR, year (f1.facFechaRectif)) ++ '04'
			  WHEN fclfacpercod='000002' AND month(f1.facFechaRectif)> 4 and month(f1.facFechaRectif)<= 8 THEN  convert( VARCHAR, year (f1.facFechaRectif)) ++ '08'
	          WHEN fclfacpercod='000002' AND month(f1.facFechaRectif)> 8 THEN convert( VARCHAR, year (f1.facFechaRectif) ) ++ '12'
	          WHEN (fclfacpercod<>'000002'  AND fclfacpercod LIKE '0%') 
			       THEN (SELECT TOP 1 przCodPer FROM perzona WHERE MONTH(przfPeriodoH) - MONTH(przfPeriodoD) + 1 = 1 AND f2.facFecha>=przfPeriodoD AND f2.facFecha<=przfPeriodoH) 
	          ELSE fclfacpercod END) AS periodoRegistrado
		
		FROM dbo.faclin AS FL
		INNER JOIN dbo.facturas AS f1 
		ON  FL.fclfaccod	 = f1.faccod 
		AND FL.fclfacpercod  = f1.facpercod 
		AND FL.fclfacctrcod  = f1.facctrcod 
		AND FL.fclfacversion = f1.facversion 
		AND f1.facNumero IS NOT NULL
		AND f1.facFecha IS NOT NULL
		--****************
		--Rango de periodos
		AND (F1.facpercod < @OMITIR_INICIO OR F1.facpercod >= @OMITIR_FIN) --Rango de exclusión
		AND (@periodoD IS NULL OR f1.facpercod >= @periodoD OR F1.facpercod LIKE '0000%')			   
		AND (@periodoH IS NULL OR f1.facpercod <= @periodoH OR F1.facpercod LIKE '0000%')	
		--********************
		AND f1.facFechaRectif IS NOT NULL 
		AND f1.facFechaRectif >= @cvFecIni 
		AND f1.facFechaRectif <  @cvFecFin
		--****************	
		INNER JOIN dbo.servicios AS S 
		ON S.svccod = FL.fcltrfsvcod
		INNER JOIN dbo.tarifas AS T 
		ON  T.trfsrvcod = FL.fcltrfsvcod 
		AND T.trfCod = FL.fcltrfcod
		INNER JOIN facturas AS f2 
		ON  f1.faccod = f2.faccod 
		AND f1.facpercod = f2.facpercod 
		AND f1.facctrcod = f2.facctrcod 
		AND f2.facversion = 1
		
		WHERE ((fclFecLiq IS NULL AND fclUsrLiq IS NULL) OR (FL.fclFecLiq >= @cvFecFin)) 
		AND   (@servicioFianza IS NULL OR fclTrfSvCod <> @servicioFianza)
		--NEW MARINA
		AND (@xmlSerCodArray IS NULL OR FL.fclTrfSvCod NOT IN (SELECT servicioCodigo FROM @serviciosExcluidos))
		--END NEW
		GROUP BY fclfacpercod, f1.faczoncod, fcltrfsvcod, fcltrfcod, fclimpuesto, svcdes, trfdes, f2.facFecha, f1.facFechaRectif
	) AS tabla
	GROUP BY "Periodo", faczoncod, "Servicio", fcltrfcod, fclImpuesto, "Des. Servicio", "Des. Tarifa", periodoRegistrado
	ORDER BY "Periodo", faczoncod, "Servicio", fcltrfcod, fclImpuesto, "Des. Servicio", "Des. Tarifa"
    OPEN cAnulado
    FETCH NEXT FROM cAnulado
    INTO  @periodo, @Zona, @Servicio, @Tarifa, @tipImpuesto, @DesServicio, @DesTarifa, @nFacturas, @CargoFijo, @Consumo, @Base, @Impuesto, @Total, @periodoRegistrado
    WHILE @@FETCH_STATUS = 0
    BEGIN

       UPDATE @tablaAuxiliar SET 
          anunFacturas = @nFacturas,
          anuCargoFijo = @CargoFijo,
          anuConsumo = @Consumo,
          anuBase = @Base,
          anuImpuesto = @Impuesto,
          anuTotal = @Total
       WHERE periodo = @periodo AND 
			 periodoRegistrado = ISNULL(@periodoRegistrado,'') AND
			 Zona = @Zona AND 
			 Servicio = @Servicio AND 
			 Tarifa = @Tarifa AND
			 tipImpuesto = @tipImpuesto AND
			 ppago = 0

    if @@ROWCOUNT = 0 
        INSERT INTO @tablaAuxiliar (periodo, periodoRegistrado, zona, servicio, tarifa, ppago, tipImpuesto, desServicio, desTarifa, anunFacturas,anuCargoFijo,anuConsumo,anuBase,anuImpuesto,anuTotal)
        VALUES (@periodo, ISNULL(@periodoRegistrado,''), @Zona, @Servicio, @Tarifa, 0, @tipImpuesto, @DesServicio, @DesTarifa, @nFacturas, @CargoFijo, @Consumo, @Base, @Impuesto, @Total)

        FETCH NEXT FROM cAnulado
        INTO  @periodo, @Zona, @Servicio, @Tarifa, @tipImpuesto, @DesServicio, @DesTarifa, @nFacturas, @CargoFijo, @Consumo, @Base, @Impuesto, @Total, @periodoRegistrado
    END

    CLOSE cAnulado
    DEALLOCATE cAnulado


 SET @nFacturas = 0 
 SET @CargoFijo = 0 
 SET @Consumo = 0
 SET @Base = 0 
 SET @Impuesto = 0
 SET @Total = 0

 
 --*************************************
-- CREADAS: facVersion > 1
--*************************************
    DECLARE cCreado CURSOR FOR
    SELECT
		"Periodo", faczoncod, "Servicio", fcltrfcod, fclImpuesto, "Des. Servicio", "Des. Tarifa", 
		SUM("N. Facturas"), SUM("Cargo Fijo"), SUM("Consumo"),	SUM("Base"), SUM("Impuesto"), SUM("Total"), periodoRegistrado
	FROM
	(
		SELECT fclfacpercod AS "Periodo", f1.faczoncod, fcltrfsvcod AS "Servicio", fcltrfcod, fclimpuesto, svcdes AS "Des. Servicio", trfdes AS "Des. Tarifa",
			count(*) as "N. Facturas",
			CAST(SUM(ROUND(fclunidades*fclprecio, 4)) AS DECIMAL(12,4)) AS "Cargo Fijo",
			CAST(SUM(ROUND(fclunidades1*fclprecio1, 4) + ROUND(fclunidades2*fclprecio2, 4) + ROUND(fclunidades3*fclprecio3, 4) + ROUND(fclunidades4*fclprecio4, 4) + ROUND(fclunidades5*fclprecio5, 4) ) AS DECIMAL(12,4)) AS "Consumo", 
			SUM(fclbase) AS "Base", 
			SUM(fclimpimpuesto) AS "Impuesto" ,
			SUM(fcltotal) AS "Total",
			--CASE WHEN fclfacpercod LIKE '0%' THEN (SELECT TOP 1 przCodPer FROM perzona WHERE MONTH(przfPeriodoH) - MONTH(przfPeriodoD) + 1 = 1 AND f2.facFecha>=przfPeriodoD AND f2.facFecha<=przfPeriodoH) ELSE fclfacpercod END AS periodoRegistrado
			(CASE WHEN fclfacpercod='000002' AND month(f1.facfecha)<=4 THEN convert( VARCHAR, year (f1.facfecha)) ++ '04'
			  WHEN fclfacpercod='000002' AND month(f1.facfecha)> 4 and month(f1.facfecha)<= 8 THEN  convert( VARCHAR, year (f1.facfecha)) ++ '08'
	          WHEN fclfacpercod='000002' AND month(f1.facfecha)> 8 THEN convert( VARCHAR, year (f1.facfecha) ) ++ '12'
	          WHEN (fclfacpercod<>'000002'  AND fclfacpercod LIKE '0%') 
			       THEN (SELECT TOP 1 przCodPer FROM perzona WHERE MONTH(przfPeriodoH) - MONTH(przfPeriodoD) + 1 = 1 AND f2.facFecha>=przfPeriodoD AND f2.facFecha<=przfPeriodoH) 
	          ELSE fclfacpercod END) AS periodoRegistrado
		
		FROM dbo.faclin AS FL 
		INNER JOIN dbo.facturas AS F1 
		ON  FL.fclfaccod	 = F1.faccod 
		AND FL.fclfacpercod  = F1.facpercod 
		AND FL.fclfacctrcod  = F1.facctrcod 
		AND FL.fclfacversion = F1.facversion 
		AND F1.facVersion > 1
		AND F1.facNumero IS NOT NULL
		AND F1.facFecha  IS NOT NULL
		--********************
		AND F1.facFecha >=  @cvFecIni
		AND F1.facFecha <  @cvFecFin
		--****************
		--Rango de periodos
		AND (F1.facpercod < @OMITIR_INICIO OR F1.facpercod >= @OMITIR_FIN) --Rango de exclusión
		AND (@periodoD IS NULL OR f1.facpercod >= @periodoD OR F1.facpercod LIKE '0000%')			   
		AND (@periodoH IS NULL OR f1.facpercod <= @periodoH OR F1.facpercod LIKE '0000%')
		--********************
		INNER JOIN dbo.servicios AS S 
		ON S.svccod = FL.fcltrfsvcod
		INNER JOIN dbo.tarifas AS T 
		ON  T.trfsrvcod = FL.fcltrfsvcod 
		AND T.trfCod = FL.fcltrfcod
		INNER JOIN facturas AS f2 
		ON  f1.faccod = f2.faccod 
		AND f1.facpercod = f2.facpercod 
		AND f1.facctrcod = f2.facctrcod 
		AND f2.facversion = 1
		WHERE ((fclFecLiq IS NULL AND fclUsrLiq IS NULL) OR (FL.fclFecLiq >= @cvFecFin)) 
		AND   (@servicioFianza IS NULL OR fclTrfSvCod <> @servicioFianza)
		--NEW MARINA
		AND (@xmlSerCodArray IS NULL OR FL.fclTrfSvCod NOT IN (SELECT servicioCodigo FROM @serviciosExcluidos))
		--END NEW
		GROUP BY fclfacpercod, f1.faczoncod, fcltrfsvcod, fcltrfcod, fclimpuesto, svcdes, trfdes, f2.facFecha, f1.facFecha
	) AS tabla
	GROUP BY "Periodo", faczoncod, "Servicio", fcltrfcod, fclimpuesto, "Des. Servicio", "Des. Tarifa", periodoRegistrado
	ORDER BY "Periodo", faczoncod, "Servicio", fcltrfcod, fclimpuesto, "Des. Servicio", "Des. Tarifa"
    OPEN cCreado 
    FETCH NEXT FROM cCreado 
    INTO  @periodo, @Zona, @Servicio, @Tarifa, @tipImpuesto, @DesServicio, @DesTarifa, @nFacturas, @CargoFijo, @Consumo, @Base, @Impuesto, @Total, @periodoRegistrado
    WHILE @@FETCH_STATUS = 0
    BEGIN

       UPDATE @tablaAuxiliar SET 
          crenFacturas = @nFacturas,
          creCargoFijo = @CargoFijo,
          creConsumo = @Consumo,
          creBase = @Base,
          creImpuesto = @Impuesto,
          creTotal = @Total
       WHERE periodo = @periodo AND 
			 periodoRegistrado = ISNULL(@periodoRegistrado,'') AND
			 Zona = @Zona AND 
			 Servicio = @Servicio AND 
			 Tarifa = @Tarifa AND
			 tipImpuesto = @tipImpuesto AND
			 ppago = 0

    IF @@ROWCOUNT = 0 
        INSERT INTO @tablaAuxiliar (periodo, periodoRegistrado, zona, servicio, tarifa, ppago, tipImpuesto, desServicio, desTarifa, crenFacturas,creCargoFijo,creConsumo,creBase,creImpuesto,creTotal)
        VALUES (@periodo, ISNULL(@periodoRegistrado,''), @Zona, @Servicio, @Tarifa, 0, @tipImpuesto, @DesServicio, @DesTarifa, @nFacturas, @CargoFijo, @Consumo, @Base, @Impuesto, @Total)

        FETCH NEXT FROM cCreado 
        INTO  @periodo, @Zona, @Servicio, @Tarifa, @tipImpuesto, @DesServicio, @DesTarifa, @nFacturas, @CargoFijo, @Consumo, @Base, @Impuesto, @Total, @periodoRegistrado
    END

    CLOSE cCreado 
    DEALLOCATE cCreado 


	SET @nFacturas = 0 
	SET @cobrado = 0
	SET @tipo = 0 

 --*************************************
-- COBROS
--*************************************
	DECLARE cCobrado CURSOR FOR 

	WITH CTR AS(
	SELECT C.ctrCod
	, C.ctrVersion
	, C.ctrZonCod
	--RN=1: Ultima versión del contrato
	, RN = ROW_NUMBER() OVER (PARTITION BY  C.ctrCod ORDER BY C.ctrVersion DESC)
	FROM dbo.contratos AS C

	), COBS AS(
	SELECT C.cobctr
	, CTR.ctrZonCod
	, C.cobfecreg
	, CL.cblper
	, CL.cblfaccod
	, CL.cblimporte
	, E.ppebca
	, C.cobppag
	, C.cobnum
	, C.cobScd
	, CL.cblLin
	, CL.cblFacVersion
	, ISNULL(F.facFecha, cobFecReg) AS fecha --El cobro debe ir con la fecha de la factura
	FROM dbo.cobros AS C
	INNER JOIN CTR 
	ON  CTR.ctrcod = C.cobCtr 
	AND CTR.RN=1
	INNER JOIN dbo.coblin AS CL 
	ON  CL.cblScd  = C.cobScd
	AND	CL.cblPpag = C.cobPpag
	AND	CL.cblNum  = C.cobnum
	--****************
	--Rango de periodos
	AND (CL.cblper < @OMITIR_INICIO OR CL.cblper >= @OMITIR_FIN) --Rango de exclusión
	AND (@periodoD IS NULL OR CL.cblper >= @periodoD OR CL.cblper LIKE '0000%')			   
	AND (@periodoH IS NULL OR CL.cblper <= @periodoH OR CL.cblper LIKE '0000%')
	--********************
	INNER JOIN dbo.ppagos AS PP 
	ON PP.ppagcod = C.cobppag
	INNER JOIN dbo.ppentidades AS E 
	ON E.ppecod = PP.ppagppcppeCod
	LEFT JOIN dbo.facturas AS F
	ON  F.facCod	= CL.cblFacCod
	AND F.facPerCod = CL.cblPer
	AND F.facCtrCod = C.cobCtr
	AND F.facVersion= CL.cblFacVersion
	WHERE 
	--********************
	C.cobfecreg >=  @cvFecIni AND  C.cobfecreg <  @cvFecFin
	--********************
	)

	SELECT cobctr, ctrZonCod, cobfecreg, cblper, cblfaccod, cblimporte, ppebca, cobppag, cobnum, cobScd, cblLin, cblFacVersion
	, periodoRegistrado = 
	  CASE WHEN cblper='000002' AND MONTH(fecha)<=4 
	  THEN CONVERT(VARCHAR, YEAR(fecha)) ++ '04'
	  WHEN cblper='000002' AND MONTH(fecha)> 4 AND MONTH(fecha)<= 8 
	  THEN  CONVERT(VARCHAR, YEAR (fecha)) ++ '08'
	  WHEN cblper='000002' AND MONTH(fecha)> 8 THEN CONVERT(VARCHAR, YEAR(fecha)) ++ '12'
	  WHEN cblper<>'000002' AND cblper LIKE '0%' 
	  THEN (SELECT TOP 1 przCodPer 
			FROM perzona 
			WHERE MONTH(przfPeriodoH) - MONTH(przfPeriodoD) + 1 = 1 
			AND (SELECT facFecha FROM facturas WHERE facPerCod = cblPer AND facCtrCod = cobCtr AND facCod = cblFacCod AND facVersion = 1)>=przfPeriodoD 
			AND (SELECT facFecha FROM facturas WHERE facPerCod = cblPer AND facCtrCod = cobCtr AND facCod = cblFacCod AND facVersion = 1)<=przfPeriodoH) 
	  ELSE cblper END 
	FROM COBS

	OPEN cCobrado
	FETCH NEXT FROM cCobrado
		INTO @contrato, @Zona, @fecCob, @periodo, @codigo, @cobrado, @tipo, @ppago, @cobNum, @sociedad, @lineaCobro, @facVersion, @periodoRegistrado
	WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @periodo = '999999' BEGIN	--Entregas a Cuenta (no hay factura)
				IF @cobrado > 0 BEGIN   -- Cobro
					IF @tipo = 1 BEGIN -- banco
						update @tablaAuxiliar set 
							  nCobBanco = nCobBanco + 1,
							  cobBanBase = cobBanBase + @cobrado,
							  cobBanTotal = cobBanTotal + @cobrado
						where periodo = @periodo AND periodoRegistrado = ISNULL(@periodoRegistrado,'') and Zona = @Zona and Servicio = 9999 and Tarifa = 1 and tipImpuesto = 0 and ppago = @ppago

						IF @@ROWCOUNT = 0 
							INSERT into @tablaAuxiliar (periodo, periodoRegistrado, Zona, Servicio, Tarifa, ppago, tipImpuesto, DesServicio, nCobBanco, cobBanBase, cobBanTotal)
							values (@periodo, ISNULL(@periodoRegistrado,''), @Zona, 9999, 1, @ppago, 0, 'Entregas a cuenta', 1, @cobrado, @cobrado)
					END ELSE BEGIN -- Oficina
						update @tablaAuxiliar set 
							  nCobOficina = nCobOficina + 1,
							  cobOfiBase = cobOfiBase + @cobrado,
							  cobOfiTotal = cobOfiTotal + @cobrado
						where periodo = @periodo AND periodoRegistrado = ISNULL(@periodoRegistrado,'') and Zona = @Zona and Servicio = 9999 and Tarifa = 1 and tipImpuesto = 0 and ppago = @ppago

						IF @@ROWCOUNT = 0 
							INSERT into @tablaAuxiliar (periodo, periodoRegistrado, Zona, Servicio, Tarifa, ppago, tipImpuesto, DesServicio, nCobOficina, cobOfiBase, cobOfiTotal)
							values (@periodo, ISNULL(@periodoRegistrado,''), @Zona, 9999, 1, @ppago, 0, 'Entregas a cuenta', 1, @cobrado, @cobrado)
					END
				END ELSE BEGIN
					IF @tipo = 1 BEGIN -- banco
						update @tablaAuxiliar set 
							  nDevBanco = nDevBanco + 1,
							  devBanBase = devBanBase + (-1)*@cobrado,
							  devBanTotal = devBanTotal + (-1)*@cobrado
						where periodo = @periodo AND periodoRegistrado = ISNULL(@periodoRegistrado,'') and Zona = @Zona and Servicio = 9999 and Tarifa = 1 and ppago = @ppago and tipImpuesto = 0

						IF @@ROWCOUNT = 0 
							INSERT into @tablaAuxiliar (periodo, periodoRegistrado, Zona, Servicio, Tarifa, ppago, tipImpuesto, DesServicio, nDevBanco, devBanBase, devBanTotal)
							values (@periodo, ISNULL(@periodoRegistrado,''), @Zona, 9999, 1, @ppago, 0, 'Entregas a cuenta', 1, (-1)*@cobrado, (-1)*@cobrado)
					END ELSE BEGIN -- Oficina
						update @tablaAuxiliar set 
							  nDevOficina = nDevOficina + 1,
							  devOfiBase = devOfiBase + (-1)*@cobrado,
							  devOfiTotal = devOfiTotal + (-1)*@cobrado
						where periodo = @periodo AND periodoRegistrado = ISNULL(@periodoRegistrado,'') and Zona = @Zona and Servicio = 9999 and Tarifa = 1 and ppago = @ppago and tipImpuesto = 0

						IF @@ROWCOUNT = 0 
							INSERT into @tablaAuxiliar (periodo, periodoRegistrado, Zona, Servicio, Tarifa, ppago, tipImpuesto, DesServicio, nDevOficina, devOfiBase, devOfiTotal)
							values (@periodo, ISNULL(@periodoRegistrado,''), @Zona, 9999, 1, @ppago, 0, 'Entregas a cuenta', 1, (-1)*@cobrado, (-1)*@cobrado)
					END
				END
			END ELSE BEGIN
					
----------------------------------------------------------------------------------------------------------------------------------				
			DECLARE @hayServicioYTarifaRepetidos INT = 1
			SET @hayServicioYTarifaRepetidos = ISNULL((SELECT COUNT(*) 
														      FROM faclin l1
														      WHERE EXISTS(SELECT fclfaccod 
																				  FROM faclin l2 
																				  WHERE l2.fclfacctrcod=l1.fclfacctrcod AND 
																						l2.fclfacpercod=l1.fclfacpercod AND 
																						l2.fclfaccod=l1.fclfaccod AND 
																						l2.fclfacversion=l1.fclfacversion AND 
																						l2.fclnumlinea <> l1.fclnumLinea AND 
																						l1.fcltrfcod = l2.fcltrfcod AND 
																						l1.fcltrfsvcod = l2.fcltrfsvcod
																						
																		  ) and fclFacCod = @codigo AND
																			fclFacPerCod = @periodo AND
																			fclFacCtrCod = @contrato AND
																			fclFacVersion = @facVersion
																			--NEW MARINA
																			AND (@xmlSerCodArray IS NULL OR 
																			(@xmlSerCodArray IS NOT NULL AND fclTrfSvCod not IN (SELECT servicioCodigo FROM @serviciosExcluidos)))
																			--END NEW
																			),1)
			IF(@hayServicioYTarifaRepetidos > 1)
			BEGIN
				DECLARE cLineas CURSOR FOR
					SELECT faczoncod,
					cldTrfSrvCod AS "Servicio",
					cldTrfCod,
					fclImpuesto AS fclimpuesto,
					svcdes AS "Des. Servicio",
					trfdes AS "Des. Tarifa",
						CASE WHEN @cobrado > 0
							 THEN CAST((CAST(ROUND(fclunidades*fclprecio, 4) AS DECIMAL(12,4)) * CAST(cldImporte AS DECIMAL(12,4))) / CAST(fcltotal AS DECIMAL(12,4)) AS DECIMAL(12,4))
							 ELSE (-1)*CAST((CAST(ROUND(fclunidades*fclprecio, 4) AS DECIMAL(12,4)) * CAST(cldImporte AS DECIMAL(12,4))) / CAST(fcltotal AS DECIMAL(12,4)) AS DECIMAL(12,4))
					END AS "Cargo Fijo",
					CASE WHEN @cobrado > 0
						 THEN CAST((CAST((ROUND(fclunidades1*fclprecio1, 4) + ROUND(fclunidades2*fclprecio2, 4) + ROUND(fclunidades3*fclprecio3, 4) + ROUND(fclunidades4*fclprecio4, 4) + ROUND(fclunidades5*fclprecio5, 4) ) AS DECIMAL(12,4)) * cldImporte) / fcltotal AS DECIMAL(12,4))
						 ELSE (-1)*CAST((CAST((ROUND(fclunidades1*fclprecio1, 4) + ROUND(fclunidades2*fclprecio2, 4) + ROUND(fclunidades3*fclprecio3, 4) + ROUND(fclunidades4*fclprecio4, 4) + ROUND(fclunidades5*fclprecio5, 4) ) AS DECIMAL(12,4)) * cldImporte) / fcltotal AS DECIMAL(12,4))
					END AS "Consumo",
					CASE WHEN @cobrado > 0
						 THEN ROUND((fclBase * cldImporte) / fcltotal, 4)
						 ELSE (-1)*ROUND((fclBase * cldImporte) / fcltotal, 4)
					END AS "Base",
					CASE WHEN @cobrado > 0
						 THEN ROUND((fclImpimpuesto * cldImporte) / fcltotal, 4)
						 ELSE (-1)*ROUND((fclImpimpuesto * cldImporte) / fcltotal, 4)
					END AS "Impuesto",
					fclTotal AS "Total",
					CASE WHEN @cobrado > 0 THEN	cldImporte ELSE (-1)*cldImporte END AS "CobLinDesTotal"
			   FROM cobros 
				INNER JOIN coblin ON cobScd = cblScd AND cobPpag = cblPpag AND cobNum = cblNum
				INNER JOIN coblinDes ON cldCblScd = cblScd AND cldCblPpag = cblPpag AND cldCblNum = cblNum AND cldCblLin = cblLin
				INNER JOIN facturas f ON facPerCod = cblPer AND facCtrCod = cobCtr AND facCod = cblFacCod 
										 AND facVersion = CASE WHEN (cblFacVersion > 1 AND 
																		 NOT EXISTS(SELECT fclNumLinea 
																						   FROM faclin 
																						   WHERE fclFacCod = f.facCod AND 
																								 fclFacPerCod = f.facPerCod AND 
																								 fclFacCtrCod = f.facCtrCod AND 
																								 fclFacVersion = cblFacVersion AND 
																								 fcltotal <> 0
																						 )
																			 )
																	 THEN (SELECT facversion --cogemos la versión anterior (ANULADAS)
																				   FROM facturas f2 
																				   WHERE f2.faccod = f.facCod  AND 
																						 f2.facpercod = f.facPerCod AND 
																						 f2.facctrcod = f.facCtrCod AND 
																						 f2.facversion = cblFacVersion - 1
																		   )
																	ELSE  cblFacVersion
																END
				INNER JOIN faclin ON facCod = fclFacCod AND facCtrCod = fclFacCtrCod AND facPerCod = fclFacPerCod AND facVersion = fclFacVersion 
									 AND fclTrfCod = cldTrfCod AND fclTrfSvCod = cldTrfSrvCod and fclNumLinea=cldFacLin
				INNER JOIN servicios ON svccod = cldTrfSrvCod
				INNER JOIN tarifas ON trfCod = fclTrfCod AND trfSrvCod = fcltrfSvCod
					WHERE cobScd = @sociedad AND
						  cobPpag = @ppago AND
						  cobNum = @cobNum AND
						  cblFacCod = @codigo AND
						  cobCtr = @contrato AND 
						  cblPer = @periodo AND
						  cblLin = @lineaCobro AND
						  fclTotal <> 0 AND --Excluir posibles líneas de factura con importe 0 (Por ejemplo los Municipales)
						((DATEADD(dd, DATEDIFF(dd, 0, fclFecLiq), 0) >= DATEADD(dd, DATEDIFF(dd, 0, @fecCob), 0)) OR (fclFecLiq IS NULL AND fclUsrLiq IS NULL)) AND 
						 (@servicioFianza IS NULL OR fclTrfSvCod <> @servicioFianza) --AND 
				 		--NEW MARINA
						AND (@xmlSerCodArray IS NULL OR 
						(@xmlSerCodArray IS NOT NULL AND fclTrfSvCod not IN (SELECT servicioCodigo FROM @serviciosExcluidos)))
						--END NEW
					ORDER BY cblPer, faczoncod, cldTrfSrvCod, cldTrfCod, svcdes
				OPEN cLineas 
				FETCH NEXT FROM cLineas 
					INTO  @Zona, @Servicio, @Tarifa, @tipImpuesto, @DesServicio, @DesTarifa, @CargoFijo, @Consumo, @Base, @Impuesto, @Total, @CobLinDesTotal
						WHILE @@FETCH_STATUS = 0
				BEGIN
					IF @cobrado > 0 BEGIN   -- Cobro
						IF @tipo = 1 BEGIN -- Banco
							UPDATE @tablaAuxiliar 
								 SET nCobBanco = nCobBanco + 1,
									 cobBanCargoFijo = cobBanCargoFijo + @CargoFijo,
									 cobBanConsumo = cobBanConsumo + @Consumo,
									 cobBanBase = cobBanBase + @Base,
									 cobBanImpuesto = cobBanImpuesto + @Impuesto,
									 cobBanTotal = cobBanTotal + CASE WHEN @Total <> @CobLinDesTotal THEN @CobLinDesTotal ELSE @Total END
							where periodo = @periodo AND periodoRegistrado = ISNULL(@periodoRegistrado,'') and Zona = @Zona and Servicio = @Servicio and Tarifa = @Tarifa and ppago = @ppago and tipImpuesto = @tipImpuesto									 

							IF @@ROWCOUNT = 0 
								
								INSERT into @tablaAuxiliar (periodo, periodoRegistrado, Zona, Servicio, Tarifa, ppago, tipImpuesto, DesServicio, DesTarifa, nCobBanco,cobBanCargoFijo,cobBanConsumo,cobBanBase,cobBanImpuesto,cobBanTotal)
								values (@periodo, ISNULL(@periodoRegistrado,''), @Zona, @Servicio, @Tarifa, @ppago, @tipImpuesto, @DesServicio, @DesTarifa, 1, @CargoFijo, @Consumo, @Base, @Impuesto, CASE WHEN @Total <> @CobLinDesTotal THEN @CobLinDesTotal ELSE @Total END)
						END ELSE BEGIN -- Oficina
							update @tablaAuxiliar set 
								  nCobOficina = nCobOficina + 1,
								  cobOfiCargoFijo = cobOfiCargoFijo + @CargoFijo,
								  cobOfiConsumo = cobOfiConsumo + @Consumo,
								  cobOfiBase = cobOfiBase + @Base,
								  cobOfiImpuesto = cobOfiImpuesto + @Impuesto,
								  cobOfiTotal = cobOfiTotal + CASE WHEN @Total <> @CobLinDesTotal THEN @CobLinDesTotal ELSE @Total END
							where periodo = @periodo AND periodoRegistrado = ISNULL(@periodoRegistrado,'') and Zona = @Zona and Servicio = @Servicio and Tarifa = @Tarifa and  ppago = @ppago and tipImpuesto = @tipImpuesto
								
							IF @@ROWCOUNT = 0 
								INSERT into @tablaAuxiliar (periodo, periodoRegistrado, Zona, Servicio, Tarifa, ppago, tipImpuesto, DesServicio, DesTarifa, nCobOficina, cobOfiCargoFijo, cobOfiConsumo,cobOfiBase,cobOfiImpuesto,cobOfiTotal)
								values (@periodo, ISNULL(@periodoRegistrado,''), @zona, @Servicio, @Tarifa, @ppago, @tipImpuesto, @DesServicio, @DesTarifa, 1, @CargoFijo, @Consumo, @Base, @Impuesto, CASE WHEN @Total <> @CobLinDesTotal THEN @CobLinDesTotal ELSE @Total END)
						END
					END ELSE BEGIN --Devolucion
						IF @tipo = 1 BEGIN -- Banco
							update @tablaAuxiliar set 
								  nDevBanco = nDevBanco + 1,
								  devBanCargoFijo = devBanCargoFijo + @CargoFijo,
								  devBanConsumo = devBanConsumo + @Consumo,
								  devBanBase = devBanBase + @Base,
								  devBanImpuesto = devBanImpuesto + @Impuesto,
								  devBanTotal = devBanTotal + CASE WHEN @Total <> @CobLinDesTotal THEN @CobLinDesTotal ELSE @Total END
							where periodo = @periodo AND periodoRegistrado = ISNULL(@periodoRegistrado,'') and Zona = @Zona and Servicio = @Servicio and Tarifa = @Tarifa and ppago = @ppago and tipImpuesto = @tipImpuesto

							IF @@ROWCOUNT = 0 
								INSERT into @tablaAuxiliar (periodo, periodoRegistrado, Zona, Servicio, Tarifa, ppago, tipImpuesto, DesServicio, DesTarifa, nDevBanco,devBanCargoFijo,devBanConsumo,devBanBase,devBanImpuesto,devBanTotal)
								values (@periodo, ISNULL(@periodoRegistrado,''), @Zona, @Servicio, @Tarifa, @ppago, @tipImpuesto, @DesServicio, @DesTarifa, 1, @CargoFijo, @Consumo, @Base, @Impuesto, CASE WHEN @Total <> @CobLinDesTotal THEN @CobLinDesTotal ELSE @Total END)
						END ELSE BEGIN -- Oficina
							update @tablaAuxiliar set 
								  nDevOficina = nDevOficina + 1,
								  devOfiCargoFijo = devOfiCargoFijo + @CargoFijo,
								  devOfiConsumo = devOfiConsumo + @Consumo,
								  devOfiBase = devOfiBase + @Base,
								  devOfiImpuesto = devOfiImpuesto + @Impuesto,
								  devOfiTotal = devOfiTotal + CASE WHEN @Total <> @CobLinDesTotal THEN @CobLinDesTotal ELSE @Total END
							where periodo = @periodo AND periodoRegistrado = ISNULL(@periodoRegistrado,'') and Zona = @Zona and Servicio = @Servicio and Tarifa = @Tarifa and ppago = @ppago and tipImpuesto = @tipImpuesto

							IF @@ROWCOUNT = 0
								INSERT into @tablaAuxiliar (periodo, periodoRegistrado, Zona, Servicio, Tarifa, ppago, tipImpuesto, DesServicio, DesTarifa, nDevOficina,devOfiCargoFijo,devOfiConsumo,devOfiBase,devOfiImpuesto,devOfiTotal)
								values (@periodo, ISNULL(@periodoRegistrado,''), @Zona, @Servicio, @Tarifa, @ppago, @tipImpuesto, @DesServicio, @DesTarifa, 1, @CargoFijo, @Consumo, @Base, @Impuesto, CASE WHEN @Total <> @CobLinDesTotal THEN @CobLinDesTotal ELSE @Total END)
						END
					END
					FETCH NEXT FROM cLineas
					INTO  @Zona, @Servicio, @Tarifa, @tipImpuesto, @DesServicio, @DesTarifa, @CargoFijo, @Consumo, @Base, @Impuesto, @Total, @CobLinDesTotal
				END
				CLOSE cLineas 
				DEALLOCATE cLineas
			END
			ELSE BEGIN
				DECLARE cLineas CURSOR FOR
					SELECT faczoncod,
					cldTrfSrvCod AS "Servicio",
					cldTrfCod,
					fclImpuesto AS fclimpuesto,
					svcdes AS "Des. Servicio",
					trfdes AS "Des. Tarifa",
					CASE WHEN @cobrado > 0
							 THEN CAST((CAST(ROUND(fclunidades*fclprecio, 4) AS DECIMAL(12,4)) * CAST(cldImporte AS DECIMAL(12,4))) / CAST(fcltotal AS DECIMAL(12,4)) AS DECIMAL(12,4))
							 ELSE (-1)*CAST((CAST(ROUND(fclunidades*fclprecio, 4) AS DECIMAL(12,4)) * CAST(cldImporte AS DECIMAL(12,4))) / CAST(fcltotal AS DECIMAL(12,4)) AS DECIMAL(12,4))
					END AS "Cargo Fijo",
					CASE WHEN @cobrado > 0
						 THEN CAST((CAST((ROUND(fclunidades1*fclprecio1, 4) + ROUND(fclunidades2*fclprecio2, 4) + ROUND(fclunidades3*fclprecio3, 4) + ROUND(fclunidades4*fclprecio4, 4) + ROUND(fclunidades5*fclprecio5, 4) ) AS DECIMAL(12,4)) * cldImporte) / fcltotal AS DECIMAL(12,4))
						 ELSE (-1)*CAST((CAST((ROUND(fclunidades1*fclprecio1, 4) + ROUND(fclunidades2*fclprecio2, 4) + ROUND(fclunidades3*fclprecio3, 4) + ROUND(fclunidades4*fclprecio4, 4) + ROUND(fclunidades5*fclprecio5, 4) ) AS DECIMAL(12,4)) * cldImporte) / fcltotal AS DECIMAL(12,4))
					END AS "Consumo",
					CASE WHEN @cobrado > 0
						 THEN ROUND((fclBase * cldImporte) / fcltotal, 4)
						 ELSE (-1)*ROUND((fclBase * cldImporte) / fcltotal, 4)
					END AS "Base",
					CASE WHEN @cobrado > 0
						 THEN ROUND((fclImpimpuesto * cldImporte) / fcltotal, 4)
						 ELSE (-1)*ROUND((fclImpimpuesto * cldImporte) / fcltotal, 4)
					END AS "Impuesto",
					fclTotal AS "Total",
					CASE WHEN @cobrado > 0 THEN	cldImporte  ELSE (-1)* cldImporte  END AS "CobLinDesTotal"
			   FROM cobros 
				INNER JOIN coblin ON cobScd = cblScd AND cobPpag = cblPpag AND cobNum = cblNum
				INNER JOIN coblinDes ON cldCblScd = cblScd AND cldCblPpag = cblPpag AND cldCblNum = cblNum AND cldCblLin = cblLin
				INNER JOIN facturas f ON facPerCod = cblPer AND facCtrCod = cobCtr AND facCod = cblFacCod 
										  AND facVersion = CASE WHEN (cblFacVersion > 1 AND 
																		 NOT EXISTS(SELECT fclNumLinea 
																						   FROM faclin 
																						   WHERE fclFacCod = f.facCod AND 
																								 fclFacPerCod = f.facPerCod AND 
																								 fclFacCtrCod = f.facCtrCod AND 
																								 fclFacVersion = cblFacVersion AND 
																								 fcltotal <> 0
																						 )
																			 )
																	 THEN (SELECT facversion --cogemos la versión anterior ANULADAS
																				   FROM facturas f2 
																				   WHERE f2.faccod = f.facCod  AND 
																						 f2.facpercod = f.facPerCod AND 
																						 f2.facctrcod = f.facCtrCod AND 
																						 f2.facversion = cblFacVersion - 1
																		   )
																	ELSE  cblFacVersion
																END
				INNER JOIN faclin ON facCod = fclFacCod AND facCtrCod = fclFacCtrCod AND facPerCod = fclFacPerCod AND facVersion = fclFacVersion 
														AND fclTrfCod = cldTrfCod AND fclTrfSvCod = cldTrfSrvCod
				INNER JOIN servicios ON svccod = cldTrfSrvCod
				INNER JOIN tarifas ON trfCod = fclTrfCod AND trfSrvCod = fcltrfSvCod
					WHERE cobScd = @sociedad AND
						  cobPpag = @ppago AND
						  cobNum = @cobNum AND
						  cblFacCod = @codigo AND
						  cobCtr = @contrato AND 
						  cblPer = @periodo AND
						  cblLin = @lineaCobro AND
						  fclTotal <> 0 AND --Excluir posibles líneas de factura con importe 0 (Por ejemplo los Municipales)
						((DATEADD(dd, DATEDIFF(dd, 0, fclFecLiq), 0) >= DATEADD(dd, DATEDIFF(dd, 0, @fecCob), 0)) OR (fclFecLiq IS NULL AND fclUsrLiq IS NULL)) AND 
						 (@servicioFianza IS NULL OR fclTrfSvCod <> @servicioFianza) --AND 
				 		--NEW MARINA
						AND (@xmlSerCodArray IS NULL OR 
						(@xmlSerCodArray IS NOT NULL AND fclTrfSvCod not IN (SELECT servicioCodigo FROM @serviciosExcluidos)))
						--END NEW
					ORDER BY cblPer, faczoncod, cldTrfSrvCod, cldTrfCod, svcdes
				OPEN cLineas 
				FETCH NEXT FROM cLineas 
				INTO  @Zona, @Servicio, @Tarifa, @tipImpuesto, @DesServicio, @DesTarifa, @CargoFijo, @Consumo, @Base, @Impuesto, @Total, @CobLinDesTotal
				WHILE @@FETCH_STATUS = 0
				BEGIN
					IF @cobrado > 0 BEGIN   -- Cobro
						IF @tipo = 1 BEGIN -- Banco
							UPDATE @tablaAuxiliar 
								 SET nCobBanco = nCobBanco + 1,
									 cobBanCargoFijo = cobBanCargoFijo + @CargoFijo,
									 cobBanConsumo = cobBanConsumo + @Consumo,
									 cobBanBase = cobBanBase + @Base,
									 cobBanImpuesto = cobBanImpuesto + @Impuesto,
									 cobBanTotal = cobBanTotal + CASE WHEN @Total <> @CobLinDesTotal THEN @CobLinDesTotal ELSE @Total END
							where periodo = @periodo AND periodoRegistrado = ISNULL(@periodoRegistrado,'') AND periodoRegistrado = ISNULL(@periodoRegistrado,'') and Zona = @Zona and Servicio = @Servicio and Tarifa = @Tarifa and ppago = @ppago and tipImpuesto = @tipImpuesto									 

							IF @@ROWCOUNT = 0 
								
								INSERT into @tablaAuxiliar (periodo, periodoRegistrado, Zona, Servicio, Tarifa, ppago, tipImpuesto, DesServicio, DesTarifa, nCobBanco,cobBanCargoFijo,cobBanConsumo,cobBanBase,cobBanImpuesto,cobBanTotal)
								values (@periodo, ISNULL(@periodoRegistrado,''), @Zona, @Servicio, @Tarifa, @ppago, @tipImpuesto, @DesServicio, @DesTarifa, 1, @CargoFijo, @Consumo, @Base, @Impuesto, CASE WHEN @Total <> @CobLinDesTotal THEN @CobLinDesTotal ELSE @Total END)
						END ELSE BEGIN -- Oficina
							update @tablaAuxiliar set 
								  nCobOficina = nCobOficina + 1,
								  cobOfiCargoFijo = cobOfiCargoFijo + @CargoFijo,
								  cobOfiConsumo = cobOfiConsumo + @Consumo,
								  cobOfiBase = cobOfiBase + @Base,
								  cobOfiImpuesto = cobOfiImpuesto + @Impuesto,
								  cobOfiTotal = cobOfiTotal + CASE WHEN @Total <> @CobLinDesTotal THEN @CobLinDesTotal ELSE @Total END
							where periodo = @periodo AND periodoRegistrado = ISNULL(@periodoRegistrado,'') and Zona = @Zona and Servicio = @Servicio and Tarifa = @Tarifa and  ppago = @ppago and tipImpuesto = @tipImpuesto
								
							IF @@ROWCOUNT = 0 
								INSERT into @tablaAuxiliar (periodo, periodoRegistrado, Zona, Servicio, Tarifa, ppago, tipImpuesto, DesServicio, DesTarifa, nCobOficina, cobOfiCargoFijo, cobOfiConsumo,cobOfiBase,cobOfiImpuesto,cobOfiTotal)
								values (@periodo, ISNULL(@periodoRegistrado,''), @zona, @Servicio, @Tarifa, @ppago, @tipImpuesto, @DesServicio, @DesTarifa, 1, @CargoFijo, @Consumo, @Base, @Impuesto, CASE WHEN @Total <> @CobLinDesTotal THEN @CobLinDesTotal ELSE @Total END)
						END
					END ELSE BEGIN --Devolucion
						IF @tipo = 1 BEGIN -- Banco
							update @tablaAuxiliar set 
								  nDevBanco = nDevBanco + 1,
								  devBanCargoFijo = devBanCargoFijo + @CargoFijo,
								  devBanConsumo = devBanConsumo + @Consumo,
								  devBanBase = devBanBase + @Base,
								  devBanImpuesto = devBanImpuesto + @Impuesto,
								  devBanTotal = devBanTotal + CASE WHEN @Total <> @CobLinDesTotal THEN @CobLinDesTotal ELSE @Total END
							where periodo = @periodo AND periodoRegistrado = ISNULL(@periodoRegistrado,'') and Zona = @Zona and Servicio = @Servicio and Tarifa = @Tarifa and ppago = @ppago and tipImpuesto = @tipImpuesto

							IF @@ROWCOUNT = 0 
								INSERT into @tablaAuxiliar (periodo, periodoRegistrado, Zona, Servicio, Tarifa, ppago, tipImpuesto, DesServicio, DesTarifa, nDevBanco,devBanCargoFijo,devBanConsumo,devBanBase,devBanImpuesto,devBanTotal)
								values (@periodo, ISNULL(@periodoRegistrado,''), @Zona, @Servicio, @Tarifa, @ppago, @tipImpuesto, @DesServicio, @DesTarifa, 1, @CargoFijo, @Consumo, @Base, @Impuesto, CASE WHEN @Total <> @CobLinDesTotal THEN @CobLinDesTotal ELSE @Total END)
						END ELSE BEGIN -- Oficina
							update @tablaAuxiliar set 
								  nDevOficina = nDevOficina + 1,
								  devOfiCargoFijo = devOfiCargoFijo + @CargoFijo,
								  devOfiConsumo = devOfiConsumo + @Consumo,
								  devOfiBase = devOfiBase + @Base,
								  devOfiImpuesto = devOfiImpuesto + @Impuesto,
								  devOfiTotal = devOfiTotal + CASE WHEN @Total <> @CobLinDesTotal THEN @CobLinDesTotal ELSE @Total END
							where periodo = @periodo AND periodoRegistrado = ISNULL(@periodoRegistrado,'') and Zona = @Zona and Servicio = @Servicio and Tarifa = @Tarifa and ppago = @ppago and tipImpuesto = @tipImpuesto

							IF @@ROWCOUNT = 0
								INSERT into @tablaAuxiliar (periodo, periodoRegistrado, Zona, Servicio, Tarifa, ppago, tipImpuesto, DesServicio, DesTarifa, nDevOficina,devOfiCargoFijo,devOfiConsumo,devOfiBase,devOfiImpuesto,devOfiTotal)
								values (@periodo, ISNULL(@periodoRegistrado,''), @Zona, @Servicio, @Tarifa, @ppago, @tipImpuesto, @DesServicio, @DesTarifa, 1, @CargoFijo, @Consumo, @Base, @Impuesto, CASE WHEN @Total <> @CobLinDesTotal THEN @CobLinDesTotal ELSE @Total END)
						END
					END
					FETCH NEXT FROM cLineas
					INTO  @Zona, @Servicio, @Tarifa, @tipImpuesto, @DesServicio, @DesTarifa, @CargoFijo, @Consumo, @Base, @Impuesto, @Total, @CobLinDesTotal
				END
				CLOSE cLineas 
				DEALLOCATE cLineas
			END
		END
		FETCH NEXT FROM cCobrado 
		INTO  @contrato, @Zona, @fecCob, @periodo, @codigo, @cobrado, @tipo, @ppago, @cobNum, @sociedad, @lineaCobro, @facVersion, @periodoRegistrado
	END
	CLOSE cCobrado 
	DEALLOCATE cCobrado 

---- En la tabla original se mantiene el detalle, en la del informe mezclamos detallado/agrupado según el caso, que es lo que se pide

-- TODO: RECORDATORIO, SI SE INSERTA UN NUEVO SERVICIO HAY QUE MIRAR LOS PROCEDIMIENTOS ALMACENADOS PARA PONER EL CB AL NUEVO SERVICIO
	
/* El informe mostrará 7 bloques, cada uno de los cuales incluirá las siguientes secciones:
		Resumen de facturación
			Facturación original
			Anulado
			Creado
			Estado de facturación
		Resumen de cobros
			Cobros banco
			Devoluciones banco
			Cobros oficina
			Devoluciones oficina 
			
   Cada bloque sólo aparecerá si hay datos que mostrar. Los bloques serán estos:
		1 - Cuatrimestrales (zona <> '0010')
				Servicio 2 (depuración).
				Servicio 3 (RSU).
				Servicio 99, 100, 103, 104, 105, 106, 107  (BONIFICACION ECOVIDRIO)
				Servicio 1 (agua), detallado por tarifas.
					Tarifas 1 y 3 (consumo 10 y doméstico) -> Uso doméstico
					Tarifas 2, 6 y 8 (consumo 15, industrial, incendios cuatrimestral) -> Uso industrial
					Tarifa 7 (riegos y piscinas).
		2 - Mensuales (zona = '0010')
				Servicio 2 (depuración).
				Servicio 3 (RSU).
				Servicio 99, 100, 103, 104, 105, 106, 107 (BONIFICACION ECOVIDRIO)
				Servicio 1 (agua), detallado por tarifas.
					Tarifas 1 y 3 (consumo 10 y doméstico) -> Uso doméstico
					Tarifas 2, 6 y 5 (consumo 15, industrial, incendios mensual) -> Uso industrial
					Tarifa 7 (riegos y piscinas).
		3 - Alta y contadores
				Servicio 4 (trabajos de conexión contador).
				Servicio 5 (colocación contador).
				Servicio 13 (fianzas).
				Servicio 14 (compra agua).
				Servicio 15 (fraude).
		4 - Acometidas 
				Servicio 12 (acometida).	
				Servicio 101 (ACOMETIDA COMUNIDAD PROPIETARIOS).
				Servicio 102 (OPERACION CON INVERSION DL SUJETO PASIVO)
		5 - Camión succionador
				Servicio 6 (camión succionador).
				Servicio 7 (gestión recogida de residuos).
		6 - Satélites suministro y analíticas
				Servicio 16 (Golmayo).
				Servicio 9 (Cidones).
				Servicio 10 (Cometa).
				Servicio 8 (Villar).
		7 - Satélites depuración
				Servicio 11 (ayuntamiento San Pedro Manrique).		
*/
	
	-- Insertamos todo lo que va agrupado por servicio, todo lo que no es agua
	INSERT INTO @tablaInforme
		(bloqueId, bloqueNom,		
		periodo, periodoRegistrado, zona, servTarifa, desServTarifa, -- Id y nombre de servicio
		facnFacturas, facCargoFijo, 	facConsumo, 	facBase, 	facImpuesto, 	facTotal,
		anunFacturas, anuCargoFijo, 	anuConsumo, 	anuBase, 	anuImpuesto, 	anuTotal,
		crenFacturas, creCargoFijo, 	creConsumo, 	creBase,  	creImpuesto, 	creTotal,
		nCobBanco, 	  cobBanCargoFijo,	cobBanConsumo,	cobBanBase, cobBanImpuesto, cobBanTotal,
		nCobOficina,  cobOfiCargoFijo,	cobOfiConsumo,	cobOfiBase, cobOfiImpuesto, cobOfiTotal,
		nDevBanco, 	  devBanCargoFijo,	devBanConsumo,	devBanBase, devBanImpuesto, devBanTotal,
		nDevOficina,  devOfiCargoFijo,	devOfiConsumo,	devOfiBase, devOfiImpuesto, devOfiTotal)
	SELECT
		-- bloqueId
		CASE WHEN Servicio IN (2, 3, 99, 100, 103, 104, 105, 106, 107, 110, 111) AND zona <> '0010' THEN 1 -- CUATRIMESTRALES 
			 WHEN Servicio IN (2, 3, 99, 100, 103, 104, 105, 106, 107, 110, 111) AND zona = '0010' THEN 2  -- MENSUALES	 
			 WHEN Servicio IN (4, 5, 13, 14, 15) THEN 3    	   -- ALTA Y CONTADORES
			 WHEN Servicio IN (12, 101, 102) THEN 4            -- ACOMETIDAS
			 WHEN Servicio IN (6, 7) THEN 5                    -- CAMIÓN SUCCIONADOR
			 WHEN Servicio IN (16, 8, 9, 10) THEN 6      	   -- SATÉLITES SUMINISTRO Y ANALÍTICAS
			 WHEN Servicio = 11 THEN 7 END,                    -- SATÉLITES DEPURACIÓN
		-- bloqueNom
		CASE WHEN Servicio IN (2, 3, 99, 100, 103, 104, 105, 106, 107, 110, 111) AND zona <> '0010' THEN 'CUATRIMESTRALES'
			 WHEN Servicio IN (2, 3, 99, 100, 103, 104, 105, 106, 107, 110, 111) AND zona = '0010' THEN 'MENSUALES'
			 WHEN Servicio IN (4, 5, 13, 14, 15) THEN 'ALTA Y CONTADORES' 
			 WHEN Servicio IN (12, 101, 102) THEN 'ACOMETIDAS' 
			 WHEN Servicio IN (6, 7) THEN 'CAMIÓN SUCCIONADOR'
			 WHEN Servicio IN (16, 8, 9, 10) THEN 'SATÉLITES SUMINISTRO Y ANALÍTICAS'
			 WHEN Servicio = 11 THEN 'SATÉLITES DEPURACIÓN' END,
		periodo, periodoRegistrado, zona, servicio, desServicio,
			ISNULL(sum(facnFacturas), 0), ISNULL(sum(facCargoFijo), 0),    ISNULL(sum(facConsumo), 0),    ISNULL(sum(facBase), 0),    ISNULL(sum(facImpuesto), 0),    ISNULL(sum(facTotal), 0),
			ISNULL(sum(anunFacturas), 0), ISNULL(sum(anuCargoFijo), 0),    ISNULL(sum(anuConsumo), 0),    ISNULL(sum(anuBase), 0),    ISNULL(sum(anuImpuesto), 0),    ISNULL(sum(anuTotal), 0),
			ISNULL(sum(crenFacturas), 0), ISNULL(sum(creCargoFijo), 0),    ISNULL(sum(creConsumo), 0),    ISNULL(sum(creBase), 0),    ISNULL(sum(creImpuesto), 0),    ISNULL(sum(creTotal), 0),
			ISNULL(sum(nCobBanco), 0),    ISNULL(sum(cobBanCargoFijo), 0), ISNULL(sum(cobBanConsumo), 0), ISNULL(sum(cobBanBase), 0), ISNULL(sum(cobBanImpuesto), 0), ISNULL(sum(cobBanTotal), 0),
			ISNULL(sum(nCobOficina), 0),  ISNULL(sum(cobOfiCargoFijo), 0), ISNULL(sum(cobOfiConsumo), 0), ISNULL(sum(cobOfiBase), 0), ISNULL(sum(cobOfiImpuesto), 0), ISNULL(sum(cobOfiTotal), 0),
			ISNULL(sum(nDevBanco), 0),    ISNULL(sum(devBanCargoFijo), 0), ISNULL(sum(devBanConsumo), 0), ISNULL(sum(devBanBase), 0), ISNULL(sum(devBanImpuesto), 0), ISNULL(sum(devBanTotal), 0),
			ISNULL(sum(nDevOficina), 0),  ISNULL(sum(devOfiCargoFijo), 0), ISNULL(sum(devOfiConsumo), 0), ISNULL(sum(devOfiBase), 0), ISNULL(sum(devOfiImpuesto), 0), ISNULL(sum(devOfiTotal), 0)			
	FROM @tablaAuxiliar  
	WHERE Servicio NOT IN (1, 17, 9999)
	GROUP BY zona, periodo, periodoRegistrado, servicio, desServicio
	
	-- Insertamos todo lo que va agrupado por tarifa (todas las tarifas de servicio de Agua) junto con las entregas a cuenta	
	UNION
	
	SELECT
		-- bloqueId
		CASE WHEN zona <> '0010' THEN 1
			 ELSE 2 END,
		-- bloqueNom
		CASE WHEN periodo = 999999 THEN 'ENTREGAS A CUENTA' 
			 WHEN zona <> '0010' THEN 'CUATRIMESTRALES'
			 ELSE 'MENSUALES' END,
		periodo, periodoRegistrado, zona, tarifa, 
		CASE WHEN periodo = 999999 THEN 'ENTREGAS A CUENTA' 
			 WHEN tarifa IN(1, 3) THEN 'USO DOMÉSTICO' 
			 WHEN tarifa IN(2, 6, 5, 8) THEN 'USO INDUSTRIAL' 
		ELSE desTarifa END,					 
			ISNULL(sum(facnFacturas), 0), ISNULL(sum(facCargoFijo), 0),    ISNULL(sum(facConsumo), 0),    ISNULL(sum(facBase), 0),    ISNULL(sum(facImpuesto), 0),    ISNULL(sum(facTotal), 0),
			ISNULL(sum(anunFacturas), 0), ISNULL(sum(anuCargoFijo), 0),    ISNULL(sum(anuConsumo), 0),    ISNULL(sum(anuBase), 0),    ISNULL(sum(anuImpuesto), 0),    ISNULL(sum(anuTotal), 0),
			ISNULL(sum(crenFacturas), 0), ISNULL(sum(creCargoFijo), 0),    ISNULL(sum(creConsumo), 0),    ISNULL(sum(creBase), 0),    ISNULL(sum(creImpuesto), 0),    ISNULL(sum(creTotal), 0),
			ISNULL(sum(nCobBanco), 0),    ISNULL(sum(cobBanCargoFijo), 0), ISNULL(sum(cobBanConsumo), 0), ISNULL(sum(cobBanBase), 0), ISNULL(sum(cobBanImpuesto), 0), ISNULL(sum(cobBanTotal), 0),
			ISNULL(sum(nCobOficina), 0),  ISNULL(sum(cobOfiCargoFijo), 0), ISNULL(sum(cobOfiConsumo), 0), ISNULL(sum(cobOfiBase), 0), ISNULL(sum(cobOfiImpuesto), 0), ISNULL(sum(cobOfiTotal), 0),
			ISNULL(sum(nDevBanco), 0),    ISNULL(sum(devBanCargoFijo), 0), ISNULL(sum(devBanConsumo), 0), ISNULL(sum(devBanBase), 0), ISNULL(sum(devBanImpuesto), 0), ISNULL(sum(devBanTotal), 0),
			ISNULL(sum(nDevOficina), 0),  ISNULL(sum(devOfiCargoFijo), 0), ISNULL(sum(devOfiConsumo), 0), ISNULL(sum(devOfiBase), 0), ISNULL(sum(devOfiImpuesto), 0), ISNULL(sum(devOfiTotal), 0)			
	FROM @tablaAuxiliar  
	WHERE Servicio IN (1, 9999) 
	GROUP BY zona, periodo, periodoRegistrado, tarifa, desTarifa	
	

	-- Si el check filtrar por tarifas está activo, escribimos los filtros	
	IF @filtrar=1
	  BEGIN
		SET	@filtro= 'RSU'
		SET @filtro2= 'BONIFICACION ECOVIDRIO%'  
	  END

	-- Select para el informe, agrupamos por bloque, periodo y servicio o tarifa según corresponda
	SELECT bloqueId, bloqueNom,	
		CASE WHEN periodo = '999999' THEN 'ENTREGAS A CUENTA' 
			 WHEN periodo = '000002' THEN 'Cuatrimestral'	
			 ELSE przTipo END AS przTipo,
		CASE WHEN periodo = '000002' THEN periodoRegistrado 
			 ELSE periodo END AS periodo,  
		periodoRegistrado, desServTarifa,
			sum(facnFacturas) as facnFacturas, sum(facCargoFijo)    as facCargoFijo,    sum(facConsumo)    as facConsumo,    sum(facBase)    as facBase,    sum(facImpuesto)    as facImpuesto,    sum(facTotal) as facTotal,
			sum(anunFacturas) as anunFacturas, sum(anuCargoFijo)    as anuCargoFijo,    sum(anuConsumo)    as anuConsumo,    sum(anuBase)    as anuBase,    sum(anuImpuesto)    as anuImpuesto,    sum(anuTotal) as anuTotal,
			sum(crenFacturas) as crenFacturas, sum(creCargoFijo)    as creCargoFijo,    sum(creConsumo)    as creConsumo,    sum(creBase)    as creBase,    sum(creImpuesto)    as creImpuesto,    sum(creTotal) as creTotal,
			sum(nCobBanco)    as nCobBanco,    sum(cobBanCargoFijo) as cobBanCargoFijo, sum(cobBanConsumo) as cobBanConsumo, sum(cobBanBase) as cobBanBase, sum(cobBanImpuesto) as cobBanImpuesto, sum(cobBanTotal) as cobBanTotal,
			sum(nCobOficina)  as nCobOficina,  sum(cobOfiCargoFijo) as cobOfiCargoFijo, sum(cobOfiConsumo) as cobOfiConsumo, sum(cobOfiBase) as cobOfiBase, sum(cobOfiImpuesto) as cobOfiImpuesto, sum(cobOfiTotal) as cobOfiTotal,
			sum(nDevBanco)    as nDevBanco,    sum(devBanCargoFijo) as devBanCargoFijo, sum(devBanConsumo) as devBanConsumo, sum(devBanBase) as devBanBase, sum(devBanImpuesto) as devBanImpuesto, sum(devBanTotal) as devBanTotal,
			sum(nDevOficina)  as nDevOficina,  sum(devOfiCargoFijo) as devOfiCargoFijo, sum(devOfiConsumo) as devOfiConsumo, sum(devOfiBase) as devOfiBase, sum(devOfiImpuesto) as devOfiImpuesto, sum(devOfiTotal) as devOfiTotal
    FROM @tablaInforme
    LEFT JOIN perzona ON przCodPer = periodo AND przCodZon = zona
	WHERE ((@filtro IS NULL AND @filtro2 IS NULL) OR (UPPER(desServTarifa) = @filtro OR UPPER(desServTarifa) LIKE @filtro2 ))
    --GROUP BY bloqueId, bloqueNom, periodo, DesServTarifa, przTipo, periodoRegistrado
    --ORDER BY bloqueId, periodo, desServTarifa
	GROUP BY bloqueId
	, bloqueNom
	, CASE WHEN periodo = '000002' THEN periodoRegistrado ELSE periodo END --periodo
	, DesServTarifa
	, CASE WHEN periodo = '999999' THEN 'ENTREGAS A CUENTA' WHEN periodo = '000002' THEN 'Cuatrimestral' ELSE przTipo END --przTipo
	, periodoRegistrado
	ORDER BY  BloqueId
	, CASE WHEN periodo = '999999' THEN 'ENTREGAS A CUENTA' WHEN periodo = '000002' THEN 'Cuatrimestral' ELSE przTipo END --przTipo
	, CASE WHEN periodo = '000002' THEN periodoRegistrado ELSE periodo END --periodo
	, periodoRegistrado
	, desServTarifa




	--PRUEBA:
	--SELECT TOTAL = SUM(facTotal) 
	--, ANULADAS = SUM(anuTotal)
	--, CREADAS = SUM(creTotal) 
	--, FACT = SUM(facTotal-anuTotal+creTotal)

	--, TMENSUALES = SUM(IIF(zona='0010', facTotal, 0))
	--, AMENSUALES = SUM(IIF(zona='0010', anuTotal, 0))
	--, CMENSUALES = SUM(IIF(zona='0010', creTotal, 0))

	--, TCUATRIMESTRAL = SUM(IIF(zona<>'0010', facTotal, 0))
	--, ACUATRIMESTRAL = SUM(IIF(zona<>'0010', anuTotal, 0))
	--, CCUATRIMESTRAL = SUM(IIF(zona<>'0010', creTotal, 0))

	--, _periodo = IIF(periodo BETWEEN @periodoD AND @periodoH, @periodoD, periodoRegistrado)
	--FROM @tablaAuxiliar
	--GROUP BY IIF(periodo BETWEEN @periodoD AND @periodoH, @periodoD, periodoRegistrado)

GO


