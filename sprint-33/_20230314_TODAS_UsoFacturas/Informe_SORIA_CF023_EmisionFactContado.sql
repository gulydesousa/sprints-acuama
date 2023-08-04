--EXEC [dbo].[Informe_SORIA_CF023_EmisionFactContado]  @periodoD='000001', @periodoH='000001'
ALTER PROCEDURE [dbo].[Informe_SORIA_CF023_EmisionFactContado]
(
	@codigoD SMALLINT =NULL,
	@codigoH SMALLINT =NULL,
	@periodoD varchar(6) = NULL,		
	@periodoH varchar(6) = NULL,		
	@zonaD varchar(4)=NULL,
	@zonaH varchar(4)=NULL,
	@fechaD datetime = NULL,
	@fechaH datetime = NULL,
	@contratoD INT =NULL,
	@contratoH INT =NULL,
	@versionD SMALLINT =NULL,
	@versionH SMALLINT =NULL,	
	@clienteD INT = NULL,
	@clienteH INT =NULL,
	@inmuebleD INT =NULL,
	@inmuebleH INT =NULL,
	@preFactura BIT =NULL,
	@verTodas BIT =0,
	@fechaCob DATETIME = null,
	@mostrarFacturasOnline BIT =NULL,
	@cuales INT =1,
	@orden1 varchar(20) = null,
	@orden2 varchar(20) = null,
	@orden3 varchar(20) = null
)
AS
	SET NOCOUNT OFF;

BEGIN

SET @fechaCob = ISNULL(@fechaCob, GETDATE())
SELECT 
[facCod], [facPerCod]      ,[facCtrCod]      ,[facVersion]      ,[facSerScdCod]      ,[facSerCod]      ,[facNumero]      ,[facFecha]      ,[facClicod]
      ,[facSerieRectif]      ,[facNumeroRectif]      ,[facFechaRectif]      ,[facLecAnt]      ,[facLecAntFec]      ,[facLecLector]      ,[facLecLectorFec]
      ,[facLecInlCod]      ,[facLecInspector]      ,[facLecInspectorFec]      ,[facInsInlCod]      ,[facLecAct]      ,[facLecActFec]      ,[facConsumoReal]
      ,[facConsumoFactura]      ,[facLote]      ,[facLectorEplCod]      ,[facLectorCttCod]      ,[facInspectorEplCod]      ,[facInspectorCttCod]
      ,[facZonCod]      ,[facInspeccion]      ,[facFecReg],
perdes, pertipo,
ctrPagDocIden, ctrPagNom,ctrPagDir,ctrPagPob, ctrPagPrv, ctrPagCPos, 
ctrTitDocIden, ctrTitNom, ctrTitDir,  ctrTitPob, ctrTitPrv, ctrTitCPos,
ctrEnvNom, ctrEnvDir, ctrEnvPob, ctrEnvPrv, ctrEnvCPos,  
ctrruta1, ctrruta2, ctrruta3, ctrruta4, ctrruta5, ctrruta6,
(CASE WHEN LEN(ctrIBAN) >= 24 AND LEN(ctrIBAN) <= 34 THEN
LEFT(ctrIBAN,4) + SUBSTRING(ctrIBAN,5,4) + SUBSTRING(ctrIBAN,9,4) + REPLICATE('*',2) + REPLICATE('*',6) + SUBSTRING(ctrIBAN, 20, 34)
   ELSE 
  'NÚMERO DE CUENTA NO VÁLIDO'
   END) as iban,  -- cuenta bancaria con asteriscos
scdnom,scddom, scdpob, scdprv,scdcpost, scdnif, scdtlf1, scdtlf2,
n1.nottxt as n1_nottxt, n2.nottxt as n2_nottxt,
inmdireccion, inmPrvCod, inmPobCod, inmMncCod, inmCpost, pobDes, pobcpos, prvDes, mncDes,
mnccpos, cllcpos,
conNumSerie,
conDiametro,
(select pgsvalor from parametros where pgsclave='PROVINCIA_POR_DEFECTO') as provinciadefecto,
(select pgsvalor from parametros where pgsclave='POBLACION_POR_DEFECTO') as poblaciondefecto,
(select pgsvalor from parametros where pgsclave='CP_POR_DEFECTO') as cpdefecto,
(select pgsvalor from parametros where pgsclave='HORARIO') as horario,
(select pgsvalor from parametros where pgsclave='TLEGALPIE') as tLegalPie,
ofcDireccion,ofcCPPost,ofcPob,ofcPrv,ofcNacion,ofcTlfAtCli,ofcTlfAvr,ofcHorario,
scdImpNombre,
perAvisoPago,
(CASE WHEN ISNULL(ctrFaceOficCon,'')<>'' AND ISNULL(ctrFaceOrgGest,'')<>'' AND ISNULL(ctrFaceUnitrmi,'')<>''
 THEN 1 ELSE 0 END) AS mostrarDir3,
ctrFaceOficCon, ctrFaceOrgGest, ctrFaceUnitrmi, ctrFaceOrgProponente

, UU.usocod
, UU.usodes
FROM dbo.facturas AS FF
	CROSS APPLY(SELECT conNumSerie, conDiametro, ctcCtr FROM fContratos_ContadoresInstalados(facFecha) WHERE ctcCtr = facCtrCod) AS c
inner join periodos on facpercod=percod

INNER JOIN dbo.contratos AS CC 
ON CC.ctrcod = FF.facCtrCod 
AND CC.ctrversion = FF.facCtrversion

inner join inmuebles on ctrinmcod=inmcod
inner join provincias on inmPrvCod = prvCod
inner join poblaciones on inmPobCod = pobCod and inmPrvCod = pobPrv
inner join municipios on inmMncCod = mncCod and inmPobCod = mncPobCod and inmPrvCod = mncPobPrv
inner join calles on cllcod = inmcllcod and cllmnccod = inmmnccod and cllPobCod = inmPobCod and cllPrvCod = inmPrvCod
left join sociedades on scdcod=ISNULL(facserscdcod,ISNULL((select pgsvalor from parametros where pgsclave='SOCIEDAD_POR_DEFECTO'),1))
left join notificaciones n1 on n1.notPer=facpercod and n1.notzon=faczoncod
left join notificaciones n2 on n2.notPer=facpercod and n2.notzon='-'

left join online_usuarios on ctrPagdociden = usrLogin

left join oficinas on scdOfcCod = ofcCodigo

LEFT JOIN dbo.usos AS UU
ON UU.usocod = CC.ctrUsoCod
WHERE
--********************************************************
ctcCtr = facCtrCod AND
(@mostrarFacturasOnline IS NULL OR @mostrarFacturasOnline = 1 OR (@mostrarFacturasOnline = 0 AND ISNULL(usrEFactura,0) = 0))

and facPerCod >= @periodoD
and facPerCod <= @periodoH
and (facCod >= @codigoD or @codigoD IS NULL)
and (facCod <= @codigoH or @codigoH IS NULL)
and (facFecha>= @fechaD OR @fechaD IS NULL)
and (facFecha<= @fechaH OR @fechaH IS NULL)
and (facCtrCod >= @contratoD OR @contratoD IS NULL)
and (facCtrCod <= @contratoH OR @contratoH IS NULL)
and (facVersion >= @versionD OR @versionD IS NULL)
and (facVersion <= @versionH OR @versionH IS NULL)
and (facZonCod >= @zonaD  OR @zonaD IS NULL)
and (facZonCod <= @zonaH OR @zonaH IS NULL)
and (facCliCod >= @clienteD  OR @clienteD IS NULL)
and (facCliCod <= @clienteH OR @clienteH IS NULL)
and (inmCod >= @inmuebleD  OR @inmuebleD IS NULL)
and (inmCod <= @inmuebleH OR @inmuebleH IS NULL)
-- Si @preFactura es 0 entonces saca las facturas definitivas y si es 1 saca todas junto con las preFACTURAS. Si es NULL, no tiene en cuenta este parámetro
and ((facNumero IS NOT NULL  and @preFactura=0) OR @preFactura=1 OR @preFactura IS NULL)


and (facFechaRectif IS NULL OR @verTodas=1)   -- verTodas junto con las rectificadas
and 
(
@cuales = 1 or

 (@cuales = 2 and 
  (
  isnull((select sum(fcltotal) from faclin where fclfaccod = faccod and fclfacpercod = facpercod and fclfacctrcod = facctrcod and fclfacversion = facversion
  AND((fclFecLiq>=@fechaH) OR (fclFecLiq IS NULL AND fclUsrLiq IS NULL))	),0) <=
  isnull((select sum(cblimporte) from coblin, cobros where cobFecReg <= @fechaCob and cobScd = cblScd and cobPpag = cblPpag and cobNum = cblNum and cobCtr = facctrcod and cblper = facpercod and cblfaccod = facCod),0)
  )
 ) or

 (@cuales = 3 and 
  (
  isnull((select sum(fcltotal) from faclin where fclfaccod = faccod and fclfacpercod = facpercod and fclfacctrcod = facctrcod and fclfacversion = facversion
  AND((fclFecLiq>=@fechaH) OR (fclFecLiq IS NULL AND fclUsrLiq IS NULL))	),0) >
  isnull((select sum(cblimporte) from coblin, cobros where cobFecReg <= @fechaCob and cobScd = cblScd and cobPpag = cblPpag and cobNum = cblNum and cobCtr = facctrcod and cblper = facpercod and cblfaccod = facCod),0)
  )
 )
)

ORDER BY
  CASE @orden1
       WHEN 'contrato' THEN CAST(REPLICATE('0',10-LEN(CAST(facCtrCod AS VARCHAR))) + CAST(facCtrCod AS VARCHAR) AS VARCHAR)
       WHEN 'periodo' THEN CAST(facPerCod as varchar)
       ELSE          REPLICATE('0',10-LEN(ISNULL(ctrRuta1,''))) + ISNULL(ctrRuta1,'') 
                      +REPLICATE('0',10-LEN(ISNULL(ctrRuta2,''))) + ISNULL(ctrRuta2,'')
                      +REPLICATE('0',10-LEN(ISNULL(ctrRuta3,''))) + ISNULL(ctrRuta3,'')
                      +REPLICATE('0',10-LEN(ISNULL(ctrRuta4,''))) + ISNULL(ctrRuta4,'')
                      +REPLICATE('0',10-LEN(ISNULL(ctrRuta5,''))) + ISNULL(ctrRuta5,'')
                      +REPLICATE('0',10-LEN(ISNULL(ctrRuta6,''))) + ISNULL(ctrRuta6,'')
  END,
  CASE @orden2
      WHEN 'ruta' THEN REPLICATE('0',10-LEN(ISNULL(ctrRuta1,''))) + ISNULL(ctrRuta1,'') 
                      +REPLICATE('0',10-LEN(ISNULL(ctrRuta2,''))) + ISNULL(ctrRuta2,'')
                      +REPLICATE('0',10-LEN(ISNULL(ctrRuta3,''))) + ISNULL(ctrRuta3,'')
                      +REPLICATE('0',10-LEN(ISNULL(ctrRuta4,''))) + ISNULL(ctrRuta4,'')
                      +REPLICATE('0',10-LEN(ISNULL(ctrRuta5,''))) + ISNULL(ctrRuta5,'')
                      +REPLICATE('0',10-LEN(ISNULL(ctrRuta6,''))) + ISNULL(ctrRuta6,'')
       WHEN 'periodo' THEN CAST(facPerCod as varchar)
       ELSE CAST(REPLICATE('0',10-LEN(CAST(facCtrCod AS VARCHAR))) + CAST(facCtrCod AS VARCHAR) AS VARCHAR)
  END,
  CASE @orden3
      WHEN 'ruta' THEN REPLICATE('0',10-LEN(ISNULL(ctrRuta1,''))) + ISNULL(ctrRuta1,'') 
                      +REPLICATE('0',10-LEN(ISNULL(ctrRuta2,''))) + ISNULL(ctrRuta2,'')
                      +REPLICATE('0',10-LEN(ISNULL(ctrRuta3,''))) + ISNULL(ctrRuta3,'')
                      +REPLICATE('0',10-LEN(ISNULL(ctrRuta4,''))) + ISNULL(ctrRuta4,'')
                      +REPLICATE('0',10-LEN(ISNULL(ctrRuta5,''))) + ISNULL(ctrRuta5,'')
                      +REPLICATE('0',10-LEN(ISNULL(ctrRuta6,''))) + ISNULL(ctrRuta6,'')
       WHEN 'contrato' THEN CAST(REPLICATE('0',10-LEN(CAST(facCtrCod AS VARCHAR))) + CAST(facCtrCod AS VARCHAR) AS VARCHAR)
       ELSE CAST(facPerCod as varchar)
   END
   
   END
GO


