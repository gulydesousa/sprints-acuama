/*
****** CONFIGURACION ******
--DELETE FROM ExcelPerfil WHERE ExPCod= '000/810'
--DELETE FROM ExcelConsultas WHERE ExcCod='000/810'
--DROP PROCEDURE [InformesExcel].[CobrosxFacLiquidacion]


DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI><FecDesde>20201201</FecDesde><FecHasta>20210809</FecHasta></LI></NodoXML>'
EXEC [InformesExcel].[CobrosLiquidadas_Validar] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;

*/


CREATE PROCEDURE [InformesExcel].[CobrosLiquidadas_Validar]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS
	--**********
	--PARAMETROS: 
	--[1]FecDesde: fecha dede
	--[2]FecHasta: fecha hasta
	--**********

	SET NOCOUNT ON;   
	BEGIN TRY
	
	--********************
	--INICIO: 2 DataTables
	-- 1: Parametros del encabezado (FecDesde, FecHasta)
	-- 2: Datos
	--********************

	--DataTable[1]:  Parametros
	DECLARE @xml AS XML = @p_params;
	DECLARE @params TABLE (FecDesde DATE NULL, fInforme DATETIME, FecHasta DATE NULL);

	INSERT INTO @params
	SELECT  FecDesde = CASE WHEN M.Item.value('FecDesde[1]', 'DATE') = '19000101' THEN NULL 
						   ELSE M.Item.value('FecDesde[1]', 'DATE') END
		  , fInforme     = GETDATE()
		  , FecHasta = CASE WHEN M.Item.value('FecHasta[1]', 'DATE') = '19000101' THEN NULL 
						   ELSE M.Item.value('FecHasta[1]', 'DATE') END
	FROM @xml.nodes('NodoXML/LI')AS M(Item);
	
	UPDATE @params SET FecHasta = DATEADD(DAY, 1, FecHasta);
	
	
	
	--********************
	--DataTable[3]:  Datos Importes desglose de cobros por lineas
	--Lineas liquidadas
	SELECT FL.fclFacPerCod
	, FL.fclFacCtrCod
	, FL.fclFacCod
	, FL.fclFacVersion
	, FL.fclNumLinea
	, FL.fclTotal
	, FL.fclFecLiq
	, FL.fclTrfSvCod 
	INTO #FCLIQ
	FROM faclin AS FL 
	INNER JOIN @params AS P 
	ON  (P.FecDesde IS NULL OR FL.fclFecLiq >= P.FecDesde) 
	AND (P.FecHasta IS NULL OR FL.fclFecLiq <= P.FecHasta);

	--Cobros asociados a lineas liquidadas
	SELECT FL.fclFacPerCod
	, FL.fclFacCtrCod
	, FL.fclFacCod
	, FL.fclFacVersion
	, FL.fclNumLinea
	, FL.fclTrfSvCod
	, FL.fclFecLiq
	, C.cobScd
	, C.cobPpag
	, C.cobNum
	, C.cobConcepto
	, C.cobOrigen
	, C.cobfecreg
	, C.cobfec
	, CL.cblLin
	, CLD.cldImporte
	, [RN] = ROW_NUMBER()  OVER (PARTITION BY FL.fclFacCod, FL.fclFacPerCod, FL.fclFacCtrCod, FL.fclFacVersion, FL.fclNumLinea ORDER BY C.cobfecreg ASC)
	, [TotalCobradoxLinea]  = SUM(CLD.cldImporte) OVER (PARTITION BY FL.fclFacCod, FL.fclFacPerCod, FL.fclFacCtrCod, FL.fclFacVersion, FL.fclNumLinea)
	INTO #COBLIQ
	FROM dbo.cobros AS C
	LEFT JOIN dbo.coblin AS CL
	ON CL.cblScd = C.cobScd
	AND CL.cblPpag = C.cobPpag
	AND CL.cblNum = C.cobNum
	LEFT JOIN dbo.cobLinDes AS CLD
	ON CLD.cldCblScd = CL.cblScd
	AND CLD.cldCblPpag = CL.cblPpag
	AND CLD.cldCblNum = CL.cblNum
	AND CLD.cldCblLin = CL.cblLin
	INNER JOIN #FCLIQ AS FL 
	ON FL.fclfacCod = cblFacCod
	AND FL.fclfacCtrCod = cobCtr
	AND FL.fclfacPerCod = cblPer
	AND FL.fclFacVersion = cblFacVersion
	AND FL.fclNumLinea= cldFacLin;

	SELECT [Contrato] = fclFacCtrCod	
	, [Periodo] = fclFacPerCod
	, [Fac.Codigo] = fclFacCod
	, [Fac.Version] = fclFacVersion
	, [Fac.Línea] = fclNumLinea	
	, [Cod.Servicio] = fclTrfSvCod
	, [Cob.Sociedad] = cobScd
	, [Cob.Punto Pago] = cobPpag
	, [Cob.Número] = cobNum
	, [Cob.Concepto] = cobConcepto	
	, [Cob.Origen] = cobOrigen
	, [Cob.Línea] = cblLin
	, [Cob.Fecha] = cobfec
	, [Fac.Fecha Liquidacion] = fclFecLiq
	, [Cob.ImportexLínea] = cldImporte
	, [Total CobradoxLínea] = TotalCobradoxLinea

	, [Estado] = IIF(cobfec >fclFecLiq, 'Error: Cobro posterior a la liquidación', 'Pendiente') 

	FROM #COBLIQ
	WHERE [TotalCobradoxLinea] <> 0
	ORDER BY fclFacCtrCod, fclFacPerCod	, cobNum;

	

	END TRY

	BEGIN CATCH
		SELECT  @p_errId_out = ERROR_NUMBER()
			 ,  @p_errMsg_out= ERROR_MESSAGE();
	END CATCH

	IF OBJECT_ID('tempdb..#FCLIQ', 'U') IS NOT NULL
	DROP TABLE dbo.#FCLIQ;

	IF OBJECT_ID('tempdb..#COBLIQ', 'U') IS NOT NULL
	DROP TABLE dbo.#COBLIQ;



GO


