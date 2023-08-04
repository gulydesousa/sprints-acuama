/*
DECLARE @fechaFacturaD AS DATETIME = '20220101',
@fechaFacturaH AS DATETIME = '20221231',
@fechaLiquidacionD AS DATETIME = NULL,
@fechaLiquidacionH AS DATETIME = NULL,
@periodoD AS VARCHAR(6) = NULL,
@periodoH AS VARCHAR(6) = NULL,
@zonaD AS VARCHAR(4) = NULL,
@zonaH AS VARCHAR(4) = NULL,
@contrato AS INT = 31810,  
@version as int = 3

EXEC [dbo].[Liquidaciones_Select_AVG_Detalle] 
@fechaFacturaD, @fechaFacturaH,
@fechaLiquidacionD, @fechaLiquidacionH, 
@periodoD, @periodoH,
@zonaD, @zonaH,
@contrato, @version;

*/
--DROP PROCEDURE [dbo].[Liquidaciones_Select_AVG_Detalle]

CREATE PROCEDURE [dbo].[Liquidaciones_Select_AVG_Detalle]
@fechaFacturaD AS DATETIME = NULL,
@fechaFacturaH AS DATETIME = NULL,
@fechaLiquidacionD AS DATETIME = NULL,
@fechaLiquidacionH AS DATETIME = NULL,
@periodoD AS VARCHAR(6) = NULL,
@periodoH AS VARCHAR(6) = NULL,
@zonaD AS VARCHAR(4) = NULL,
@zonaH AS VARCHAR(4) = NULL,
@contrato as int, 
@version as int 
AS 
	SET NOCOUNT ON; 
	
DECLARE @fecFinMigracion datetime = '05/03/2019'
declare @fechaPerD as datetime = NULL
declare @fechaPerH as datetime = NULL

set @fechaPerD = (select top 1 przfPeriodoD from perzona where przcodper = @periodoD)
set @fechaPerH = (select top 1 przfPeriodoH from perzona where przcodper = @periodoH)

;with aux as(
	select distinct
	'F' tipo,	
	 case 
		when F.facPerCod = '202103' and F.facCtrCod = 8753 then 'D' 
		when fclTrfSvCod = 20 and fclTrfCod in (101,401,501,601,701,1001,8501) then 'D' 
	 else 'N' end uso,
	F.facNumero,
	F.facNumeroRectif,
	F.facctrcod contrato,
	max(ctrTitDocIden) TitDocIden,

	DATEADD(day, 1, F.facLecAntFec) as fecInicio,	
	F.facLecActFec as fecFin,
		
	datediff(day, DATEADD(day, 1, F.facLecAntFec), F.facLecActFec) as diasF1,
	0 as diasF2,
	
	F.facConsumoReal AS consumoAbastecimiento,
	F.facConsumoFactura AS consumoEstimado,
	
	--Volumen, si el contrato tiene servicio 8 pero no servicio 1.
	(case when(
			select COUNT(*) from contratoServicio cs
			where cs.ctsctrcod=F.facctrcod and cs.ctssrv=8 and not exists (select * from contratoServicio c where c.ctsctrcod=cs.ctsctrcod and c.ctssrv=1)
			)=1
		then
		(select sum(fl.fclunidades1 + fl.fclunidades2 + fl.fclunidades3 + fl.fclunidades4 + fl.fclunidades5 + fl.fclunidades6 + fl.fclunidades7 + fl.fclunidades8 + fl.fclunidades9)
		from faclin fl
		where fl.fclFacCtrCod= fclFacCtrCod and fl.fclFacCod= fclFacCod and fl.fclFacPerCod= fclFacPerCod and fl.fclFacVersion= fclFacVersion and fl.fclTrfSvCod=8)
	else 0 end) as volumen,
	max(CASE
		WHEN (ctrComunitario IS NULL AND ctrValorc1 = 1 AND fclTrfSvCod = 20 AND fclTrfCod = 401) THEN 5
		WHEN (ctrComunitario IS NULL AND ctrValorc1 = 1 AND fclTrfSvCod = 20 AND fclTrfCod = 501) THEN 6
		WHEN (ctrComunitario IS NULL AND ctrValorc1 = 1 AND fclTrfSvCod = 20 AND fclTrfCod = 601) THEN 7
		WHEN (ctrComunitario IS NULL AND ctrValorc1 = 1 AND fclTrfSvCod = 20 AND fclTrfCod = 701) THEN 8
		WHEN (ctrComunitario IS NULL AND ctrValorc1 = 1 AND fclTrfSvCod = 20 AND fclTrfCod = 1001) THEN 9
		--para el caso de las fugas, tengo que ir a buscar los habitantes en la versión de factura anterior
		WHEN (ctrComunitario IS NULL AND ctrValorc1 = 1 AND fclTrfSvCod = 20 AND fclTrfCod = 8501) THEN 0
		ELSE 0 end) as habitantes,

	null ival,
	null ccv,
	null reduccion,	
	sum(case when fclTrfSvCod=19 then ROUND(fclbase,2) else 0 end) as cuotaFija,
	sum(case when fclTrfSvCod=20 and fclTrfCod not in (8501) then ROUND(fclPrecio2 * fclUnidades2,2)  else 0 end) as CV1,
	sum(case when fclTrfSvCod=20 and fclTrfCod not in (8501) then ROUND(fclPrecio3 * fclUnidades3,2) else 0 end) as CV2,
	sum(case when fclTrfSvCod=20 and fclTrfCod not in (8501) then ROUND(fclPrecio4 * fclUnidades4 ,2) else 0 end) as CV3,
	sum(case when fclTrfSvCod=20 then ROUND(fclbase,2) else 0 end) AS CVTotal, --debe incluir fugas si hubiera
	0 impDisp,
	SUM(case when (fclTrfSvCod=19 or fclTrfSvCod=20) then ROUND(fclbase,2) else 0 end) cuotaTotal,
	'F' indFact,
	fclFacPerCod periodo
	, [tipoFactura] = CASE WHEN F.facVersion = 1 THEN 'N'
						   --Es una rectificativa pero la factura rectificada no tiene numero
						   WHEN F0.facCod IS NOT NULL AND F0.facNumero IS NULL THEN 'N'
						   ELSE 'S2' END,
	F.facFecha as fechaFactura,
	case 
		when fclTrfSvCod = 20 and fcltotal > 0 then '20_1' --en caso de que haya más de una línea de canon variable, priorizará la que tenga importe
		when fclTrfSvCod = 20 and fcltotal <= 0 then '20'
		when fclTrfSvCod = 19 then '19'
	end	as servicio
	from faclin
	INNER JOIN tarifas ON trfcod = fclTrfCod AND trfsrvcod = fclTrfSvCod
	INNER JOIN dbo.facturas AS F 
	ON  F.facCtrCod = fclFacCtrCod 
	AND F.facPerCod = fclFacPerCod 
	AND F.facVersion = fclFacVersion 
	AND F.facCod = fclFacCod
	INNER JOIN contratos on ctrcod = fclFacCtrCod and ctrversion = facCtrVersion
	--**********************************
	--Para sacar la rectificada asociada
	LEFT JOIN dbo.facturas AS F0
	ON  F0.facCtrCod = F.facCtrCod
	AND F0.facPerCod = F.facPerCod
	AND F0.facCod = F.facCod
	AND F0.facFechaRectif = F.facFecha
	AND F0.facNumeroRectif = F.facNumero

	where 

			  ((F.facFecha <= @fecFinMigracion) OR (F.facFecha > @fecFinMigracion))
			  
			  AND

			  (fclFecLiqImpuesto IS NOT NULL) AND
			  (F.facFecha >= @fechaFacturaD OR @fechaFacturaD IS NULL) AND
			  (F.facFecha <= @fechaFacturaH OR @fechaFacturaH IS NULL) AND
			  (F.facFecha >= @fechaPerD OR @fechaPerD IS NULL) AND
			  (F.facFecha <= @fechaPerH OR @fechaPerH IS NULL) AND
			  (fclFecLiqImpuesto >= @fechaLiquidacionD OR @fechaLiquidacionD IS NULL) AND
			  (fclFecLiqImpuesto <= @fechaLiquidacionH OR @fechaLiquidacionH IS NULL) AND


			  (
				  ((F.facPerCod >= @periodoD OR @periodoD IS NULL) AND (F.facPerCod <= @periodoH OR @periodoH IS NULL)) 
				  OR
				  ((fclFacPerCod like '0%') 
					AND fclTrfSvCod IN (19, 20) 
					AND (F.facFecha between @fechaPerD AND @fechaPerH)				
				  )
			  )

			  AND fclTrfSvCod IN (19, 20)

			  AND
			  (ctrZonCod >= @zonaD OR @zonaD IS NULL) AND
			  (ctrZonCod <= @zonaH OR @zonaH IS NULL ) 
			  AND	      
			   NOT EXISTS(SELECT aprNumero 
								 FROM apremios
								 WHERE aprFacCod = F.facCod AND
									   aprFacCtrCod = F.facCtrCod AND
									   aprFacPerCod = F.facPerCod AND
									   aprFacVersion = F.facVersion
						  )
			and ctrcod= @contrato
			and ctrversion = @version
			
			GROUP BY F.facctrcod, F.facPerCod, F.facFecha
				  , fclFacCod, fclFacPerCod, fclFacVersion
				  , F.facNumero, F.facNumeroRectif, F.facLecAntFec, F.facLecActFec
				  , ctrUsoCod
				  , F.facVersion, F.facConsumoFactura
				  , F.facConsumoReal
				  , fclTrfSvCod, fclTrfCod, fcltotal
				  --Rectificada:
				  , F0.facCod, F0.facNumero
), agrupadas as(
	select tipo, uso, facNumero, facNumeroRectif, contrato, TitDocIden, fecInicio, fecFin, diasF1, diasF2, consumoAbastecimiento, consumoEstimado, volumen, 
			sum(habitantes) OVER (PARTITION BY facnumero) habitantes,
			ival, ccv, reduccion, 
			CONVERT(VARCHAR, sum(cuotaFija) OVER (PARTITION BY facnumero), 2) cuotaFija,
			CONVERT(VARCHAR, sum(CV1) OVER (PARTITION BY facnumero), 2) CV1,
			CONVERT(VARCHAR, sum(CV2) OVER (PARTITION BY facnumero), 2) CV2, 
			CONVERT(VARCHAR, sum(CV3) OVER (PARTITION BY facnumero), 2) CV3, 
			CONVERT(VARCHAR, sum(CVTotal) OVER (PARTITION BY facnumero), 2) CVTotal, 
			impDisp, 
			CONVERT(VARCHAR, sum(cuotaTotal) OVER (PARTITION BY facnumero), 2) cuotaTotal, 
			indFact, periodo, tipoFactura, fechaFactura, servicio,			
			RN = ROW_NUMBER() OVER(PARTITION BY facnumero ORDER BY servicio desc)
	 from aux
), agrupUnificadas as(
	select 
		tipo, uso, facNumero, facNumeroRectif, contrato, TitDocIden, fecInicio, fecFin, diasF1, diasF2, consumoAbastecimiento, consumoEstimado, volumen, habitantes, ival, ccv, reduccion, 
		cuotaFija, CV1, CV2, CV3, CVTotal, impDisp, cuotaTotal, indFact, periodo, tipoFactura, fechaFactura
	from agrupadas
	where RN = 1
), conRectificadas as(
	select distinct
		a.*,
		f.facNumero as facNumeroRectificada, f.facFecha as facFechaRectificada,
		year(f.facFecha) as ejercicioRectificada,
		case
			when (f.facFecha is not null and month(f.facFecha) <= 6) then '1S' 
			when (f.facFecha is not null and month(f.facFecha) > 6) then '2S' 
			else null end as periodoRectificada,
		f.facConsumoFactura as consumoRectificada,
		CONVERT(VARCHAR, sum(case when fcl.fclTrfSvCod=19 then ROUND(fcl.fclbase,2) else 0 end),2) as cuotaFijaRectificada,
		CONVERT(VARCHAR, sum(case when fcl.fclTrfSvCod=20 and fcl.fclTrfCod not in (201,301,801) then ROUND(fcl.fclPrecio2 * fcl.fclUnidades2,2)  else 0 end),2) as CV1Rectificada,
		CONVERT(VARCHAR, sum(case when fcl.fclTrfSvCod=20 and fcl.fclTrfCod not in (201,301,801) then ROUND(fcl.fclPrecio3 * fcl.fclUnidades3,2) else 0 end),2) as CV2Rectificada,
		CONVERT(VARCHAR, sum(case when fcl.fclTrfSvCod=20 and fcl.fclTrfCod not in (201,301,801) then ROUND(fcl.fclPrecio4 * fcl.fclUnidades4 ,2) else 0 end),2) as CV3Rectificada,
		CONVERT(VARCHAR, sum(case when fcl.fclTrfSvCod=20 then ROUND(fcl.fclbase,2) else 0 end),2) AS CVTotalRectificada,
		CONVERT(VARCHAR, SUM(case when (fcl.fclTrfSvCod=19 or fcl.fclTrfSvCod=20) then ROUND(fcl.fclbase,2) else 0 end),2) cuotaTotalRectificada,
		CONVERT(VARCHAR, SUM(case when (fcl.fclTrfSvCod = 20 and fcl.fclTrfCod = 8501) then ROUND(fcl.fclbase,2) else 0 end),2) cuotaVariableFugasRectificada,		
		case
			when (f.facFecha is not null and month(f.facFecha) <= 6) and YEAR(f.facfecha) = '2021' then '7612000004743' 
			when (f.facFecha is not null and month(f.facFecha) <= 6) and YEAR(f.facfecha) = '2020' then '7611000168030'
			when (f.facFecha is not null and month(f.facFecha) > 6) and YEAR(f.facfecha) = '2021' then '7612000017763' 
			when (f.facFecha is not null and month(f.facFecha) > 6) and YEAR(f.facfecha) = '2020' then '7611000164135'
			else null end as modelo761Rectificada
	from agrupUnificadas a
	left join facturas f
		on a.periodo = f.facPerCod and a.contrato = f.facCtrCod and a.facNumero = f.facNumeroRectif
	left join faclin fcl
		ON f.facCod = fcl.fclFacCod and f.facPerCod = fcl.fclFacPerCod and f.facCtrCod = fcl.fclFacCtrCod and f.facVersion = fcl.fclFacVersion	
	group by a.contrato, a.FechaFactura, a.tipo, a.uso, a.facNumero, a.TitDocIden, a.fecInicio, a.fecFin, a.diasF1, a.diasF2, a.consumoAbastecimiento, a.consumoEstimado, a.volumen, a.habitantes, 
			a.ival, a.ccv, a.reduccion, a.cuotaFija, a.CV1, a.CV2, a.CV3, a.CVTotal, a.impDisp, a.cuotaTotal, a.indFact, a.periodo, a.TipoFactura, a.facNumero, a.facNumeroRectif, f.facNumero, 
			f.facFecha, f.facConsumoFactura
), conFugas as(
	select
		r.*,
		case when fcl.fclTrfSvCod is not null then 'S' else 'N' end as indFuga,		
		isnull(CONVERT(VARCHAR, case when fcl.fclTrfSvCod is not null then ROUND(fcl.fclbase,2) else null end, 2), 0.00) as cuotaVariableFugas
	from conRectificadas r
	left join facturas f
		on r.periodo = f.facPerCod and r.contrato = f.facCtrCod and r.facNumero = f.facNumero
	left join faclin fcl
		on f.facCod = fcl.fclFacCod and f.facPerCod = fcl.fclFacPerCod and f.facCtrCod = fcl.fclFacCtrCod and f.facVersion = fcl.fclFacVersion	and fcl.fclTrfSvCod = 20 and fcl.fclTrfCod = 8501
), conFugasConsumo as(
	select 
		tipo, uso, facNumero, contrato, TitDocIden, fecInicio, fecFin, diasF1, diasF2, 
		case when indFuga = 'S' then consumoAbastecimiento else consumoEstimado end consumoAbastecimiento,
		consumoEstimado, volumen, habitantes, ival, ccv, reduccion, cuotaFija, CV1, CV2, CV3, CVTotal, impDisp, cuotaTotal, indFact, periodo,
		tipoFactura, fechaFactura, facNumeroRectificada, facFechaRectificada, ejercicioRectificada, periodoRectificada, consumoRectificada, 
		cuotaFijaRectificada, CV1Rectificada, CV2Rectificada, CV3Rectificada, CVTotalRectificada, cuotaTotalRectificada, cuotaVariableFugasRectificada,
		modelo761Rectificada, indFuga, cuotaVariableFugas
	from conFugas
)

select * from conFugasConsumo

--modificación para canon >= 2023
--where cuotaTotal <> '0.0000' --and cuotaTotalRectificada <> '0.0000'
order by contrato, fechaFactura
GO


