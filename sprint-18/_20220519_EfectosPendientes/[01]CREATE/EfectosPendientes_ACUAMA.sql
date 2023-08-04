--EXEC ReportingServices.EfectosPendientes_ACUAMA @efePdteCtrCod=83, @efePdtePerCod='202102'
CREATE PROCEDURE [ReportingServices].[EfectosPendientes_ACUAMA]
	--Enviados desde acuama
	@efePdteCtrCod INT
  , @efePdtePerCod VARCHAR(6)=NULL
  , @efePdteFacCod INT=NULL
AS
BEGIN
--Se recuperan todas las facturas con el total de efectos pendientes de cobro
WITH FAC AS(
SELECT F.facCod
, F.facCtrCod
, F.facPerCod
, F.facVersion
, F.facCtrVersion
, F.facNumeroAqua
, F.facFecha
--RN=1: Nos quedamos con la última versión de la factura
, ROW_NUMBER() OVER (PARTITION BY F.facCod, F.facPerCod, F.facCtrCod ORDER BY F.facVersion DESC)  AS RN
FROM dbo.facturas AS F
WHERE (@efePdteFacCod IS NULL OR F.facCod = @efePdteFacCod)
AND (@efePdtePerCod IS NULL OR F.facPerCod = @efePdtePerCod)
AND (@efePdteCtrCod IS NULL OR F.facCtrCod = @efePdteCtrCod)
AND F.facFecha IS NOT NULL

), EP AS(
SELECT F.facCod
, F.facCtrCod
, F.facPerCod
, F.facVersion
, F.facCtrVersion

, SUM(ISNULL(P.efePdteImporte, 0)) AS ImportePendiente
, COUNT(P.efePdteCod) AS NumFraccionamientos
FROM FAC AS F
LEFT JOIN dbo.efectosPendientes AS P
ON P.efePdteFacCod = F.facCod
AND P.efePdteCtrCod = F.facCtrCod
AND P.efePdtePerCod = F.facPerCod
--Efectos pendientes no cobrados
LEFT JOIN dbo.cobLinEfectosPendientes AS C
ON C.clefePdteCod = P.efePdteCod
AND C.clefePdteCtrCod = P.efePdteCtrCod
AND C.clefePdtePerCod = P.efePdtePerCod 
AND C.clefePdteFacCod = P.efePdteFacCod
AND C.cleCblScd = P.efePdteScd
WHERE F.RN=1 
AND C.cleCblScd IS NULL 
AND P.efePdteFecRechazado IS NULL 
GROUP BY F.facCod, F.facCtrCod, F.facPerCod, F.facVersion, F.facCtrVersion)


SELECT F.facCod
, F.facCtrCod
, F.facPerCod
, F.facVersion
, EP.ImportePendiente
, EP.NumFraccionamientos
, C.ctrcod
, C.ctrTitNom
, C.ctrTitDocIden
, C.ctrTlf1
, C.ctrTlf2
, C.ctrTlf3
, I.inmDireccion
, C.ctrTitDir
, C.ctrEnvDir
, F.facNumeroAqua
, F.facFecha
FROM FAC AS F
INNER JOIN dbo.contratos AS C
ON C.ctrcod = F.facCtrCod
AND C.ctrversion = F.facCtrVersion
AND F.RN=1
LEFT JOIN dbo.inmuebles AS I
ON I.inmcod = C.ctrInmCod 
LEFT JOIN EP 
ON EP.facCod = F.facCod
AND EP.facPerCod = F.facPerCod
AND EP.facCtrCod = F.facCtrCod
AND EP.facVersion = F.facVersion
END
GO
