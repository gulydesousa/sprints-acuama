/*
DECLARE @fDesde AS DATETIME='20220129'
, @fHasta AS DATETIME='20230719'
, @origenOT AS VARCHAR(250)='ANY, CCMASIVO, CCCONTRATO';

EXEC  ReportingServices.CambiosContador_PorDia_Detalle @fDesde, @fHasta, @origenOT;

*/

ALTER PROCEDURE [ReportingServices].[CambiosContador_PorDia_Detalle]
  @fDesde AS DATETIME
, @fHasta AS DATETIME 
, @origenOT AS VARCHAR(250)
AS

	SET NOCOUNT ON;


	--**********
	--VARIABLES
	--**********
	DECLARE @OT_TIPO_CC INT;
	
	SELECT @OT_TIPO_CC = P.pgsvalor 
	FROM dbo.parametros AS P 
	WHERE  P.pgsclave='OT_TIPO_CC';

	SET @fHasta = DATEADD(DAY, 1, @fHasta);
	
	BEGIN TRY
	--**********
	--Ordenes de trabajo con emplazamiento
	--**********
	SELECT OT.otsercod, OT.otserscd, OT.otnum
	, OT.otCtrCod
	, OT.otEplCttCod
	, CT.cttnom
	, OT.otEplCod
	, EM.eplnom
	, OT.otfsolicitud
	, otFecRechazo	 = CAST(OT.otFecRechazo AS DATE) 
	, otfrealizacion = CAST(OT.otfrealizacion AS DATE)
	, otfcierre		 = CAST(OT.otfcierre AS DATE)
	--************************************************
	--otFecRechazo: No cumple las validaciones automaticas
	--otfrealizacion: Cumple las validaciones automaticas pero por algo no se pudo cerrar
	--otfcierre: Cumple las validaciones automaticas y se pudo cerrar
	, estado = CASE WHEN otfcierre IS NOT NULL THEN 'OK'
					WHEN otfrealizacion IS NOT NULL THEN 'KO' 
					WHEN otFecRechazo IS NOT NULL THEN 'RECHAZO'
					ELSE 'PDTE' END
	, fecha = CAST(COALESCE(otfcierre, otfrealizacion, otFecRechazo) AS DATE) 
	, C.ctremplaza
	, E.emcdes
	, esBateria = IIF(E.emcDes COLLATE Latin1_general_CI_AI LIKE '%bateria%', 1, 0) 
	, [otAsignada] = IIF(COALESCE(CT.cttcod, EM.eplcttcod) IS NULL, 0, 1)
	, OT.otObsRealizacion
	--************************************************
	INTO #OT
	
	FROM dbo.ordenTrabajo AS OT
	LEFT JOIN dbo.vContratosUltimaVersion AS C
	ON C.ctrCod = OT.otCtrCod
	LEFT JOIN dbo.contratos AS CC
	ON CC.ctrcod = C.ctrCod
	AND CC.ctrversion = C.ctrVersion
	LEFT JOIN dbo.emplaza AS E
	ON CC.ctremplaza = E.emccod
	LEFT JOIN dbo.contratistas AS CT
	ON CT.cttcod = OT.otEplCttCod
	LEFT JOIN dbo.empleados AS EM
	ON EM.eplcttcod = OT.otEplCttCod
	AND EM.eplcod = OT.otEplCod
	LEFT JOIN dbo.Split(@origenOT, ',') AS O
	ON OT.otTipoOrigen=O.value 
	WHERE OT.otottcod = @OT_TIPO_CC
	 AND OT.otfsolicitud>=@fDesde 
	 AND OT.otfsolicitud<@fHasta
	 AND (@origenOT IS NULL OR @origenOT= '' OR O.value IS NOT NULL);
	
	

	--*************************************************************************************
	--Filas ficticias para que el informe pueda pintar siempre las dos columnas: Bateria/Individual
	
	WITH BATERIA AS(
	SELECT * FROM (VALUES (0),(1)) AS esBateria(valor)
	
	), OTS AS (
	SELECT DISTINCT otEplCttCod, cttnom , otEplCod, eplnom, fecha, esBateria
	FROM #OT
	
	), FECHAS AS(
	SELECT otEplCttCod, cttnom, otEplCod, eplnom, fecha
		  , esBateria=valor
	FROM OTS
	CROSS JOIN BATERIA AS B
	
	), MOCK AS(
	--Combinacion de fecha, empleado, bateria que no hay en los resultados
	--Filas ficticias para que el informe pueda pintar las dos columnas: Bateria/Individual
	SELECT O.otsercod, O.otserscd, O.otnum, O.otCtrCod
	, M.otEplCttCod, M.cttnom
	, M.otEplCod, M.eplnom
	, O.otfsolicitud, O.otFecRechazo, O.otfrealizacion, O.otfcierre
	, estado='PDTE'
	, M.fecha
	, O.ctremplaza, O.emcdes
	, M.esBateria
	, [otAsignada] = 0
	, [otObsRealizacion] = NULL
	, [mock] = 1 
	
	FROM FECHAS AS M
	LEFT JOIN #OT AS O
	ON M.otEplCttCod = O.otEplCttCod
	AND M.otEplCod = O.otEplCod
	AND M.esBateria = O.esBateria
	AND M.fecha = O.fecha
	WHERE O.otnum IS NULL)
	
	SELECT *, [mock] = CAST(0 AS BIT) FROM #OT
	--Filas ficticias para que el informe pueda pintar las dos columnas: Bateria/Individual
	UNION ALL
	SELECT * FROM MOCK;

	END TRY
	BEGIN CATCH
	
	END CATCH
	
	DROP TABLE IF EXISTS #OT
GO


