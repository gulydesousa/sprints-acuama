
/*
DECLARE @codigoD SMALLINT =NULL,
	@codigoH SMALLINT =NULL,
	@periodoD varchar(6) = '000001',		
	@periodoH varchar(6) = '999999',		
	@zonaD varchar(4)=NULL,
	@zonaH varchar(4)=NULL,
	@fechaD datetime = NULL,
	@fechaH datetime = NULL,
	@contratoD INT = 5984,
	@contratoH INT = 5984,
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
	@filtrarEmision BIT = 1

	EXEC [dbo].[Informe_AVG_CF010_EmisionFactCAB] @codigoD, @codigoH
												, @periodoD, @periodoH	
												, @zonaD,	@zonaH
												, @fechaD, @fechaH
												, @contratoD,	@contratoH
												, @versionD,	@versionH
												, @clienteD,	@clienteH
												, @inmuebleD,	@inmuebleH
												, @preFactura, @verTodas
												, @fechaCob
												, @mostrarFacturasOnline
												, @mostrarFacturasE
												, @cuales
												, @orden1, @orden2, @orden3
												, @repLegal
												, @filtrarEmision;

*/

ALTER PROCEDURE [dbo].[Informe_AVG_CF010_EmisionFactCAB]
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
	@filtrarEmision BIT = NULL
)
AS
	SET NOCOUNT OFF;

BEGIN 


BEGIN TRY;

--************************
WITH CTR AS(
SELECT C.ctrCod
, C.ctrVersion 
, C.ctrNoEmision
--RN=1: para quedarnos con la última version del contrato si la explotacion es AVG
, ROW_NUMBER() OVER (PARTITION BY C.ctrCod ORDER BY C.ctrVersion DESC) AS RN
FROM dbo.parametros AS P
INNER JOIN dbo.contratos AS C
ON P.pgsclave = 'EXPLOTACION' 
AND P.pgsvalor='AVG'
AND @filtrarEmision = 1)

SELECT cctrCod = ctrCod
	 , cctrVersion = ctrVersion
	 --cctrNoEmision será NULL cuando la explotación NO ES AVG
	 , cctrNoEmision = ISNULL(ctrNoEmision, 0)
INTO #CTR
FROM CTR WHERE RN=1;

--************************

SET @fechaCob = ISNULL(@fechaCob, GETDATE())

SELECT 
[facCod], [facPerCod]      ,[facCtrCod]      ,[facVersion]      ,[facSerScdCod]     ,[facSerCod]      ,
CASE 
	WHEN 
		(Select sercodAlternativo  from series where sercod = facSerCod) IS NULL THEN ''
	WHEN facPerCod = '000015' then 
	(Select Concat(sercodAlternativo,'-', year(facFecha),'/',RIGHT('000000000'+ RTRIM(facNumero), (case when(len(facNumero)>8) then len(facnumero) else 8 end)))  from series where sercod = facSerCod)
	ELSE
		(Select Concat(sercodAlternativo,'-',Substring(facPerCod,0,5),'/',RIGHT('000000000' + RTRIM(facNumero), (case when(len(facNumero)>8) then len(facnumero) else 8 end)))  from series where sercod = facSerCod) END 
as facSerCodAlternativo, 
[facNumero]      ,[facFecha]      ,[facClicod]
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
(CASE WHEN (inciInspector.inlmc='E' OR inciInspector.inlmc='EP') OR (inciInspector.inlcod IS NULL AND (inciLector.inlmc='E' OR inciLector.inlmc='EP')) THEN 1 ELSE 0 END) AS lecturaEstimada,
(select pgsvalor from parametros where pgsclave='PROVINCIA_POR_DEFECTO') as provinciadefecto,
(select pgsvalor from parametros where pgsclave='POBLACION_POR_DEFECTO') as poblaciondefecto,
(select pgsvalor from parametros where pgsclave='CP_POR_DEFECTO') as cpdefecto,
(select pgsvalor from parametros where pgsclave='HORARIO') as horario,
(select pgsvalor from parametros where pgsclave='TLEGALPIE') as tLegalPie,
(select pgsvalor from parametros where pgsclave='ONLINE_MAILACCOUNT') as tEmail,
(select pgsvalor from parametros where pgsclave='PERIODO_INICIO') as pInicio,
ofcDireccion,ofcCPPost,ofcPob,ofcPrv,ofcNacion,ofcTlfAtCli,ofcTlfAvr,ofcHorario,
scdImpNombre,
ctrFaceOficCon, ctrFaceOrgGest, ctrFaceUnitrmi, ctrFaceOrgProponente
, U.usodes
, U.usocod
, CONVERT(INT,ISNULL(fclUnidades, 0.00)) as viviendas,
--nuevos campos correspondencia titular para las facturas del canon de 2015
clicnombre, clicdomicilio, cliccpostal, clicpoblacion, clicprovincia, clicnacion,

--se añade por temas de descuadres mínimos
isnull((select sum(fcltotal) from faclin where fclfaccod = faccod and fclfacpercod = facpercod and fclfacctrcod = facctrcod and fclfacversion = facversion and ((fclFecLiq>=@fechaH) OR	 (fclFecLiq IS NULL AND fclUsrLiq IS NULL))),0) as facturado,
  isnull((select sum(cblimporte) from coblin, cobros where cobFecReg <= @fechaCob and cobScd = cblScd and cobPpag = cblPpag and cobNum = cblNum and cobCtr = facctrcod and cblper = facpercod and cblfaccod = faccod),0) as cobrado,
 isnull((select sum(fcltotal) from faclin where fclfaccod = faccod and fclfacpercod = facpercod and fclfacctrcod = facctrcod and fclfacversion = facversion and ((fclFecLiq>=@fechaH) OR	 (fclFecLiq IS NULL AND fclUsrLiq IS NULL))),0) -
  isnull((select sum(cblimporte) from coblin, cobros where cobFecReg <= @fechaCob and cobScd = cblScd and cobPpag = cblPpag and cobNum = cblNum and cobCtr = facctrcod and cblper = facpercod and cblfaccod = faccod),0) as diferencia
--se añade por temas de descuadres mínimos
--************************
, cctrNoEmision
, ctrNoEmision
--************************
FROM facturas AS F
	CROSS APPLY(SELECT conNumSerie, conDiametro, ctcCtr FROM fContratos_ContadoresInstalados(facFecha) WHERE ctcCtr = facCtrCod) AS c	
inner join periodos on facpercod=percod
inner join contratos on ctrcod=facCtrCod and ctrversion=facCtrversion
inner join dbo.usos AS U on ctrUsoCod = usocod
inner join inmuebles on ctrinmcod=inmcod
inner join provincias on inmPrvCod = prvCod
inner join poblaciones on inmPobCod = pobCod and inmPrvCod = pobPrv
inner join municipios on inmMncCod = mncCod and inmPobCod = mncPobCod and inmPrvCod = mncPobPrv
inner join calles on cllcod = inmcllcod and cllmnccod = inmmnccod and cllPobCod = inmPobCod and cllPrvCod = inmPrvCod
--inner join clientes on ctrTitDocIden = clidociden and ctrTitCod = clicod
INNER JOIN dbo.clientes AS CL 
ON CL.clicod=ctrTitCod	--SYR215203
left join sociedades on scdcod=ISNULL(facserscdcod,ISNULL((select pgsvalor from parametros where pgsclave='SOCIEDAD_POR_DEFECTO'),1))
left join notificaciones n1 on n1.notPer=facpercod and n1.notzon=faczoncod
left join notificaciones n2 on n2.notPer=facpercod and n2.notzon='-'
left join online_usuarios on ISNULL(ctrPagdociden,ctrTitDocIden) = usrLogin
left join oficinas on scdOfcCod = ofcCodigo
LEFT JOIN incilec as inciLector ON inciLector.inlcod = facLecInlCod
LEFT JOIN incilec as inciInspector ON inciInspector.inlcod = facInsInlCod
-- unimos con faclin para sacar las viviendas de esa factura
LEFT JOIN faclin on facCod = fclFacCod and facCtrCod = fclFacCtrCod and facPerCod = fclFacPerCod and facCtrVersion = fclFacVersion and fclTrfSvCod = 19 
--************************
LEFT JOIN #CTR AS CC
ON CC.cctrCod = F.facCtrCod
--************************
where
ctcCtr = facCtrCod AND
(@mostrarFacturasOnline IS NULL OR @mostrarFacturasOnline = 1 OR (@mostrarFacturasOnline = 0 AND ISNULL(usrEFactura,0) = 0)) AND
( 
  @mostrarFacturasE IS NULL OR 
 (@mostrarFacturasE = 0 AND (ctrFaceTipoEnvio = 'POSTAL' OR (ISNULL(facEnvSERES, 'X') <> 'E' AND ISNULL(facEnvSERES, 'X') <> 'P' AND ISNULL(facEnvSERES, 'X') <> 'R'))) OR
 (@mostrarFacturasE = 1 AND facEnvSERES IS NOT NULL)
)
and (facCod >= @codigoD or @codigoD IS NULL)
and (facCod <= @codigoH or @codigoH IS NULL)
AND (@filtrarEmision IS NULL OR @filtrarEmision = 0 OR (@filtrarEmision = 1 AND COALESCE(cctrNoEmision, ctrNoEmision, 0) = 0))
and facPerCod >= @periodoD
and facPerCod <= @periodoH
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
  isnull((select sum(fcltotal) from faclin where fclfaccod = faccod and fclfacpercod = facpercod and fclfacctrcod = facctrcod and fclfacversion = facversion and ((fclFecLiq>=@fechaH) OR	(fclFecLiq IS NULL AND fclUsrLiq IS NULL))),0) <=
  isnull((select sum(cblimporte) from coblin, cobros where cobFecReg <= @fechaCob and cobScd = cblScd and cobPpag = cblPpag and cobNum = cblNum and cobCtr = facctrcod and cblper = facpercod and cblfaccod = faccod),0)
  )
 ) or

 (@cuales = 3 and 
  (
  isnull((select sum(fcltotal) from faclin where fclfaccod = faccod and fclfacpercod = facpercod and fclfacctrcod = facctrcod and fclfacversion = facversion and ((fclFecLiq>=@fechaH) OR	 (fclFecLiq IS NULL AND fclUsrLiq IS NULL))),0) >
  isnull((select sum(cblimporte) from coblin, cobros where cobFecReg <= @fechaCob and cobScd = cblScd and cobPpag = cblPpag and cobNum = cblNum and cobCtr = facctrcod and cblper = facpercod and cblfaccod = faccod),0) + 0.20 --ajuste de descuadres mínimos
  )
 )
)

AND (@repLegal IS NULL OR ctrRepresent LIKE '%' + @repLegal + '%')

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

END TRY

BEGIN CATCH
END CATCH
--************************
IF OBJECT_ID('tempdb.dbo.#CTR', 'U') IS NOT NULL 
DROP TABLE #CTR;
--************************

END



GO


