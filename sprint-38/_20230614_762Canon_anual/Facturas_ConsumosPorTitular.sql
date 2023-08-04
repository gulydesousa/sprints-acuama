/*
DECLARE @fechaFacturaD AS DATETIME = '20220101',
@fechaFacturaH AS DATETIME = '20221231',
@fechaLiquidacionD AS DATETIME = NULL,
@fechaLiquidacionH AS DATETIME = NULL,
@periodoD AS VARCHAR(6) = NULL,
@periodoH AS VARCHAR(6) = NULL,
@zonaD AS VARCHAR(4) = NULL,
@zonaH AS VARCHAR(4) = NULL, 
@ctrTitDocIden VARCHAR(25) = 'A11768546'


EXEC [dbo].[Facturas_ConsumosPorTitular] @fechaFacturaD, @fechaFacturaH
, @fechaLiquidacionD, @fechaLiquidacionH
, @periodoD, @periodoH
, @zonaD, @zonaH
, @ctrTitDocIden;


*/
--DROP PROCEDURE [dbo].[Facturas_ConsumosPorTitular]

CREATE PROCEDURE [dbo].[Facturas_ConsumosPorTitular]
@fechaFacturaD AS DATETIME = NULL,
@fechaFacturaH AS DATETIME = NULL,
@fechaLiquidacionD AS DATETIME = NULL,
@fechaLiquidacionH AS DATETIME = NULL,
@periodoD AS VARCHAR(6) = NULL,
@periodoH AS VARCHAR(6) = NULL,
@zonaD AS VARCHAR(4) = NULL,
@zonaH AS VARCHAR(4) = NULL,
@ctrTitDocIden VARCHAR(25) = NULL
AS

SET NOCOUNT ON;



DECLARE @facFechaD DATE;
DECLARE @facFechaH DATE;

DECLARE @fechaPerD AS DATE;
DECLARE @fechaPerH AS DATE;

SET @fechaPerD = (SELECT TOP 1 przfPeriodoD FROM dbo.perzona AS P WHERE P.przcodper = @periodoD)
SET @fechaPerH = (SELECT TOP 1 przfPeriodoH FROM dbo.perzona AS P WHERE P.przcodper = @periodoH)


SELECT @facFechaD = IIF(@fechaFacturaD IS NOT NULL, @fechaFacturaD, NULL),
	   @facFechaH = IIF(@fechaFacturaH IS NOT NULL, DATEADD(DAY, 1, @fechaFacturaH), NULL),
	   @fechaPerH = IIF(@fechaPerH IS NOT NULL, DATEADD(DAY, 1, @fechaPerH), NULL);


BEGIN TRY
	--*********************************************
	--[01]Buscamos los datos clave según los filtros en la tabla: #AUX
	SELECT F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion
	, F.facCtrVersion
	, F.facConsumoFactura	
	, C.ctrTitDocIden
	, C.ctrTitNom
	--RN=1: Para quedarnos con la mayor version de contrato y el periodo mas reciente
	, RN = ROW_NUMBER() OVER(ORDER BY ctrversion DESC, F.facPerCod DESC)
	, CNS = SUM(F.facConsumoFactura) OVER()
	INTO #AUX
	FROM dbo.facturas AS F 
	INNER JOIN dbo.contratos AS C
	ON  F.facCtrCod = C.ctrcod
	AND F.facCtrVersion = C.ctrversion
	AND C.ctrTitDocIden= @ctrTitDocIden
	LEFT JOIN dbo.facturas AS F0
	ON F0.facCod = F.facCod
	AND F0.facPerCod = F.facPerCod
	AND F0.facCtrCod = F.facCtrCod
	AND F0.facFechaRectif = F.facFecha
	AND F0.facNumeroRectif = F.facNumero
	WHERE F.facFecha IS NOT NULL AND
		  (F.facFecha >= @facFechaD OR @fechaFacturaD IS NULL) AND
		  (F.facFecha <  @facFechaH OR @fechaFacturaH IS NULL) AND
		  (F.facFecha >= @fechaPerD OR @fechaPerD IS NULL) AND
		  (F.facFecha < @fechaPerH OR @fechaPerH IS NULL) AND
		  (((F.facPerCod >= @periodoD OR @periodoD IS NULL) AND
		    (F.facPerCod <= @periodoH OR @periodoH IS NULL))
			OR 
			((F.facPerCod like '0%') 
				AND ((F.facFecha >= @fechaPerD OR @fechaPerD IS NULL) AND (F.facFecha < @fechaPerH OR @fechaPerH IS NULL))
			)
		  ) AND
		  (ctrZonCod >= @zonaD OR @zonaD IS NULL) AND
		  (ctrZonCod <= @zonaH OR @zonaH IS NULL) AND
		  (F.facFechaRectif is null);
		
	SELECT ctrTitDocIden, CNS 
	FROM #AUX WHERE RN=1
	
		
END TRY

BEGIN CATCH
END CATCH


DROP TABLE IF EXISTS #AUX; 

GO