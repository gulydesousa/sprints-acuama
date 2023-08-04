--SELECT * FROM dbo.vLiquidaciones_RIBADESELLA_Omitir

ALTER VIEW dbo.vLiquidaciones_RIBADESELLA_Omitir
AS

WITH EXCLUIR AS(
	SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion 
	FROM dbo.facturas AS F
	WHERE (facCtrCod = 3667459 AND facPerCod IN ('202004','202005'))
	   OR (facCtrCod = 3666908 AND facPerCod IN ('202103'))
)

SELECT F.facCod
, F.facPerCod
, F.facCtrCod
, F.facVersion 
, C.ctrTitDocIden

FROM dbo.facturas AS F
INNER JOIN dbo.contratos AS C
ON  C.ctrCod = F.facCtrCod
AND C.ctrVersion = F.facCtrVersion
LEFT JOIN EXCLUIR AS X
ON  F.facCod	 = X.facCod
AND F.facPerCod  = X.facPerCod
AND F.facCtrCod  = X.facCtrCod
AND F.facVersion = X.facVersion
WHERE [ctrTitDocIden] IS NULL
   OR [ctrTitDocIden] IN ('', '00000000T')
   OR X.facCod IS NOT NULL;
GO