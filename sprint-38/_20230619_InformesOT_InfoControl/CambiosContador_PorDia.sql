--EXEC ReportingServices.CambiosContador_PorDia '20220101', '20230701';


DROP PROCEDURE ReportingServices.CambiosContador_PorDia;
GO


CREATE PROCEDURE ReportingServices.CambiosContador_PorDia
@fDesde AS DATETIME, @fHasta AS DATETIME 
AS
	--**********
	--VARIABLES
	--**********
	DECLARE @OT_TIPO_CC INT;

	DECLARE @contratosPK AS dbo.tContratosPK;

	DECLARE @Totales AS TABLE
	( estado VARCHAR(5)
	, fecha	DATE
	, otEplCttCod INT
	, otEplCod INT
	--, ctremplaza VARCHAR(4)
	, esBateria  BIT
	, Total INT)
	SELECT @OT_TIPO_CC = P.pgsvalor 
	FROM dbo.parametros AS P 
	WHERE  P.pgsclave='OT_TIPO_CC';

	SET @fHasta = DATEADD(DAY, 1, @fHasta);

	--**********
	--Ordenes de trabajo con emplazamiento
	--**********
	SELECT OT.otsercod, OT.otserscd, OT.otnum
	, OT.otCtrCod
	, OT.otEplCttCod
	, OT.otEplCod
	, OT.otfsolicitud
	, OT.otFechaReg
	, OT.otFecUltMod
	, OT.otFPrevision
	, otFecRechazo	 = CAST(OT.otFecRechazo AS DATE) 
	, otfrealizacion = CAST(OT.otfrealizacion AS DATE)
	, otfcierre		 = CAST(OT.otfcierre AS DATE)
	--************************************************
	--otFecRechazo: No cumple las validaciones automaticas
	--otfrealizacion: Cumple las validaciones automaticas pero por algo no se pudo cerrar
	--otfcierre: Cumple las validaciones automaticas y se pudo cerrar
	, estado = CASE WHEN otfcierre IS NOT NULL THEN 'OK'
					WHEN otfrealizacion IS NOT NULL OR otFecRechazo IS NOT NULL THEN 'KO'
					ELSE 'PDTE' END
	, fecha = CAST(COALESCE(otfcierre, otfrealizacion, otFecRechazo) AS DATE) 
	, C.ctremplaza
	, esBateria = IIF(E.emcDes COLLATE Latin1_general_CI_AI LIKE '%bateria%', 1, 0) 
	INTO #OT
	FROM dbo.ordenTrabajo AS OT
	LEFT JOIN dbo.vContratosUltimaVersion AS C
	ON C.ctrCod = OT.otCtrCod
	LEFT JOIN dbo.contratos AS CC
	ON CC.ctrcod = C.ctrCod
	AND CC.ctrversion = C.ctrVersion
	LEFT JOIN dbo.emplaza AS E
	ON CC.ctremplaza = E.emccod
	WHERE OT.otfsolicitud>=@fDesde AND OT.otfsolicitud<@fHasta
	 AND OT.otottcod = @OT_TIPO_CC;


	--**********
	--Totales
	--**********
	INSERT INTO @Totales
	--SELECT R.estado, R.fecha, R.otEplCttCod, R.otEplCod, R.ctremplaza, R.esBateria, COUNT(otnum)
	SELECT R.estado, R.fecha, R.otEplCttCod, R.otEplCod, R.esBateria, COUNT(otnum)
	FROM #OT AS R
	GROUP BY R.fecha, R.otEplCttCod, R.otEplCod, R.esBateria, R.estado;

	WITH BATERIA AS(
	SELECT * FROM (VALUES (0),(1)) AS esBateria(valor))

	
	--**********
	--Resultado
	--**********
	SELECT T.estado
	, T.fecha
	, T.otEplCttCod
	, T.otEplCod
	, esBateria = B.valor
	, Total = IIF(T.esBateria=valor, T.Total, 0)
	, [otAsignada] = IIF(COALESCE(C.cttcod, E.eplcttcod) IS NULL, 0, 1)
	, C.cttnom
	, eplnom = LTRIM(E.eplnom)
	, B.valor
	FROM @Totales AS T
	LEFT JOIN dbo.contratistas AS C
	ON C.cttcod = T.otEplCttCod
	LEFT JOIN dbo.empleados AS E
	ON E.eplcttcod = T.otEplCttCod
	AND E.eplcod = T.otEplCod
	CROSS JOIN BATERIA AS B
	
	ORDER BY OtAsignada,  E.eplcod, C.cttcod, T.fecha


	
	DROP TABLE IF EXISTS #OT;
GO