--EXEC [dbo].[Informe_SORIA_CF010_EmisionFactCAB] @periodoD='202012', @periodoH='202012'
 
ALTER PROCEDURE [dbo].[Informe_SORIA_CF010_EmisionFactCAB]
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
	@mostrarFacturasE BIT =NULL,
	@cuales INT =1,
	@orden1 varchar(20) = null,
	@orden2 varchar(20) = null,
	@orden3 varchar(20) = null,
	@repLegal varchar(40) = NULL,
	@filtrarEmision bit = NULL
)
AS
	SET NOCOUNT OFF;

BEGIN
DECLARE @provinciadefecto as varchar(200)
declare @poblaciondefecto as varchar(200)
DECLARE @cpdefecto as varchar(200)
DECLARE @horario as varchar(200)
DECLARE @tLegalPie as varchar(200)
DECLARE @SOCIEDAD_POR_DEFECTO as smallint

set @provinciadefecto=(select pgsvalor from parametros where pgsclave='PROVINCIA_POR_DEFECTO')
set @poblaciondefecto=(select pgsvalor from parametros where pgsclave='POBLACION_POR_DEFECTO') 
set @cpdefecto= (select pgsvalor from parametros where pgsclave='CP_POR_DEFECTO')
set @horario =(select pgsvalor from parametros where pgsclave='HORARIO') 
set  @tLegalPie= (select pgsvalor from parametros where pgsclave='TLEGALPIE') 
set @SOCIEDAD_POR_DEFECTO =(select pgsvalor from parametros where pgsclave='SOCIEDAD_POR_DEFECTO')

SET @fechaCob = ISNULL(@fechaCob, GETDATE())

SELECT 
f0.[facCod], f0.[facPerCod]      ,f0.[facCtrCod]      ,f0.[facVersion]      ,f0.[facSerScdCod]      ,f0.[facSerCod]      ,f0.[facNumero]      ,f0.[facFecha]      ,f0.[facClicod]
      ,f0.[facSerieRectif]      ,f0.[facNumeroRectif]      ,f0.[facFechaRectif]      ,f0.[facLecAnt]      ,f0.[facLecAntFec]      ,f0.[facLecLector]      ,f0.[facLecLectorFec]
      ,f0.[facLecInlCod]      ,f0.[facLecInspector]      ,f0.[facLecInspectorFec]      ,f0.[facInsInlCod]      ,f0.[facLecAct]      ,f0.[facLecActFec]      ,f0.[facConsumoReal]
      ,f0.[facConsumoFactura]      ,f0.[facLote]      ,f0.[facLectorEplCod]      ,f0.[facLectorCttCod]      ,f0.[facInspectorEplCod]      ,f0.[facInspectorCttCod]
      ,f0.[facZonCod]      ,f0.[facInspeccion]      ,f0.[facFecReg],
perdes, pertipo,
(CASE WHEN (inciInspector.inlmc='E' OR inciInspector.inlmc='EP') OR (inciInspector.inlcod IS NULL AND (inciLector.inlmc='E' OR inciLector.inlmc='EP')) THEN 1 ELSE 0 END) AS lecturaEstimada,
ctrPagDocIden, ctrPagNom,ctrPagDir,ctrPagPob, ctrPagPrv, ctrPagCPos, 
ctrTitDocIden, ctrTitNom, ctrTitDir,  ctrTitPob, ctrTitPrv, ctrTitCPos,
ctrEnvNom, ctrEnvDir, ctrEnvPob, ctrEnvPrv, ctrEnvCPos, ctrfecanu,  
ctrruta1, ctrruta2, ctrruta3, ctrruta4, ctrruta5, ctrruta6,
(CASE WHEN LEN(ctrIBAN) >= 24 AND LEN(ctrIBAN) <= 34 THEN
  LEFT(ctrIBAN,4) + SUBSTRING(ctrIBAN,5,4) + SUBSTRING(ctrIBAN,9,4) + REPLICATE('*',2) + REPLICATE('*',6) + SUBSTRING(ctrIBAN, 20, 34)
   ELSE 
  'NÚMERO DE CUENTA NO VÁLIDO'
   END) as iban,  -- cuenta bancaria con asteriscos
scdnom,scddom, scdpob, scdprv,scdcpost, scdnif, scdtlf1, scdtlf2
, ISNULL(n1.nottxt, '') AS n1_nottxt
, ISNULL(n2.nottxt, '') AS n2_nottxt
, inmdireccion, inmPrvCod, inmPobCod, inmMncCod, inmCpost, pobDes, pobcpos, prvDes, mncDes,
mnccpos, cllcpos,
conNumSerie,
conDiametro,
@provinciadefecto  as provinciadefecto,
@poblaciondefecto as poblaciondefecto,
@cpdefecto as cpdefecto,
@horario as horario,
@tLegalPie as tLegalPie,
ofcDireccion,ofcCPPost,ofcPob,ofcPrv,ofcNacion,ofcTlfAtCli,ofcTlfAvr,ofcHorario,
scdImpNombre
, ISNULL(perAvisoPago,'') AS perAvisoPago
, ctrFaceOficCon, ctrFaceOrgGest, ctrFaceUnitrmi, ctrFaceOrgProponente,
f1.facNumero AS numeroRectificada,
f1.facSerCod AS serieRectificada,
f1.facFecha  AS facFechaRectificada
, ISNULL(OBS.obsFactura, '') AS obsFactura
, ISNULL(OBS.obsComplementaria, 1) AS obsComplementaria 
, IIF(ctrIBAN IS NOT NULL AND LEN(ctrIBAN) BETWEEN 24 AND 34, 1, 0) AS facDomiciliada
--Si hay una notificación configurada para mi zona, la muestro
--Sino mostramos la notificación para el resto de zonas 
, ISNULL(IIF(N1.notZon IS NOT NULL, N1.nottxt, N2.nottxt), '') AS txtNotificacion 
, UU.usocod
, UU.usodes

FROM dbo.facturas AS f0
	CROSS APPLY(SELECT conNumSerie, conDiametro, ctcCtr FROM fContratos_ContadoresInstalados(facFecha) WHERE ctcCtr = facCtrCod) AS c
left join facturas f1 on f1.facCod=f0.facCod AND f1.facPerCod=f0.facPerCod AND f1.facCtrCod=f0.facCtrCod AND f1.facVersion=f0.facVersion-1 
left join dbo.fFacturas_TotalCobrado(@fechaCob) TC on TC.ftcFacCod = f0.faccod and TC.ftcPer = f0.facpercod and tc.ftcCtr = f0.facctrcod  
left join dbo.fFacturas_TotalFacturado(null,null,null) TF	on TF.ftfFacCod=f0.facCod and TF.ftfFacPerCod =f0.facPerCod and
			TF.ftfFacVersion = f0.facVersion and TF.ftfFacCtrCod =f0.facCtrCod
inner join periodos on f0.facpercod=percod

INNER JOIN dbo.contratos AS CC 
ON  CC.ctrcod = f0.facCtrCod 
AND CC.ctrversion = f0.facCtrversion

inner join inmuebles on ctrinmcod=inmcod
inner join provincias on inmPrvCod = prvCod
inner join poblaciones on inmPobCod = pobCod and inmPrvCod = pobPrv
inner join municipios on inmMncCod = mncCod and inmPobCod = mncPobCod and inmPrvCod = mncPobPrv
inner join calles on cllcod = inmcllcod and cllmnccod = inmmnccod and cllPobCod = inmPobCod and cllPrvCod = inmPrvCod
left join sociedades on scdcod=ISNULL(f0.facserscdcod,ISNULL((@SOCIEDAD_POR_DEFECTO),1))
--******** O B S E R V A C I O N E S ********
--N1: PARA UNA ZONA
LEFT JOIN dbo.notificaciones AS N1 
ON N1.notPer=f0.facpercod AND N1.notzon=f0.faczoncod
--N2: RESTO DE ZONAS
LEFT JOIN dbo.notificaciones AS N2 
ON N2.notPer=f0.facpercod AND N2.notzon='-'
--*******************************************
left join online_usuarios on ISNULL(ctrPagdociden,ctrTitDocIden) = usrLogin
left join oficinas on scdOfcCod = ofcCodigo
LEFT JOIN incilec as inciLector ON inciLector.inlcod = f0.facLecInlCod
LEFT JOIN incilec as inciInspector ON inciInspector.inlcod = f0.facInsInlCod

OUTER APPLY dbo.fFacObservacionesImp(f0.facctrcod, f0.facpercod) AS OBS

LEFT JOIN dbo.usos AS UU
ON UU.usocod = CC.ctrUsoCod
WHERE
--********************************************************
ctcCtr = f0.facCtrCod AND
(@mostrarFacturasOnline IS NULL OR @mostrarFacturasOnline = 1 OR (@mostrarFacturasOnline = 0 AND ISNULL(usrEFactura,0) = 0)) AND 
( 
  @mostrarFacturasE IS NULL OR 
 (@mostrarFacturasE = 0 AND (ctrFaceTipoEnvio = 'POSTAL' OR (ISNULL(f0.facEnvSERES, 'X') <> 'E' AND ISNULL(f0.facEnvSERES, 'X') <> 'P' AND ISNULL(f0.facEnvSERES, 'X') <> 'R'))) OR
 (@mostrarFacturasE = 1 AND f0.facEnvSERES IS NOT NULL)
)
and (f0.facCod >= @codigoD or @codigoD IS NULL)
and (f0.facCod <= @codigoH or @codigoH IS NULL)
AND (@filtrarEmision IS NULL OR @filtrarEmision = 0 OR (@filtrarEmision = 1 AND ISNULL(ctrNoEmision, 0) = 0))
and f0.facPerCod >= @periodoD
and f0.facPerCod <= @periodoH
and (f0.facFecha>= @fechaD OR @fechaD IS NULL)
and (f0.facFecha<= @fechaH OR @fechaH IS NULL)
and (f0.facCtrCod >= @contratoD OR @contratoD IS NULL)
and (f0.facCtrCod <= @contratoH OR @contratoH IS NULL)
and (f0.facVersion >= @versionD OR @versionD IS NULL)
and (f0.facVersion <= @versionH OR @versionH IS NULL)
and (f0.facZonCod >= @zonaD  OR @zonaD IS NULL)
and (f0.facZonCod <= @zonaH OR @zonaH IS NULL)
and (f0.facCliCod >= @clienteD  OR @clienteD IS NULL)
and (f0.facCliCod <= @clienteH OR @clienteH IS NULL)
and (inmCod >= @inmuebleD  OR @inmuebleD IS NULL)
and (inmCod <= @inmuebleH OR @inmuebleH IS NULL)
-- Si @preFactura es 0 entonces saca las facturas definitivas y si es 1 saca todas junto con las preFACTURAS. Si es NULL, no tiene en cuenta este parámetro
and ((f0.facNumero IS NOT NULL  and @preFactura=0) OR @preFactura=1 OR @preFactura IS NULL)


and (f0.facFechaRectif IS NULL OR @verTodas=1)   -- verTodas junto con las rectificadas
and 
(
@cuales = 1 or

 (@cuales = 2 and 
  (
  isnull(TF.ftfImporte,0) <=
    isnull(TC.ftcImporte,0)
  )
 ) or

 (@cuales = 3 and 
  (
  isnull(TF.ftfImporte,0) >
  isnull(TC.ftcImporte,0)
  )
 )
)

AND (@repLegal IS NULL OR ctrRepresent LIKE '%' + @repLegal + '%')

ORDER BY
  CASE @orden1
       WHEN 'contrato' THEN CAST(REPLICATE('0',10-LEN(CAST(f0.facCtrCod AS VARCHAR))) + CAST(f0.facCtrCod AS VARCHAR) AS VARCHAR)
       WHEN 'periodo' THEN CAST(f0.facPerCod as varchar)
       ELSE                           REPLICATE('0',10-LEN(ISNULL(ctrRuta1,''))) + ISNULL(ctrRuta1,'') 
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
       WHEN 'periodo' THEN CAST(f0.facPerCod as varchar)
       ELSE CAST(REPLICATE('0',10-LEN(CAST(f0.facCtrCod AS VARCHAR))) + CAST(f0.facCtrCod AS VARCHAR) AS VARCHAR)
  END,
  CASE @orden3
      WHEN 'ruta' THEN REPLICATE('0',10-LEN(ISNULL(ctrRuta1,''))) + ISNULL(ctrRuta1,'') 
                      +REPLICATE('0',10-LEN(ISNULL(ctrRuta2,''))) + ISNULL(ctrRuta2,'')
                      +REPLICATE('0',10-LEN(ISNULL(ctrRuta3,''))) + ISNULL(ctrRuta3,'')
                      +REPLICATE('0',10-LEN(ISNULL(ctrRuta4,''))) + ISNULL(ctrRuta4,'')
                      +REPLICATE('0',10-LEN(ISNULL(ctrRuta5,''))) + ISNULL(ctrRuta5,'')
                      +REPLICATE('0',10-LEN(ISNULL(ctrRuta6,''))) + ISNULL(ctrRuta6,'')
       WHEN 'contrato' THEN CAST(REPLICATE('0',10-LEN(CAST(f0.facCtrCod AS VARCHAR))) + CAST(f0.facCtrCod AS VARCHAR) AS VARCHAR)
       ELSE CAST(f0.facPerCod as varchar)
   END
   
   END

GO


