/*
--Validar antes de marcar como pendiente de envio a seres
DECLARE @facturas AS dbo.tFacturasPK;
DECLARE @usrCod AS VARCHAR(10) = ''
INSERT INTO  @facturas(facCod, facPerCod, facCtrCod, facVersion)
SELECT F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion
	FROM dbo.facturas AS F
	INNER JOIN dbo.contratos AS C
	ON  C.ctrcod = F.facCtrCod
	AND C.ctrversion = F.facCtrVersion
	AND C.ctrFace=1
	AND F.facFechaRectif IS NULL;

EXEC dbo.Facturas_RevisionImportesFacE  @facturas, NULL;
*/

CREATE PROCEDURE dbo.Facturas_RevisionImportesFacE  
  @facturas AS dbo.tFacturasPK READONLY
, @usrCod AS VARCHAR(10) = ''
AS


BEGIN TRY
	
	--****************************
	--[01]#COBS: Cobros por factura
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
	INNER JOIN @facturas AS F
	ON  C.cobCtr  = F.facCtrcod
	AND CL.cblPer = F.facPerCod
	AND CL.cblFacCod = F.facCod
	GROUP BY C.cobCtr, CL.cblPer, CL.cblFacCod;

	
	--****************************
	--[02]#FCL: Líneas de factura
	SELECT *
	, _LINEA	 = ROW_NUMBER()			OVER (PARTITION BY FL.fclFacCod, FL.fclFacPerCod, FL.fclFacCtrCod, FL.fclFacVersion ORDER BY fclNumLinea)
	, _IMPUESTOS = SUM(fclImpImpuesto)	OVER (PARTITION BY FL.fclFacCod, FL.fclFacPerCod, FL.fclFacCtrCod, FL.fclFacVersion )
	, _BASE		 = SUM(fclBase)			OVER (PARTITION BY FL.fclFacCod, FL.fclFacPerCod, FL.fclFacCtrCod, FL.fclFacVersion ) 
	, _TOTAL	 = SUM(fclTotal)		OVER (PARTITION BY FL.fclFacCod, FL.fclFacPerCod, FL.fclFacCtrCod, FL.fclFacVersion ) 

	INTO #FCL
	FROM dbo.vFacturas_LineasAcuama AS FL
	INNER JOIN @facturas AS F
	ON  F.facCod = FL.fclFacCod
	AND F.facPerCod = FL.fclFacPerCod
	AND F.facCtrCod = FL.fclFacCtrCod
	AND F.facVersion = FL.fclFacVersion;
	
	--[04]#SERES_LIN: Lineas de la factura en SERES
	--Una linea por escala
	SELECT * 
	INTO #SERES_LIN
	FROM dbo.fLineasFacE(@facturas);
	

	--*****************
	--RESULTADO:
	--Se comparan los totales de SERES con los de Acuama
	--Se sacan las facturas con discrepancias
	--*****************
	BEGIN TRAN;

	WITH FACE AS(
	--FACE: TOTALES AGRUPADOS POR TIPO IMPOSITIVO
	SELECT F.fclFacCod
	, F.fclFacPerCod
	, F.fclFacCtrCod
	, F.fclFacVersion
	, F.[IVA]
	, F.[_LINEA]
	
	, F.[IVA_B.IMPONIBLE]
	, [TOTAL_BASEIMPO.] = SUM(F.[IVA_B.IMPONIBLE]) 
						  OVER (PARTITION BY F.fclFacCod, F.fclFacPerCod, F.fclFacCtrCod, F.fclFacVersion)
	
	, [IVA_IMPUESTOS]	= CAST(ROUND(F.[IVA_B.IMPONIBLE]*F.[IVA]*0.01, 2) AS MONEY) 	
	, [TOTAL_IMP.REP]	= SUM(CAST(ROUND(F.[IVA_B.IMPONIBLE]*F.[IVA]*0.01, 2) AS MONEY)) 
						  OVER (PARTITION BY F.fclFacCod, F.fclFacPerCod, F.fclFacCtrCod, F.fclFacVersion)
	
	FROM #SERES_LIN AS F
	WHERE IVA_LINEA = 1

	), FACT AS(
	--TOTALES FACTURA
	SELECT FL.fclFacCod
	, FL.fclFacPerCod
	, FL.fclFacCtrCod
	, FL.fclFacVersion
	, [_TOTAL_BASEIMPO.] = ROUND(_BASE, 2)
	, [_TOTAL_IMP.REP]	 = ROUND(_IMPUESTOS, 2)
	, [_TOTAL]			 = ROUND([_TOTAL], 2)
	FROM #FCL AS FL
	WHERE _LINEA = 1

	), ESTADO_SERES AS(
	SELECT  
	  F.facCod 
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion
	, S.facECodEstado
	, S.facEDescEstado
	, S.facEDescRazon
	, S.facEStatusDate
	, S.facElink
	, RN = ROW_NUMBER() OVER(PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion ORDER BY S.facEStatusDate DESC)
	FROM @facturas AS F
	INNER JOIN dbo.facturas AS FF WITH(INDEX(PK_facturas))
	ON F.facCod = FF.facCod
	AND F.facPerCod = FF.facPerCod
	AND F.facCtrCod = FF.facCtrCod
	AND F.facVersion = FF.facVersion
	INNER JOIN dbo.facEstadoSeres AS S
	ON  FF.facNumero = S.facEfacNum
	AND FF.facFecha = S.FacEfacFecha)

	--*****************
	--COMPARAMOS LOS TOTALES DE FACE CON LOS DE ACUAMA
	--*****************
	INSERT INTO Trabajo.RevisionImportesFacE
	OUTPUT INSERTED.facCod, INSERTED.facPerCod, INSERTED.facCtrCod, INSERTED.facVersion
		 , INSERTED.facEnvSERES, INSERTED.facFecEmisionSERES
		 , INSERTED.[Acuama_TOTAL_BASEIMPO] , INSERTED.[FacE_TOTAL_BASEIMPO]
		 , INSERTED.[Acuama_TOTAL_IMP_REP], INSERTED.[FacE_TOTAL_IMP_REP]
		 , INSERTED.[Acuama_TOTAL_FACTURA], INSERTED.[FacE_TOTAL_FACTURA]
		 , INSERTED.[Acuama_TOTAL], INSERTED.[TOTAL_COBRADO]
		 , INSERTED.facEDescEstado, INSERTED.facECodEstado
		 , INSERTED.[ERROR_MSG]
	SELECT fecha= GETDATE()
	, usuario	= @usrCod
	, F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion
	, FF.facEnvSERES
	, FF.facFecEmisionSERES
	--Totales de acuama empiezan con "Guión Bajo"
	, [Acuama_TOTAL_BASEIMPO]= ISNULL(FT.[_TOTAL_BASEIMPO.], 0)
	, [FacE_TOTAL_BASEIMPO]	= ISNULL(FS.[TOTAL_BASEIMPO.], 0)

	, [Acuama_TOTAL_IMP_REP]	= ISNULL(FT.[_TOTAL_IMP.REP], 0)
	, [FacE_TOTAL_IMP_REP]	= ISNULL(FS.[TOTAL_IMP.REP], 0)

	, [Acuama_TOTAL_FACTURA]	= ISNULL(FT.[_TOTAL_BASEIMPO.], 0) + ISNULL(FT.[_TOTAL_IMP.REP], 0)
	, [FacE_TOTAL_FACTURA]	= ISNULL(FS.[TOTAL_BASEIMPO.], 0)  + ISNULL(FS.[TOTAL_IMP.REP], 0)
	
	, [Acuama_TOTAL]			= ISNULL(FT._TOTAL, 0)
	, [TOTAL_COBRADO]	= ISNULL(C.Cobrado, 0)
	, E.facEDescEstado
	, E.facECodEstado
	, [ERROR_MSG] = CONCAT(
					IIF (ISNULL(FS.[TOTAL_BASEIMPO.], 0) <> 
						ISNULL(FT.[_TOTAL_BASEIMPO.], 0), 'FacE: TOTAL_BASEIMPO. ' + CHAR(10), ''),
	   
					IIF (ISNULL(FS.[TOTAL_IMP.REP], 0) <> 
							ISNULL(FT.[_TOTAL_IMP.REP], 0), 'FacE: TOTAL_IMP.REP ' + CHAR(10), ''),
	
					IIF(ISNULL(FT.[_TOTAL_BASEIMPO.], 0) + ISNULL(FT.[_TOTAL_IMP.REP], 0) <> 
						ISNULL(FT.[_TOTAL], 0), 'Acuama: Compruebe que los totales de la factura impresa coincide con el facturado.', ''))

	FROM @facturas AS F
	INNER JOIN dbo.facturas AS FF WITH(INDEX(PK_facturas))
	ON F.facCod = FF.facCod
	AND F.facPerCod = FF.facPerCod
	AND F.facCtrCod = FF.facCtrCod
	AND F.facVersion = FF.facVersion
	LEFT JOIN FACT AS FT
	ON F.facCod = FT.fclFacCod
	AND F.facPerCod = FT.fclFacPerCod
	AND F.facCtrCod = FT.fclFacCtrCod
	AND F.facVersion = FT.fclFacVersion

	LEFT JOIN #COBS AS C
	ON  C.cobCtr	= F.facCtrCod
	AND C.cblPer	= F.facPerCod
	AND C.cblFacCod = F.facCod

	LEFT JOIN FACE AS FS
	ON  FS._LINEA=1
	AND FS.fclFacCod	 = F.facCod
	AND FS.fclFacPerCod	 = F.facPerCod
	AND FS.fclFacCtrCod	 = F.facCtrCod
	AND FS.fclFacVersion = F.facVersion

	LEFT JOIN ESTADO_SERES AS E
	ON  E.facCod	 = F.facCod
	AND E.facCtrCod  = F.facCtrCod
	AND E.facPerCod  = F.facPerCod
	AND E.facVersion = F.facVersion
	AND E.RN=1
 
	WHERE (C.cobrado IS NULL OR C.cobrado < FT._TOTAL)	--*** PENDIENTE DE COBRO 
	   AND(ISNULL(FS.[TOTAL_BASEIMPO.], 0) <> 
		   ISNULL(FT.[_TOTAL_BASEIMPO.], 0)

	    OR ISNULL(FS.[TOTAL_IMP.REP], 0) <> 
	 	   ISNULL(FT.[_TOTAL_IMP.REP], 0)

		OR (ISNULL(FS.[TOTAL_BASEIMPO.], 0) + ISNULL(FS.[TOTAL_IMP.REP], 0)) <> 
		   (ISNULL(FT.[_TOTAL_BASEIMPO.], 0) + ISNULL(FT.[_TOTAL_IMP.REP], 0))

	    OR (ISNULL(FT.[_TOTAL_BASEIMPO.], 0) + ISNULL(FT.[_TOTAL_IMP.REP], 0)) <> 
		   (ISNULL(FT.[_TOTAL], 0))
		) 
	--ORDER BY F.facPerCod, F.facCtrCod, F.facCod, F.facVersion;
	
	--******************************************************
	--Dejamos los resultados en Trabajo.RevisionImportesFacE
	--Solo si se envía codigo de usuario.
	--Para hacer pruebas mejor no enviar el @usrCod
	IF (@usrcod= '')
		ROLLBACK TRAN;
	ELSE
		COMMIT TRAN;

END TRY

BEGIN CATCH
END CATCH

IF OBJECT_ID('tempdb..#COBS') IS NOT NULL DROP TABLE #COBS
IF OBJECT_ID('tempdb..#FCL') IS NOT NULL DROP TABLE #FCL;
IF OBJECT_ID('tempdb..#SERES_LIN') IS NOT NULL DROP TABLE #SERES_LIN;

GO