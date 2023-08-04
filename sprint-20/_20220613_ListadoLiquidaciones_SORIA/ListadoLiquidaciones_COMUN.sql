

/*
DECLARE @fechaFacturaD NVARCHAR(4000)
	  , @fechaFacturaH NVARCHAR(4000)
	  , @fechaLiquidacionD NVARCHAR(4000)
	  , @fechaLiquidacionH NVARCHAR(4000)
	  , @periodoD NVARCHAR(4000)
	  , @periodoH NVARCHAR(4000)
	  , @zonaD NVARCHAR(4000)
	  , @zonaH NVARCHAR(4000);


EXEC ReportingServices.ListadoLiquidaciones_COMUN
  @fechaFacturaD, @fechaFacturaH 
, @fechaLiquidacionD, @fechaLiquidacionH 
, @periodoD, @periodoH 
, @zonaD, @zonaH;
*/

ALTER PROCEDURE [ReportingServices].[ListadoLiquidaciones_COMUN]
  @fechaFacturaD NVARCHAR(4000)
, @fechaFacturaH NVARCHAR(4000)
, @fechaLiquidacionD NVARCHAR(4000)
, @fechaLiquidacionH NVARCHAR(4000)
, @periodoD NVARCHAR(4000)
, @periodoH NVARCHAR(4000)
, @zonaD NVARCHAR(4000)
, @zonaH NVARCHAR(4000)

AS
SELECT FL.fcltrfcod
, FL.fclfacctrcod
, FL.fclFacPerCod
, FL.fcltotal
, F.facNumero
, T.trfdes
, Consumo = (fclunidades1 + fclunidades2 + fclunidades3 + fclunidades4 + fclunidades5 + fclunidades6 + fclunidades7 + fclunidades8 + fclunidades9)
, CargoFijo = CAST((fclUnidades * fclPrecio) AS MONEY)
, CargoVariable = CAST((fclunidades1*fclprecio1 + fclunidades2*fclprecio2 + fclunidades3*fclprecio3 + fclunidades4*fclprecio4 + fclunidades5*fclprecio5 + fclunidades6*fclprecio6 + fclunidades7*fclprecio7 + fclunidades8 * fclprecio8 + fclunidades9*fclprecio9) AS MONEY)
, C.ctrTitNom
, C.ctrTitDocIden
, C.ctrZonCod
, I.inmdireccion
FROM dbo.faclin AS FL
INNER JOIN dbo.tarifas AS T
ON T.trfcod = FL.fclTrfCod AND T.trfsrvcod = FL.fclTrfSvCod
INNER JOIN dbo.facturas AS F
ON F.facCtrCod = FL.fclFacCtrCod 
AND F.facPerCod = FL.fclFacPerCod 
AND F.facVersion = FL.fclFacVersion 
AND F.facCod = FL.fclFacCod
INNER JOIN dbo.contratos AS C 
ON C.ctrcod = FL.fclFacCtrCod 
AND C.ctrversion = F.facCtrVersion
INNER JOIN dbo.inmuebles AS I 
ON I.inmcod = C.ctrinmcod
WHERE FL.fclFecLiq IS NOT NULL 
  AND FL.fclUsrLiq IS NOT NULL 
  AND F.facFechaRectif IS NULL 
  AND (@fechaFacturaD IS NULL OR F.facFecha >= @fechaFacturaD) 
  AND (@fechaFacturaH IS NULL OR F.facFecha <= @fechaFacturaH) 
  AND (@fechaLiquidacionD IS NULL OR FL.fclFecLiq >= @fechaLiquidacionD) 
  AND (@fechaLiquidacionH IS NULL OR FL.fclFecLiq <= @fechaLiquidacionH) 
  AND (@periodoD IS NULL OR F.facPerCod >= @periodoD) 
  AND (@periodoH IS NULL OR F.facPerCod <= @periodoH) 
  AND (@zonaD IS NULL OR C.ctrZonCod >= @zonaD) 
  AND (@zonaH IS NULL OR C.ctrZonCod <= @zonaH)
ORDER BY FL.fclTrfCod, FL.fclFacCtrCod, FL.fclFacPerCod;


GO


