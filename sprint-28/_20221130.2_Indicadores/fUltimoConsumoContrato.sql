  /*
  DECLARE @fHasta AS DATE = '20221101';
  DECLARE @SvcCod AS INT = 1;

  SELECT * FROM Indicadores.fUltimoConsumoContrato(@fHasta, @SvcCod)  WHERE esFacturada IS NOT NULL AND esFacturada=1

  */
CREATE FUNCTION Indicadores.fUltimoConsumoContrato
( @fHasta AS DATE
, @SvcCod AS INT)
RETURNS TABLE 
AS
RETURN(

  WITH CTRS AS(
  SELECT DISTINCT C.ctrcod 
  FROM dbo.contratos AS C
  WHERE C.ctrfecreg<@fHasta 
  AND (C.ctrfecanu IS NULL OR C.ctrfecanu >= @fHasta)
  
  ), FACS AS(  
  SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, F.facConsumoFactura, FL.fclTrfSvCod
  , esFacturada = IIF(FL.fclPrecio=0 
				  AND FL.fclPrecio1=0 AND FL.fclPrecio2=0 AND FL.fclPrecio3=0 AND FL.fclPrecio4=0 
				  AND FL.fclPrecio5=0 AND FL.fclPrecio6=0 AND FL.fclPrecio7=0 AND FL.fclPrecio8=0 
				  AND FL.fclPrecio9=0, 0, 1)
  
  --RN=1: Para quedarnos con la factura con fecha de registro mas reciente
  , RN= ROW_NUMBER() OVER (PARTITION BY F.facCtrCod ORDER BY F.facFecReg DESC)
  FROM dbo.facturas AS F
  INNER JOIN CTRS AS C
  ON C.ctrcod = F.facCtrCod
  INNER JOIN dbo.faclin AS FL
  ON F.facCod = FL.fclFacCod
  AND F.facPerCod = FL.fclFacPerCod
  AND F.facCtrCod = FL.fclFacCtrCod
  AND F.facVersion = FL.fclFacVersion
  AND FL.fclTrfSvCod = @SvcCod
  AND (FL.fclFecLiq IS NULL OR FL.fclFecLiq>=@fHasta)
  WHERE F.facFecReg < @fHasta
  AND (F.facFechaRectif IS NULL OR F.facFechaRectif>=@fHasta))

  SELECT C.ctrcod, F.facCod, F.facPerCod, F.facVersion, F.facConsumoFactura, fclTrfSvCod, esFacturada
  FROM CTRS AS C
  LEFT JOIN FACS AS F 
  ON C.ctrcod = F.facCtrCod
  AND F.RN=1
)
GO