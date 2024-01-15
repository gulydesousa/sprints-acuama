--************************
--EXEC dbo.LiquidacionesPendientes
--************************
CREATE PROCEDURE LiquidacionesPendientes
AS
	--Facturas que tienen la linea del servicio y la linea del descuento
	--Pero una está liquidada y la otra no
	SELECT F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion
	, A.aprNumero
	, [Servicio] = T.svccod
	, [Servicio Liquidación] = FL0.fclFecLiq
	, [Descuento Svc] = T.tribSvcDescuento
	, [Descuento Liquidación] = FLD.fclFecLiq
	FROM dbo.facturas AS F
	INNER JOIN dbo.faclin AS FL0
	ON F.facCod = FL0.fclFacCod
	AND F.facPerCod = FL0.fclFacPerCod
	AND F.facCtrCod = FL0.fclFacCtrCod
	AND F.facVersion = FL0.fclFacVersion
	AND F.facFecha IS NOT NULL
	INNER JOIN dbo.vLiquidacionesTributos AS T
	ON T.svcCod = FL0.fclTrfSvCod
	AND T.liqTipoId = 0 --Las liquidaciones de todos los servicios
	AND T.tribSvcDescuento IS NOT NULL
	INNER JOIN dbo.faclin AS FLD
	ON  FLD.fclFacCod = FL0.fclFacCod
	AND FLD.fclFacPerCod = FL0.fclFacPerCod
	AND FLD.fclFacCtrCod = FL0.fclFacCtrCod
	AND FLD.fclFacVersion = FL0.fclFacVersion
	AND FLD.fclTrfSvCod = T.tribSvcDescuento
	AND((FL0.fclFecLiq IS NOT NULL AND FLD.fclFecLiq IS NULL)
	   OR (FLD.fclFecLiq IS NOT NULL AND FL0.fclFecLiq IS NULL))
	LEFT JOIN dbo.apremios AS A
	ON  A.aprFacCod = F.facCod 
	AND A.aprFacCtrCod = F.facCtrCod 
	AND A.aprFacPerCod = F.facPerCod 
	AND A.aprFacVersion = F.facVersion
	WHERE (A.aprNumero IS NULL)
	ORDER BY facCtrCod;
GO