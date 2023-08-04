CREATE PROCEDURE ReportingServices.EfectosPendientesLineas_ACUAMA
	--Enviados desde acuama
	@efePdteCtrCod INT
  , @efePdtePerCod VARCHAR(6)
  , @efePdteFacCod INT
  , @efePdteCobrado INT= 0
  --1:	Solo cobrados
  --0:	Solo pendientes de cobro	
  --NULL: Todos: cobrados y no cobrados
AS
BEGIN
--Recupera las lineas asociadas en Efectos Pendientes
WITH EP AS(
SELECT P.efePdteCod
, P.efePdteCtrCod
, P.efePdtePerCod
, P.efePdteFacCod
, P.efePdteScd
, P.efePdteFecRemDesde
--, P.efePdteFecVencimiento
, P.efePdteImporte

, IIF(C.cleCblScd IS NULL, 0, 1) AS efePdteCobrado
FROM dbo.efectosPendientes AS P
--Efectos pendientes no cobrados
LEFT JOIN dbo.cobLinEfectosPendientes AS C
ON C.clefePdteCod = P.efePdteCod
AND C.clefePdteCtrCod = P.efePdteCtrCod
AND C.clefePdtePerCod = P.efePdtePerCod 
AND C.clefePdteFacCod = P.efePdteFacCod
AND C.cleCblScd = P.efePdteScd
WHERE ((@efePdteCobrado IS NULL) OR (@efePdteCobrado=1 AND C.cleCblScd IS NOT NULL) OR (@efePdteCobrado=0 AND C.cleCblScd IS NULL))
  AND (@efePdteCtrCod IS NULL OR P.efePdteCtrCod = @efePdteCtrCod)
  AND (@efePdtePerCod IS NULL OR P.efePdtePerCod = @efePdtePerCod)
  AND (@efePdteFacCod IS NULL OR P.efePdteFacCod = @efePdteFacCod) AND P.efePdteFecRechazado IS NULL)

SELECT  F.facNumero
, FORMAT(F.facFecha, 'dd/MM/yyyy') AS Periodo
, EP.efePdteCod
, EP.efePdteCtrCod
, EP.efePdtePerCod
, EP.efePdteFacCod
, EP.efePdteScd
, EP.efePdteCobrado
, SUM(IIF(EP.efePdteCod IS NULL, 0, 1)) OVER(PARTITION BY EP.efePdteCtrCod, EP.efePdtePerCod, EP.efePdteFacCod, EP.efePdteScd ORDER BY EP.efePdteCod ASC) AS [NºFraccionamientos]
, FORMAT(EP.efePdteFecRemDesde,  'dd/MM/yyyy') AS fechaLimite
, EP.efePdteImporte
FROM dbo.facturas AS F
LEFT JOIN EP
ON F.facCod = EP.efePdteFacCod
AND F.facPerCod = EP.efePdtePerCod
AND F.facCtrCod = EP.efePdteCtrCod
AND F.facFechaRectif IS NULL
WHERE F.facPerCod = @efePdtePerCod
AND F.facCtrCod = @efePdteCtrCod
AND F.facCod = @efePdteFacCod
AND F.facFechaRectif IS NULL

ORDER BY EP.efePdteCtrCod
, EP.efePdtePerCod
, EP.efePdteFacCod
, EP.efePdteScd
, [NºFraccionamientos]

END
GO