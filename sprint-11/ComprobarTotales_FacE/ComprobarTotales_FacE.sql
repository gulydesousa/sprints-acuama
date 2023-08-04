/*
****** CONFIGURACION ******
--DELETE FROM excelConsultas WHERE ExcCod='000/101'
--DELETE FROM ExcelPerfil WHERE ExPCod='000/101'

--SELECT * FROM excelConsultas

INSERT INTO dbo.ExcelConsultas
VALUES ('000/101',	'Comprobar Totales FacE', 'Comprobar Totales por Tipo Impositivo (FacE)', 12, '[InformesExcel].[ComprobarTotales_FacE]', '000', 'Facturas electrónicas <b>enviadas</b> a <b><i>facE</i></b> con <b>deuda pendiente</b>.<br>En la columna <b>"Error"</b> se informa el resultado de la comparación de los totales de acuama con los importes esperados en la factura electrónica <b><i>facE</i></b>.');

INSERT INTO ExcelPerfil
VALUES('000/101', 'root', 4, NULL)

INSERT INTO ExcelPerfil
VALUES('000/101', 'jefeExp', 4, NULL)

INSERT INTO ExcelPerfil
VALUES('000/101', 'jefAdmon', 4, NULL)

*/

/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_error_out INT;
DECLARE @p_errMsg_out   NVARCHAR(MAX);

SET @p_params= '<NodoXML><LI><periodoD>000000</periodoD><periodoH>999999</periodoH></LI></NodoXML>'

EXEC [InformesExcel].[ComprobarTotales_FacE] @p_params, @p_error_out OUTPUT, @p_errMsg_out OUTPUT;
*/


CREATE PROCEDURE [InformesExcel].[ComprobarTotales_FacE]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS

SET NOCOUNT ON;  
BEGIN TRY

	--********************
	--INICIO: 2 DataTables
	-- 1: Paramentros del encabezado
	-- 2: Gurpos
	-- 3: Datos
	--********************
	
	--DataTable[1]:  Parametros
	DECLARE @xml AS XML = @p_params;
	
	DECLARE @params TABLE (periodoD VARCHAR(6) NULL, periodoH VARCHAR(6) NULL, fInforme DATETIME);

	INSERT INTO @params
	SELECT periodoD = M.Item.value('periodoD[1]', 'VARCHAR(6)')
		 , periodoH = M.Item.value('periodoH[1]', 'VARCHAR(6)')
		 , fInforme = GETDATE()	
	FROM @xml.nodes('NodoXML/LI')AS M(Item);

	--********************
	--VALIDAR PARAMETROS
	--********************
	UPDATE @params
	SET periodoD = IIF(periodoD IS NULL OR periodoD='', '000000', periodoD)
	  , periodoH = IIF(periodoH IS NULL OR periodoH='', '999999', periodoH)
	OUTPUT INSERTED.* ;
	
	
	
	--********************
	--DataTable[2]:  Grupos
	SELECT * 
	FROM (VALUES ('facE Facturas')
			   , ('facE Líneas de Facturas')) 
	AS DataTables(Grupo);
	
	--********************


	--********************
	--[01]#FACS: Facturas FacE
	SELECT F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion
	, F.facNumero
	, F.facFecha
	, facEnvSERES = ISNULL(F.facEnvSERES, '')
	, F.facFecEmisionSERES
	, F.facFechaRectif
	INTO #FACS
	FROM dbo.facturas AS F
	INNER JOIN dbo.contratos AS C
	ON C.ctrcod = F.facCtrCod
	AND C.ctrversion = F.facCtrVersion
	AND C.ctrFace=1
	AND F.facFechaRectif IS NULL
	INNER JOIN @params AS _P
	ON  F.facPerCod >=  _P.periodoD
	AND F.facPerCod<= _P.periodoH


	--[02]#COBS: Cobros por factura
	SELECT C.cobCtr
		 , CL.cblPer
		 , CL.cblFacCod
		 , Cobrado = SUM(CL.cblImporte)
	INTO #COBS
	FROM dbo.cobros AS C
	INNER JOIN dbo.coblin AS CL
	ON  CL.cblScd = C.cobScd
	AND CL.cblPpag = C.cobPpag
	AND CL.cblNum = C.cobNum
	INNER JOIN #FACS AS F
	ON  C.cobCtr  = F.facCtrcod
	AND CL.cblPer = F.facPerCod
	AND CL.cblFacCod = F.facCod
	GROUP BY C.cobCtr, CL.cblPer, CL.cblFacCod
	
	--[03]#FCL: Líneas de factura
	SELECT FL.*
	, _LINEA	 = ROW_NUMBER()			OVER (PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion ORDER BY fclNumLinea)
	, _IMPUESTOS = SUM(fclImpImpuesto)	OVER (PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion)
	, _BASE		 = SUM(fclBase)			OVER (PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion) 
	, _TOTAL	 = SUM(fclTotal)		OVER (PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion) 
	INTO #FCL
	FROM dbo.faclin AS FL
	INNER JOIN #FACS AS F
	ON  F.facCod = FL.fclFacCod
	AND F.facPerCod = FL.fclFacPerCod
	AND F.facCtrCod = FL.fclFacCtrCod
	AND F.facVersion = FL.fclFacVersion
	AND FL.fclFecLiq IS NULL;

	--[04]#SERES_LIN: Lineas de la factura en SERES
	--Una linea por escalado
	SELECT FL.fclFacCod, FL.fclFacPerCod, FL.fclFacCtrCod, FL.fclFacVersion, FL.fclNumLinea
		 , [PRECIO]			= CAST(FL.fclPrecio AS DECIMAL(16,4))
		 , [UDS]			= FL.fclUnidades
		 , [TOTAL]			= CAST(ROUND(FL.fclUnidades*FL.fclPrecio, 2) AS MONEY)
		 , [ESCALA]			= 0
		 , [LINEA_SERES]	= CAST(NULL AS INT)
		 , [IVA]			= fclImpuesto
		 , [IVA_LINEA]		= CAST(NULL AS INT)
		 , [IVA_B.IMPONIBLE]= CAST(0 AS MONEY)	
	INTO #SERES_LIN
	FROM #FCL AS FL
	WHERE FL.fclPrecio<>0 AND FL.fclUnidades<>0
	UNION ALL
	--ESCALA#1
	SELECT FL.fclFacCod, FL.fclFacPerCod, FL.fclFacCtrCod, FL.fclFacVersion, FL.fclNumLinea
		 , [PRECIO]			= CAST(FL.fclPrecio1 AS DECIMAL(16,4))
		 , [UDS]			= FL.fclUnidades1
		 , [TOTAL]			= CAST(ROUND(FL.fclUnidades1*FL.fclPrecio1, 2) AS MONEY)
		 , [ESCALA]			= 1
		 , [LINEA_SERES]	= NULL
		 , [IVA]			= fclImpuesto
		 , [IVA_LINEA]		= NULL
		 , [IVA_B.IMPONIBLE]= NULL
	FROM #FCL AS FL
	WHERE FL.fclPrecio1<>0 AND FL.fclUnidades1<>0
	UNION ALL

	--ESCALA#2
	SELECT FL.fclFacCod, FL.fclFacPerCod, FL.fclFacCtrCod, FL.fclFacVersion, FL.fclNumLinea
		 , [PRECIO]			= CAST(FL.fclPrecio2 AS DECIMAL(16,4))
		 , [UDS]			= FL.fclUnidades2
		 , [TOTAL]			= CAST(ROUND(FL.fclUnidades2*FL.fclPrecio2, 2) AS MONEY)
		 , [ESCALA]			= 2
		 , [LINEA_SERES]	= NULL
		 , [IVA]			= fclImpuesto
		 , [IVA_LINEA]		= NULL
		 , [IVA_B.IMPONIBLE]= NULL
	FROM #FCL AS FL
	WHERE FL.fclPrecio2<>0 AND FL.fclUnidades2<>0
	UNION ALL

	--ESCALA#3
	SELECT FL.fclFacCod, FL.fclFacPerCod, FL.fclFacCtrCod, FL.fclFacVersion, FL.fclNumLinea
		 , [PRECIO]			= CAST(FL.fclPrecio3 AS DECIMAL(16,4))
		 , [UDS]			= FL.fclUnidades3
		 , [TOTAL]			= CAST(ROUND(FL.fclUnidades3*FL.fclPrecio3, 2) AS MONEY)
		 , [ESCALA]			= 3
		 , [LINEA_SERES]	= NULL
		 , [IVA]			= fclImpuesto
		 , [IVA_LINEA]		= NULL
		 , [IVA_B.IMPONIBLE]= NULL
	FROM #FCL AS FL
	WHERE FL.fclPrecio3<>0 AND FL.fclUnidades3<>0
	UNION ALL

	--ESCALA#4
	SELECT FL.fclFacCod, FL.fclFacPerCod, FL.fclFacCtrCod, FL.fclFacVersion, FL.fclNumLinea
		 , [PRECIO]			= CAST(FL.fclPrecio4 AS DECIMAL(16,4))
		 , [UDS]			= FL.fclUnidades4
		 , [TOTAL]			= CAST(ROUND(FL.fclUnidades4*FL.fclPrecio4, 2) AS MONEY)
		 , [ESCALA]			= 4
		 , [LINEA_SERES]	= NULL
		 , [IVA]			= fclImpuesto
		 , [IVA_LINEA]		= NULL
		 , [IVA_B.IMPONIBLE]= NULL
	FROM #FCL AS FL
	WHERE FL.fclPrecio4<>0 AND FL.fclUnidades4<>0
	UNION ALL

	--ESCALA#5
	SELECT FL.fclFacCod, FL.fclFacPerCod, FL.fclFacCtrCod, FL.fclFacVersion, FL.fclNumLinea
		 , [PRECIO]			= CAST(FL.fclPrecio5 AS DECIMAL(16,4))
		 , [UDS]			= FL.fclUnidades5
		 , [TOTAL]			= CAST(ROUND(FL.fclUnidades5*FL.fclPrecio5, 2) AS MONEY)
		 , [ESCALA]			= 5
		 , [LINEA_SERES]	= NULL
		 , [IVA]			= fclImpuesto
		 , [IVA_LINEA]		= NULL
		 , [IVA_B.IMPONIBLE]= NULL
	FROM #FCL AS FL
	WHERE FL.fclPrecio5<>0 AND FL.fclUnidades5<>0
	UNION ALL

	--ESCALA#6
	SELECT FL.fclFacCod, FL.fclFacPerCod, FL.fclFacCtrCod, FL.fclFacVersion, FL.fclNumLinea
		 , [PRECIO]			= CAST(FL.fclPrecio6 AS DECIMAL(16,4))
		 , [UDS]			= FL.fclUnidades6
		 , [TOTAL]			= CAST(ROUND(FL.fclUnidades6*FL.fclPrecio6, 2) AS MONEY)
		 , [ESCALA]			= 6
		 , [LINEA_SERES]	= NULL
		 , [IVA]			= fclImpuesto
		 , [IVA_LINEA]		= NULL
		 , [IVA_B.IMPONIBLE]= NULL
	FROM #FCL AS FL
	WHERE FL.fclPrecio6<>0 AND FL.fclUnidades6<>0;
	
	--[05]UPDATE: #SERES_LIN 
	--Totaliza las bases agrupando por tipo impositivo
	WITH DATA AS(
	SELECT fclFacCod
	, fclFacPerCod
	, fclFacCtrCod
	, fclFacVersion 
	, fclNumLinea
	, [ESCALA]
	, [LINEA_SERES]		= ROW_NUMBER() OVER(PARTITION BY fclFacCod, fclFacPerCod, fclFacCtrCod, fclFacVersion ORDER BY fclNumLinea, ESCALA) 
	--IMPUESTOS SERES
	, [IVA]
	, [IVA_LINEA]		= ROW_NUMBER() OVER(PARTITION BY fclFacCod, fclFacPerCod, fclFacCtrCod, fclFacVersion, IVA ORDER BY fclNumLinea, Escala)  
	, [IVA_B.IMPONIBLE]	= CAST(SUM(ROUND(UDS*PRECIO, 2)) OVER (PARTITION BY fclFacCod, fclFacPerCod, fclFacCtrCod, fclFacVersion, IVA) AS MONEY)
	FROM #SERES_LIN AS L)

	UPDATE SL
	SET SL.[LINEA_SERES]	 = D.[LINEA_SERES]
	  , SL.[IVA_LINEA]		 = D.[IVA_LINEA]
	  , SL.[IVA_B.IMPONIBLE] = D.[IVA_B.IMPONIBLE]
	FROM #SERES_LIN AS SL
	INNER JOIN DATA AS D
	ON SL.fclFacCod = D.fclFacCod
	AND SL.fclFacPerCod = D.fclFacPerCod
	AND SL.fclFacCtrCod = D.fclFacCtrCod
	AND SL.fclFacVersion = D.fclFacVersion
	AND SL.fclNumLinea = D.fclNumLinea
	AND SL.ESCALA = D.ESCALA;

	--*****************
	--RESULTADO
	--*****************
	WITH FACE AS(
	--TOTALES FACE
	SELECT F.fclFacCod
	, F.fclFacPerCod
	, F.fclFacCtrCod
	, F.fclFacVersion
	, F.[IVA_B.IMPONIBLE]
	, F.[IVA]
	, _LINEA = ROW_NUMBER() OVER(PARTITION BY F.fclFacCod, F.fclFacPerCod, F.fclFacCtrCod, F.fclFacVersion ORDER BY F.IVA)
	, CAST(ROUND(F.[IVA_B.IMPONIBLE]*F.[IVA]*0.01, 2) AS MONEY) AS [IVA_IMPUESTOS]
	, SUM(CAST(ROUND(F.[IVA_B.IMPONIBLE]*F.[IVA]*0.01, 2) AS MONEY)) 
	  OVER (PARTITION BY F.fclFacCod, F.fclFacPerCod, F.fclFacCtrCod, F.fclFacVersion) AS [TOTAL_IMP.REP]
	, SUM(F.[IVA_B.IMPONIBLE]) 
	  OVER (PARTITION BY F.fclFacCod, F.fclFacPerCod, F.fclFacCtrCod, F.fclFacVersion) AS [TOTAL_BASEIMPO.]
	, SUM(CAST(ROUND(F.[IVA_B.IMPONIBLE]*F.[IVA]*0.01, 2) AS MONEY) + F.[IVA_B.IMPONIBLE])
	OVER (PARTITION BY F.fclFacCod, F.fclFacPerCod, F.fclFacCtrCod, F.fclFacVersion) AS [TOTAL_FACTURA]
	FROM #SERES_LIN AS F
	WHERE IVA_LINEA=1
	
	), FACT AS(
	--TOTALES FACTURA
	SELECT FL.fclFacCod
	, FL.fclFacPerCod
	, FL.fclFacCtrCod
	, FL.fclFacVersion
	, [_TOTAL_BASEIMPO.] = ROUND(_BASE, 2)
	, [_TOTAL_IMP.REP]	 = ROUND(_IMPUESTOS, 2)
	, [_TOTAL_FACTURA]   = ROUND(_BASE, 2) + ROUND(_IMPUESTOS, 2)
	, [_TOTAL]			 = ROUND([_TOTAL], 2)
	FROM #FCL AS FL
	WHERE _LINEA = 1

	), ESTADO_SERES AS(
	SELECT  
	  F.facCod 
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion
	, S.facEDescEstado
	, S.facEDescRazon
	, S.facEStatusDate
	, S.facElink
	, RN = ROW_NUMBER() OVER(PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion ORDER BY S.facEStatusDate DESC)
	FROM dbo.facEstadoSeres AS S
	INNER JOIN #FACS AS F
	ON F.facNumero = S.facEfacNum
	AND F.facFecha = S.FacEfacFecha)

	--COMPARAMOS LOS TOTALES DE FACE CON LOS DE ACUAMA
	SELECT  
	  F0.fclFacPerCod
	, F0.fclFacCtrCod
	, F0.fclFacCod
	, F0.fclFacVersion
	, F.facFecha
	, F.facFechaRectif
	, F0.[_TOTAL_BASEIMPO.]
	, F1.[TOTAL_BASEIMPO.]
	
	, F0.[_TOTAL_IMP.REP]
	, F1.[TOTAL_IMP.REP]
	
	, F0.[_TOTAL_FACTURA] 
	, F1.[TOTAL_FACTURA] 
	
	, F0.[_TOTAL]
	
	, C.Cobrado
	, F.facEnvSeres
	, F.facFecEmisionSERES
	, E.facEDescEstado
	, E.facEDescRazon

	, [Error] = CONCAT(
	  IIF(ISNULL(F1.[TOTAL_BASEIMPO.], 0)	<>F0.[_TOTAL_BASEIMPO.]	, 'Error en la base imponible total.\n', '')
	, IIF(ISNULL(F1.[TOTAL_IMP.REP], 0)	<>F0.[_TOTAL_IMP.REP]		, 'Error en el impuesto repercutido total.\n', '')
	, IIF(ISNULL(F1.[TOTAL_FACTURA], 0)	<>F0.[_TOTAL_FACTURA] 		, 'Error en el total a pagar.\n', '')
	, IIF(F0.[_TOTAL_FACTURA] <>F0.[_TOTAL]							, 'Error Acuama: Compruebe que los totales de la factura impresa coincide con el facturado.\n', ''))

	INTO #RESULT	  
	FROM FACT AS F0
	INNER JOIN #FACS AS F
	ON F.facCod		= F0.fclFacCod
	AND F.facPerCod = F0.fclFacPerCod
	AND F.facCtrCod = F0.fclFacCtrCod
	AND F.facVersion= F0.fclFacVersion
	LEFT JOIN #COBS AS C
	ON  C.cobCtr	= F0.fclFacCtrCod
	AND C.cblPer	= F0.fclFacPerCod
	AND C.cblFacCod = F0.fclFacCod

	LEFT JOIN FACE AS F1
	ON  F1._LINEA=1
	AND F0.fclFacCod	=F1.fclFacCod
	AND F0.fclFacPerCod	=F1.fclFacPerCod
	AND F0.fclFacCtrCod	=F1.fclFacCtrCod
	AND F0.fclFacVersion = F1.fclFacVersion

	LEFT JOIN ESTADO_SERES AS E
	ON  F.facCod	= E.facCod
	AND F.facPerCod = E.facPerCod
	AND F.facCtrCod = E.facCtrCod
	AND F.facVersion= E.facVersion 
	AND E.RN=1
	WHERE F.facEnvSeres = 'E'							--Enviado
	AND (C.cobrado IS NULL OR C.cobrado < F0._TOTAL)	--Pendiente de cobro 
	/*
	AND ( --Con discrepancias en los importes
	   F1.[TOTAL_BASEIMPO.]		<>F0.[_TOTAL_BASEIMPO.]
	OR F1.[TOTAL_IMP.REP]		<>F0.[_TOTAL_IMP.REP]
	OR F1.[TOTAL_FACTURA]		<>F0.[_TOTAL_FACTURA] 
	OR F1.[TOTAL_IMP.REP]		<>F0.[_TOTAL_IMP.REP]
	OR F0.[_TOTAL_FACTURA]		<>F0.[_TOTAL]
	)*/
	;


	--****************************
	--FACTURAS PENDIENTES
	--****************************
	SELECT  
	  [Periodo]		= fclFacPerCod
	, [Contrato]	= fclFacCtrCod
	, [Fac.Codigo]	= fclFacCod
	, [Fac.Version]	= fclFacVersion
	, [Fac.Fecha]	= facFecha
	--, F.facFechaRectif
	--****************************
	, [Total Base Impo.]		= [_TOTAL_BASEIMPO.]
	, [facE: Total Base Impo.]	= [TOTAL_BASEIMPO.]
	
	, [Total Imp. Rep.]			= [_TOTAL_IMP.REP]
	, [facE: Total Imp. Rep.]	= [TOTAL_IMP.REP]
	
	, [Total a Pagar]			= [_TOTAL_FACTURA] 
	, [facE: Total a Pagar]		= [TOTAL_FACTURA] 
	
	, [Total facturado]			= [_TOTAL]
	
	, [Total cobrado]			= Cobrado
	, [Envio facE]				= facEnvSeres
	, [Envio facE: Fecha]		= facFecEmisionSERES
	, [Estado facE]				= facEDescEstado
	, [Detalle: facE]			= facEDescRazon

	, [Error]

	FROM #RESULT
	ORDER BY fclFacPerCod, fclFacCtrCod;
	
	--****************************
	--LINEAS FACTURAS PENDIENTES
	--****************************
	SELECT [Periodo]				= S.fclFacPerCod
		 , [Contrato]				= S.fclFacCtrCod
		 , [Fac. Codigo]			= S.fclFacCod
		 , [Fac. Version]			= S.fclFacVersion
		 , [Fac. Linea]				= S.fclNumLinea
		 , [Fac. Bloque]			= S.ESCALA
		 , [FacE Linea]				= LINEA_SERES
		 , [CANTIDAD]				= S.UDS
		 , [PRECIO]					= S.PRECIO
		 , [%IMP.]					= S.IVA
		 , [TOTAL]					= S.TOTAL
		 , [IMPUESTOS: B.Imponible] = S.[IVA_B.IMPONIBLE]
	FROM #SERES_LIN AS S
	INNER JOIN #RESULT AS R
	ON  S.fclFacCod		=R.fclFacCod
	AND S.fclFacPerCod	=R.fclFacPerCod
	AND S.fclFacCtrCod	=R.fclFacCtrCod
	AND S.fclFacVersion =R.fclFacVersion
	ORDER BY S.fclFacPerCod,  S.fclFacCtrCod, S.LINEA_SERES;

END TRY
	
BEGIN CATCH
	SELECT  @p_errId_out = ERROR_NUMBER()
		 ,  @p_errMsg_out= ERROR_MESSAGE();
END CATCH
	
IF OBJECT_ID('tempdb..#FACS') IS NOT NULL DROP TABLE #FACS;
IF OBJECT_ID('tempdb..#COBS') IS NOT NULL DROP TABLE #COBS;  
IF OBJECT_ID('tempdb..#FCL') IS NOT NULL DROP TABLE #FCL;
IF OBJECT_ID('tempdb..#SERES_LIN') IS NOT NULL DROP TABLE #SERES_LIN;  
IF OBJECT_ID('tempdb..#RESULT') IS NOT NULL DROP TABLE #RESULT;  
GO
