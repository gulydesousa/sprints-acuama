/*
DECLARE @fechaFacturaD AS DATETIME = '20220101',
@fechaFacturaH AS DATETIME = '20221231',
@fechaLiquidacionD AS DATETIME = NULL,
@fechaLiquidacionH AS DATETIME = NULL,
@periodoD AS VARCHAR(6) = NULL,
@periodoH AS VARCHAR(6) = NULL,
@zonaD AS VARCHAR(4) = NULL,
@zonaH AS VARCHAR(4) = NULL

EXEC [dbo].[Liquidaciones_Select_AVG] @fechaFacturaD, @fechaFacturaH
, @fechaLiquidacionD, @fechaLiquidacionH
, @periodoD, @periodoH
, @zonaD, @zonaH;

*/
--DROP PROCEDURE [dbo].[Liquidaciones_Select_AVG]

CREATE  PROCEDURE [dbo].[Liquidaciones_Select_AVG]
@fechaFacturaD AS DATETIME = NULL,
@fechaFacturaH AS DATETIME = NULL,
@fechaLiquidacionD AS DATETIME = NULL,
@fechaLiquidacionH AS DATETIME = NULL,
@periodoD AS VARCHAR(6) = NULL,
@periodoH AS VARCHAR(6) = NULL,
@zonaD AS VARCHAR(4) = NULL,
@zonaH AS VARCHAR(4) = NULL
AS

BEGIN

DECLARE @tabla1 TABLE(cli int,fechaIni datetime, fechaFin datetime, t1p1 decimal(12,4), t2p1 decimal(12,4), t3p1 decimal(12,4), tndP1 decimal(12,4), tpP1 decimal(12,4))

DECLARE @tabla2 TABLE(cli int,fechaIni2 datetime, fechaFin2 datetime, t1p2 decimal(12,4), t2p2 decimal(12,4), t3p2 decimal(12,4), tndP2 decimal(12,4), tpP2 decimal(12,4))

DECLARE @ejercicio varchar(4)

DECLARE @fecFinMigracion datetime = '05/03/2019'
declare @fechaPerD as datetime = NULL
declare @fechaPerH as datetime = NULL

set @fechaPerD = (select top 1 przfPeriodoD from perzona where przcodper = @periodoD)
set @fechaPerH = (select top 1 przfPeriodoH from perzona where przcodper = @periodoH)

IF(@periodoD is null)
begin

	IF(@fechaLiquidacionD is not null)
		set @ejercicio = (select year(@fechaLiquidacionD))
	ELSE
		set @ejercicio = (select year(@fechaFacturaD))

end
ELSE
	SET @ejercicio=SUBSTRING(@periodoD,1,4)


--NUEVO
	 IF
		(select COUNT(*) from tarval where trvsrvcod=20 and trvtrfcod=101 and trvfecha like '%' + @ejercicio + '%')<2
		BEGIN
			INSERT INTO @tabla1	
			select TOP 1 1,'01/01/'+@ejercicio fIni, '31/12/'+@ejercicio fFin, 
			trvprecio2,trvprecio3,trvprecio4,
			(select trvprecio1 from tarval where trvsrvcod=20 and trvtrfcod=201 and trvfecha=(select MAX(t.trvfecha) from tarval t
																	where t.trvfecha<=('01/01/'+@ejercicio)
																	and t.trvsrvcod=20 and t.trvtrfcod=201)
			),
			(select trvprecio1 from tarval where trvsrvcod=20 and trvtrfcod=8501 and trvfecha=(select MAX(t.trvfecha) from tarval t
																	where t.trvfecha<=('01/01/'+@ejercicio)
																	and t.trvsrvcod=20 and t.trvtrfcod=8501)
			)
			from tarval where trvsrvcod=20 and trvtrfcod=101 and trvfecha =
																(
																	select MAX(t.trvfecha) from tarval t
																	where t.trvfecha<=('01/01/'+@ejercicio)
																	and t.trvsrvcod=20 and t.trvtrfcod=101
																)

			Insert into @tabla2
			values
			(1, null, null, null, null, null, null, null)
		END
	ELSE
		BEGIN
			INSERT INTO @tabla1	
			select TOP 1 1,'01/01/'+@ejercicio fIni, trvfechafin fFin, 
			trvprecio2,trvprecio3,trvprecio4,
			null,null
			from tarval where trvsrvcod=20 and trvtrfcod=101 and trvfecha =
																(
																	select MAX(t.trvfecha) from tarval t
																	where t.trvfecha<=('01/01/'+@ejercicio)
																	and t.trvsrvcod=20 and t.trvtrfcod=101
																)
			order by trvfecha

			INSERT INTO @tabla2
			select TOP 1 1,trvfecha fIni, trvfechafin fFin, 
			trvprecio2,trvprecio3,trvprecio4,
			null,null
			from tarval where trvsrvcod=20 and trvtrfcod=101 and trvfecha like '%' + @ejercicio + '%'
			order by trvfecha desc
		END


--INICIO
SELECT 
	'I' tipo,
	 clidociden,
	 SUBSTRING(clinom,1,125) clinom,
	 @ejercicio ejercicio,
	 'N' indTarifa,
	 t.fechaIni fecIni,
	 t.fechaFin fecFin,
	 t.t1p1 t1p1,
	 t.t2p1 t2p1,
	 t.t3p1 t3p1,
	 t.tndP1 tndp1,
	 t.tpP1 tpp1,
	 t2.fechaIni2 fechaIni2,
	 t2.fechaFin2 fechaFin2,
	 t2.t1p2 t1p2,
	 t2.t2p2 t2p2,
	 t2.t3p2 t3p2,
	 t2.tndP2 tndP2,
	 t2.tpP2 tpP2
from clientes
inner join @tabla1 t
	on clicod=t.cli
inner join @tabla2 t2
	on clicod=t2.cli
where clicod=1


IF OBJECT_ID(N'tempdb..#tempContratos') IS NOT NULL 
begin
   DROP TABLE #tempContratos
end

IF OBJECT_ID(N'tempdb..#contratos') IS NOT NULL
begin
   DROP TABLE #contratos;  
end

--**************************************************************
--Evolutivo: Liquidaciones 2022
--**************************************************************
EXEC Liquidaciones_RegistrosContratos_AVG @fechaFacturaD, @fechaFacturaH
, @fechaLiquidacionD, @fechaLiquidacionH
, @periodoD, @periodoH
, @zonaD, @zonaH;


----------------------------------------------------------------
DECLARE @entidadSuministradora VARCHAR(25) = 'A11768546';
DECLARE @cnsTitular TABLE(ctrTitDocIden VARCHAR(25), CNS INT);

INSERT INTO @cnsTitular
EXEC [dbo].[Facturas_ConsumosPorTitular] @fechaFacturaD, @fechaFacturaH
, @fechaLiquidacionD, @fechaLiquidacionH
, @periodoD, @periodoH
, @zonaD, @zonaH
, @entidadSuministradora;

--Buscamos el cliente por documento de identidad
WITH CLI AS(
SELECT clicod, clidociden, clinom 
--RN=1: Para quedarnos con el ultimo cliente por codigo
, RN= ROW_NUMBER() OVER (ORDER BY clicod DESC)
FROM dbo.clientes AS C 
WHERE C.clidociden=@entidadSuministradora
)

--A: Volumen Abastecido
--Campo numérico con el volumen abastecido por el tercero. 
--Dato que no está en acuama, lo dejamos a cero para que el usuario lo complete tras la descarga
SELECT tipo ='A'
, clidociden = C.clidociden
, clinombre = SUBSTRING(C.clinom, 1, 125) 
, consumo = 0
FROM CLI AS C WHERE RN=1

UNION 
--S: Volumen Suministrado
--Campo numérico con el volumen suministrado al tercero.
--Es el total de consumo facturado al cliente
SELECT tipo ='S'
, clidociden = C.clidociden
, clinombre = SUBSTRING(C.clinom, 1, 125)
, volumen = CN.CNS
FROM CLI AS C
LEFT JOIN @cnsTitular AS CN
ON C.clidociden = CN.ctrTitDocIden
WHERE C.RN=1
RETURN;
--**************************************************************














--en caso de que haya distintas tarifas, domésticas y no domésticas, siempre priorizo no doméstico
;with aux as (
SELECT 	
	 distinct C.ctrcod contrato,
	 C.ctrVersion ctrVersion,
	 C.ctrTitDocIden Titular,
	 'C' tipo,	 
	  case WHEN C.ctrTitTipDoc in ('0','1') then 'F'
	       WHEN C.ctrTitTipDoc in ('2','4') then 'E'
		else 'O'
	 end as tipoIdent,
	 SUBSTRING(C.ctrTitNom,1,125) nomTit,
	 CASE WHEN C.ctrTitDir<>inmDireccion THEN SUBSTRING(C.ctrTitDir,1,250) ELSE NULL END AS titDir,
	 '11' as titPrv,
	 '0337' as titPob,
	 CASE WHEN (C.ctrComunitario IS NULL AND C.ctrValorc1 > 1) then 'C' else 'I' end as contador,
	 case when ctstar in (101,401,501,601,701,1001,8501) then 'D' else 'N' end uso,
	 CASE WHEN (C.ctrComunitario IS NULL AND C.ctrValorc1 > 1) 
		then (C.ctrValorc1) 
		else NULL end as usuarios,
	case
		when len(trim(inmrefcatastral)) = 20 then trim(inmrefcatastral)
		else null end as refCatastral,
	SUBSTRING(inmDireccion,1,250) dirAbastecida,
	3 periodicidad,
	ctrfecreg, ctrfecanu, ctrbaja,
	
	--(case 
	--	when (C.ctrVersion = 1 AND (C.ctrfecanu IS NULL OR C.ctrfecanu > @fechaFacturaH) 
	--		AND (C.ctrfecreg BETWEEN @fechaFacturaD AND @fechaFacturaH)) then 'C' 
	--	when (C.ctrVersion > 1 AND (C.ctrfecanu IS NULL OR C.ctrfecanu > @fechaFacturaH) 
	--		AND (C.ctrfecreg BETWEEN @fechaFacturaD AND @fechaFacturaH)
	--		and (select top 1 C1.ctrTitDocIden from contratos C1 where C1.ctrcod = C.ctrcod and C1.ctrversion = (C.ctrversion - 1)) <> C.ctrTitDocIden) then 'T'
	--	else null end) indAlta,
	--	--hay que tener en cuenta el cambio de titularidad, no el cambio de versión

	--(case 
	--	when((C.ctrfecanu is not null AND C.ctrfecanu BETWEEN @fechaFacturaD AND @fechaFacturaH) and
	--			(select top 1 C1.ctrTitDocIden from contratos C1 where C1.ctrcod = C.ctrcod and C1.ctrversion = (C.ctrversion + 1)) is null) then 'C' 
	--	when ((C.ctrfecanu is not null AND C.ctrfecanu BETWEEN @fechaFacturaD AND @fechaFacturaH) and
	--			(select top 1 C1.ctrTitDocIden from contratos C1 where C1.ctrcod = C.ctrcod and C1.ctrversion = (C.ctrversion + 1)) <> C.ctrTitDocIden) then 'T'
	--	else null end) indBaja,

	facPercod, facVersion, facCod, facNumero, facNumeroRectif
from contratos C
INNER JOIN inmuebles
	on C.ctrinmcod= inmcod
INNER JOIN facturas on facCtrCod = C.ctrcod  and facCtrVersion = C.ctrversion
INNER JOIN faclin on fclFacCtrCod= facCtrCod and fclFacPerCod= facPerCod and fclFacCod= facCod and fclFacVersion= facVersion
left join contratoServicio
	on ctrcod = ctsctrcod and ctssrv = 20

where 
	  ((facFecha <= @fecFinMigracion) OR (facFecha > @fecFinMigracion))		
	  --modificación para canon >= 2023
	  --AND fcltotal <> 0.0	
	  
	  AND
	  (fclFecLiqImpuesto IS NOT NULL AND fclUsrLiqImpuesto IS NOT NULL) AND
	  (facFecha >= @fechaFacturaD OR @fechaFacturaD IS NULL) AND
	  (facFecha <= @fechaFacturaH OR @fechaFacturaH IS NULL) AND
	  (facFecha >= @fechaPerD OR @fechaPerD IS NULL) AND
	  (facFecha <= @fechaPerH OR @fechaPerH IS NULL) AND
	  (fclFecLiqImpuesto >= @fechaLiquidacionD OR @fechaLiquidacionD IS NULL) AND
	  (fclFecLiqImpuesto <= @fechaLiquidacionH OR @fechaLiquidacionH IS NULL) AND
	  (((facPerCod >= @periodoD OR @periodoD IS NULL) AND
	  (facPerCod <= @periodoH OR @periodoH IS NULL))
		OR 
		((facPerCod like '0%') 
			AND ((facFecha >= @fechaPerD OR @fechaPerD IS NULL) AND (facFecha <= @fechaPerH OR @fechaPerH IS NULL))
		)
	  ) 
	  AND
	  (ctrZonCod >= @zonaD OR @zonaD IS NULL) AND
	  (ctrZonCod <= @zonaH OR @zonaH IS NULL )
	  --new
	  AND
	  (facFechaRectif is null

		OR
		(
			facFechaRectif is not null and fclTrfSvCod in (19,20)
		)
	)			 
), rectConServicio as (
	
	select 
		a.*, fcl.* 
	from aux a
	inner join facturas f
		on f.facNumero = a.facNumeroRectif and a.contrato = f.facCtrCod
	inner join faclin fcl
		on fclFacCtrCod = f.facCtrCod and fclFacPerCod = f.facPerCod and fclFacCod = f.facCod and fclFacVersion = f.facVersion
			and fclTrfSvCod in (19,20)

), contratosConServicio as(

	select 
		contrato, ctrVersion, Titular, tipo, tipoIdent, nomTit, titDir, titPrv, titPob, contador, uso, usuarios, refCatastral, dirAbastecida, periodicidad,
		ctrfecreg, ctrfecanu, ctrbaja
	from aux
	where 
		facNumeroRectif is null
		or
		facNumeroRectif in (select facNumeroRectif from rectConServicio)

), auxNumber as (
	select 
		ROW_NUMBER() OVER (PARTITION BY contrato, ctrVersion ORDER BY uso desc) row_num
	, * 
	from contratosConServicio

), auxDom as (

	select contrato, ctrVersion, Titular, tipo, tipoIdent, nomTit, titDir, titPrv, titPob, contador, 
		case 
			when contrato = 8753 and ctrVersion = 1 then 'D'
			when contrato = 8753 and ctrVersion = 1 then 'N'
			else uso end as uso, 
		usuarios, refCatastral, dirAbastecida, periodicidad, ctrfecreg, ctrfecanu, ctrbaja
	 from auxNumber
	where row_num = 1

), auxUsuarios as (

	select contrato, ctrVersion, Titular, tipo, tipoIdent, nomTit, titDir, titPrv, titPob, contador, uso, usuarios, 
		ROW_NUMBER() OVER (PARTITION BY contrato, titular ORDER BY ctrVersion desc) row_num_users,
		refCatastral, dirAbastecida, periodicidad, ctrfecreg, ctrfecanu, ctrbaja
	 from auxNumber
	where row_num = 1

), auxUsuariosFinal as (

	select a1.contrato, a1.ctrVersion, a1.Titular, a1.tipo, a1.TipoIdent, a1.nomTit, a1.titDir, a1.titPrv, a1.titPob, a1.contador, a1.uso, 
			a2.usuarios, 
			a1.refCatastral, a1.dirAbastecida, a1.periodicidad, a1.ctrfecreg, a1.ctrfecanu, a1.ctrbaja
	from auxUsuarios a1
	inner join auxUsuarios a2 on a1.contrato = a2.contrato and a1.Titular = a2.Titular and a2.row_num_users = 1

), auxDomNumber as (

	select 
		*,
		cast(null as varchar) indAlta,
		cast(null as varchar) indBaja,
		ROW_NUMBER() OVER (PARTITION BY null ORDER BY contrato, ctrVersion) RN
	from auxUsuariosFinal

)

--select * from auxDomNumber

	--ahora recorro para actualizar los indicadores de alta y baja
	select *
	into #tempContratos
	from auxDomNumber
	
	--la final que voy a actualizar
	select *
	into #contratos
	from #tempContratos

	DECLARE 
	  @count int = 0
      ,@contrato int
      ,@ctrVersion int
	  ,@fechaRegistro datetime
	  ,@fechaBaja datetime
	  ,@titular varchar (100)
	  ,@ctrbaja bit
	  ,@num_registro int = 1


	BEGIN
		SELECT @count = COUNT(*) FROM #tempContratos;

		WHILE @count > 0
		BEGIN
			SET @contrato = (SELECT contrato FROM #tempContratos where RN = @num_registro)
			SET @ctrVersion = (SELECT ctrVersion FROM #tempContratos where RN = @num_registro)
			SET @fechaRegistro = (SELECT ctrfecreg FROM #tempContratos where RN = @num_registro)
			SET @fechaBaja = (SELECT ctrfecanu FROM #tempContratos where RN = @num_registro)
			SET @titular = (SELECT Titular FROM #tempContratos where RN = @num_registro)
			SET @ctrbaja = (SELECT ctrbaja FROM #tempContratos where RN = @num_registro)			

			--altas
			if (@ctrVersion = 1 and (@fechaRegistro between @fechaFacturaD and @fechaFacturaH))
			begin
				update #contratos
				set indAlta = 'C'
				where RN = @num_registro
			end
			else
				if ((@contrato = (select contrato from #contratos where RN = @num_registro-1)) and (@titular <> (select Titular from #contratos where RN = @num_registro-1)))
				begin
					update #contratos
					set indAlta = 'T'
					where RN = @num_registro
				end
						
			--bajas
			if (@ctrbaja = 1 and (@fechaBaja between @fechaFacturaD and @fechaFacturaH))
			begin
				update #contratos
				set indBaja = 'C'
				where RN = @num_registro
			end
			else
				if ((@contrato = (select contrato from #contratos where RN = @num_registro+1)) and (@titular <> (select Titular from #contratos where RN = @num_registro+1)))
				begin
					update #contratos
					set indBaja = 'T'
					where RN = @num_registro
				end


			DELETE FROM #tempContratos WHERE RN = @num_registro
			
			SET @num_registro = @num_registro + 1

			SELECT @count = COUNT(*) FROM #tempContratos;
			print @num_registro
		END
	END	
	
select * from #contratos
order by contrato


--A
select
'A' tipo,
ctrTitDocIden clidociden,
SUBSTRING(ctrTitNom,1,125) clinombre,
1939120 consumo
from contratos
where ctrcod=6140

UNION

--S
select
'S' tipo,
ctrTitDocIden clidociden,
SUBSTRING(ctrTitNom,1,125) clinombre,
96240 volumen
from contratos
where ctrcod=6140


END
GO


