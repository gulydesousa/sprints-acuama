/**************
** Para cada factura (contrato, periodo) se buscan las lineas que corresponden a servicios repetidos
** Se hace un desglose de esas lineas de factura con todas las tarifas que aplican en las fechas de lectura (o periodo)
** El consumo total de la factura se distribuye en cada desglose, aplicando la correspondiente proporcionalidad por dias
** Para cada linea de factura, totalizamos los consumos antes desglosados.
** De esta manera sabemos la parte de consumo de la factura que debe asociarse a cada linea de factura que corresponde a un servicio repetido  
***************/
CREATE PROCEDURE [dbo].[Facturas_DesglosarConsumosxFactura]
 @facturas  [dbo].[tFacturasPK] READONLY,
 @soloServiciosDuplicados BIT = 1
AS

	SET NOCOUNT ON;
	BEGIN TRY
	--[001]Facturas con servicios medidos 
	--#FCL
	WITH FCL AS (
	SELECT F.facCod
		, F.facPerCod
		, F.facCtrCod
		, F.facVersion
		, FL.fclNumLinea
		, FL.fclEscala1
		, FL.fclEscala2		
		, S.svcTipo
		, FL.fclTrfSvCod
		, FL.fclTrfCod
		, F.facConsumoFactura
		, F.facZonCod	
		, C.ctrValorc1
		, C.ctrFace
		, T.trfUdsPorEsc
		, T.trfUdsPorPrecio
		, CAST(F.facLecAntFec AS DATE) AS facLecAntFec
		, CAST(F.facLecActFec AS DATE) AS facLecActFec
		, CAST(PZ.przfPeriodoD AS DATE) AS przfPeriodoD
		, CAST(PZ.przfPeriodoH AS DATE) AS przfPeriodoH
		, P.pgsvalor AS explotacion
		--Numero de ocurrencias del servicio en una misma factura:
		--CN_SVC>1: Servicio repetido
		, COUNT(FL.fclNumLinea) OVER (PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion,FL.fclTrfSvCod) AS CN_SVC
	FROM dbo.facturas AS F
	INNER JOIN @facturas AS PK
	ON  F.facCtrCod = PK.facCtrCod
	AND F.facPerCod = PK.facPerCod
	LEFT JOIN dbo.perzona AS PZ
	ON  PZ.przcodzon = F.facZonCod
	AND PZ.przcodper = F.facPerCod
	--**************************
	--Se recupera la explotación
	--AVG distribuye por fechas de lectura
	--Otro por fechas de periodo
	LEFT JOIN dbo.parametros AS P
	ON P.pgsclave='EXPLOTACION'
	--***************************
	INNER JOIN dbo.contratos AS C
	ON  C.ctrCod = F.facCtrCod
	AND C.ctrVersion = F.facCtrVersion
	--AND F.facLecAntFec IS NOT NULL
	--AND F.facLecActFec IS NOT NULL
	INNER JOIN dbo.faclin AS FL
	ON  FL.fclFacCod = F.facCod 
	AND FL.fclFacPerCod = F.facPerCod 
	AND FL.fclFacCtrCod = F.facCtrCod 
	AND FL.fclFacVersion = F.facVersion
	AND FL.fclFecLiq IS NULL
	INNER JOIN dbo.servicios AS S
	ON S.svccod = FL.fclTrfSvCod
	LEFT JOIN dbo.tarifas AS T
	ON T.trfsrvcod = FL.fclTrfSvCod
	AND T.trfCod = FL.fclTrfCod)

	--[002]Facturas con servicios medidos duplicados: #FCL
	--Mas de una linea para el mismo servicio
	--El consumo total de la factura debe distribuirse proporcionalmente entre las lineas de la factura
	--La proporción se aplicará en función al numero de días de la lectura y la vigencia de su tarifa/tarval
	SELECT *
	--AVG:  Se aplica proporcionalidad por días de lectura
	--OTRA: Se aplica proporcionalidad por días del periodo
	, IIF(explotacion='AVG', facLecAntFec, przfPeriodoD) AS fechaDesde
	, IIF(explotacion='AVG', facLecActFec, DATEADD(DAY,1, przfPeriodoH)) AS fechaHasta
	INTO #FCL
	FROM FCL
	--***************
	--Recuperamos datos solo cuando se trata de AVG y hay dias entre lecturas mientras podemos probarlo con AVG y otras explotaciones
	WHERE explotacion='AVG' AND facLecAntFec IS NOT NULL AND facLecActFec IS NOT NULL AND  facLecActFec > facLecAntFec;
	
	
	--*****************
	--[101]Valores de Tarifa aplicables a las lineas de factura
	--#TARVAL
	SELECT F.*
	, DATEDIFF(DAY, F.fechaDesde, F.fechaHasta) AS diasEntreLecturas 
	--*************************
	, CAST(NULL AS INT) AS diasxLinea
	--El limite de la tarifa lo marcan contratoServicio y tarval
	, TV.trvfecha AS tarval_ini
	, CS.ctsfecalt AS ctrsvc_ini
	, TV.trvfechafin AS tarval_fin 
	, CS.ctsfecbaj AS ctrsvc_fin

	--, CAST(TV.trvfecha AS DATE) AS trvfecha
	, CAST(
	     CASE WHEN CAST(CS.ctsfecalt AS DATE) >= CAST(TV.trvfecha AS DATE) THEN CS.ctsfecalt
			  ELSE TV.trvfecha END 
	  AS DATE) AS trvfecha	
	
	--, CAST(TV.trvfechafin AS DATE) AS 
	, CAST( 
		CASE WHEN CS.ctsfecbaj IS NULL   THEN TV.trvfechafin
			 WHEN TV.trvfechafin IS NULL THEN CS.ctsfecbaj
			 WHEN CAST(CS.ctsfecbaj AS DATE) >= CAST(TV.trvfechafin AS DATE) THEN TV.trvfechafin
			 ELSE CS.ctsfecbaj END
	  AS DATE) AS trvfechafin
	--*************************	 
	, TV.trvCuota
	--RN_TRV=1 / Versión de tarifa por defecto al aperturar: La mas antigua
	--Versiones de tarifa ordenadas por fecha 
	, ROW_NUMBER() OVER (PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, F.fclNumLinea, F.fclTrfSvCod, F.fclTrfCod  ORDER BY TV.trvfecha) AS RN_TRV
	--RN: Orden del desglose 
	, ROW_NUMBER() OVER (PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, F.fclTrfSvCod  ORDER BY F.fclNumLinea, TV.trvfecha) AS RN
	--CN: Numero de lineas en el desglose
	, COUNT(F.fclTrfCod) OVER (PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, F.fclTrfSvCod) AS CN
	--CN_LIN: Numero de lineas en el desglose por linea
	, COUNT(F.fclTrfCod) OVER (PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, F.fclNumLinea) AS CN_LIN
	INTO #TARVAL
	FROM #FCL AS F
	LEFT JOIN dbo.contratoServicio AS CS
	ON  F.facCtrCod = CS.ctsctrcod
	AND F.fclTrfSvCod = CS.ctssrv
	AND F.fclTrfCod = CS.ctstar
	AND (CS.ctsfecalt <= F.fechaHasta)
	AND (CS.ctsfecbaj IS NULL OR CS.ctsfecbaj >= fechaDesde) 

	LEFT JOIN dbo.tarval AS TV
	ON  (TV.trvtrfcod = CS.ctstar) 
	AND (TV.trvsrvcod = CS.ctssrv)
	-- Tarifas que están activas dentro del intervalo de fechas. Este JOIN es el que hace que salgan varias sublíneas por cada línea de factura
	AND (CAST(TV.trvfecha AS DATE) <= F.fechaHasta)
	AND (TV.trvfechafin IS NULL OR CAST(TV.trvfechafin AS DATE) >= fechaDesde);
	
	
	
	--*****************
	--[102]DIASxLINEA: SE CALCULA POR CONTRATOxSERVICIO
	UPDATE TV
	SET diasxLinea=
		 DATEDIFF(DAY, CASE WHEN TV.trvFecha < fechaDesde THEN fechaDesde ELSE TV.trvFecha END
					 , CASE WHEN TV.trvFechaFin IS NULL OR TV.trvFechaFin > fechaHasta THEN fechaHasta 
					   ELSE DATEADD(DAY, IIF(CN_SVC>1 , 1, 0) , TV.trvFechaFin) END) 

	FROM #TARVAL AS TV;


	
	--*****************
	--[201]CONSUMO PROPORCIONAL PARA CADA LINEA DE FACTURA
	WITH CONSUMO AS(
	--[202]consumoProporcional: 
	--Repartición del consumo proporcional al numero de días que aplica el tarval
	SELECT IIF ( diasEntreLecturas<>0 
				, CAST(ROUND(facConsumoFactura * diasxLinea / CAST(diasEntreLecturas AS DECIMAL(10,2)), 0) AS INT)
				, facConsumoFactura
				) AS consumoProporcional	
		 , facCod
		 , facPerCod
		 , facCtrCod
		 , facVersion
		 , fclNumLinea
		 , fclTrfSvCod
		 , fclTrfCod
		 , facConsumoFactura
		 , fechaDesde
		 , fechaHasta
		 , diasEntreLecturas
		 , trfUdsPorPrecio
		 , trvfecha
		 , trvfechafin
		 , trvCuota
		 , diasxLinea
		 , ctrFace
		 , svcTipo
		 , RN_TRV
		 , RN
		 , CN
		 , CN_LIN
		 , CN_SVC																
	FROM #TARVAL
	
	), ACUMULADO AS(
	SELECT 
	--[203]consumoAcumulado: 
	--Totaliza el consumo proporcional de las tarifas previas hasta la actual 	
	--esConsumoRestante: Si solo se aplica una tarifa o la ultima tarifa cubre hasta la fecha de ultima lectura nos quedamos con lo queda de consumo
	  IIF(CN=RN AND (trvfechafin IS NULL OR trvfechafin > fechaHasta OR CN_LIN=1), 1, 0) AS esConsumoRestante 
	, SUM(consumoProporcional) OVER(PARTITION BY facCod, facPerCod, facCtrCod, facVersion, fclTrfSvCod ORDER BY RN) AS consumoAcumulado
	, *
	FROM CONSUMO
	
	), DESGLOSE AS (
	--[204]consumoxDesglose:
	--Consumo que se aplica a cada desglose de la linea
	SELECT 
	IIF(esConsumoRestante=1, facConsumoFactura-(consumoAcumulado-consumoProporcional), consumoProporcional) AS consumoxDesglose
	, * 
	FROM ACUMULADO

	), FCL_CONSUMO AS(
	--[205]consumoxLinea:
	--Consumo que se aplica a cada desglose de la linea
	SELECT SUM(consumoxDesglose) OVER(PARTITION BY facCod, facPerCod, facCtrCod, facVersion, fclTrfSvCod, fclNumLinea) AS consumoxLinea
	, *
	FROM DESGLOSE)

	SELECT facCod
		, facPerCod
		, facCtrCod
		, facVersion
		, fclNumLinea
		, svcTipo
		, fclTrfSvCod
		, fclTrfCod
		, trvfecha
		, trvfechafin
		, trvCuota
		, diasEntreLecturas
		, diasxLinea
		, consumoxLinea
		, CN_LIN AS tarifasxLinea		
	FROM FCL_CONSUMO
	WHERE (
	 (@soloServiciosDuplicados = 0) OR 
	 (@soloServiciosDuplicados = 1 AND (diasxLinea<>diasEntreLecturas OR CN_SVC>1))) 
	 
	 AND RN_TRV= 1;
	
	END TRY
	BEGIN CATCH

	END CATCH

	IF OBJECT_ID('tempdb.dbo.#FCL', 'U') IS NOT NULL  
	DROP TABLE dbo.#FCL;

	IF OBJECT_ID('tempdb.dbo.#TARVAL', 'U') IS NOT NULL  
	DROP TABLE dbo.#TARVAL;



GO


