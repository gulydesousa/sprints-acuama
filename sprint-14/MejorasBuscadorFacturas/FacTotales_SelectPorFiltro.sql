CREATE PROCEDURE dbo.FacTotales_SelectPorFiltro
@facturas tFacturasPK READONLY
AS 
	SET NOCOUNT ON;
	BEGIN TRY

	DECLARE @cobPpag AS INT;
	DECLARE @cobMpc AS INT;
	SELECT  @cobPpag = P.pgsvalor FROM dbo.parametros AS P WHERE pgsclave = 'PUNTO_PAGO_ENTREGAS_A_CTA';
	SELECT  @cobMpc = P.pgsvalor FROM dbo.parametros AS P WHERE pgsclave = 'MEDIO_PAGO_ENTREGAS_A_CTA';
	
	--[10]#FACS: Totales una linea por tipo impositivo
	SELECT F.facCod
	, F.facCtrCod
	, F.facPerCod
	, F.facVersion
	, fclImpuesto	  = ISNULL(FL.fclImpuesto, 0)
	, F.facFechaRectif
	, fctActiva		  = IIF(F.facFechaRectif IS NULL, 1, 0)
	, fclBase		  = SUM(ISNULL(FL.fclBase, 0))
	, fclImpImpuesto  = SUM(ISNULL(FL.fclImpImpuesto, 0))
	, fclTotal		  = SUM(ISNULL(FL.fclTotal, 0))
	, fctTipoImp	  = CAST(NULL AS INT)
	, Facturado		  = CAST(NULL AS MONEY)
	
	INTO #FACS
	FROM dbo.facturas AS F
	INNER JOIN @facturas AS FF 
	ON  FF.facCod = F.facCod
	AND FF.facCtrCod = F.facCtrCod
	AND FF.facPerCod = F.facPerCod
	LEFT JOIN dbo.faclin AS FL
	ON FL.fclFacPerCod = F.facPerCod
	AND FL.fclFacVersion = F.facVersion
	AND FL.fclFacCod = F.facCod
	AND FL.fclFacCtrCod = F.facCtrCod
	AND FL.fclFecLiq IS NULL
	GROUP BY F.facCod
		   , F.facCtrCod
		   , F.facPerCod
		   , F.facVersion
		   , FL.fclImpuesto
		   , F.facFechaRectif;
	   
	--[11]#FACS.fctTipoImp: Asignamos orden por tipo impositivo y totalizamos las facturas activas
	WITH TI AS (
	SELECT facCod
	, facCtrCod
	, facPerCod
	, facVersion
	, fclImpuesto
	, fctTipoImp = ROW_NUMBER() OVER (PARTITION BY  facCod, facCtrCod, facPerCod, facVersion ORDER BY IIF(fclImpuesto IS NULL OR fclImpuesto=0, 1, 0) ASC, fclImpuesto ASC)
	, Facturado  = SUM(fclTotal*fctActiva) OVER (PARTITION BY facCod, facCtrCod, facPerCod)
	FROM #FACS)
	
	UPDATE F 
	SET F.fctTipoImp = TI.fctTipoImp
	  , F.Facturado	 = TI.Facturado
	FROM #FACS AS F 
	INNER JOIN TI
	ON   F.facCod	  = TI.facCod
	AND  F.facCtrCod  = TI.facCtrCod
	AND  F.facPerCod  = TI.facPerCod
	AND	 F.facVersion = TI.facVersion
	AND	 F.fclImpuesto= TI.fclImpuesto;

	--[20]#COBS: Totales cobros por periodo
	WITH FACS AS(
	SELECT DISTINCT facCod, facCtrCod, facPerCod
	FROM #FACS AS F)
	
	 SELECT C.cobCtr
		 , CL.cblPer
		 , CL.cblFacCod
		 , Cobrado = SUM(CL.cblImporte)
		 , EntregasCta = SUM(IIF(C.cobPpag=@cobPpag AND C.cobMpc=@cobMpc, CL.cblImporte, 0))
	INTO #COBS
	FROM dbo.cobros AS C
	INNER JOIN dbo.coblin AS CL
	ON  CL.cblScd = C.cobScd
	AND CL.cblPpag = C.cobPpag
	AND CL.cblNum = C.cobNum
	INNER JOIN FACS AS F
	ON  C.cobCtr  = F.facCtrcod
	AND CL.cblPer = F.facPerCod
	AND CL.cblFacCod = F.facCod
	GROUP BY C.cobCtr, CL.cblPer, CL.cblFacCod;

	--******************************************************
	--******************************************************
	--[99]RESULTADO: Totales por Factura y por tipo impositivo
	SELECT facCod
		 , facCtrCod
		 , facPerCod
		 , facVersion
		 , fctActiva		= MAX(fctActiva)
		 , ftcBase			= ISNULL(SUM(fclBase), 0)
		 , fctImpuestos		= ISNULL(SUM(fclImpImpuesto), 0)
		 , fctTotal			= ISNULL(SUM(fclTotal), 0)

		 , Facturado		= ROUND(ISNULL(MAX(Facturado), 0), 2)
		 , Cobrado			= ROUND(ISNULL(MAX(C.Cobrado), 0) , 2)
		 , EntregasCta		= ROUND(ISNULL(MAX(C.EntregasCta), 0) , 2)
	
		, fctTipoImp1		= MAX(IIF(fctTipoImp = 1, fclImpuesto, 0))
		, fctBaseTipoImp1	= SUM(IIF(fctTipoImp = 1, fclBase, 0))

		, fctTipoImp2		= MAX(IIF(fctTipoImp = 2, fclImpuesto, 0))
		, fctBaseTipoImp2	= SUM(IIF(fctTipoImp = 2, fclBase, 0))

		, fctTipoImp3		= MAX(IIF(fctTipoImp = 3, fclImpuesto, 0))
		, fctBaseTipoImp3	= SUM(IIF(fctTipoImp = 3, fclBase, 0))

		, fctTipoImp4		= MAX(IIF(fctTipoImp = 4, fclImpuesto, 0))
		, fctBaseTipoImp4	= SUM(IIF(fctTipoImp = 4, fclBase, 0))

		, fctTipoImp5		= MAX(IIF(fctTipoImp = 5, fclImpuesto, 0))
		, fctBaseTipoImp5	= SUM(IIF(fctTipoImp = 5, fclBase, 0))

		, fctTipoImp6		= MAX(IIF(fctTipoImp = 6, fclImpuesto, 0))
		, fctBaseTipoImp6	= SUM(IIF(fctTipoImp = 6, fclBase, 0))

	FROM #FACS AS F
	LEFT JOIN #COBS AS C
	ON  C.cobCtr		= F.facCtrCod
	AND C.cblPer		= F.facPerCod
	AND C.cblFacCod		= F.facCod
	GROUP BY facCod, facCtrCod, facPerCod, facVersion;
	
	END TRY

	BEGIN CATCH
	
	END CATCH


	IF OBJECT_ID('tempdb.dbo.#FACS', 'U') IS NOT NULL 
	DROP TABLE #FACS;

	IF OBJECT_ID('tempdb.dbo.#COBS', 'U') IS NOT NULL 
	DROP TABLE #COBS;
GO