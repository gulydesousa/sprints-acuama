/*


DECLARE @fDesde DATE='20220201';
DECLARE @fHasta DATE = '20220301';
DECLARE @srvCod INT = NULL;
DECLARE @esFacturada BIT = NULL;
DECLARE @usos VARCHAR(100) = '1';

SELECT SUM(VALOR) FROM Indicadores.fConsumoFacturaxSemana (@fDesde, @fHasta, @srvCod, @esFacturada, @usos);

SELECT * FROM Indicadores.fConsumoFacturaxSemana (@fDesde, @fHasta, @srvCod, @esFacturada, @usos) ORDER BY SEMANA;
*/

CREATE FUNCTION Indicadores.fConsumoFacturaxSemana 
( @fDesde DATE
, @fHasta DATE
, @srvCod INT = NULL
, @esFacturada BIT = NULL
, @usos VARCHAR(100) = NULL)
RETURNS TABLE 

AS
RETURN(

WITH U AS(
SELECT DISTINCT(value) FROM dbo.Split(@usos, ',')

), CNS AS(
SELECT --F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, F.facNumero,
	   --RN=1: Para contar el consumo una vez por factura
	   RN = ROW_NUMBER() OVER(PARTITION BY  F.facCod, F.facPerCod, F.facCtrCod, F.facVersion ORDER BY FL.fclNumLinea),
	   F.facLecActFec,
	   F.facConsumoFactura, 
	   usoCod = U.value, 
	   SEMANA = (DATEDIFF(DAY, @fDesde, facLecActFec)/7)+1
	   
FROM dbo.facturas AS F
INNER JOIN dbo.contratos AS C
ON  C.ctrcod = F.facCtrCod
AND C.ctrversion = F.facCtrVersion
INNER JOIN dbo.faclin AS FL
ON F.facCod = FL.fclFacCod
AND F.facPerCod = FL.fclFacPerCod
AND F.facCtrCod = FL.fclFacCtrCod
AND F.facVersion = FL.fclFacVersion
AND FL.fclFecLiq IS NULL 
AND F.facFechaRectif IS NULL
AND F.facLecActFec >= @fDesde 
AND F.facLecActFec < @fHasta
AND (@srvCod IS NULL OR FL.fclTrfSvCod = @srvCod)

AND ((@esFacturada IS NULL) OR 
	 
	 (@esFacturada = 1 AND (FL.fclPrecio<>0 OR FL.fclPrecio1<>0 OR FL.fclPrecio2<>0 OR FL.fclPrecio3<>0
	 OR FL.fclPrecio4<>0 OR FL.fclPrecio5<>0 OR FL.fclPrecio6<>0
	 OR FL.fclPrecio7<>0 OR FL.fclPrecio8<>0 OR FL.fclPrecio9<>0)) OR

	 (@esFacturada = 0 AND (FL.fclPrecio=0 AND FL.fclPrecio1=0 AND FL.fclPrecio2=0 AND FL.fclPrecio3=0
	 AND FL.fclPrecio4=0 AND FL.fclPrecio5=0 AND FL.fclPrecio6=0
	 AND FL.fclPrecio7=0 AND FL.fclPrecio8=0 AND FL.fclPrecio9=0))) 

LEFT JOIN U 
ON C.ctrUsoCod = U.value
)

SELECT SEMANA
	 , VALOR = SUM(facConsumoFactura)
FROM CNS
WHERE RN=1 
AND (@usos IS NULL OR usoCod IS NOT NULL )
GROUP BY SEMANA
) 

GO
