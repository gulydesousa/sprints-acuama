/*
DECLARE @sociedadD INT;
DECLARE @sociedadH INT;
DECLARE @periodoD VARCHAR(6);
DECLARE @periodoH VARCHAR(6);
DECLARE @contratoD INT;
DECLARE @contratoH INT;
DECLARE @zonaD VARCHAR(4);
DECLARE @zonaH VARCHAR(4);
DECLARE @afecha DATETIME = GETDATE();
EXEC ReportingServices.ListadoSaldosClientes @sociedadD, @sociedadH, @periodoD, @periodoH, @contratoD, @contratoH, @zonaD, @zonaH, @afecha
*/
CREATE PROCEDURE ReportingServices.ListadoSaldosClientes(
  @sociedadD INT = NULL
, @sociedadH INT = NULL
, @periodoD VARCHAR(6) = NULL
, @periodoH VARCHAR(6) = NULL
, @contratoD INT = NULL
, @contratoH INT = NULL
, @zonaD VARCHAR(4) = NULL
, @zonaH VARCHAR(4) = NULL
, @afecha DATETIME = NULL)

AS

SET @afecha = ISNULL(@afecha, dbo.GetAcuamaDate());

SELECT cobCtr
, cblPer
, dirSuministro = inm.inmdireccion
, facFecha
, facSerCod
, facNumero
, facClicod
, cli.clinom
, facConsumoFactura
, importeCobradodeFactura
, importeFacturado
FROM(

	SELECT cobCtr
		 , cblPer
		 , cblFacCod
		 , importeCobradodeFactura = ISNULL((SELECT ROUND(SUM(cl.cblImporte), 2)
											 FROM dbo.cobros AS c 
											 INNER JOIN dbo.coblin AS cl 
											 ON c.cobScd=cl.cblScd 
											 AND c.cobPpag=cl.cblPpag 
											 AND c.cobNum=cl.cblNum
											 WHERE cobCtr=cob.cobCtr 
											 AND cl.cblPer=cbl.cblPer 
											 AND cl.cblFacCod=cbl.cblFacCod 
											 AND c.cobFecReg <= @afecha), 0)
											  
		, importeFacturado = ISNULL((SELECT ROUND(SUM(sfl.fcltotal), 2)
							 FROM dbo.facturas AS sf 
							 INNER JOIN dbo.faclin AS sfl 
							 ON sf.FacCod=sfl.fclFacCod 
							 AND sf.facPerCod=sfl.fclFacPerCod 
							 AND sf.facCtrCod=sfl.fclFacCtrCod 
							 AND sf.facVersion=sfl.fclFacVersion
							 WHERE sf.facCtrCod=cob.cobCtr 
							 AND sf.facPerCod=cbl.cblPer 
							 AND sf.facCod=cbl.cblFacCod 
							 AND (fclFecLiq IS NULL AND fclUsrLiq IS NULL) 
							 AND (facFechaRectif IS NULL OR facFechaRectif > @afecha)), 0)
FROM dbo.coblin AS cbl
INNER JOIN dbo.cobros cob 
ON  cobNum=cblNum 
AND cobPpag=cblPpag 
AND cobScd=cblScd

WHERE (@sociedadD IS NULL OR cblScd>=@sociedadD) AND (@sociedadH IS NULL OR cblScd<=@sociedadH)
  AND (@contratoD IS NULL OR cobCtr>=@contratoD) AND (@contratoH IS NULL OR cobCtr<=@contratoH)
  AND ((@periodoD IS NULL OR cblPer>=@periodoD) AND (@periodoH IS NULL OR cblPer<=@periodoH) OR cblPer='999999')
  -- IMPORTE_COBRADO > IMPORTE_FACTURADO condici??n para que sean Saldos a favor del cliente
  AND (SELECT ROUND(ISNULL(SUM(cblImporte),0), 2)
	   FROM dbo.cobros 
	   INNER JOIN dbo.coblin 
	   ON cobScd=cblScd 
	   AND cobPpag=cblPpag 
	   AND cobNum=cblNum
	   WHERE cobCtr=cob.cobCtr 
	    AND cblPer=cbl.cblPer 
		AND cblFacCod=cbl.cblFacCod 
		AND cobFecReg <= @afecha)	
	>
	(SELECT ROUND(ISNULL(SUM(fclTotal), 0), 2)
	FROM dbo.facturas AS fTotal 
	INNER JOIN dbo.faclin 
	ON  fclFacCod=fTotal.facCod 
	AND fclFacPerCod=fTotal.facPerCod 
	AND fclFacCtrCod=fTotal.facCtrCod 
	AND fclFacVersion=fTotal.facVersion
	WHERE (fTotal.facCtrCod=cob.cobCtr) 
	  AND (fTotal.facPerCod=cbl.cblPer) 
	  AND (fTotal.facCod=cbl.cblFacCod) 
	  AND (fclFecLiq IS NULL AND fclUsrLiq IS NULL) 
	  AND ((facFechaRectif IS NULL) OR (facFechaRectif > @afecha)))
GROUP BY cobCtr, cblPer, cblFacCod
) AS saldoClientes
LEFT JOIN facturas ON facCtrCod=saldoClientes.cobCtr AND facPerCod=saldoClientes.cblPer AND facCod=saldoClientes.cblFacCod AND facFechaRectif IS NULL
LEFT JOIN contratos ctr on cobCtr=ctr.ctrcod AND ctr.ctrversion=(SELECT MAX(ctrversion) FROM contratos ctr2 WHERE ctr.ctrcod=ctr2.ctrcod)
LEFT JOIN inmuebles inm ON ctr.ctrinmcod=inm.inmcod
LEFT JOIN clientes cli ON facClicod=cli.clicod
WHERE (@zonaD IS NULL OR facZonCod>=@zonaD) 
  AND (@zonaH IS NULL OR facZonCod<=@zonaH)
ORDER BY cobCtr, facPerCod DESC, facZonCod, facfecReg;

GO