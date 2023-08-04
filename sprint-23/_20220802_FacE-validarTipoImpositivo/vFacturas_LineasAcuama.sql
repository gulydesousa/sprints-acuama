CREATE VIEW dbo.vFacturas_LineasAcuama
WITH SCHEMABINDING 
AS

SELECT fclFacCod, fclFacPerCod, fclFacCtrCod, fclFacVersion, fclNumLinea, fclImpuesto, fclImpImpuesto, fclBase, fclTotal
	, fclPrecio = CAST(FL.fclPrecio  AS DECIMAL(16,4)), fclUnidades,  fclImporte  = CAST(ROUND(fclUnidades*fclPrecio, 2) AS MONEY) 
	, fclPrecio1= CAST(FL.fclPrecio1 AS DECIMAL(16,4)), fclUnidades1, fclImporte1 = CAST(ROUND(fclUnidades1*fclPrecio1, 2) AS MONEY) 
	, fclPrecio2= CAST(FL.fclPrecio2 AS DECIMAL(16,4)), fclUnidades2, fclImporte2 = CAST(ROUND(fclUnidades2*fclPrecio2, 2) AS MONEY) 
	, fclPrecio3= CAST(FL.fclPrecio3 AS DECIMAL(16,4)), fclUnidades3, fclImporte3 = CAST(ROUND(fclUnidades3*fclPrecio3, 2) AS MONEY) 
	, fclPrecio4= CAST(FL.fclPrecio4 AS DECIMAL(16,4)), fclUnidades4, fclImporte4 = CAST(ROUND(fclUnidades4*fclPrecio4, 2) AS MONEY) 
	, fclPrecio5= CAST(FL.fclPrecio5 AS DECIMAL(16,4)), fclUnidades5, fclImporte5 = CAST(ROUND(fclUnidades5*fclPrecio5, 2) AS MONEY) 
	, fclPrecio6= CAST(FL.fclPrecio6 AS DECIMAL(16,4)), fclUnidades6, fclImporte6 = CAST(ROUND(fclUnidades6*fclPrecio6, 2) AS MONEY) 
	, fclPrecio7= CAST(FL.fclPrecio7 AS DECIMAL(16,4)), fclUnidades7, fclImporte7 = CAST(ROUND(fclUnidades7*fclPrecio7, 2) AS MONEY) 
	, fclPrecio8= CAST(FL.fclPrecio8 AS DECIMAL(16,4)), fclUnidades8, fclImporte8 = CAST(ROUND(fclUnidades8*fclPrecio8, 2) AS MONEY) 
	, fclPrecio9= CAST(FL.fclPrecio9 AS DECIMAL(16,4)), fclUnidades9, fclImporte9 = CAST(ROUND(fclUnidades9*fclPrecio9, 2) AS MONEY) 
	FROM dbo.faclin AS FL
	WHERE FL.fclFecLiq IS NULL;
GO


--CREATE UNIQUE CLUSTERED INDEX IX_vFacturas_LineasAcuama 
--ON dbo.vFacturas_LineasAcuama
--(fclFacCod, fclFacPerCod, fclFacCtrCod, fclFacVersion, fclNumLinea);
--GO