/*
DECLARE   @periodoD AS VARCHAR(6) = '202201'
, @periodoH AS VARCHAR(6) = '202301'
, @fechaD AS DATE = NULL
, @fechaH AS DATE = NULL
, @contratoD AS INT = NULL
, @contratoH AS INT = NULL
, @versionD AS INT = NULL
, @versionH AS INT = NULL
, @zonaD AS VARCHAR(4) = NULL
, @zonaH AS VARCHAR(4) = NULL
, @consuMin AS INT = 0
, @consuMax AS INT = 999999999
, @verTodas AS BIT = 1
, @preFactura AS BIT = 0

EXEC [ReportingServices].[RelacionConsumoPadron] 
  @periodoD, @periodoH, @fechaD, @fechaH, @contratoD, @contratoH
, @versionD, @versionH, @zonaD, @zonaH, @consuMin, @consuMax
, @verTodas, @preFactura;

*/

ALTER PROCEDURE [ReportingServices].[RelacionConsumoPadron]
  @periodoD AS VARCHAR(6) = NULL
, @periodoH AS VARCHAR(6) = NULL
, @fechaD AS DATE = NULL
, @fechaH AS DATE = NULL
, @contratoD AS INT = NULL
, @contratoH AS INT = NULL
, @versionD AS INT = NULL
, @versionH AS INT = NULL
, @zonaD AS VARCHAR(4) = NULL
, @zonaH AS VARCHAR(4) = NULL
, @consuMin AS INT = NULL
, @consuMax AS INT = NULL
, @verTodas AS BIT
, @preFactura AS BIT
AS

--*********************************************************
--SYR-441389:INFORMES DE CONSUMO PADRON SALEN POR SEPARADO
--19/05/2023: lo dejamos condicionado para AVG pero debería valer igual para el resto de las explotaciones
IF (EXISTS(SELECT 1 FROM parametros WHERE pgsclave = 'EXPLOTACION' AND pgsvalor='AVG'))
BEGIN
	EXEC [ReportingServices].[RelacionConsumoPadron_SinCursor] 
	  @periodoD, @periodoH, @fechaD, @fechaH, @contratoD, @contratoH
	, @versionD, @versionH, @zonaD, @zonaH, @consuMin, @consuMax
	, @verTodas, @preFactura;
	RETURN;
END
--*********************************************************




--******************************************
--BOP175 ha implicado creacíón nuevas tarifas
--Creamos esta vista para poder agrupar estas en tarifas en una sola:
--ReportingServices.TarifasBOP175_AVG 
--Como ha sido el caso del informes "Relación Consumos Padrón"
--******************************************

SET @fechaH = DATEADD(DAY, 1, @fechaH);

DECLARE @contrato as int
DECLARE @tarifa as int
DECLARE @periodo as varchar(6)
DECLARE @diametro as int
DECLARE @cliente as varchar(60)
DECLARE @documento as varchar(20)
DECLARE @direccion as varchar(200)
DECLARE @consumo as int
DECLARE @version as int
DECLARE @perContador as int

DECLARE @padron as 
		TABLE (contrato int,
               documento varchar(20),
			   cliente varchar(60),
			   tarifa int,
			   direccion varchar(200),
			   diametro int,
			   periodo1 varchar(6),
			   consumo1 int,
			   periodo2 varchar(6),
			   consumo2 int,
			   periodo3 varchar(6),
			   consumo3 int,
			   periodo4 varchar(6),
			   consumo4 int,
			   periodo5 varchar(6),
			   consumo5 int,
			   periodo6 varchar(6),
			   consumo6 int,
primary key(contrato, tarifa)
			)

DECLARE @periodo1 varchar(6) = NULL
DECLARE @periodo2 varchar(6) = NULL
DECLARE @periodo3 varchar(6) = NULL
DECLARE @periodo4 varchar(6) = NULL
DECLARE @periodo5 varchar(6) = NULL
DECLARE @periodo6 varchar(6) = NULL

SET @perContador = 1
DECLARE cPeriodos CURSOR FOR
	SELECT TOP 6 percod FROM periodos 
WHERE (PerCod >= @periodoD OR @periodoD IS NULL) and (PerCod <= @periodoH OR @periodoH IS NULL)
ORDER BY percod

OPEN cPeriodos
FETCH NEXT FROM cPeriodos
INTO @periodo
WHILE @@FETCH_STATUS = 0
BEGIN
		IF @perContador = 1 
			SET @periodo1 = @periodo
		ELSE BEGIN
			IF @perContador = 2
				SET @periodo2 = @periodo
			ELSE BEGIN
				IF @perContador = 3
					SET @periodo3 = @periodo
				ELSE BEGIN
					IF @perContador = 4
						SET @periodo4 = @periodo
					ELSE BEGIN
						IF @perContador = 5
							SET @periodo5 = @periodo
						ELSE BEGIN
							IF @perContador = 6
								SET @periodo6 = @periodo
						END
					END
				END
			END
		END
	SET @perContador = @perContador + 1

	FETCH NEXT FROM cPeriodos
	INTO @periodo
END
CLOSE cPeriodos
DEALLOCATE cPeriodos

SET @perContador = 1
DECLARE cPeriodos CURSOR FOR
	select percod from periodos 
where (PerCod >= @periodoD OR @periodoD IS NULL) and (PerCod <= @periodoH OR @periodoH IS NULL)
order by percod

OPEN cPeriodos
FETCH NEXT FROM cPeriodos
INTO @periodo
WHILE @@FETCH_STATUS = 0
BEGIN
	DECLARE cPadron CURSOR FOR
		select [facCtrCod], [facversion], ISNULL(ctrPagNom, ctrTitNom), inmdireccion, ISNULL(ctrPagDocIden, ctrTitDocIden), [facconsumofactura],
		(SELECT conDiametro 
			FROM fContratos_ContadoresInstalados(NULL) 
			WHERE ctcCtr = facCtrCod 
		) as conDiametro,                                            
		fcltrfcod
		from facturas 
		inner join contratos on ctrcod = facctrcod and ctrversion = facctrversion
		inner join inmuebles on inmcod = ctrinmcod
		inner join faclin on fclfaccod = faccod and fclfacpercod = facpercod and fclfacversion = facversion and fclfacctrcod = facctrcod and fcltrfsvcod = 1
		where (facPerCod = @periodo )
		and (facVersion >= @versionD  OR @versionD IS NULL)
		and (facVersion <= @versionH OR @versionH IS NULL)
		and (facZonCod >= @zonaD  OR @zonaD IS NULL)
		and (facZonCod <= @zonaH OR @zonaH IS NULL)
		and (facFecha>= @fechaD OR @fechaD IS NULL)
		and (facFecha < @fechaH OR @fechaH IS NULL)
		and (facCtrCod>= @contratoD OR @contratoD IS NULL)
		and (facCtrCod<= @contratoH OR @contratoH IS NULL)
		and (facFechaRectif IS NULL OR (facFechaRectif>=@fechaH) OR @verTodas=1)   -- verTodas junto con las rectificadas
		and ( (facNumero is not null and @preFactura=0) OR  (@preFactura=1) )-- Si @preFactura es 0 entonces saca las facturas definitivas y si es 1 saca todas junto con las preFACTURAS
		AND((fclFecLiq>=@fechaH) OR (fclFecLiq IS NULL AND fclUsrLiq IS NULL))	
		and (@consuMin IS NULL OR @consuMin<=facConsumoFactura)
		and (@consuMax IS NULL OR @consuMax>=facConsumoFactura)

		order by facCtrCod
	OPEN cPadron
	FETCH NEXT FROM cPadron
	INTO @contrato, @version, @cliente, @direccion, @documento, @consumo, @diametro, @tarifa
	WHILE @@FETCH_STATUS = 0
	BEGIN


		
		IF NOT EXISTS(SELECT contrato from @padron where contrato = @contrato and tarifa=@tarifa) BEGIN
			insert into @padron (contrato, documento, cliente, direccion, diametro, tarifa,periodo1, consumo1, periodo2,  consumo2,  periodo3,  consumo3,  periodo4,  consumo4,  periodo5, consumo5,  periodo6, consumo6)
			Values(@contrato, @documento, @cliente, @direccion, @diametro, @tarifa, @periodo1, null, @periodo2, null, @periodo3, null, @periodo4, null, @periodo5, null, @periodo6, null)
		END


		IF @perContador = 1 
				update @padron set consumo1 = @consumo
					where contrato = @contrato and tarifa = @tarifa
		ELSE BEGIN
			IF @perContador = 2
				update @padron set consumo2 = @consumo
					where contrato = @contrato and tarifa = @tarifa
			ELSE BEGIN
				IF @perContador = 3
					update @padron set consumo3 = @consumo
						where contrato = @contrato and tarifa = @tarifa
				ELSE BEGIN
					IF @perContador = 4
						update @padron set consumo4 = @consumo
							where contrato = @contrato and tarifa = @tarifa
					ELSE BEGIN
						IF @perContador = 5
							update @padron set consumo5 = @consumo
								where contrato = @contrato and tarifa = @tarifa
						ELSE BEGIN
							IF @perContador = 6
								update @padron set consumo6 = @consumo
									where contrato = @contrato and tarifa = @tarifa
						END
					END
				END
			END
		END

		FETCH NEXT FROM cPadron
		INTO @contrato, @version, @cliente, @direccion, @documento, @consumo, @diametro, @tarifa
	END
	CLOSE cPadron
	DEALLOCATE cPadron

	SET @perContador = @perContador + 1
	FETCH NEXT FROM cPeriodos
	INTO @periodo
END
CLOSE cPeriodos
DEALLOCATE cPeriodos

--*******************
SELECT P.*
 , TT.codBOP175  AS trfCod
 , TT.descBOP175 AS trfDes
FROM @padron AS P
INNER JOIN ReportingServices.TarifasBOP175_AVG AS TT
ON  TT.trfsrvcod=1 
AND TT.trfcod = P.tarifa
ORDER BY P.tarifa, P.direccion;

--select * from @padron 
--inner join tarifas on trfcod = tarifa and trfsrvcod = 1
--order by tarifa, direccion


GO


