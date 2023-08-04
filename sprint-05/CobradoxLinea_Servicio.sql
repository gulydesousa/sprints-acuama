
/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI><FecDesde>20210427</FecDesde><FecHasta>20210727</FecHasta><svcCod>2</svcCod></LI></NodoXML>'

EXEC [InformesExcel].[CobradoxLinea_Servicio] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/
ALTER PROCEDURE [InformesExcel].[CobradoxLinea_Servicio]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS


	--**********
	--PARAMETROS: 
	--[1]FecDesde: fecha desde
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
	DECLARE @params TABLE (FecDesde DATE NULL, Servicio VARCHAR(150), fInforme DATETIME, FecHasta DATE NULL);

	INSERT INTO @params
	SELECT  FecDesde = CASE WHEN M.Item.value('FecDesde[1]', 'DATE') = '19000101' THEN NULL 
						   ELSE M.Item.value('FecDesde[1]', 'DATE') END
		  , Servicio =  M.Item.value('svcCod[1]', 'INT')	
		  , fInforme     = GETDATE()
		  , FecHasta = CASE WHEN M.Item.value('FecHasta[1]', 'DATE') = '19000101' THEN NULL 
						   ELSE M.Item.value('FecHasta[1]', 'DATE') END
		
	FROM @xml.nodes('NodoXML/LI')AS M(Item);
	
	UPDATE @params SET FecHasta = DATEADD(DAY, 1, FecHasta)
	OUTPUT DELETED.*;
	

	DECLARE @svc INT;
	DECLARE @fDesde DATE;
	DECLARE @fHasta DATE;

	SELECT @svc = Servicio, @fDesde=FecDesde, @fHasta= FecHasta FROM @params;

	SELECT  FL.fclFacPerCod
	, FL.fclFacCtrCod
	, FL.fclFacCod
	, FL.fclFacVersion
	, FL.fclNumLinea
	, FL.fclTotal
	, FL.fclFecLiq
	, FL.fclTrfSvCod
	, C.cobScd
	, C.cobPpag
	, C.cobNum
	, C.cobConcepto
	, C.cobOrigen
	, C.cobfecreg
	, C.cobfec
	, CL.cblLin
	, CLD.cldImporte
	--Importe cobrado entre las fechas en consulta
	, [Total CobradoxFechas]  = SUM(IIF(C.cobfec >=@fDesde AND C.cobfec < @fHasta, CLD.cldImporte, 0)) OVER (PARTITION BY FL.fclFacCod, FL.fclFacPerCod, FL.fclFacCtrCod, FL.fclFacVersion, FL.fclNumLinea) 
	, [Total Cobrado] = CAST(NULL AS MONEY)
	INTO #RESULT
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
	WHERE  cldImporte<>0
	AND C.cobfec >=@fDesde AND C.cobfec < @fHasta
	AND FL.fclTrfSvCod=@svc;

	WITH FCL AS(
	SELECT DISTINCT fclFacPerCod, fclFacCtrCod, fclFacCod, fclFacVersion, fclNumLinea
	FROM #RESULT
	
	), COBT AS(
	SELECT 
	  FL.fclFacPerCod
	, FL.fclFacCtrCod
	, FL.fclFacCod
	, FL.fclFacVersion
	, FL.fclNumLinea
	, [Total Cobrado] = SUM(CLD.cldImporte) 
	--Calculamos el total globalmente cobrado
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
	AND FL.fclNumLinea= cldFacLin
	GROUP BY FL.fclFacPerCod, FL.fclFacCtrCod, FL.fclFacCod, FL.fclFacVersion, FL.fclNumLinea)

	UPDATE R SET R.[Total Cobrado]  = T.[Total Cobrado] 
	FROM #RESULT AS R
	LEFT JOIN COBT AS T
	ON  R.fclFacPerCod	= T.fclFacPerCod
	AND R.fclFacCtrCod	= T.fclFacCtrCod
	AND R.fclFacCod		= T.fclFacCod
	AND R.fclFacVersion = T.fclFacVersion
	AND R.fclNumLinea	= T.fclNumLinea;

	WITH CTRS AS(
	SELECT ctrCod
	, ctrVersion
	, ctrInmCod
	, ctrTitDocIden
	, ROW_NUMBER() OVER(PARTITION BY ctrCod ORDER BY ctrVersion DESC) AS RN
	FROM dbo.contratos AS C)

	SELECT C.ctrCod, C.ctrVersion, C.ctrTitDocIden, C.ctrInmCod, I.inmDireccion 
	INTO #CTRS
	FROM CTRS AS C
	LEFT JOIN dbo.Inmuebles AS I
	ON I.inmCod = C.ctrInmCod
	WHERE RN=1


	SELECT 
	  [Periodo]				= R.fclFacPerCod
	, [Contrato]			= R.fclFacCtrCod
	, [Titular]				= C.ctrTitDocIden
	, [Dir.Suministro]		= C.inmDireccion 
	, [Fac.Cod]				= R.fclFacCod
	, [Fac.Versión]			= R.fclFacVersion
	, [Fac.Línea]			= R.fclNumLinea
	, [Fac.Línea Importe]	= R.fclTotal
	, [Fecha LIQ.]			= R.fclFecLiq
	
	, [Svc.Cod]			 = R.fclTrfSvCod
	, [Servicio]		 = S.svcDes
	, [Cobro Scd]		 = R.cobScd
	, [Cobro Pto.Pag]	 = R.cobPpag
	, [Cobro Número]	 = R.cobNum
	, [Cobro Concepto]	 = R.cobConcepto
	, [Cobro Origen]	 = R.cobOrigen
	, [Cobro F.Registro] = R.cobfecreg
	, [Cobro Fecha]		 = R.cobfec
	, [Cobro Línea]		 = R.cblLin
	, [Cobro Importe]	 = R.cldImporte
	
	, R.[Total Cobrado] 
	--Importe cobrado entre las fechas en consulta
	, R.[Total CobradoxFechas] 
	, DEUDA  = R.fclTotal-R.[Total Cobrado] 
	FROM #RESULT AS R
	LEFT JOIN dbo.Servicios AS S
	ON S.svcCod= R.fclTrfSvCod
	LEFT JOIN #CTRS AS C
	ON C.ctrCod = R.fclFacCtrCod
	ORDER BY R.fclFacPerCod,  R.fclFacCtrCod,  R.fclFacCod, R.fclFacVersion, R.fclNumLinea, R.cobfec;




	END TRY

	BEGIN CATCH
		SELECT  @p_errId_out = ERROR_NUMBER()
			 ,  @p_errMsg_out= ERROR_MESSAGE();
	END CATCH

	IF OBJECT_ID('dbo.#RESULT', 'U') IS NOT NULL
	DROP TABLE dbo.#RESULT;


	IF OBJECT_ID('dbo.#CTRS', 'U') IS NOT NULL
	DROP TABLE dbo.#CTRS;

GO