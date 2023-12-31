ALTER PROCEDURE [dbo].[InformeSituacionTrf_AVG]
(
	@cvFecIni datetime = NULL,
	@cvFecFin datetime = NULL,
	@periodoD varchar(6) = NULL,
	@periodoH varchar(6) = NULL,
	@bajasyCambioContador bit = 1,
	@agruparServicios bit = 0,
	@incluirCanonAtipico bit = 0,
	@SituacionTarifaInformeExcel bit = 0
)
AS
	SET NOCOUNT OFF;
	
-- TODO: RECORDATORIO, SI SE INSERTA UN NUEVO SERVICIO HAY QUE MIRAR LOS PROCEDIMIENTOS ALMACENADOS PARA PONER EL CB AL NUEVO SERVICIO

BEGIN TRY
/*Valores por defecto de los parámetros*/
SET @cvFecIni = ISNULL(@cvFecIni, CAST('01/01/1901' AS DATETIME))
SET @cvFecFin = ISNULL(@cvFecFin, GETDATE())

DECLARE @date DATETIME, @time time
SET @date= @cvFecFin
SET @time='23:59:59.999'
SET @cvFecFin = @date + CAST(@time AS DATETIME)

set @bajasyCambioContador = ISNULL(@bajasyCambioContador,1);
set @agruparServicios = ISNULL(@agruparServicios,0);
set @incluirCanonAtipico = ISNULL(@incluirCanonAtipico,1);
set @SituacionTarifaInformeExcel = ISNULL(@SituacionTarifaInformeExcel,0);

DECLARE @filtro VARCHAR(10)= null 
DECLARE @filtro2 VARCHAR(50)= null 

DECLARE @tablaAuxiliar as 
		TABLE (
		periodo varchar(6),
		periodoRegistrado varchar(6),
		periodoReferencia varchar(6),
		zona varchar(4),
		servicio int ,
		tarifa int,
		desTarifa varchar(75),
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
		devOfiTotal money default 0

           
        --,primary key(periodo, periodoRegistrado, periodoReferencia, Zona, Servicio, Tarifa, ppago, tipImpuesto)
		)
		
DECLARE @tablaInforme as 
		TABLE (
		bloqueId tinyint,
		bloqueNom varchar(60),
		
		periodo  varchar(6), 
		periodoRegistrado varchar(6),
		periodoReferencia varchar(6),
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
 DECLARE @ctrversion as SMALLINT	
 DECLARE @serie as SMALLINT	
 DECLARE @cliCod as SMALLINT
 DECLARE @lineaCobro as SMALLINT	
 DECLARE @cobNum as int        
 DECLARE @periodo as varchar(6)
 DECLARE @periodoRegistrado as varchar(6)
 DECLARE @periodoReferencia as varchar(6)
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
 
 DECLARE @perInicioDeuda varchar(6) = '200501'
 DECLARE @fecFinMigracion datetime = '05/03/2019'

DECLARE @explotacion varchar(100) = NULL
SELECT @explotacion = pgsValor FROM parametros WHERE pgsClave = 'EXPLOTACION'

DECLARE @servicioFianza INT = NULL
IF 'AVG' <> @explotacion BEGIN
	 SELECT @servicioFianza = pgsValor FROM parametros WHERE pgsClave='SERVICIO_FIANZA'
END
		
If((@periodoD between '000013' and '000015') and (@periodoH between '000013' and '000015'))
begin 
	set @bajasyCambioContador = 0
	set @incluirCanonAtipico = 1
end

If((@periodoD between '000005' and '000005'))
begin 
	set @bajasyCambioContador = 0
	set @incluirCanonAtipico = 0
end

IF(@bajasyCambioContador = 1)
BEGIN
	--Insertamos Bajas y consumos parciales de antes de cambios de contador -> (periodo ='000002' OR periodo = '000001')
	 -- insertamos distintos de bajas, tanto periodos normales como de contado altas '000005' convirtiendo periodo a año-mes
	 INSERT INTO @tablaAuxiliar (periodo, zona, servicio, tarifa, ppago, tipImpuesto, desServicio, desTarifa, facnFacturas,facCargoFijo,facConsumo,facBase,facImpuesto,facTotal, periodoRegistrado, periodoReferencia)
	SELECT
		"Periodo", isnull(faczoncod,''), "Servicio", fcltrfcod, SUM(ppag), fclImpuesto, "Des. Servicio", "Des. Tarifa", 
		SUM("N. Facturas"), SUM("Cargo Fijo"), SUM("Consumo"),	SUM("Base"), SUM("Impuesto"), SUM("Total"), ISNULL(periodoRegistrado,''), ISNULL(periodoReferencia,'')
	FROM
	(
		SELECT fclfacpercod AS "Periodo", f1.faczoncod, fcltrfsvcod AS "Servicio", fcltrfcod, 0 AS ppag, fclImpuesto, svcdes AS "Des. Servicio", trfdes AS "Des. Tarifa",
			COUNT(*) AS "N. Facturas",
			CAST(SUM(ROUND(fclunidades*fclprecio, 4)) as decimal(12,4)) as "Cargo Fijo",
			CAST(SUM(ROUND(fclunidades1*fclprecio1, 4) + ROUND(fclunidades2*fclprecio2, 4) + ROUND(fclunidades3*fclprecio3, 4) + ROUND(fclunidades4*fclprecio4, 4) + ROUND(fclunidades5*fclprecio5, 4)) AS DECIMAL(12,4)) AS "Consumo",
			SUM(fclbase) AS "Base",
			SUM(fclimpimpuesto) AS "Impuesto",
			SUM(fcltotal) AS "Total",
			(CASE
				--new
				WHEN (fclfacpercod LIKE '0%' AND f1.facFecha < @fecFinMigracion AND f1.facSerCod IN (12, 13, 14, 17)) THEN
					(SELECT dbo.fnPeriodoFacturaOriginal(f1.facpercod, f1.facCtrCod , f1.facClicod, f1.facSerCod-10))
				--end new
				--new2
				WHEN (fclfacpercod='000002' OR fclfacpercod='000001') AND month(f1.facfecha)<= 3 THEN convert( VARCHAR, year (f1.facfecha)) ++ '01'
				WHEN (fclfacpercod='000002' OR fclfacpercod='000001') AND month(f1.facfecha)>= 4 and month(f1.facfecha) < 7 THEN  convert( VARCHAR, year (f1.facfecha)) ++ '02'
				WHEN (fclfacpercod='000002' OR fclfacpercod='000001') AND month(f1.facfecha)>= 7 and month(f1.facfecha) < 10 THEN  convert( VARCHAR, year (f1.facfecha)) ++ '03'
				WHEN (fclfacpercod='000002' OR fclfacpercod='000001') AND month(f1.facfecha)>= 10 THEN convert( VARCHAR, year (f1.facfecha) ) ++ '04'
				--end new2
				WHEN (fclfacpercod LIKE '0%')
					THEN convert( VARCHAR, year (f1.facfecha) ) ++ RIGHT('0' + RTRIM(MONTH(f1.facfecha)), 2)
				ELSE fclfacpercod END) AS periodoRegistrado,
			(CASE
				--de contado
				WHEN (fclfacpercod LIKE '0%')
					THEN convert( VARCHAR, year (f1.facfecha) ) ++ RIGHT('0' + RTRIM(MONTH(f1.facfecha)), 2)			     
				--de consumo
				WHEN fclfacpercod NOT LIKE '0%' AND substring(f1.facpercod,5,2) = '01'
					THEN substring(f1.facpercod,1,4) ++ '03'
				WHEN fclfacpercod NOT LIKE '0%' AND substring(f1.facpercod,5,2) = '02'
					THEN substring(f1.facpercod,1,4) ++ '06'
				WHEN fclfacpercod NOT LIKE '0%' AND substring(f1.facpercod,5,2) = '03'
					THEN substring(f1.facpercod,1,4) ++ '09'
				WHEN fclfacpercod NOT LIKE '0%' AND substring(f1.facpercod,5,2) = '04'
					THEN substring(f1.facpercod,1,4) ++ '12' END) AS periodoReferencia
		FROM faclin 
		INNER JOIN facturas f1 ON fclfaccod = faccod AND
									   fclfacpercod = facpercod AND 
									   fclfacctrcod = facctrcod AND 
									   fclfacversion = facversion 
				AND (
				facpercod >= @perInicioDeuda
				OR
				facpercod like '0000%'
				)
				and (facpercod='000002' OR facpercod='000001')
				AND facversion = 1
				AND facfecha BETWEEN CAST(@cvFecIni AS DATETIME) AND CAST(@cvFecFin AS DATETIME)
				AND facnumero IS NOT NULL
			INNER JOIN servicios ON svccod = fcltrfsvcod
			INNER JOIN tarifas ON trfsrvcod = fcltrfsvcod AND trfCod = fcltrfcod
			INNER JOIN facturas f2 ON f1.faccod = f2.faccod AND f1.facpercod = f2.facpercod AND f1.facctrcod = f2.facctrcod AND f2.facversion = 1
		WHERE (fclfacpercod='000002' OR fclfacpercod='000001') and ((fclFecLiq>=@cvFecFin) OR (fclFecLiq IS NULL AND fclUsrLiq IS NULL)) AND (@servicioFianza IS NULL OR fclTrfSvCod <> @servicioFianza)
		GROUP BY fclfacpercod, f1.faczoncod, fcltrfsvcod, fcltrfcod, fclimpuesto, svcdes, trfdes, f2.facFecha, f1.facFecha, f1.facPerCod
			--new
				,f1.facCtrCod, f1.facCliCod, f1.facSerCod, f1.facCod
			--end new
	) AS tabla
	GROUP BY "Periodo", faczoncod, "Servicio", fcltrfcod, fclimpuesto, "Des. Servicio", "Des. Tarifa", periodoRegistrado, periodoReferencia
	ORDER BY "Periodo", faczoncod, "Servicio", fcltrfcod, fclimpuesto, "Des. Servicio", "Des. Tarifa"
END

If(@incluirCanonAtipico = 1)
BEGIN

 INSERT INTO @tablaAuxiliar (periodo, zona, servicio, tarifa, ppago, tipImpuesto, desServicio, desTarifa, facnFacturas,facCargoFijo,facConsumo,facBase,facImpuesto,facTotal, periodoRegistrado, periodoReferencia)
SELECT
	"Periodo", isnull(faczoncod,''), "Servicio", fcltrfcod, SUM(ppag), fclImpuesto, "Des. Servicio", "Des. Tarifa", 
	SUM("N. Facturas"), SUM("Cargo Fijo"), SUM("Consumo"),	SUM("Base"), SUM("Impuesto"), SUM("Total"), ISNULL(periodoRegistrado,''), ISNULL(periodoReferencia,'')
FROM
(
	SELECT fclfacpercod AS "Periodo", f1.faczoncod, fcltrfsvcod AS "Servicio", fcltrfcod, 0 AS ppag, fclImpuesto, svcdes AS "Des. Servicio", trfdes AS "Des. Tarifa",
		COUNT(*) AS "N. Facturas",
		CAST(SUM(ROUND(fclunidades*fclprecio, 4)) as decimal(12,4)) as "Cargo Fijo",
		CAST(SUM(ROUND(fclunidades1*fclprecio1, 4) + ROUND(fclunidades2*fclprecio2, 4) + ROUND(fclunidades3*fclprecio3, 4) + ROUND(fclunidades4*fclprecio4, 4) + ROUND(fclunidades5*fclprecio5, 4)) AS DECIMAL(12,4)) AS "Consumo",
		SUM(fclbase) AS "Base",
		SUM(fclimpimpuesto) AS "Impuesto",
		SUM(fcltotal) AS "Total",
		(CASE 			
			--new
			WHEN (fclfacpercod LIKE '0%' AND f1.facFecha < @fecFinMigracion AND f1.facSerCod IN (12, 13, 14, 17)) THEN
				(SELECT dbo.fnPeriodoFacturaOriginal(f1.facpercod, f1.facCtrCod , f1.facClicod, f1.facSerCod-10))
			--end new
			--new2
			WHEN (fclfacpercod='000002' OR fclfacpercod='000001') AND month(f1.facfecha)<= 3 THEN convert( VARCHAR, year (f1.facfecha)) ++ '01'
			WHEN (fclfacpercod='000002' OR fclfacpercod='000001') AND month(f1.facfecha)>= 4 and month(f1.facfecha) < 7 THEN  convert( VARCHAR, year (f1.facfecha)) ++ '02'
			WHEN (fclfacpercod='000002' OR fclfacpercod='000001') AND month(f1.facfecha)>= 7 and month(f1.facfecha) < 10 THEN  convert( VARCHAR, year (f1.facfecha)) ++ '03'
			WHEN (fclfacpercod='000002' OR fclfacpercod='000001') AND month(f1.facfecha)>= 10 THEN convert( VARCHAR, year (f1.facfecha) ) ++ '04'
			--end new2

			WHEN (fclfacpercod LIKE '0%')
			    THEN convert( VARCHAR, year (f1.facfecha) ) ++ RIGHT('0' + RTRIM(MONTH(f1.facfecha)), 2)
	        ELSE fclfacpercod END) AS periodoRegistrado,
		(CASE
			--de contado
			WHEN (fclfacpercod LIKE '0%')
				THEN convert( VARCHAR, year (f1.facfecha) ) ++ RIGHT('0' + RTRIM(MONTH(f1.facfecha)), 2)			     
			--de consumo
			WHEN fclfacpercod NOT LIKE '0%' AND substring(f1.facpercod,5,2) = '01'
				THEN substring(f1.facpercod,1,4) ++ '03'
			WHEN fclfacpercod NOT LIKE '0%' AND substring(f1.facpercod,5,2) = '02'
				THEN substring(f1.facpercod,1,4) ++ '06'
			WHEN fclfacpercod NOT LIKE '0%' AND substring(f1.facpercod,5,2) = '03'
				THEN substring(f1.facpercod,1,4) ++ '09'
			WHEN fclfacpercod NOT LIKE '0%' AND substring(f1.facpercod,5,2) = '04'
				THEN substring(f1.facpercod,1,4) ++ '12' END) AS periodoReferencia
	FROM faclin
	INNER JOIN facturas f1 ON fclfaccod = faccod AND
								   fclfacpercod = facpercod AND
								   fclfacctrcod = facctrcod AND
								   fclfacversion = facversion
			AND (
			facpercod >= @perInicioDeuda
			OR
			facpercod like '0000%'
			)			
			and ((facPerCod = '000013') or (facPerCod = '000015'))
			AND facversion = 1
			AND facfecha BETWEEN CAST(@cvFecIni AS DATETIME) AND CAST(@cvFecFin AS DATETIME)
			AND facnumero IS NOT NULL
		INNER JOIN servicios ON svccod = fcltrfsvcod
		INNER JOIN tarifas ON trfsrvcod = fcltrfsvcod AND trfCod = fcltrfcod
		INNER JOIN facturas f2 ON f1.faccod = f2.faccod AND f1.facpercod = f2.facpercod AND f1.facctrcod = f2.facctrcod AND f2.facversion = 1
	WHERE ((fclFecLiq>=@cvFecFin) OR (fclFecLiq IS NULL AND fclUsrLiq IS NULL)) AND (@servicioFianza IS NULL OR fclTrfSvCod <> @servicioFianza)
	GROUP BY fclfacpercod, f1.faczoncod, fcltrfsvcod, fcltrfcod, fclimpuesto, svcdes, trfdes, f2.facFecha, f1.facFecha, f1.facPerCod
		--new
			,f1.facCtrCod, f1.facClicod, f1.facSerCod, f1.facCod
		--end new
) AS tabla
GROUP BY "Periodo", faczoncod, "Servicio", fcltrfcod, fclimpuesto, "Des. Servicio", "Des. Tarifa", periodoRegistrado, periodoReferencia
ORDER BY "Periodo", faczoncod, "Servicio", fcltrfcod, fclimpuesto, "Des. Servicio", "Des. Tarifa"

END

 -- insertamos distintos de bajas y canon atípico, tanto periodos normales como de contado altas '000001' convirtiendo periodo a año-mes
 INSERT INTO @tablaAuxiliar (periodo, zona, servicio, tarifa, ppago, tipImpuesto, desServicio, desTarifa, facnFacturas,facCargoFijo,facConsumo,facBase,facImpuesto,facTotal, periodoRegistrado, periodoReferencia)
SELECT
	"Periodo", isnull(faczoncod,''), "Servicio", fcltrfcod, SUM(ppag), fclImpuesto, "Des. Servicio", "Des. Tarifa", 
	SUM("N. Facturas"), SUM("Cargo Fijo"), SUM("Consumo"),	SUM("Base"), SUM("Impuesto"), SUM("Total"), ISNULL(periodoRegistrado,''), ISNULL(periodoReferencia,'')
FROM
(
	SELECT fclfacpercod AS "Periodo", f1.faczoncod, fcltrfsvcod AS "Servicio", fcltrfcod, 0 AS ppag, fclImpuesto, svcdes AS "Des. Servicio", trfdes AS "Des. Tarifa",
		COUNT(*) AS "N. Facturas",
		CAST(SUM(ROUND(fclunidades*fclprecio, 4)) as decimal(12,4)) as "Cargo Fijo",
		CAST(SUM(ROUND(fclunidades1*fclprecio1, 4) + ROUND(fclunidades2*fclprecio2, 4) + ROUND(fclunidades3*fclprecio3, 4) + ROUND(fclunidades4*fclprecio4, 4) + ROUND(fclunidades5*fclprecio5, 4)) AS DECIMAL(12,4)) AS "Consumo",
		SUM(fclbase) AS "Base",
		SUM(fclimpimpuesto) AS "Impuesto",
		SUM(fcltotal) AS "Total",
		(CASE 			
			--new
			WHEN (fclfacpercod LIKE '0%' AND f1.facFecha < @fecFinMigracion AND f1.facSerCod IN (12, 13, 14, 17)) THEN
				(SELECT dbo.fnPeriodoFacturaOriginal(f1.facpercod, f1.facCtrCod , f1.facClicod, f1.facSerCod-10))
			--end new
			--new2
			WHEN (fclfacpercod='000002' OR fclfacpercod='000001') AND month(f1.facfecha)<= 3 THEN convert( VARCHAR, year (f1.facfecha)) ++ '01'
			WHEN (fclfacpercod='000002' OR fclfacpercod='000001') AND month(f1.facfecha)>= 4 and month(f1.facfecha) < 7 THEN  convert( VARCHAR, year (f1.facfecha)) ++ '02'
			WHEN (fclfacpercod='000002' OR fclfacpercod='000001') AND month(f1.facfecha)>= 7 and month(f1.facfecha) < 10 THEN  convert( VARCHAR, year (f1.facfecha)) ++ '03'
			WHEN (fclfacpercod='000002' OR fclfacpercod='000001') AND month(f1.facfecha)>= 10 THEN convert( VARCHAR, year (f1.facfecha) ) ++ '04'
			--end new2

			WHEN (fclfacpercod LIKE '0%')
			    THEN convert( VARCHAR, year (f1.facfecha) ) ++ RIGHT('0' + RTRIM(MONTH(f1.facfecha)), 2)
	        ELSE fclfacpercod END) AS periodoRegistrado,
		(CASE
			--de contado
			WHEN (fclfacpercod LIKE '0%')
				THEN convert( VARCHAR, year (f1.facfecha) ) ++ RIGHT('0' + RTRIM(MONTH(f1.facfecha)), 2)			     
			--de consumo
			WHEN fclfacpercod NOT LIKE '0%' AND substring(f1.facpercod,5,2) = '01'
				THEN substring(f1.facpercod,1,4) ++ '03'
			WHEN fclfacpercod NOT LIKE '0%' AND substring(f1.facpercod,5,2) = '02'
				THEN substring(f1.facpercod,1,4) ++ '06'
			WHEN fclfacpercod NOT LIKE '0%' AND substring(f1.facpercod,5,2) = '03'
				THEN substring(f1.facpercod,1,4) ++ '09'
			WHEN fclfacpercod NOT LIKE '0%' AND substring(f1.facpercod,5,2) = '04'
				THEN substring(f1.facpercod,1,4) ++ '12' END) AS periodoReferencia
	FROM faclin
	INNER JOIN facturas f1 ON fclfaccod = faccod AND
								   fclfacpercod = facpercod AND
								   fclfacctrcod = facctrcod AND
								   fclfacversion = facversion
			AND (
			facpercod >= @perInicioDeuda
			OR
			facpercod like '0000%'
			)			
			and (facpercod <> '000002') 
			and (facpercod <> '000001') 
			and (facPerCod <> '000013')
			and (facPerCod <> '000015')
			and (facpercod >= @periodoD or @periodoD is null)
			and (facpercod <= @periodoH or @periodoH is null)
			AND facversion = 1
			AND facfecha BETWEEN CAST(@cvFecIni AS DATETIME) AND CAST(@cvFecFin AS DATETIME)
			AND facnumero IS NOT NULL
		INNER JOIN servicios ON svccod = fcltrfsvcod
		INNER JOIN tarifas ON trfsrvcod = fcltrfsvcod AND trfCod = fcltrfcod
		INNER JOIN facturas f2 ON f1.faccod = f2.faccod AND f1.facpercod = f2.facpercod AND f1.facctrcod = f2.facctrcod AND f2.facversion = 1
	WHERE ((fclFecLiq>=@cvFecFin) OR (fclFecLiq IS NULL AND fclUsrLiq IS NULL)) AND (@servicioFianza IS NULL OR fclTrfSvCod <> @servicioFianza)
	GROUP BY fclfacpercod, f1.faczoncod, fcltrfsvcod, fcltrfcod, fclimpuesto, svcdes, trfdes, f2.facFecha, f1.facFecha, f1.facPerCod
		--new
			,f1.facCtrCod, f1.facClicod, f1.facSerCod, f1.facCod
		--end new
) AS tabla
GROUP BY "Periodo", faczoncod, "Servicio", fcltrfcod, fclimpuesto, "Des. Servicio", "Des. Tarifa", periodoRegistrado, periodoReferencia
ORDER BY "Periodo", faczoncod, "Servicio", fcltrfcod, fclimpuesto, "Des. Servicio", "Des. Tarifa"

 SET @nFacturas = 0 
 SET @CargoFijo = 0 
 SET @Consumo = 0
 SET @Base = 0 
 SET @Impuesto = 0
 SET @Total = 0

    DECLARE cAnulado CURSOR FOR
    SELECT
		"Periodo", faczoncod, "Servicio", fcltrfcod, fclImpuesto, "Des. Servicio", "Des. Tarifa", 
		SUM("N. Facturas"), SUM("Cargo Fijo"), SUM("Consumo"),	SUM("Base"), SUM("Impuesto"), SUM("Total"), periodoRegistrado, periodoReferencia
	FROM
	(
		SELECT fclfacpercod AS "Periodo", f1.faczoncod, fcltrfsvcod AS "Servicio", fcltrfcod, fclImpuesto ,svcdes AS "Des. Servicio", trfdes AS "Des. Tarifa",
			COUNT(*) AS "N. Facturas",
			CAST(SUM(ROUND(fclunidades*fclprecio, 4)) AS DECIMAL(12,4)) AS "Cargo Fijo",
			CAST(SUM(ROUND(fclunidades1*fclprecio1, 4) + ROUND(fclunidades2*fclprecio2, 4) + ROUND(fclunidades3*fclprecio3, 4) + ROUND(fclunidades4*fclprecio4, 4) + ROUND(fclunidades5*fclprecio5, 4) ) AS DECIMAL(12,4)) AS "Consumo", 
			SUM(fclbase) AS "Base", 
			SUM(fclimpimpuesto) AS "Impuesto" ,
			SUM(fcltotal) AS "Total",
			(CASE 
				--new
				WHEN (fclfacpercod LIKE '0%' AND f1.facFecha < @fecFinMigracion AND f1.facSerCod IN (12, 13, 14, 17)) THEN
					(SELECT dbo.fnPeriodoFacturaOriginal(f1.facpercod, f1.facCtrCod , f1.facClicod, f1.facSerCod-10))
				--end new
				--new2
				WHEN (fclfacpercod='000002' OR fclfacpercod='000001') AND month(f1.facFechaRectif)<= 3 THEN convert( VARCHAR, year (f1.facFechaRectif)) ++ '01'
				WHEN (fclfacpercod='000002' OR fclfacpercod='000001') AND month(f1.facFechaRectif)>= 4 and month(f1.facFechaRectif) < 7 THEN  convert( VARCHAR, year (f1.facFechaRectif)) ++ '02'
				WHEN (fclfacpercod='000002' OR fclfacpercod='000001') AND month(f1.facFechaRectif)>= 7 and month(f1.facFechaRectif) < 10 THEN  convert( VARCHAR, year (f1.facFechaRectif)) ++ '03'
				WHEN (fclfacpercod='000002' OR fclfacpercod='000001') AND month(f1.facFechaRectif)>= 10 THEN convert( VARCHAR, year (f1.facFechaRectif) ) ++ '04'
				--end new2
				WHEN (fclfacpercod LIKE '0%')
			       THEN convert( VARCHAR, year (f1.facFechaRectif) ) ++ RIGHT('0' + RTRIM(MONTH(f1.facFechaRectif)), 2)
			    ELSE fclfacpercod END) AS periodoRegistrado,
			(CASE
				--de contado
				WHEN (fclfacpercod LIKE '0%')
					THEN convert( VARCHAR, year (f1.facFechaRectif) ) ++ RIGHT('0' + RTRIM(MONTH(f1.facFechaRectif)), 2)			     
				--de consumo		     
				WHEN fclfacpercod NOT LIKE '0%' AND substring(f1.facpercod,5,2) = '01'
					THEN substring(f1.facpercod,1,4) ++ '03'
				WHEN fclfacpercod NOT LIKE '0%' AND substring(f1.facpercod,5,2) = '02'
					THEN substring(f1.facpercod,1,4) ++ '06'
				WHEN fclfacpercod NOT LIKE '0%' AND substring(f1.facpercod,5,2) = '03'
					THEN substring(f1.facpercod,1,4) ++ '09'
				WHEN fclfacpercod NOT LIKE '0%' AND substring(f1.facpercod,5,2) = '04'
				THEN substring(f1.facpercod,1,4) ++ '12' END) AS periodoReferencia
		FROM faclin 
			INNER JOIN facturas f1 ON fclfaccod = faccod AND 
								   fclfacpercod = facpercod AND 
								   fclfacctrcod = facctrcod AND 
								   fclfacversion = facversion 
				AND (
						facpercod >= @perInicioDeuda 
						OR
						facpercod like '0000%'
					)
				and (facpercod >= @periodoD or @periodoD is null)
				and (facpercod <= @periodoH or @periodoH is null)
			AND facFechaRectif BETWEEN CAST(@cvFecIni AS DATETIME) AND CAST(@cvFecFin AS DATETIME)
			AND facnumero IS NOT NULL
			INNER JOIN servicios ON svccod = fcltrfsvcod
			INNER JOIN tarifas ON trfsrvcod = fcltrfsvcod AND trfCod = fcltrfcod
			INNER JOIN facturas f2 ON f1.faccod = f2.faccod AND f1.facpercod = f2.facpercod AND f1.facctrcod = f2.facctrcod AND f2.facversion = 1
		WHERE ((fclFecLiq>=@cvFecFin) OR (fclFecLiq IS NULL AND fclUsrLiq IS NULL)) AND (@servicioFianza IS NULL OR fclTrfSvCod <> @servicioFianza)
		GROUP BY fclfacpercod, f1.faczoncod, fcltrfsvcod, fcltrfcod, fclimpuesto, svcdes, trfdes, f2.facFecha, f1.facFecha, f1.facFechaRectif, f1.facPerCod
		--new
			,f1.facCtrCod, f1.facCliCod, f1.facSerCod, f1.facCod
		--end new
	) AS tabla
	GROUP BY "Periodo", faczoncod, "Servicio", fcltrfcod, fclImpuesto, "Des. Servicio", "Des. Tarifa", periodoRegistrado, periodoReferencia
	ORDER BY "Periodo", faczoncod, "Servicio", fcltrfcod, fclImpuesto, "Des. Servicio", "Des. Tarifa"

    OPEN cAnulado
    FETCH NEXT FROM cAnulado
    INTO  @periodo, @Zona, @Servicio, @Tarifa, @tipImpuesto, @DesServicio, @DesTarifa, @nFacturas, @CargoFijo, @Consumo, @Base, @Impuesto, @Total, @periodoRegistrado, @periodoReferencia
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
        INSERT INTO @tablaAuxiliar (periodo, periodoRegistrado, periodoReferencia, zona, servicio, tarifa, ppago, tipImpuesto, desServicio, desTarifa, anunFacturas,anuCargoFijo,anuConsumo,anuBase,anuImpuesto,anuTotal)
        VALUES (@periodo, ISNULL(@periodoRegistrado,''), @periodoReferencia, @Zona, @Servicio, @Tarifa, 0, @tipImpuesto, @DesServicio, @DesTarifa, @nFacturas, @CargoFijo, @Consumo, @Base, @Impuesto, @Total)

        FETCH NEXT FROM cAnulado
        INTO  @periodo, @Zona, @Servicio, @Tarifa, @tipImpuesto, @DesServicio, @DesTarifa, @nFacturas, @CargoFijo, @Consumo, @Base, @Impuesto, @Total, @periodoRegistrado, @periodoReferencia
    END

    CLOSE cAnulado
    DEALLOCATE cAnulado


 SET @nFacturas = 0 
 SET @CargoFijo = 0 
 SET @Consumo = 0
 SET @Base = 0 
 SET @Impuesto = 0
 SET @Total = 0

    DECLARE cCreado CURSOR FOR
    SELECT
		"Periodo", faczoncod, "Servicio", fcltrfcod, fclImpuesto, "Des. Servicio", "Des. Tarifa", 
		SUM("N. Facturas"), SUM("Cargo Fijo"), SUM("Consumo"),	SUM("Base"), SUM("Impuesto"), SUM("Total"), periodoRegistrado, periodoReferencia
	FROM
	(
		SELECT fclfacpercod AS "Periodo", f1.faczoncod, fcltrfsvcod AS "Servicio", fcltrfcod, fclimpuesto, svcdes AS "Des. Servicio", trfdes AS "Des. Tarifa",
			count(*) as "N. Facturas",
			CAST(SUM(ROUND(fclunidades*fclprecio, 4)) AS DECIMAL(12,4)) AS "Cargo Fijo",
			CAST(SUM(ROUND(fclunidades1*fclprecio1, 4) + ROUND(fclunidades2*fclprecio2, 4) + ROUND(fclunidades3*fclprecio3, 4) + ROUND(fclunidades4*fclprecio4, 4) + ROUND(fclunidades5*fclprecio5, 4) ) AS DECIMAL(12,4)) AS "Consumo", 
			SUM(fclbase) AS "Base", 
			SUM(fclimpimpuesto) AS "Impuesto" ,
			SUM(fcltotal) AS "Total",
			(CASE 
				--new
				WHEN (fclfacpercod LIKE '0%' AND f1.facFecha < @fecFinMigracion AND f1.facSerCod IN (12, 13, 14, 17)) THEN
					(SELECT dbo.fnPeriodoFacturaOriginal(f1.facpercod, f1.facCtrCod , f1.facClicod, f1.facSerCod-10))
				--end new
				--new2
				WHEN (fclfacpercod='000002' OR fclfacpercod='000001') AND month(f1.facfecha)<= 3 THEN convert( VARCHAR, year (f1.facfecha)) ++ '01'
				WHEN (fclfacpercod='000002' OR fclfacpercod='000001') AND month(f1.facfecha)>= 4 and month(f1.facfecha) < 7 THEN  convert( VARCHAR, year (f1.facfecha)) ++ '02'
				WHEN (fclfacpercod='000002' OR fclfacpercod='000001') AND month(f1.facfecha)>= 7 and month(f1.facfecha) < 10 THEN  convert( VARCHAR, year (f1.facfecha)) ++ '03'
				WHEN (fclfacpercod='000002' OR fclfacpercod='000001') AND month(f1.facfecha)>= 10 THEN convert( VARCHAR, year (f1.facfecha) ) ++ '04'
				--end new2

				WHEN (fclfacpercod LIKE '0%')
					THEN convert( VARCHAR, year (f1.facfecha) ) ++ RIGHT('0' + RTRIM(MONTH(f1.facfecha)), 2)
				ELSE fclfacpercod END) AS periodoRegistrado,
			(CASE
				--de contado	
				WHEN (fclfacpercod LIKE '0%')
					THEN convert( VARCHAR, year (f1.facfecha) ) ++ RIGHT('0' + RTRIM(MONTH(f1.facfecha)), 2)			     
				--de consumo
				WHEN fclfacpercod NOT LIKE '0%' AND substring(f1.facpercod,5,2) = '01'
					THEN substring(f1.facpercod,1,4) ++ '03'
				WHEN fclfacpercod NOT LIKE '0%' AND substring(f1.facpercod,5,2) = '02'
					THEN substring(f1.facpercod,1,4) ++ '06'
				WHEN fclfacpercod NOT LIKE '0%' AND substring(f1.facpercod,5,2) = '03'
					THEN substring(f1.facpercod,1,4) ++ '09'
				WHEN fclfacpercod NOT LIKE '0%' AND substring(f1.facpercod,5,2) = '04'
					THEN substring(f1.facpercod,1,4) ++ '12' END) AS periodoReferencia
		FROM faclin 
			INNER JOIN facturas f1 ON fclfaccod = faccod AND fclfacpercod = facpercod AND fclfacctrcod = facctrcod AND fclfacversion = facversion 
				AND (
					facpercod >= @perInicioDeuda
					OR
					facpercod like '0000%'
					)
				and (facpercod >= @periodoD or @periodoD is null)
				and (facpercod <= @periodoH or @periodoH is null)
				AND facversion > 1
				AND facfecha BETWEEN CAST(@cvFecIni AS DATETIME) AND CAST(@cvFecFin AS DATETIME)
				AND facnumero IS NOT NULL
			INNER JOIN servicios on svccod = fcltrfsvcod
			INNER JOIN tarifas ON trfsrvcod = fcltrfsvcod AND trfCod = fcltrfcod
			INNER JOIN facturas f2 ON f1.faccod = f2.faccod AND f1.facpercod = f2.facpercod AND f1.facctrcod = f2.facctrcod AND f2.facversion = 1
		WHERE ((fclFecLiq>=@cvFecFin) OR (fclFecLiq IS NULL AND fclUsrLiq IS NULL)) AND (@servicioFianza IS NULL OR fclTrfSvCod <> @servicioFianza)
		GROUP BY fclfacpercod, f1.faczoncod, fcltrfsvcod, fcltrfcod, fclimpuesto, svcdes, trfdes, f2.facFecha, f1.facFecha, f1.facPerCod
		--new
			,f1.facCtrCod, f1.facClicod, f1.facSerCod, f1.facCod
		--end new
	) AS tabla
	GROUP BY "Periodo", faczoncod, "Servicio", fcltrfcod, fclimpuesto, "Des. Servicio", "Des. Tarifa", periodoRegistrado, periodoReferencia
	ORDER BY "Periodo", faczoncod, "Servicio", fcltrfcod, fclimpuesto, "Des. Servicio", "Des. Tarifa"
    OPEN cCreado 
    FETCH NEXT FROM cCreado 
    INTO  @periodo, @Zona, @Servicio, @Tarifa, @tipImpuesto, @DesServicio, @DesTarifa, @nFacturas, @CargoFijo, @Consumo, @Base, @Impuesto, @Total, @periodoRegistrado, @periodoReferencia
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
        INSERT INTO @tablaAuxiliar (periodo, periodoRegistrado, periodoReferencia, zona, servicio, tarifa, ppago, tipImpuesto, desServicio, desTarifa, crenFacturas,creCargoFijo,creConsumo,creBase,creImpuesto,creTotal)
        VALUES (@periodo, ISNULL(@periodoRegistrado,''), @periodoReferencia, @Zona, @Servicio, @Tarifa, 0, @tipImpuesto, @DesServicio, @DesTarifa, @nFacturas, @CargoFijo, @Consumo, @Base, @Impuesto, @Total)

        FETCH NEXT FROM cCreado 
        INTO  @periodo, @Zona, @Servicio, @Tarifa, @tipImpuesto, @DesServicio, @DesTarifa, @nFacturas, @CargoFijo, @Consumo, @Base, @Impuesto, @Total, @periodoRegistrado, @periodoReferencia
    END

    CLOSE cCreado 
    DEALLOCATE cCreado 


SET @nFacturas = 0 
	SET @cobrado = 0
	SET @tipo = 0 

	DECLARE cCobrado CURSOR FOR 
	WITH COBS AS(
	SELECT cobctr, ctrZonCod, cobfec, cblper, cblfaccod, cblimporte, ppebca, cobppag, cobnum, cobScd, cblLin, cblFacVersion
	, ISNULL(F.facFecha, cobfec) AS fecha --El cobro debe ir con la fecha de la factura
	,facSerCod, facClicod
	FROM cobros
	INNER JOIN contratos c1 ON ctrcod = cobCtr AND ctrversion=(SELECT MAX(c2.ctrversion) FROM contratos c2 WHERE c2.ctrcod = c1.ctrcod)
	INNER JOIN coblin ON cblScd = cobScd
					AND	 cblPpag = cobPpag
					AND	 cblNum = cobnum
					AND	(cblper >= @perInicioDeuda OR cblper like '0000%' OR cblper = '999999')
					AND (cblper >= @periodoD or @periodoD is null)
					AND (cblper <= @periodoH or @periodoH is null)
	INNER JOIN ppagos ON ppagcod = cobppag
	INNER JOIN ppentidades ON ppecod = ppagppcppeCod
	LEFT JOIN facturas AS F
		ON f.facCod = cblFacCod
		AND f.facPerCod = cblPer
		AND f.facCtrCod = cobCtr
		AND f.facVersion = cblFacVersion
	WHERE cobfec BETWEEN CAST(@cvFecIni AS DATETIME) AND CAST(@cvFecFin AS DATETIME))
	
	SELECT cobctr, ctrZonCod, cobfec, cblper, cblfaccod, cblimporte, ppebca, cobppag, cobnum, cobScd, cblLin, cblFacVersion
	, periodoRegistrado = 
	  CASE 
		    --new
			WHEN (cblPer LIKE '0%' AND fecha < @fecFinMigracion AND facSerCod IN (12, 13, 14, 17)) THEN
				(SELECT dbo.fnPeriodoFacturaOriginal(cblPer, cobctr , facClicod, facSerCod-10))
			--end new
			--new2
			WHEN (cblPer='000002' OR cblPer='000001') AND month(fecha)<= 3 THEN convert( VARCHAR, year (fecha)) ++ '01'
			WHEN (cblPer='000002' OR cblPer='000001') AND month(fecha)>= 4 and month(fecha) < 7 THEN  convert( VARCHAR, year (fecha)) ++ '02'
			WHEN (cblPer='000002' OR cblPer='000001') AND month(fecha)>= 7 and month(fecha) < 10 THEN  convert( VARCHAR, year (fecha)) ++ '03'
			WHEN (cblPer='000002' OR cblPer='000001') AND month(fecha)>= 10 THEN convert( VARCHAR, year (fecha) ) ++ '04'
			--end new2

		  WHEN cblper LIKE '0%' 
	  THEN convert( VARCHAR, year (fecha) ) ++ RIGHT('0' + RTRIM(MONTH(fecha)), 2)
	  ELSE cblper END 
	 , periodoReferencia = 
	  CASE 
		  --de contado
		  WHEN cblper LIKE '0%' 
				THEN convert( VARCHAR, year (fecha) ) ++ RIGHT('0' + RTRIM(MONTH(fecha)), 2)

		  --de consumo
		  WHEN cblper NOT LIKE '0%' AND substring(cblper,5,2) = '01'
				THEN substring(cblper,1,4) ++ '03'
		  WHEN cblper NOT LIKE '0%' AND substring(cblper,5,2) = '02'
				THEN substring(cblper,1,4) ++ '06'
		  WHEN cblper NOT LIKE '0%' AND substring(cblper,5,2) = '03'
				THEN substring(cblper,1,4) ++ '09'
		  WHEN cblper NOT LIKE '0%' AND substring(cblper,5,2) = '04'
				THEN substring(cblper,1,4) ++ '12' 
		  ELSE
				cblPer
		  END,
		  facSerCod, facClicod
	FROM COBS

	OPEN cCobrado
	FETCH NEXT FROM cCobrado
		INTO @contrato, @Zona, @fecCob, @periodo, @codigo, @cobrado, @tipo, @ppago, @cobNum, @sociedad, @lineaCobro, @facVersion, @periodoRegistrado, @periodoReferencia, @serie, @cliCod
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
																			fclFacVersion = @facVersion),1)
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
								
								INSERT into @tablaAuxiliar (periodo, periodoRegistrado, periodoReferencia, Zona, Servicio, Tarifa, ppago, tipImpuesto, DesServicio, DesTarifa, nCobBanco,cobBanCargoFijo,cobBanConsumo,cobBanBase,cobBanImpuesto,cobBanTotal)
								values (@periodo, ISNULL(@periodoRegistrado,''), ISNULL(@periodoReferencia,''), @Zona, @Servicio, @Tarifa, @ppago, @tipImpuesto, @DesServicio, @DesTarifa, 1, @CargoFijo, @Consumo, @Base, @Impuesto, CASE WHEN @Total <> @CobLinDesTotal THEN @CobLinDesTotal ELSE @Total END)
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
								INSERT into @tablaAuxiliar (periodo, periodoRegistrado, periodoReferencia, Zona, Servicio, Tarifa, ppago, tipImpuesto, DesServicio, DesTarifa, nCobOficina, cobOfiCargoFijo, cobOfiConsumo,cobOfiBase,cobOfiImpuesto,cobOfiTotal)
								values (@periodo, ISNULL(@periodoRegistrado,''), ISNULL(@periodoReferencia,''), @zona, @Servicio, @Tarifa, @ppago, @tipImpuesto, @DesServicio, @DesTarifa, 1, @CargoFijo, @Consumo, @Base, @Impuesto, CASE WHEN @Total <> @CobLinDesTotal THEN @CobLinDesTotal ELSE @Total END)
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
								INSERT into @tablaAuxiliar (periodo, periodoRegistrado, periodoReferencia, Zona, Servicio, Tarifa, ppago, tipImpuesto, DesServicio, DesTarifa, nDevBanco,devBanCargoFijo,devBanConsumo,devBanBase,devBanImpuesto,devBanTotal)
								values (@periodo, ISNULL(@periodoRegistrado,''), ISNULL(@periodoReferencia,''), @Zona, @Servicio, @Tarifa, @ppago, @tipImpuesto, @DesServicio, @DesTarifa, 1, @CargoFijo, @Consumo, @Base, @Impuesto, CASE WHEN @Total <> @CobLinDesTotal THEN @CobLinDesTotal ELSE @Total END)
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
								INSERT into @tablaAuxiliar (periodo, periodoRegistrado, periodoReferencia, Zona, Servicio, Tarifa, ppago, tipImpuesto, DesServicio, DesTarifa, nDevOficina,devOfiCargoFijo,devOfiConsumo,devOfiBase,devOfiImpuesto,devOfiTotal)
								values (@periodo, ISNULL(@periodoRegistrado,''), ISNULL(@periodoReferencia,''), @Zona, @Servicio, @Tarifa, @ppago, @tipImpuesto, @DesServicio, @DesTarifa, 1, @CargoFijo, @Consumo, @Base, @Impuesto, CASE WHEN @Total <> @CobLinDesTotal THEN @CobLinDesTotal ELSE @Total END)
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
								
								INSERT into @tablaAuxiliar (periodo, periodoRegistrado, periodoReferencia, Zona, Servicio, Tarifa, ppago, tipImpuesto, DesServicio, DesTarifa, nCobBanco,cobBanCargoFijo,cobBanConsumo,cobBanBase,cobBanImpuesto,cobBanTotal)
								values (@periodo, ISNULL(@periodoRegistrado,''), ISNULL(@periodoReferencia,''), @Zona, @Servicio, @Tarifa, @ppago, @tipImpuesto, @DesServicio, @DesTarifa, 1, @CargoFijo, @Consumo, @Base, @Impuesto, CASE WHEN @Total <> @CobLinDesTotal THEN @CobLinDesTotal ELSE @Total END)
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
								INSERT into @tablaAuxiliar (periodo, periodoRegistrado, periodoReferencia, Zona, Servicio, Tarifa, ppago, tipImpuesto, DesServicio, DesTarifa, nCobOficina, cobOfiCargoFijo, cobOfiConsumo,cobOfiBase,cobOfiImpuesto,cobOfiTotal)
								values (@periodo, ISNULL(@periodoRegistrado,''), ISNULL(@periodoReferencia,''), isnull(@zona,''), @Servicio, @Tarifa, @ppago, @tipImpuesto, @DesServicio, @DesTarifa, 1, @CargoFijo, @Consumo, @Base, @Impuesto, CASE WHEN @Total <> @CobLinDesTotal THEN @CobLinDesTotal ELSE @Total END)
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
								INSERT into @tablaAuxiliar (periodo, periodoRegistrado, periodoReferencia, Zona, Servicio, Tarifa, ppago, tipImpuesto, DesServicio, DesTarifa, nDevBanco,devBanCargoFijo,devBanConsumo,devBanBase,devBanImpuesto,devBanTotal)
								values (@periodo, ISNULL(@periodoRegistrado,''), ISNULL(@periodoReferencia,''), @Zona, @Servicio, @Tarifa, @ppago, @tipImpuesto, @DesServicio, @DesTarifa, 1, @CargoFijo, @Consumo, @Base, @Impuesto, CASE WHEN @Total <> @CobLinDesTotal THEN @CobLinDesTotal ELSE @Total END)
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
								INSERT into @tablaAuxiliar (periodo, periodoRegistrado, periodoReferencia, Zona, Servicio, Tarifa, ppago, tipImpuesto, DesServicio, DesTarifa, nDevOficina,devOfiCargoFijo,devOfiConsumo,devOfiBase,devOfiImpuesto,devOfiTotal)
								values (@periodo, ISNULL(@periodoRegistrado,''), ISNULL(@periodoReferencia,''), isnull(@Zona,''), @Servicio, @Tarifa, @ppago, @tipImpuesto, @DesServicio, @DesTarifa, 1, @CargoFijo, @Consumo, @Base, @Impuesto, CASE WHEN @Total <> @CobLinDesTotal THEN @CobLinDesTotal ELSE @Total END)
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
		INTO  @contrato, @Zona, @fecCob, @periodo, @codigo, @cobrado, @tipo, @ppago, @cobNum, @sociedad, @lineaCobro, @facVersion, @periodoRegistrado, @periodoReferencia, @serie, @cliCod
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
		1 - Trimestrales (periodo not like '0000%')				
		2 - Mensuales (periodo like '0000%')
				
		Los servicios a mostrar serán los siguientes:

		1   - CONSUMO DE AGUA
		2   - CUOTA SERVICIO AGUA
		3   - VERIFICACIÓN VEIASA
		4   - VERTIDO
		8   - C.SERVICIO SANEAMIENTO Y DEPURACION
		12  - CANON DE MEJORA
		19  - CANON FIJO
		20  - CANON VARIABLE
		60  - CANON JUNTA ANDALUCÍA 2014
		100 - CUOTA DE CONTRATACION
		101 - DERECHOS DE ACOMETIDA (agrupados 101, 105, 106)
		102 - FIANZA CONSTITUIDA
		105 - IMPORTE PARAMETRO A (agrupados 101, 105, 106)
		106 - IMPORTE PARAMETRO B (agrupados 101, 105, 106)
		107 - SANEAMIENTO
		108 - CUOTA DE CONTRATACION / cambio titularidad
*/
	
	IF((@periodoD like '00%' and @periodoH like '00%') OR @SituacionTarifaInformeExcel=1)
	begin
	-- Insertamos todo lo que va agrupado por servicio, todo lo que no es agua
		INSERT INTO @tablaInforme
			(bloqueId, bloqueNom,		
			periodo, periodoRegistrado, periodoReferencia, zona, servTarifa, desServTarifa, -- Id y nombre de servicio
			facnFacturas, facCargoFijo, 	facConsumo, 	facBase, 	facImpuesto, 	facTotal,
			anunFacturas, anuCargoFijo, 	anuConsumo, 	anuBase, 	anuImpuesto, 	anuTotal,
			crenFacturas, creCargoFijo, 	creConsumo, 	creBase,  	creImpuesto, 	creTotal,
			nCobBanco, 	  cobBanCargoFijo,	cobBanConsumo,	cobBanBase, cobBanImpuesto, cobBanTotal,
			nCobOficina,  cobOfiCargoFijo,	cobOfiConsumo,	cobOfiBase, cobOfiImpuesto, cobOfiTotal,
			nDevBanco, 	  devBanCargoFijo,	devBanConsumo,	devBanBase, devBanImpuesto, devBanTotal,
			nDevOficina,  devOfiCargoFijo,	devOfiConsumo,	devOfiBase, devOfiImpuesto, devOfiTotal)
		SELECT
			-- bloqueId
			CASE WHEN periodo not like '0000%' THEN 1 -- TRIMESTRALES 
				 WHEN periodo like '0000%' THEN 2 END, -- MENSUALES
			-- bloqueNom
			CASE WHEN periodo not like '0000%' THEN 'TRIMESTRALES'
				 WHEN periodo like '0000%' THEN 'MENSUALES'END,
			periodo, periodoRegistrado, periodoReferencia, zona, 
			(CASE 
				WHEN (@agruparServicios = 1) and (servicio in (105,106,101)) THEN 200 --servicio agrupa (par A + par B + D.Acometida)
			  
				  ELSE servicio END) AS servicio,
			(CASE 
				WHEN (@agruparServicios = 1) and (servicio in (105,106,101)) THEN 'Par. A + Par. B + D. Acometida' --servicio agrupa (par A + par B + D.Acometida)
			  
				  ELSE desServicio END) AS desServicio,
				ISNULL(sum(facnFacturas), 0), ISNULL(sum(facCargoFijo), 0),    ISNULL(sum(facConsumo), 0),    ISNULL(sum(facBase), 0),    ISNULL(sum(facImpuesto), 0),    ISNULL(sum(facTotal), 0),
				ISNULL(sum(anunFacturas), 0), ISNULL(sum(anuCargoFijo), 0),    ISNULL(sum(anuConsumo), 0),    ISNULL(sum(anuBase), 0),    ISNULL(sum(anuImpuesto), 0),    ISNULL(sum(anuTotal), 0),
				ISNULL(sum(crenFacturas), 0), ISNULL(sum(creCargoFijo), 0),    ISNULL(sum(creConsumo), 0),    ISNULL(sum(creBase), 0),    ISNULL(sum(creImpuesto), 0),    ISNULL(sum(creTotal), 0),
				ISNULL(sum(nCobBanco), 0),    ISNULL(sum(cobBanCargoFijo), 0), ISNULL(sum(cobBanConsumo), 0), ISNULL(sum(cobBanBase), 0), ISNULL(sum(cobBanImpuesto), 0), ISNULL(sum(cobBanTotal), 0),
				ISNULL(sum(nCobOficina), 0),  ISNULL(sum(cobOfiCargoFijo), 0), ISNULL(sum(cobOfiConsumo), 0), ISNULL(sum(cobOfiBase), 0), ISNULL(sum(cobOfiImpuesto), 0), ISNULL(sum(cobOfiTotal), 0),
				ISNULL(sum(nDevBanco), 0),    ISNULL(sum(devBanCargoFijo), 0), ISNULL(sum(devBanConsumo), 0), ISNULL(sum(devBanBase), 0), ISNULL(sum(devBanImpuesto), 0), ISNULL(sum(devBanTotal), 0),
				ISNULL(sum(nDevOficina), 0),  ISNULL(sum(devOfiCargoFijo), 0), ISNULL(sum(devOfiConsumo), 0), ISNULL(sum(devOfiBase), 0), ISNULL(sum(devOfiImpuesto), 0), ISNULL(sum(devOfiTotal), 0)			
		FROM @tablaAuxiliar  
		GROUP BY zona, periodo, periodoRegistrado, periodoReferencia, servicio, desServicio
	end
	else
	begin
		-- Insertamos todo lo que va agrupado por servicio, todo lo que no es agua
		INSERT INTO @tablaInforme
			(bloqueId, bloqueNom,		
			periodo, periodoRegistrado, periodoReferencia, zona, servTarifa, desServTarifa, -- Id y nombre de servicio
			facnFacturas, facCargoFijo, 	facConsumo, 	facBase, 	facImpuesto, 	facTotal,
			anunFacturas, anuCargoFijo, 	anuConsumo, 	anuBase, 	anuImpuesto, 	anuTotal,
			crenFacturas, creCargoFijo, 	creConsumo, 	creBase,  	creImpuesto, 	creTotal,
			nCobBanco, 	  cobBanCargoFijo,	cobBanConsumo,	cobBanBase, cobBanImpuesto, cobBanTotal,
			nCobOficina,  cobOfiCargoFijo,	cobOfiConsumo,	cobOfiBase, cobOfiImpuesto, cobOfiTotal,
			nDevBanco, 	  devBanCargoFijo,	devBanConsumo,	devBanBase, devBanImpuesto, devBanTotal,
			nDevOficina,  devOfiCargoFijo,	devOfiConsumo,	devOfiBase, devOfiImpuesto, devOfiTotal)
		SELECT
			-- bloqueId
			CASE WHEN periodo not like '0000%' THEN 1 -- TRIMESTRALES 
				 WHEN periodo like '0000%' THEN 2 END, -- MENSUALES
			-- bloqueNom
			CASE WHEN periodo not like '0000%' THEN 'TRIMESTRALES'
				 WHEN periodo like '0000%' THEN 'MENSUALES'END,
			periodo, periodoRegistrado, periodoReferencia, zona, 
			(CASE 
				WHEN (@agruparServicios = 1) and (servicio in (105,106,101)) THEN 200 --servicio agrupa (par A + par B + D.Acometida)
			  
				  ELSE servicio END) AS servicio,
			(CASE 
				WHEN (@agruparServicios = 1) and (servicio in (105,106,101)) THEN 'Par. A + Par. B + D. Acometida' --servicio agrupa (par A + par B + D.Acometida)
			  
				  ELSE desServicio END) AS desServicio,
				ISNULL(sum(facnFacturas), 0), ISNULL(sum(facCargoFijo), 0),    ISNULL(sum(facConsumo), 0),    ISNULL(sum(facBase), 0),    ISNULL(sum(facImpuesto), 0),    ISNULL(sum(facTotal), 0),
				ISNULL(sum(anunFacturas), 0), ISNULL(sum(anuCargoFijo), 0),    ISNULL(sum(anuConsumo), 0),    ISNULL(sum(anuBase), 0),    ISNULL(sum(anuImpuesto), 0),    ISNULL(sum(anuTotal), 0),
				ISNULL(sum(crenFacturas), 0), ISNULL(sum(creCargoFijo), 0),    ISNULL(sum(creConsumo), 0),    ISNULL(sum(creBase), 0),    ISNULL(sum(creImpuesto), 0),    ISNULL(sum(creTotal), 0),
				ISNULL(sum(nCobBanco), 0),    ISNULL(sum(cobBanCargoFijo), 0), ISNULL(sum(cobBanConsumo), 0), ISNULL(sum(cobBanBase), 0), ISNULL(sum(cobBanImpuesto), 0), ISNULL(sum(cobBanTotal), 0),
				ISNULL(sum(nCobOficina), 0),  ISNULL(sum(cobOfiCargoFijo), 0), ISNULL(sum(cobOfiConsumo), 0), ISNULL(sum(cobOfiBase), 0), ISNULL(sum(cobOfiImpuesto), 0), ISNULL(sum(cobOfiTotal), 0),
				ISNULL(sum(nDevBanco), 0),    ISNULL(sum(devBanCargoFijo), 0), ISNULL(sum(devBanConsumo), 0), ISNULL(sum(devBanBase), 0), ISNULL(sum(devBanImpuesto), 0), ISNULL(sum(devBanTotal), 0),
				ISNULL(sum(nDevOficina), 0),  ISNULL(sum(devOfiCargoFijo), 0), ISNULL(sum(devOfiConsumo), 0), ISNULL(sum(devOfiBase), 0), ISNULL(sum(devOfiImpuesto), 0), ISNULL(sum(devOfiTotal), 0)			
		FROM @tablaAuxiliar  		
		WHERE Servicio NOT IN (102, 103)
		GROUP BY zona, periodo, periodoRegistrado, periodoReferencia, servicio, desServicio
	end


	IF(@SituacionTarifaInformeExcel = 0)
	begin
		-- Select para el informe, agrupamos por bloque, periodo y servicio o tarifa según corresponda
		SELECT bloqueId, bloqueNom,	
			CASE WHEN periodo = '999999' THEN 'ENTREGAS A CUENTA' 
				 WHEN (periodo ='000002' OR periodo = '000001') THEN 'Trimestral' 
				 WHEN periodo not like '0000%' THEN 'Trimestral'	
				 WHEN periodo like '0000%' THEN 'Mensual'
				 ELSE przTipo END AS przTipo,
			CASE WHEN periodo like '0000%' THEN periodoRegistrado 
				 ELSE periodo END AS 
				 periodo,  
			periodoRegistrado, periodoReferencia, desServTarifa,
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
		GROUP BY bloqueId, bloqueNom, periodo, DesServTarifa, przTipo, periodoRegistrado, periodoReferencia
		ORDER BY bloqueId, periodo, periodoRegistrado, desServTarifa
	end
	else
	begin
		-- select para informe de excel con más datos de totales y menos de consumos
		SELECT 
			CASE WHEN periodo = '999999' THEN 'ENTREGAS A CUENTA'
				 WHEN (periodo ='000002' OR periodo = '000001') THEN 'Trimestral' 
				 WHEN periodo not like '0000%' THEN 'Trimestral'	
				 WHEN periodo like '0000%' THEN 'Mensual'
				 ELSE przTipo END AS 'Tipo',
				 periodo,  
			periodoRegistrado as 'Año-Mes' , desServTarifa as 'Servicio',
				sum(facBase)    as 'Fac. Original Base',    sum(facImpuesto)    as 'Fac. Original Impuestos',    sum(facTotal) as 'Fac. Original Total',
				sum(anuBase)    as 'Anulada Base',    sum(anuImpuesto)    as 'Anulada Impuestos',    sum(anuTotal) as 'Anulada Total',
				sum(creBase)    as 'Creada Base',    sum(creImpuesto)    as 'Creada Impuestos',    sum(creTotal) as 'Creada Total',
				sum(facTotal) - sum(anuTotal) + sum(creTotal) as 'TOTAL FACTURADO',
				sum(cobBanBase) as 'Cobrado Banco Base', sum(cobBanImpuesto) as 'Cobrado Banco Impuestos', sum(cobBanTotal) as 'Cobrado Banco Total',
				sum(cobOfiBase) as 'Cobrado Oficina Base', sum(cobOfiImpuesto) as 'Cobrado Oficina Impuestos', sum(cobOfiTotal) as 'Cobrado Oficina Total',
				sum(devBanBase) as 'Devolución Banco Base', sum(devBanImpuesto) as 'Devolución Banco Impuestos', sum(devBanTotal) as 'Devolución Banco Total',
				sum(devOfiBase) as 'Devolución Oficina Base', sum(devOfiImpuesto) as 'Devolución Oficina Impuestos', sum(devOfiTotal) as 'Devolución Oficina Total',
				sum(cobBanTotal) + sum(cobOfiTotal) - sum(devBanTotal) - sum(devOfiTotal) as 'TOTAL COBRADO',
				(sum(facTotal) - sum(anuTotal) + sum(creTotal))-(sum(cobBanTotal) + sum(cobOfiTotal) - sum(devBanTotal) - sum(devOfiTotal)) as 'DEUDA'
		FROM @tablaInforme
		LEFT JOIN perzona ON przCodPer = periodo AND przCodZon = zona
		WHERE ((@filtro IS NULL AND @filtro2 IS NULL) OR (UPPER(desServTarifa) = @filtro OR UPPER(desServTarifa) LIKE @filtro2 ))
		GROUP BY periodo, DesServTarifa, przTipo, periodoRegistrado
			ORDER BY periodo, periodoRegistrado, desServTarifa
	end

END TRY
	
BEGIN CATCH
		
	DECLARE @erlNumber INT = (SELECT ERROR_NUMBER());
	DECLARE @erlSeverity INT = (SELECT ERROR_SEVERITY());
	DECLARE @erlState INT = (SELECT ERROR_STATE());
	DECLARE @erlProcedure nvarchar(128) = (SELECT ERROR_PROCEDURE());
	DECLARE @erlLine int = (SELECT ERROR_LINE());
	DECLARE @erlMessage nvarchar(4000) = (SELECT ERROR_MESSAGE());
	
	DECLARE @erlParams varchar(500) = NULL;
		
	DECLARE @expl VARCHAR(20) = NULL
	SET @expl = (SELECT pgsvalor FROM parametros WHERE pgsclave = 'EXPLOTACION')

	BEGIN TRAN
		EXEC ErrorLog_Insert  @expl, 'InformeSituacionTrf_AVG', @erlNumber, @erlSeverity, @erlState, @erlProcedure, @erlLine, @erlMessage, @erlParams	
	COMMIT TRAN
	
END CATCH
GO