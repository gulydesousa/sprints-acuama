CREATE FUNCTION fLineasFacE (@facturas AS dbo.tFacturasPK READONLY)
RETURNS TABLE
AS
	RETURN
	WITH FL AS(
	SELECT F.* 
	FROM vFacturas_LineasAcuama AS F
	INNER JOIN @facturas AS FF
	ON  FF.facCod = F.fclFacCod
	AND FF.facPerCod = F.fclFacPerCod
	AND FF.facCtrCod = F.fclFacCtrCod
	AND FF.facVersion = F.fclFacVersion

	), UNIDADES AS(
	SELECT fclFacCod, fclFacPerCod, fclFacCtrCod, fclFacVersion, fclNumLinea, fclImpuesto, ESCALA, UNIDADES, ID = REPLACE(ESCALA, 'fclUnidades', '')
	FROM FL
	UNPIVOT(
	  UNIDADES FOR ESCALA IN(fclUnidades, fclUnidades1, fclUnidades2, fclUnidades3, fclUnidades4, fclUnidades5, fclUnidades6, fclUnidades7, fclUnidades8, fclUnidades9)
	) AS P

	), PRECIOS AS(
	SELECT fclFacCod, fclFacPerCod, fclFacCtrCod, fclFacVersion, fclNumLinea, fclImpuesto, ESCALA, PRECIO, ID = REPLACE(ESCALA, 'fclPrecio', '')
	FROM FL
	UNPIVOT(
	  PRECIO FOR ESCALA IN(fclPrecio, fclPrecio1, fclPrecio2, fclPrecio3, fclPrecio4, fclPrecio5, fclPrecio6, fclPrecio7, fclPrecio8, fclPrecio9)
	) AS P

	), TOTAL AS(
	SELECT fclFacCod, fclFacPerCod, fclFacCtrCod, fclFacVersion, fclNumLinea, fclImpuesto, ESCALA, TOTAL, ID = REPLACE(ESCALA, 'fclImporte', '')
	FROM FL
	UNPIVOT(
	  TOTAL	FOR ESCALA IN(fclImporte, fclImporte1, fclImporte2, fclImporte3, fclImporte4, fclImporte5, fclImporte6, fclImporte7, fclImporte8, fclImporte9)
	) AS P)

	
	SELECT U.fclFacCod
	, U.fclFacPerCod
	, U.fclFacCtrCod
	, U.fclFacVersion
	, U.fclNumLinea
	
	--***********************************
	--****   AGRUPANDO POR FACTURA   ****
	--***********************************
	--[LINEA_SERES]: Se asigna una linea por escala 
	, [LINEA_SERES] = ROW_NUMBER() 
					  OVER(PARTITION BY U.fclFacCod, U.fclFacPerCod, U.fclFacCtrCod, U.fclFacVersion ORDER BY U.fclNumLinea, U.ID) 
	--[_LINEA]: Se asigna un numero diferente a cada tipo impositivo
	, [_LINEA]		= DENSE_RANK() 
					  OVER(PARTITION BY U.fclFacCod, U.fclFacPerCod, U.fclFacCtrCod, U.fclFacVersion ORDER BY U.fclImpuesto)
	--[IVA_LINEA]: Se asigna una linea diferente a cada grupo de lineas por tipo impositivo
	, [IVA_LINEA]	= ROW_NUMBER() 
					  OVER(PARTITION BY U.fclFacCod, U.fclFacPerCod, U.fclFacCtrCod, U.fclFacVersion, U.fclImpuesto ORDER BY U.fclNumLinea, U.ID)  
	
	, [IVA] = U.fclImpuesto
	, [ESCALA] = CAST(IIF(U.ID='', 0, U.ID) AS INT)

	--******************************************
	--****   DETALLE POR LINEA DE FACTURA   ****
	--******************************************
	, U.UNIDADES 
	, P.PRECIO
	, T.TOTAL

	--**************************
	--****   TOTALES FACE   ****
	--**************************
	, [IVA_B.IMPONIBLE]	= CAST(SUM(ROUND(U.UNIDADES*P.PRECIO, 2)) 
						  OVER (PARTITION BY U.fclFacCod, U.fclFacPerCod, U.fclFacCtrCod, U.fclFacVersion, U.fclImpuesto) AS MONEY)
	FROM UNIDADES AS U
	INNER JOIN PRECIOS AS P
	ON	U.ID = P.ID  
	AND U.fclFacCod		= P.fclFacCod
	AND U.fclFacPerCod	= P.fclFacPerCod
	AND U.fclFacCtrCod	= P.fclFacCtrCod
	AND U.fclFacVersion = P.fclFacVersion
	AND U.fclNumLinea	= P.fclNumLinea
	AND U.UNIDADES <> 0
	AND P.PRECIO <>0
	INNER JOIN TOTAL AS T
	ON	U.ID = T.ID  
	AND U.fclFacCod		= T.fclFacCod
	AND U.fclFacPerCod	= T.fclFacPerCod
	AND U.fclFacCtrCod	= T.fclFacCtrCod
	AND U.fclFacVersion = T.fclFacVersion
	AND U.fclNumLinea	= T.fclNumLinea;

	
GO