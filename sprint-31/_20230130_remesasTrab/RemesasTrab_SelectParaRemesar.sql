ALTER PROCEDURE [dbo].[RemesasTrab_SelectParaRemesar] 
@remUsrCod VARCHAR(10) = NULL,
@remCtrCod INT = NULL,
@remPerCod INT = NULL,
@remFacCod SMALLINT = NULL,
@remEfePdteCod INT = NULL
, @remTskType INT = NULL
, @remTskNumber INT = NULL
AS 
	SET NOCOUNT ON; 
SELECT [remUsrCod]
      ,[remCtrCod]
      ,[remPerCod]
	  ,[remFacCod]
      ,[remZonCod]
      ,[remPerTipo]
      ,[remSerCod]
      ,[remSerScdCod]
      ,[remFacNumero]
      ,[remFacTotal]
      ,[remPagado]
	  ,[remVersionCtrCCC]
	  ,[remEfePdteCod]
	  ,inmdireccion
	  ,mncdes
	  ,facSerCod
	  ,facNumero
	  ,facVersion
	  ,facFecha
	  ,facLecActFec
	  ,facLecAct
	  ,facLecAntFec
	  ,facLecAnt
	  ,facConsumoFactura
	  ,ctrVersion
	  ,ISNULL(efePdteTitCCC, ISNULL(ctrPagNom, ISNULL(ctrTitNom, clinom))) AS clinom
	  ,ISNULL(efePdteDocIdenCCC, ISNULL(ctrPagDocIden, ISNULL(ctrTitDocIden, cliDocIden))) AS ctrPagDocIden
	  ,ISNULL(efePdteCCC, ctrCCC) AS ctrCCC
	  ,ISNULL(efePdteIban, ctrIban) AS ctrIBAN
	  ,ISNULL(efePdteBic, ctrBic) AS ctrBIC
	  ,ISNULL(efePdteManRef, ctrManRef) AS refMan
FROM dbo.remesasTrab (SERIALIZABLE) AS R1
INNER JOIN dbo.facturas AS F 
ON  F.facCod = R1.remFacCod
AND F.facPerCod = R1.remPerCod 
AND F.facCtrCod = R1.remCtrCod 
AND F.facFechaRectif IS NULL


INNER JOIN contratos c ON ctrcod = remCtrCod AND ctrversion = CASE WHEN remVersionCtrCCC = 'UV' THEN (SELECT MAX(ctrVersion) FROM contratos cSub WHERE c.ctrcod = cSub.ctrcod) ELSE facCtrVersion END
INNER JOIN inmuebles ON inmcod = ctrinmcod
INNER JOIN municipios ON mnccod = inmmnccod AND mncPobCod = inmPobCod AND mncPobPrv = inmPrvCod
INNER JOIN clientes ON clicod = ctrTitCod
LEFT JOIN efectosPendientes ON efePdteCtrCod = remCtrCod AND efePdtePerCod = remPerCod AND efePdteFacCod = remFacCod AND efePdteCod = remEfePdteCod 
WHERE (remUsrCod = @remUsrCod OR @remUsrCod IS NULL) AND 
(remCtrCod = @remCtrCod OR @remCtrCod IS NULL) AND
(remPerCod = @remPerCod OR @remPerCod IS NULL) AND
(remFacCod = @remFacCod OR @remFacCod IS NULL) AND
(remEfePdteCod = @remEfePdteCod OR @remEfePdteCod IS NULL)

AND ((@remTskType IS NULL AND R1.[remTskType] IS NULL)		OR R1.[remTskType]	=@remTskType)
AND ((@remTskNumber IS NULL AND R1.[remTskNumber] IS NULL)	OR R1.[remTskNumber]=@remTskNumber)
ORDER BY facCtrCod, facPerCod;


GO


