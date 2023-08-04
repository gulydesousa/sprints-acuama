/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI><FecDesde>20210427</FecDesde><FecHasta>20210727</FecHasta><svcCod>2</svcCod></LI></NodoXML>'

EXEC [InformesExcel].[CobradoxLinea_Servicio] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/

CREATE PROCEDURE [InformesExcel].[CobradoxLinea_Servicio]
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
	DECLARE @explo INT;

	SELECT @svc = Servicio, @fDesde=FecDesde, @fHasta= FecHasta FROM @params;

	SELECT @explo=P.pgsvalor FROM dbo.parametros AS P 
	WHERE pgsclave='EXPLOTACION_CODIGO';

	SELECT  FL.fclFacPerCod
	, FL.fclFacCtrCod
	, FL.fclFacCod
	, FL.fclFacVersion
	, FL.fclNumLinea
	, FL.fclTotal
	, [CuotaSvc] = FL.fclPrecio
	, [CuotaCns] =  IIF(FL.fclEscala1=999999999, fclPrecio1, NULL)
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
	, ctrTitNom
	, ctrzoncod
	, ROW_NUMBER() OVER(PARTITION BY ctrCod ORDER BY ctrVersion DESC) AS RN
	FROM dbo.contratos AS C)

	SELECT C.ctrCod, C.ctrVersion, C.ctrTitDocIden, C.ctrTitNom, C.ctrInmCod, C.ctrzoncod
	, I.inmDireccion, I.inmcpost, M.mncdes
	, CC.conDiametro
	INTO #CTRS
	FROM CTRS AS C
	LEFT JOIN dbo.Inmuebles AS I
	ON I.inmCod = C.ctrInmCod
	LEFT JOIN dbo.municipios AS M
	ON  M.mnccod = I.inmmnccod
	AND M.mncPobPrv= I.inmPrvCod
	AND M.mncPobCod = I.inmPobCod
	LEFT JOIN dbo.vCambiosContador AS CC
	ON CC.ctrCod=C.ctrCod
	AND CC.esUltimaInstalacion=1 
	AND CC.opRetirada IS NULL
	WHERE RN=1;

	
	SELECT 
	  [Periodo]				= R.fclFacPerCod
	, [Inicio Periodo]		= CAST(P.przfPeriodoD AS DATE)
	, [Fin Periodo]			= CAST(P.przfPeriodoH AS DATE)
	, [Contrato]			= R.fclFacCtrCod
	, [Titular]				= C.ctrTitDocIden
	, [Abonado]				= C.ctrTitNom
	
	, [Dir.Suministro]		= C.inmDireccion 
	, [CP]					= C.inmcpost
	, [Municipio]			= C.mncdes

	, [Fac.Cod]				= R.fclFacCod
	, [Fac.Versión]			= R.fclFacVersion
	, [Fac.Número]			= F.facNumero
	, [Fac.Línea]			= R.fclNumLinea
	, [Fac.Línea Importe]	= R.fclTotal
	, [Fecha LIQ.]			= R.fclFecLiq
	
	, [Calibre]				= C.conDiametro
	, [m3]					= F.facConsumoFactura
	, [Cuota Servicio]		= [CuotaSvc]
	, [Cuota Consumo]		= [CuotaCns]
	, [Nº Factura]			= FORMATMESSAGE('%i00-%i-%s', @explo,F.facSerCod, F.facNumero)

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
	LEFT JOIN dbo.facturas AS F
	ON  F.facCod	 = R.fclFacCod
	AND F.facPerCod  = R.fclfacPerCod
	AND F.facCtrCod  = R.fclFacCtrCod
	AND F.facVersion = R.fclFacVersion
	LEFT JOIN dbo.perZona AS P
	ON  P.przcodzon=C.ctrzoncod 
	AND P.przcodper=R.fclFacPerCod
	ORDER BY R.fclFacPerCod,  R.fclFacCtrCod,  R.fclFacCod, R.fclFacVersion, R.fclNumLinea, R.cobfec;

	END TRY

	BEGIN CATCH
		SELECT  @p_errId_out = ERROR_NUMBER()
			 ,  @p_errMsg_out= ERROR_MESSAGE();
	END CATCH

	IF OBJECT_ID('tempdb..#RESULT') IS NOT NULL 
	DROP TABLE #RESULT;   

	IF OBJECT_ID('tempdb..#CTRS') IS NOT NULL 
	DROP TABLE #CTRS;  

GO


