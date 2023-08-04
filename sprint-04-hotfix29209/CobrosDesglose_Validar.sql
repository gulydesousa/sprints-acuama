/*
****** CONFIGURACION ******
--DELETE FROM ExcelPerfil WHERE ExPCod= '000/820'
--DELETE FROM ExcelConsultas WHERE ExcCod='000/820'
--DROP PROCEDURE [InformesExcel].[CobrosxDesglose]

DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI><FecDesde>20201201</FecDesde><FecHasta>20210809</FecHasta></LI></NodoXML>'

EXEC [InformesExcel].[CobrosDesglose_Validar] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;

*/


CREATE PROCEDURE [InformesExcel].[CobrosDesglose_Validar]
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
	--Cobros x rango de fechas
	SELECT  FL.fclFacPerCod
	, FL.fclFacCtrCod
	, FL.fclFacCod
	, FL.fclFacVersion
	, FL.fclNumLinea
	, FL.fclTotal
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
	, [Total Cobrado] = CAST(NULL AS MONEY)
	INTO #COBS
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
	INNER JOIN faclin AS FL 
	ON FL.fclfacCod = cblFacCod
	AND FL.fclfacCtrCod = cobCtr
	AND FL.fclfacPerCod = cblPer
	AND FL.fclFacVersion = cblFacVersion
	AND FL.fclNumLinea= cldFacLin
	INNER JOIN @params AS P 
	ON  (P.FecDesde IS NULL OR cobFec >= P.FecDesde) 
	AND (P.FecHasta IS NULL OR cobFec <= P.FecHasta);



	WITH FCL AS(
	SELECT DISTINCT fclFacPerCod, fclFacCtrCod, fclFacCod, fclFacVersion, fclNumLinea, fclTotal
	FROM #COBS)



	SELECT 
	  FL.fclFacPerCod
	, FL.fclFacCtrCod
	, FL.fclFacCod
	, FL.fclFacVersion
	, FL.fclNumLinea
	, FL.fclTotal
	, C.cobScd
	, C.cobPpag
	, C.cobNum
	, CL.cblLin
	, CL.cblImporte
	, CLD.cldImporte
	--Calculamos el total globalmente cobrado
	, CobTotal = SUM(CLD.cldImporte) OVER(PARTITION BY FL.fclFacPerCod, FL.fclFacCtrCod, FL.fclFacCod, FL.fclFacVersion, FL.fclNumLinea)
	, RN = ROW_NUMBER() OVER(PARTITION BY FL.fclFacPerCod, FL.fclFacCtrCod, FL.fclFacCod, FL.fclFacVersion, FL.fclNumLinea ORDER BY cobFec, cobNum)
	INTO #COBL
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
	INNER JOIN FCL AS FL 
	ON FL.fclfacCod = cblFacCod
	AND FL.fclfacCtrCod = cobCtr
	AND FL.fclfacPerCod = cblPer
	AND FL.fclFacVersion = cblFacVersion
	AND FL.fclNumLinea= cldFacLin;

	SELECT [Periodo] = fclFacPerCod
	, [Contrato] = fclFacCtrCod
	, [Fac.Código] = fclFacCod
	, [Fac.Versión] = fclFacVersion
	, [Fac.Línea] = fclNumLinea
	, [Fac.Línea Importe] = fclTotal
	
	, [Cob.Sociedad] = cobScd
	, [Cob.Punto Pago] = cobPpag
	, [Cob.Número] = cobNum
	, [Cob.Línea] = cblLin
	, cblImporte
	, cldImporte
	, [Total_Cobrado] = CobTotal
	FROM #COBL
 	WHERE cobTotal <> 0 
	  AND SIGN(fclTotal-cobTotal) <> 0
	  AND SIGN(fclTotal-cobTotal) <> SIGN(fclTotal)
	ORDER BY fclFacPerCod, fclFacCtrCod, fclFacCod, fclFacVersion, fclNumLinea;


	END TRY

	BEGIN CATCH
		SELECT  @p_errId_out = ERROR_NUMBER()
			 ,  @p_errMsg_out= ERROR_MESSAGE();
	END CATCH

	IF OBJECT_ID('tempdb..#COBS', 'U') IS NOT NULL
	DROP TABLE dbo.#COBS;
	
	IF OBJECT_ID('tempdb..#COBL', 'U') IS NOT NULL
	DROP TABLE dbo.#COBL;

GO


