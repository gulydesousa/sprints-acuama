/*
DECLARE @codigoContratoD INT=3;
DECLARE @codigoContratoH INT=3;
DECLARE @fechaD DATE;
DECLARE @fechaH DATE;
DECLARE @periodoD VARCHAR(6) = '202101';
DECLARE @periodoH VARCHAR(6);
DECLARE @repLegal VARCHAR(80);
DECLARE @zonaD VARCHAR(4) --='28';
DECLARE @zonaH VARCHAR(4) --='28';

EXEC [ReportingServices].[HistoricoConsumoContrato] @codigoContratoD, @codigoContratoH, @fechaD, @fechaH, @periodoD, @periodoH, @repLegal, @zonaD, @zonaH
*/

ALTER PROCEDURE [ReportingServices].[HistoricoConsumoContrato]
@codigoContratoD INT,
@codigoContratoH INT,
@fechaD DATE,
@fechaH DATE,
@periodoD VARCHAR(6),
@periodoH VARCHAR(6),
@repLegal VARCHAR(80),
@zonaD VARCHAR(4),
@zonaH VARCHAR(4)
AS


DECLARE @FAC AS tFacturasPK
INSERT INTO @FAC (facCod, facPerCod, facCtrCod, facVersion)
SELECT facCod, facPerCod, facCtrCod, facVersion

FROM dbo.facturas AS F
INNER JOIN dbo.contratos AS C 
ON  C.ctrcod = F.facctrcod 
AND C.ctrversion = F.facctrversion
AND (@codigoContratoD IS NULL OR F.facCtrCod >= @codigoContratoD)
AND (@codigoContratoH IS NULL OR F.facCtrCod <= @codigoContratoH)
AND (@fechaD IS NULL OR facFecha>=@fechaD) 
AND (@fechaH IS NULL OR facFecha<=@fechaH) 
AND (@periodoD IS NULL OR F.facPerCod>=@periodoD)
AND (@periodoH IS NULL OR F.facPerCod<=@periodoH)
AND (@zonaD IS NULL OR F.facZonCod>=@zonaD)
AND (@zonaH IS NULL OR F.facZonCod<=@zonaH)
AND (@repLegal IS NULL OR C.ctrRepresent LIKE '%' + @repLegal + '%')
AND (F.facFechaRectif IS NULL OR facFechaRectif > ISNULL(@fechaH, dbo.GetAcuamaDate()))

WHERE (COALESCE(@zonaD, @zonaH, @periodoD, @periodoH, @repLegal) IS NOT NULL OR
	   COALESCE(@codigoContratoD, @codigoContratoH) IS NOT NULL OR
	   COALESCE(@fechaD, @fechaH) IS NOT NULL)
OPTION(RECOMPILE);


SELECT F.*
, TotalFactura = SUM(FL.fcltotal)
FROM @FAC AS F
LEFT JOIN dbo.faclin AS FL
ON F.facCod = FL.fclFacCod
AND F.facPerCod = FL.fclFacPerCod
AND F.facCtrCod = FL.fclFacCtrCod
AND F.facVersion = FL.fclFacVersion
AND((FL.fclFecLiq IS NULL AND FL.fclUsrLiq IS NULL) OR FL.fclFecLiq>=@fechaH)
GROUP BY facCod, facPerCod, facCtrCod, facVersion;


GO