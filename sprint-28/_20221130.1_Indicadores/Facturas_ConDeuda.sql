/*
DECLARE @fecha DATE = '20220201'
DECLARE @minDeuda MONEY = 0.01;
DECLARE @diasVencimiento INT = 120;
DECLARE @usos VARCHAR(MAX) = '4';
DECLARE @tipoSalida TINYINT = 0;
DECLARE @periodosConsumo BIT = 0

DECLARE @result INT;

EXEC Indicadores.Facturas_ConDeuda @fecha, @minDeuda, @diasVencimiento, @usos, @periodosConsumo, @tipoSalida,  @result OUTPUT;

SELECT @result
*/

ALTER PROCEDURE [Indicadores].[Facturas_ConDeuda](
@fecha DATE
, @minDeuda MONEY
, @diasVencimiento INT
, @usos VARCHAR(MAX)
, @periodosConsumo BIT
, @tipoSalida TINYINT
, @result INT OUTPUT)
AS 

--********
--@tipoSalida: 0 => Detalle por factura
--@tipoSalida: 1 => Numero de facturas
--@tipoSalida: 2 => Numero de distintos contratos

--********
--[01] Parametros de configuración
--********
DECLARE @BARCODE_FECHAVTO INT =  1;
DECLARE @DIAS_PAGO_VOLUNTARIO INT =  0;
DECLARE @DIAS_VTO_C57_POR_DEFECTO INT =  0; 
DECLARE @SCD_REMESA INT = 0;

SELECT @BARCODE_FECHAVTO = p.pgsvalor FROM dbo.parametros AS P WHERE P.pgsclave='BARCODE_FECHAVTO'; --1:SegunFactura, 2:SiempreFuturo, 3:SinFecha
SELECT @DIAS_PAGO_VOLUNTARIO = p.pgsvalor FROM dbo.parametros AS P WHERE P.pgsclave='DIAS_PAGO_VOLUNTARIO';
SELECT @DIAS_VTO_C57_POR_DEFECTO = p.pgsvalor FROM dbo.parametros AS P WHERE P.pgsclave='DIAS_VTO_C57_POR_DEFECTO';
SELECT @SCD_REMESA = p.pgsvalor FROM dbo.parametros AS P WHERE P.pgsclave='SOCIEDAD_REMESA';


SELECT @usos = ISNULL(@usos, ''), @tipoSalida = ISNULL(@tipoSalida, 0);

BEGIN TRY
	--********
	--[02] #FACS: FACTURAS x USO
	--********
	WITH U AS(
	SELECT DISTINCT(value) 
	FROM dbo.Split(@usos, ',') 
	WHERE [value] IS NOT NULL

	), FACS AS(
	SELECT F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion 
	, C.ctrUsoCod
	, facScd	 = IIF(@SCD_REMESA > 0, @SCD_REMESA, F.facSerScdCod)
	, facFecha	 = CAST(F.facFecha AS DATE)
	, facTotal	 = CAST(0 AS MONEY)
	, facCobrado = CAST(0 AS MONEY)
	, facDeuda	 = CAST(0 AS MONEY)
	, fecVto	 = CAST(NULL AS DATE)
	, RN		 = ROW_NUMBER() OVER(PARTITION BY F.facCod, F.facPerCod, F.facCtrCod ORDER BY F.facVersion  DESC)
	FROM dbo.facturas AS F 
	INNER JOIN dbo.vContratosUltimaVersion AS V
	ON V.ctrCod = F.facCtrCod
	INNER JOIN dbo.contratos AS C
	ON  C.ctrcod = V.ctrCod
	AND C.ctrversion = V.ctrVersion
	LEFT JOIN U
	ON C.ctrUsoCod = U.[value]
	WHERE (facFecha IS NOT NULL) 
	  AND (facFecha < @fecha)
	  AND (F.facFechaRectif IS NULL OR F.facFechaRectif>= @fecha)
	  AND (@usos = '' OR (U.[value] IS NOT NULL))
	  AND (@periodosConsumo IS NULL OR @periodosConsumo = IIF(LEFT(F.facPerCod, 1) NOT IN ('0', '9'), 1, 0)))

	SELECT facCod, facPerCod, facCtrCod, facVersion
	, facScd
	, ctrUsoCod
	, facFecha
	, fecVto
	, facTotal
	, facCobrado
	, facDeuda
	INTO #FACS 
	FROM FACS 
	WHERE RN=1
	OPTION (OPTIMIZE FOR UNKNOWN);

	--********
	--[03]fclTotal: Totales por factura
	--********
	WITH FACT AS(
	SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, fclTotal = SUM(fclTotal) 
	FROM dbo.faclin AS FL
	INNER JOIN #FACS AS F
	ON F.facCod = FL.fclFacCod
	AND F.facPerCod = FL.fclFacPerCod
	AND F.facCtrCod = FL.fclFacCtrCod
	AND F.facVersion = FL.fclFacVersion
	AND (FL.fclFecLiq IS NULL OR  FL.fclFecLiq>@fecha)
	GROUP BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion)

	UPDATE F SET facTotal = T.fclTotal
	FROM #FACS AS F
	INNER JOIN FACT AS T
	ON  F.facCod	= T.facCod 
	AND F.facPerCod = T.facPerCod 
	AND F.facCtrCod = T.facCtrCod
	AND F.facVersion= T.facVersion
	OPTION (OPTIMIZE FOR UNKNOWN);

	--********
	--[04]cblImporte: Total cobrado por cabecera de factura
	--********
	WITH COBT AS(
	SELECT F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion
	, cblImporte = SUM(CL.cblImporte)
	FROM dbo.cobros AS C 
	INNER JOIN dbo.coblin AS CL 
	ON  C.cobScd = CL.cblScd 
	AND C.cobPpag = CL.cblPpag 
	AND C.cobNum =CL.cblNum
	AND C.cobFec < @fecha
	INNER JOIN #FACS AS F
	ON F.facCod = CL.cblFacCod
	AND F.facPerCod = CL.cblPer
	AND F.facCtrCod = C.cobCtr
	AND F.facVersion = CL.cblFacVersion
	GROUP BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion)

	UPDATE F 
	SET facCobrado = T.cblImporte
	  , facDeuda = ROUND(F.facTotal, 2) - ROUND(T.cblImporte, 2)
	FROM #FACS AS F
	INNER JOIN COBT AS T
	ON  F.facCod	= T.facCod 
	AND F.facPerCod = T.facPerCod 
	AND F.facCtrCod = T.facCtrCod
	AND F.facVersion= T.facVersion
	OPTION (OPTIMIZE FOR UNKNOWN);


	--********
	--[05]fecVto: Fecha de vencimiento con el mismo criterio usado en el codigo de barras en:
	--ReportingServices.CF010_EmisionFacTotales_CodigoBarras
	--********
	UPDATE F SET 
	fecVto = CASE @BARCODE_FECHAVTO 
			   --1:SegunFactura
			   WHEN 1 THEN
			   CASE WHEN P.perFecFinPagoVol IS NOT NULL THEN P.perFecFinPagoVol
					WHEN F.facFecha IS NOT NULL			THEN DATEADD(DAY, @DIAS_PAGO_VOLUNTARIO, F.facFecha)
					WHEN F.facFecha IS NULL				THEN DATEADD(DAY, @DIAS_PAGO_VOLUNTARIO, @fecha)
					ELSE ISNULL(F.facFecha, @fecha) 
					END 
			   --2:SiempreFuturo
			   WHEN 2 THEN 
			   CASE WHEN P.perFecFinPagoVol IS NOT NULL AND P.perFecFinPagoVol > @fecha THEN  P.perFecFinPagoVol  
					WHEN SS.scdDiasVtoC57 IS NOT NULL AND SS.scdDiasVtoC57 > 0			THEN  DATEADD(DAY, SS.scdDiasVtoC57 , @fecha)
					WHEN @DIAS_VTO_C57_POR_DEFECTO > 0									THEN  DATEADD(DAY, @DIAS_VTO_C57_POR_DEFECTO, @fecha)
					ELSE NULL
					END
			   --3: Sin Fecha
			   ELSE NULL END

	FROM #FACS AS F
	INNER JOIN dbo.periodos AS P
	ON P.percod = F.facPerCod
	LEFT JOIN dbo.sociedades AS SS
	ON SS.scdcod = F.facScd
	WHERE @diasVencimiento IS NOT NULL
	OPTION (OPTIMIZE FOR UNKNOWN);


	--********
	--[10]#RESULT: Facturas que cumplen los filtros.
	--********
	SELECT * 
	, [DiasPostVencimiento] = IIF(fecVto IS NULL, 0, DATEDIFF(DAY, fecVto, @fecha))
	INTO #RESULT
	FROM #FACS AS F
	WHERE F.facTotal > 0 
		AND F.facDeuda <> 0
		AND (@minDeuda IS NULL OR F.facDeuda>=@minDeuda)
		AND (@diasVencimiento IS NULL OR IIF(fecVto IS NULL, 0, DATEDIFF(DAY, fecVto, @fecha)) > @diasVencimiento);


	--********
	--[99]Salida por tipo.
	--********
	IF (@tipoSalida = 0)
	BEGIN
		SELECT * 
		FROM #RESULT ORDER BY facDeuda DESC;

		SELECT @result= @@ROWCOUNT;
	END
	ELSE IF(@tipoSalida = 1)
	BEGIN	
		SELECT @result = COUNT(*) FROM #RESULT;
	END
	ELSE IF(@tipoSalida = 2)
	BEGIN
		SELECT @result = COUNT(DISTINCT facCtrCod) FROM #RESULT;
	END

	END TRY

	BEGIN CATCH
	END CATCH
	

	IF OBJECT_ID('tempdb..#FACS') IS NOT NULL DROP TABLE #FACS;
	IF OBJECT_ID('tempdb..#RESULT') IS NOT NULL DROP TABLE #RESULT;

GO


