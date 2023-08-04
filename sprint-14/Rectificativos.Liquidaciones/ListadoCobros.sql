

/*
DECLARE @sociedadD INT = NULL
DECLARE @sociedadH INT = NULL
DECLARE @puntoPagoD INT = NULL
DECLARE @puntoPagoH INT = NULL
DECLARE @numeroD INT = NULL
DECLARE @numeroH INT = NULL
DECLARE @contratoD INT = NULL
DECLARE @contratoH INT = NULL
DECLARE @fechaCobroD DATE = '20211231'
DECLARE @fechaCobroH DATE = NULL
DECLARE @fechaRegistroD DATE = NULL
DECLARE @fechaRegistroH DATE = NULL
DECLARE @medioPagoD INT = NULL
DECLARE @medioPagoH INT = NULL
DECLARE @usuario AS VARCHAR(20)
DECLARE @impoD MONEY = NULL
DECLARE @impoH MONEY = NULL
DECLARE @zonaD AS VARCHAR(4) = NULL
DECLARE @zonaH AS VARCHAR(4) = NULL

EXEC ReportingServices.ListadoCobros @sociedadD, @sociedadH
, @puntoPagoD, @puntoPagoH, @numeroD, @numeroH, @contratoD, @contratoH, @fechaCobroD, @fechaCobroH, @fechaRegistroD
, @fechaRegistroH, @medioPagoD, @medioPagoH, @usuario, @impoD, @impoH, @zonaD, @zonaH

*/

CREATE PROCEDURE [ReportingServices].[ListadoCobros]
  @sociedadD INT = NULL
, @sociedadH INT = NULL
, @puntoPagoD INT = NULL
, @puntoPagoH INT = NULL
, @numeroD INT = NULL
, @numeroH INT = NULL
, @contratoD INT = NULL
, @contratoH INT = NULL
, @fechaCobroD DATE = NULL
, @fechaCobroH DATE = NULL
, @fechaRegistroD DATE = NULL
, @fechaRegistroH DATE = NULL
, @medioPagoD INT = NULL
, @medioPagoH INT = NULL
, @usuario AS VARCHAR(20)
, @impoD MONEY = NULL
, @impoH MONEY = NULL
, @zonaD AS VARCHAR(4) = NULL
, @zonaH AS VARCHAR(4) = NULL

AS

SELECT @fechaCobroH		= DATEADD(DAY, 1, @fechaCobroH)
	,  @fechaRegistroH	= DATEADD(DAY, 1, @fechaRegistroH);


WITH CTR AS (
SELECT ctrCod
, ctrversion 
, ctrZonCod
--RN=1: Ultima version del contrato
, RN=ROW_NUMBER() OVER(PARTITION BY ctrCod ORDER BY ctrversion DESC)
FROM dbo.contratos AS C
)

SELECT  C.cobScd
	  , C.cobPpag
	  , C.cobNum
	  , C.cobFecReg
	  , C.cobFec 
	  , C.cobImporte
	  , CL.cblImporte
	  , CL.cblLin
	  , CL.cblPer
	  , CLD.cldCblLin
	  , CLD.cldImporte
	  , RN = ROW_NUMBER() OVER (PARTITION BY C.cobScd, C.cobPpag, C.cobNum, CL.cblLin ORDER BY CLD.cldCblLin ASC) 
	  , S.scdnom
	  , P.ppagDes
	  , PP.perdes
	  , SS.svccod
	  , SS.svcdes
	  

FROM dbo.cobros AS C
INNER JOIN dbo.coblin AS CL
ON  C.cobScd	= CL.cblScd 
AND C.cobPpag	= CL.cblPpag 
AND C.cobNum	= CL.cblNum
INNER JOIN dbo.coblinDes AS CLD
ON  CLD.cldCblScd	= CL.cblScd 
AND CLD.cldCblPpag	= CL.cblPpag 
AND CLD.cldCblNum	= CL.cblNum 
AND CLD.cldCblLin	= CL.cblLin
INNER JOIN dbo.ppagos AS P 
ON C.cobppag = P.ppagcod
INNER JOIN dbo.sociedades AS S
ON C.cobscd=S.scdcod
INNER JOIN CTR 
ON  CTR.ctrcod=C.cobCtr 
AND CTR.RN = 1
INNER JOIN dbo.servicios AS SS
ON SS.svccod = CLD.cldTrfSrvCod
INNER JOIN dbo.periodos AS PP
ON PP.percod = CL.cblper
WHERE (C.cobScd>=@sociedadD OR @sociedadD IS NULL)
AND (C.cobScd<=@sociedadH OR @sociedadH IS NULL)
AND (C.cobPpag>=@puntoPagoD OR @puntoPagoD IS NULL)
AND (C.cobPpag<=@puntoPagoH OR @puntoPagoH IS NULL)
AND (C.cobNum>=@numeroD or @numeroD IS NULL)
AND (C.cobNum<=@numeroH or @numeroH IS NULL)
AND (C.cobFec>=@fechaCobroD OR @fechaCobroD IS NULL)
AND (C.cobFec<@fechaCobroH OR @fechaCobroH IS NULL)
AND (C.cobCtr>=@contratoD OR @contratoD IS NULL)
AND (C.cobCtr<=@contratoH OR @contratoH IS NULL)
AND (C.cobFecReg>=@fechaRegistroD or @fechaRegistroD IS NULL)
AND (C.cobFecReg<@fechaRegistroH or @fechaRegistroH IS NULL)
AND (cobMpc>=@medioPagoD OR @medioPagoD IS NULL)
AND (cobMpc<=@medioPagoH OR @medioPagoH IS NULL)
AND (cobUsr = @usuario OR @usuario IS NULL)
AND (cobImporte>=@impoD OR @impoD IS NULL)
AND (cobImporte<=@impoH OR @impoH IS NULL)
AND (ctrZonCod >= @zonaD OR @zonaD IS NULL) 
AND (ctrZonCod <= @zonaH OR @zonaH IS NULL);


GO


