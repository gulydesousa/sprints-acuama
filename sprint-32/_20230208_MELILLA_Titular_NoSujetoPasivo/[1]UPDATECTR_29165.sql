USE ACUAMA_MELILLA
GO 

BEGIN TRAN;
DECLARE @CTR AS TABLE(CTRCOD INT, CTRVERSION INT);

WITH C AS(
SELECT CC.ctrcod
, CC.ctrversion
, CC.ctrfecini
, SvcActivos = SUM(IIF(CS.ctsfecbaj IS NULL OR CS.ctsfecbaj>GETDATE(), 1, 0)) 
, NumSvc = COUNT(DISTINCT CS.ctssrv)
FROM [dbo].[vContratosUltimaVersion] AS C
INNER JOIN contratos AS CC
ON CC.ctrcod = C.ctrCod
AND CC.ctrversion = C.ctrVersion
AND CC.ctrTitCod NOT IN (20106, 30726, 31336, 29165)
INNER JOIN dbo.contratoServicio AS CS
ON CS.ctsctrcod = C.ctrCod
GROUP BY CC.ctrcod, CC.ctrversion, CC.ctrfecini)

INSERT INTO @CTR
SELECT C.ctrcod, C.ctrversion 
FROM C 
WHERE SvcActivos=0 AND NumSvc>0;



--Insertamos una nueva version con el titular
INSERT INTO dbo.contratos
SELECT CC.ctrcod
, ctrversion	= CC.ctrversion+1
, CC.ctrfec
, CC.ctrfecini
, ctrfecreg_		= '20230206' 
, ctrusrcod_		= 'gmdesousa'
, ctrfecanu_		= NULL
, ctrusrcodanu_		= NULL
, CC.ctrinmcod
, CC.ctremplaza
, CC.ctrbatfila
, CC.ctrbatcolum
, CC.ctravisolector
, CC.ctrzoncod
, CC.ctrbaja
, CC.ctrRuta1, CC.ctrRuta2, CC.ctrRuta3, CC.ctrRuta4, CC.ctrRuta5, CC.ctrRuta6
, ctrobs_			= 'SYR-409839: TRASPASO AL CLIENTE 29165 "SERVICIOS POR CONTRATO INACTIVOS"'
, CC.ctrLecturaUlt
, CC.ctrLecturaUltFec
, CC.ctrUsoCod
, CC.ctrFecSolAlta
, CC.ctrFecSolBaja
, ctrTitCod_		= CL.clicod
, ctrTitTipDoc_		= CL.clitipdoc
, ctrTitDocIden_	= CL.clidociden
, ctrTitNom_		= CL.clinom
, ctrTitNac_		= CL.cliNacionalidad
, ctrTitDir_		= CL.clidomicilio
, ctrTitPrv_		= UPPER(CL.cliprovincia)
, ctrTitPob_		= UPPER(CL.clipoblacion)
, ctrTitCPos_	= CL.clicpostal
--NO TIENEN QUE TENER ni datos de pagador ni de representante legal NINGUNO
, ctrPagTipDoc_		= NULL
, ctrPagDocIden_	= NULL
, ctrPagNom_		= NULL
, ctrPagNac_		= NULL
, ctrPagDir_		= NULL
, ctrPagPrv_		= NULL
, ctrPagPob_		= NULL
, ctrPagCPos_		= NULL

, ctrCCC_			= CL.cliccc
--DIRECCION DE CORRESPONDENCIA
, ctrEnvNom_		= CL.clicnombre
, ctrEnvNac_		= CL.clinacion
, ctrEnvDir_		= CL.clicdomicilio
, ctrEnvPob_		= UPPER(CL.clicpoblacion)
, ctrEnvPrv_		= UPPER(CL.clicprovincia)
, ctrEnvCPos_		= CL.cliccpostal
--REFERENCIAS
, ctrTlf1_			= CL.clitelefono1
, ctrTlfRef1_		= CL.clireftelf1
, ctrTlf2_			= CL.clitelefono2
, ctrTlfRef2_		= CL.clireftelf2
, ctrTlf3_			= CL.clitelefono3
, ctrTlfRef3_		= CL.clireftelf3
, ctrFax_			= CL.clireffax
, ctrFaxRef_		= CL.clifax
, ctrEmail_			= CL.climail

, CC.ctrNumChapa
, CC.ctrNuevo
, CC.ctrComunitario
, CC.ctrEmpadronados
, CC.ctrCalculoComunitario
--NO TIENEN QUE TENER ni datos de pagador ni de representante legal NINGUNO
, ctrRepresent_		= NULL

, CC.ctrValorc1, CC.ctrValorc2, CC.ctrValorc3, CC.ctrValorc4
, ctrTvipCodigo_	= CL.cliTvipCodigo
, CC.ctrAcoCod
, CC.ctrSctCod

, ctrIban_			= CL.cliIban
, ctrBic_			= CL.cliBic
, ctrManRef_		= NULL

, CC.ctrFace, CC.ctrFaceMinimo, CC.ctrFaceOficCon, CC.ctrFaceOrgGest, CC.ctrFaceUnitrmi, CC.ctrFacePortal, CC.ctrFaceMail, CC.ctrFaceTipoEnvio, CC.ctrFaceAdmPublica, CC.ctrFaceTipo, CC.ctrFaceOrgProponente
, CC.ctrNoEmision

, ctrTitDocIdenValidado_	= CL.cliDocIdenValidado
, ctrPagDocIdenValidado_	= 0
, ctrTitNacionalidad_		= CL.cliNacionalidad
, ctrPagNacionalidad_		= NULL
FROM @CTR AS C
INNER JOIN contratos AS CC
ON CC.ctrcod = C.ctrCod
AND CC.ctrversion = C.ctrVersion
LEFT JOIN dbo.clientes AS CL
ON CL.clicod=29165;

--Asignamos fecha baja a la version anterior
UPDATE CC 
SET CC.ctrusrcodanu='gmdesousa', CC.ctrfecanu= '20230206' 
FROM @CTR AS C
INNER JOIN contratos AS CC
ON CC.ctrcod = C.ctrCod
AND CC.ctrversion = C.ctrVersion;


SELECT C.* 
FROM contratos AS C 
INNER JOIN @CTR AS CC 
ON C.ctrcod=CC.CTRCOD 
AND C.ctrversion>=CC.CTRVERSION
ORDER BY ctrBic DESC

--ROLLBACK
COMMIT