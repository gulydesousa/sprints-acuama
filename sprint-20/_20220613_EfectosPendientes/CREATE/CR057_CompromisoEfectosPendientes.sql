--DROP PROCEDURE [ReportingServices].[CR057_CompromisoEfectosPendientes]
/*
DECLARE @percodD AS VARCHAR(6)
DECLARE @percodH AS VARCHAR(6)
DECLARE @ctrCodD AS INT =8784
DECLARE @ctrCodH AS INT=8784
DECLARE @fecha AS DATE = NULL
DECLARE @cobroPendiente BIT = NULL;

EXEC [ReportingServices].[CR057_CompromisoEfectosPendientes] @percodD, @percodH, @ctrCodD, @ctrCodH, @cobroPendiente, @fecha;
*/

ALTER PROCEDURE [ReportingServices].[CR057_CompromisoEfectosPendientes]
  @percodD AS VARCHAR(6)	= NULL
, @percodH AS VARCHAR(6)	= NULL
, @ctrCodD AS INT			= NULL
, @ctrCodH AS INT			= NULL
, @cobroPendiente BIT		= NULL
, @fecha AS DATE			= NULL

AS

DECLARE @EfectosPdtesPK AS dbo.tEfectosPendientesPK;
DECLARE @tFacturasPK AS dbo.tFacturasPK

SELECT @fecha = DATEADD(DAY, 1, @fecha) WHERE @fecha IS NOT NULL;

--*******************
--[01]@EfectosPdtesPK
--Efectos pendientes en el rango de consulta
--*******************
WITH EP AS(
SELECT E.efePdteCod
, E.efePdteCtrCod
, E.efePdtePerCod
, E.efePdteFacCod
, E.efePdteScd
, E.efePdteImporte
, E.efePdteDomiciliado
, E.efePdteFecRemDesde
, E.efePdteFecRemesada
, E.efePdteIban
, E.efePdteTitCCC
, E.efePdteDocIdenCCC
, [cobroPdte]  = SUM(CASE	WHEN E.efePdteDomiciliado=0 AND CL.cleCblLin IS NULL THEN 1
							WHEN E.efePdteDomiciliado=1 AND E.efePdteFecRemesada IS NULL THEN 1
							ELSE 0 END)
  OVER(PARTITION BY E.efePdteCtrCod)
FROM dbo.efectosPendientes AS E
LEFT JOIN  dbo.cobLinEfectosPendientes AS CL
ON  CL.clefePdteCod		= E.efePdteCod
AND CL.clefePdteCtrCod	= E.efePdteCtrCod
AND CL.clefePdtePerCod	= E.efePdtePerCod
AND CL.clefePdteFacCod  = E.efePdteFacCod
AND CL.cleCblScd		= E.efePdteScd
AND E.efePdteDomiciliado= 0

WHERE (@percodD IS NULL  OR E.efePdtePerCod>=@percodD)
  AND (@percodH IS NULL  OR E.efePdtePerCod<=@percodH)
  AND (@ctrCodD IS NULL  OR E.efePdteCtrCod>=@ctrCodD)
  AND (@ctrCodH IS NULL  OR E.efePdteCtrCod<=@ctrCodH)
  AND (@fecha IS NULL	 OR E.efePdteFecReg < @fecha)
  AND ((E.efePdteFecRechazado IS NULL) OR 
	   (E.efePdteFecRechazado IS NOT NULL AND @fecha IS NOT NULL AND E.efePdteFecRechazado>@fecha ) 
	  ))

INSERT INTO @EfectosPdtesPK(efePdteCod, efePdteCtrCod, efePdtePerCod, efePdteFacCod, efePdteScd
						  , efePdteImporte, efePdteDomiciliado, efePdteFecRemDesde, efePdteFecRemesada
						  , efePdteIban, efePdteTitCCC, efePdteDocIdenCCC)
SELECT EP.efePdteCod
, EP.efePdteCtrCod
, EP.efePdtePerCod
, EP.efePdteFacCod
, EP.efePdteScd
, EP.efePdteImporte
, EP.efePdteDomiciliado
, EP.efePdteFecRemDesde
, EP.efePdteFecRemesada
, EP.efePdteIban
, EP.efePdteTitCCC
, EP.efePdteDocIdenCCC
FROM EP 
WHERE  (@cobroPendiente IS NULL) 
	OR (@cobroPendiente=1 AND [cobroPdte] > 0) 
	OR (@cobroPendiente=0 AND [cobroPdte] = 0);

--*******************
--[02]@tFacturasPK
--Ultima versión de la facturas relacionadas a los efectos pendientes
--*******************
WITH FACS AS (
SELECT F.facCod
, F.facCtrCod
, F.facPerCod
, F.facVersion
, E.efePdteCod
-- RN=1: Ultima version de la factura con el primer efecto pendiente
, RN = ROW_NUMBER() OVER (PARTITION BY F.facCod, F.facCtrCod, F.facPerCod ORDER BY F.facVersion DESC, E.efePdteCod ASC)
FROM dbo.facturas AS F
INNER JOIN @EfectosPdtesPK AS E
ON  F.facCod	= E.efePdteFacCod
AND F.facCtrCod = E.efePdteCtrCod
AND F.facPerCod = E.efePdtePerCod)

INSERT INTO @tFacturasPK(facCod, facCtrCod, facPerCod, facVersion)
SELECT facCod, facCtrCod, facPerCod, facVersion 
FROM FACS 
WHERE RN=1;


--*******************
--[99]RESULTADO
--*******************
WITH FCT AS(
--Total facturado
SELECT F.facCod
	 , F.facPerCod
	 , F.facCtrCod
	 , F.facVersion
	 , facTotal = SUM(FL.fcltotal) 
FROM dbo.faclin AS FL
INNER JOIN @tFacturasPK AS F
ON F.facCod = FL.fclFacCod
AND F.facPerCod = FL.fclFacPerCod
AND F.facCtrCod = FL.fclFacCtrCod
AND F.facVersion = FL.fclFacVersion
AND FL.fclFecLiq IS NULL
GROUP BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion 

), COBT AS(
--Total Cobrado
SELECT F.facCod
	 , F.facPerCod
	 , F.facCtrCod
	 , F.facVersion
	 , cobTotal = SUM(CL.cblImporte) 
FROM dbo.cobros AS C
INNER JOIN dbo.coblin AS CL
ON  C.cobScd	= CL.cblScd
AND C.cobPpag	= CL.cblPpag
AND C.cobNum	= CL.cblNum
INNER JOIN @tFacturasPK AS F
ON  F.facCod	= CL.cblFacCod
AND F.facPerCod = CL.cblPer
AND F.facCtrCod = C.cobCtr
AND F.facVersion = CL.cblFacVersion
AND (@fecha IS NULL OR C.cobFecReg < @fecha)
GROUP BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion

), IBAN AS(
--El iban será la concatenación en HTML de los diferentes IBAN que aparecen en los efectos pendientes
SELECT efePdteCtrCod
	 , IBAN_HTML = STRING_AGG(efePdteIban, '<br>') 
FROM (SELECT DISTINCT efePdteCtrCod, efePdteIban FROM @EfectosPdtesPK) X 
GROUP BY efePdteCtrCod
)

SELECT E.efePdteCod
, E.efePdteScd
--*******************************
, F.facCod
, F.facCtrCod
, F.facPerCod
, F.facVersion
--*******************************
, FF.facSerCod
, FF.facNumero
, FF.facFecha
, facConsumoFactura	= ISNULL(FF.facConsumoFactura, 0)
--*******************************
, P.perdes
, I.inmDireccion
--*******************************
, facTotal	= ISNULL(FT.facTotal, 0)
, cobTotal	= ISNULL(CT.cobTotal, 0)
, Deuda		= ROUND(ISNULL(FT.facTotal, 0), 2) - ROUND(ISNULL(CT.cobTotal, 0), 2)
--*******************************
, E.efePdteFecRemDesde
, E.efePdteFecRemesada
, E.efePdteDomiciliado
, E.efePdteImporte
--*******************************
, E.efePdteIban
, E.efePdteTitCCC
, E.efePdteDocIdenCCC
--*******************************
, C.ctrTitDocIden
, C.ctrTitNom
--*******************************
, CL.cleCblLin
, CC.cobFec
, [EfePdteCobrado] = CASE WHEN E.efePdteDomiciliado=0 AND CL.cleCblLin IS NOT NULL THEN 1
						  WHEN E.efePdteDomiciliado=1 AND E.efePdteFecRemesada IS NOT NULL THEN 1
						  ELSE 0 END

--*******************************
--Las facturas se repiten por cada efecto pendiente que pueda tener asociado 
--RN=1: Para ordenar las facturas y totalizar la factura una sola vez en el informe
, [RN]			= ROW_NUMBER() OVER(PARTITION BY F.facCtrCod, F.facPerCod, F.facCod, F.facVersion  ORDER BY  E.efePdteCod, efePdteScd)

--Los efectos pendientes se ordenan en cuotas a partir de efePdteFecRemDesde
--[Cuota] : todos los EP que se remesan a partir de la misma fecha comparten numero de cuota
, [Cuota]		= DENSE_RANK() OVER(PARTITION BY F.facCtrCod ORDER BY E.efePdteFecRemDesde)

--Se totalizan las cuotas cuando hay mas de una factura 
--[CN_Cuotas]: Numero de facturas por cuota 
, [CN_Cuotas]	= COUNT(F.facCod) OVER(PARTITION BY F.facCtrCod, E.efePdteFecRemDesde)

--Es posible que un contrato tenga domiciliaciones a mas de una cuenta bancaria o incluso tenga ep domiciliados y no.domiciliados
--Los datos del titular se sacan del ultimo efecto pendiente 
--Si el ultimo EP es domiciliado lo sacamos de ahí, sino ponemos los datos del titular del contrato.
-- Mayor fecha de remesa & Mayor factura
, [FIRST_TITULAR]	= FIRST_VALUE(ISNULL(E.efePdteTitCCC, C.ctrTitNom)) OVER (PARTITION BY F.facCtrCod ORDER BY E.efePdteFecRemDesde DESC, efePdtePerCod DESC)
, [FIRST_DNI]		= FIRST_VALUE(ISNULL(E.efePdteDocIdenCCC, C.ctrTitDocIden)) OVER (PARTITION BY F.facCtrCod ORDER BY E.efePdteFecRemDesde DESC, efePdtePerCod DESC)
--*******************************
--Contatenacion de todos los IBAN asociados a los efectos pendientes del contrato
, [ALL_IBAN]		= IB.IBAN_HTML
--*******************************
--Numerador único por contrato
, [ID_Compromiso]	= DENSE_RANK() OVER(ORDER BY F.facCtrCod)

FROM @EfectosPdtesPK AS E
INNER JOIN @tFacturasPK AS F
ON  E.efePdteCtrCod = F.facCtrCod
AND E.efePdtePerCod = F.facPerCod
AND E.efePdteFacCod = F.facCod

INNER JOIN dbo.facturas AS FF
ON  F.facCod	 = FF.facCod
AND F.facCtrCod  = FF.facCtrCod
AND F.facPerCod  = FF.facPerCod
AND F.facVersion = FF.facVersion

INNER JOIN dbo.periodos AS P
ON P.percod = F.facPerCod

INNER JOIN dbo.vContratosUltimaVersion AS C
ON C.ctrCod = F.facCtrCod

INNER JOIN dbo.inmuebles AS I
ON I.inmcod = C.ctrinmcod

INNER JOIN IBAN AS IB
ON IB.efePdteCtrCod = E.efePdteCtrCod

LEFT JOIN FCT AS FT
ON  FT.facCod = F.facCod
AND FT.facPerCod = F.facPerCod
AND FT.facCtrCod = F.facCtrCod
AND FT.facVersion = F.facVersion

LEFT JOIN COBT AS CT
ON  CT.facCod = F.facCod
AND CT.facPerCod = F.facPerCod
AND CT.facCtrCod = F.facCtrCod
AND CT.facVersion = F.facVersion

LEFT JOIN  dbo.cobLinEfectosPendientes AS CL
ON  CL.clefePdteCod		= E.efePdteCod
AND CL.clefePdteCtrCod	= E.efePdteCtrCod
AND CL.clefePdtePerCod	= E.efePdtePerCod
AND CL.clefePdteFacCod  = E.efePdteFacCod
AND CL.cleCblScd		= E.efePdteScd
AND E.efePdteDomiciliado= 0

LEFT JOIN dbo.cobros AS CC
ON  CC.cobScd	= CL.cleCblScd
AND CC.cobPpag	= CL.cleCblPpag
AND CC.cobNum	= CL.cleCblNum

ORDER BY  FF.facCtrCod, E.efePdteFecRemDesde, FF.facPerCod, FF.facCod, E.efePdteCod;


GO



