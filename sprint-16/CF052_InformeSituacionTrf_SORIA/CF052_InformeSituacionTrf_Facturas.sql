/*
DECLARE @cvFecIni DATE = '20180101';
DECLARE @cvFecFin DATE = '20220228';
DECLARE @periodoD VARCHAR(6) = '201801';
DECLARE @periodoH VARCHAR(6) = '201912';
DECLARE @xmlSerCodArray VARCHAR(MAX) = '';


SELECT @xmlSerCodArray = CONCAT(@xmlSerCodArray, '<servicioCodigo><value>') + CAST(svccod AS VARCHAR(5))+ '</value></servicioCodigo>'
FROM dbo.servicios
WHERE svccod NOT IN  (3, 99, 100 , 103, 104, 105, 106, 107);


SET @xmlSerCodArray = FORMATMESSAGE('<servicioCodigo_List>%s</servicioCodigo_List>', @xmlSerCodArray)

EXEC [Trabajo].[CF052_InformeSituacionTrf_Facturas] @cvFecIni, @cvFecFin, @periodoD, @periodoH, @xmlSerCodArray;

--EXEC [ReportingServices].[CF052_InformeSituacionTrf_SORIA] @cvFecIni, @cvFecFin, @periodoD, @periodoH, 1, @xmlSerCodArray 
*/

CREATE PROCEDURE [Trabajo].[CF052_InformeSituacionTrf_Facturas]
@cvFecIni DATE = NULL,
@cvFecFin DATE = NULL,
@periodoD varchar(6) = NULL,
@periodoH varchar(6) = NULL,
@xmlSerCodArray TEXT = NULL 

AS

--***** P A R A M E T R O S *****
SELECT @cvFecIni = ISNULL(@cvFecIni, '19010101')
	 , @cvFecFin = DATEADD(DAY, 1, ISNULL(@cvFecFin, GETDATE()));

--******************************
--Servicios excluidos
DECLARE @serviciosExcluidos AS TABLE(svcCod SMALLINT);
DECLARE @idoc INT;

IF @xmlSerCodArray IS NOT NULL 
BEGIN
	EXEC sp_xml_preparedocument @idoc OUTPUT, @xmlSerCodArray;

	INSERT INTO @serviciosExcluidos
	SELECT value
	FROM   OPENXML (@idoc, '/servicioCodigo_List/servicioCodigo', 2) WITH (value SMALLINT);

	EXEC  sp_xml_removedocument @idoc;
END


--******************************
--Periodos que debemos omitir si existe PERIODO_INICIO
--Todos los periodos de consumo en el rango [@PERIODO_INICIO, @PERIODO_FIN]
DECLARE @OMITIR_INICIO VARCHAR(6) = NULL;
DECLARE @OMITIR_FIN VARCHAR(6) = NULL;

--Minimo periodo de consumo por defecto
SELECT @OMITIR_INICIO = MIN(P.percod) 
FROM dbo.periodos AS P 
WHERE P.percod  NOT LIKE '0000%';

--Periodo por configuración
SELECT @OMITIR_FIN = P.pgsValor
FROM dbo.parametros AS P
WHERE P.pgsClave = 'PERIODO_INICIO';

SELECT @OMITIR_FIN = ISNULL(@OMITIR_FIN, @OMITIR_INICIO);


--************************
--Lineas de facturas
--************************
WITH FACS AS(
SELECT perRegistrado = IIF(FF.facPerCod LIKE '000002', FORMATMESSAGE('%i%02i', YEAR(FF.facFecha), ((MONTH(FF.facFecha)/4)+1)*4), FL.fclFacPerCod)
	 , FL.fclFacPerCod
	 , FL.fclFacCtrCod
	 , FL.fclFacCod
	 , FL.fclFacVersion
	 , FL.fclNumLinea
	
	 , FL.fclTotal
	 , FF.facFecha
	 , FF.facZonCod
	 , FF.facFechaRectif
	 --VER=1. Para mostar la factura mas reciente
	 , VER = DENSE_RANK() OVER (PARTITION BY FL.fclFacPerCod, FL.fclFacCtrCod, FL.fclFacCod ORDER BY fclFacVersion DESC)
	FROM dbo.facturas AS FF
LEFT JOIN dbo.facLin AS FL
ON FF.facCod = FL.fclFacCod 
AND FF.facPerCod = FL.fclFacPerCod 
AND FF.facCtrCod = FL.fclFacCtrCod 
AND FF.facVersion = FL.fclFacVersion
AND FL.fclTrfSvCod NOT IN  (SELECT svcCod FROM @serviciosExcluidos)
AND ((fclFecLiq IS NULL AND fclUsrLiq IS NULL) OR (FL.fclFecLiq >= @cvFecFin))
--********************
AND FF.facFecha >=  @cvFecIni
AND FF.facFecha <   @cvFecFin
--****************
--Rango de periodos
AND (FF.facpercod < @OMITIR_INICIO OR FF.facpercod >= @OMITIR_FIN) --Rango de exclusión
AND (@periodoD IS NULL OR FF.facpercod >= @periodoD OR FF.facpercod LIKE '0000%')			   
AND (@periodoH IS NULL OR FF.facpercod <= @periodoH OR FF.facpercod LIKE '0000%')	
)


----************************
----#FACS: TODAS LAS LINEAS / TODAS LAS VERSIONES
----************************

SELECT *
	, esOriginal = IIF(fclFacVersion = 1, 1, 0)
	, esAnulada  = IIF(facFechaRectif IS NOT NULL, 1, 0)
	, esCreada  = IIF(fclFacVersion > 1, 1, 0)

	, fnOriginal = SUM(IIF(fclFacVersion = 1, fclTotal, 0)) OVER()
	, fnAnulada = SUM(IIF(facFechaRectif IS NOT NULL, fclTotal, 0)) OVER()
    , fnCreada  = SUM(IIF(fclFacVersion > 1, fclTotal, 0)) OVER()

	, fnTotal = SUM(  IIF(fclFacVersion = 1, fclTotal, 0) --Original
					- IIF(facFechaRectif IS NOT NULL, fclTotal, 0) --Anulada
					+ IIF(fclFacVersion > 1, fclTotal, 0)) OVER()  --Creada

	, sumFacturado = SUM(IIF(facFechaRectif IS NULL, fclTotal, 0)) OVER()
	, sumFacturadoMensual = SUM(IIF(facFechaRectif IS NULL AND facZonCod = '0010', fclTotal, 0)) OVER()
	, sumFacturadoCuatrim = SUM(IIF(facFechaRectif IS NULL AND facZonCod <>'0010', fclTotal, 0)) OVER()
INTO #FL
FROM FACS
WHERE COALESCE(perRegistrado, fclFacPerCod) BETWEEN @periodoD AND @periodoH


----************************
----#COBROS: TODOS LOS COBROS POR FACTURA (sin version)
----************************
SELECT FL.fclFacPerCod
	 , FL.fclFacCtrCod
	 , FL.fclFacCod
	 , FL.fclFacVersion
	 , FL.VER
	 , FL.perRegistrado
	 , FL.fclNumLinea
	 , FL.fclTotal

	 , C.cobScd
	 , C.cobPpag
	 , C.cobNum
	 , CLD.cldImporte
	 , RN= ROW_NUMBER() OVER (PARTITION BY FL.fclFacPerCod, FL.fclFacCtrCod, FL.fclFacCod, FL.fclNumLinea ORDER BY cobnum, FL.fclFacVersion)
	 , fclCobrado = SUM(CLD.cldImporte) OVER (PARTITION BY FL.fclFacPerCod, FL.fclFacCtrCod, FL.fclFacCod, FL.fclNumLinea)	
	 
	 , sumFacturado
	 , sumFacturadoMensual
	 , sumFacturadoCuatrim

	 , sumCobrado = SUM(CLD.cldImporte) OVER ()
	 , sumCobradoMensual = SUM(IIF(facZonCod = '0010', CLD.cldImporte, 0)) OVER ()
	 , sumCobradoCuatrim = SUM(IIF(facZonCod <> '0010', CLD.cldImporte, 0)) OVER ()
INTO #COB
FROM dbo.cobros AS C
INNER JOIN dbo.coblin AS CL
ON  CL.cblScd = C.cobScd
AND CL.cblPpag = C.cobPpag
AND CL.cblNum = C.cobNum
AND C.cobFecReg >= @cvFecIni
AND C.cobFecReg < @cvFecFin
INNER JOIN dbo.cobLinDes AS CLD
ON  CLD.cldCblScd =  CL.cblScd
AND CLD.cldCblPpag = CL.cblPpag
AND CLD.cldCblNum =  CL.cblNum
AND CLD.cldCblLin =  CL.cblLin
INNER JOIN #FL AS FL 
ON  FL.fclfacCod = cblFacCod
AND FL.fclfacCtrCod = cobCtr
AND FL.fclfacPerCod = cblPer	
AND FL.fclNumLinea= cldFacLin
--Buscamos los cobros por factura sin version
--AND FL.fclFacVersion = cblFacVersion
AND VER=1; --Importante para quedarnos con una ocurrencia por factura
	
----************************
----#DEUDA:por factura
----************************
SELECT FL.fclFacPerCod
	 , FL.fclFacCtrCod
	 , FL.fclFacCod
	 , FL.fclFacVersion
	 , FL.fclNumLinea 
	 , FL.perRegistrado
	 , FL.facZonCod
	 , C.fclCobrado
	 , FL.fclTotal
	 , fclDeuda = (ROUND(FL.fclTotal, 2) - ROUND(ISNULL(C.fclCobrado, 0), 2))
INTO #DEUDA
FROM #FL AS FL
LEFT JOIN #COB AS C
ON   FL.fclFacPerCod = C.fclFacPerCod
AND  FL.fclFacCtrCod = C.fclFacCtrCod
AND  FL.fclFacCod = C.fclFacCod
--AND  FL.fclFacVersion = C.fclFacVersion
AND FL.fclNumLinea = C.fclNumLinea
AND C.RN=1		--Para sacar solo la linea que totaliza la deuda por factura
WHERE FL.VER=1;	--Para sacar solo la ultima factura;

----************************
----RELACIÓN DE DEUDAS
----************************
SELECT *
, Deuda = SUM(fclDeuda) OVER() 
, DeudaMensual =  SUM(IIF(facZonCod = '0010', fclDeuda, 0)) OVER ()
, DeudaCuatrim = SUM(IIF(facZonCod <> '0010', fclDeuda, 0)) OVER ()
FROM #DEUDA WHERE fclDeuda<>0
ORDER BY fclFacPerCod

----************************
----COBROS
----************************
SELECT C.*
FROM #COB AS C
ORDER BY C.fclFacPerCod, C.fclFacCtrCod

----************************
----RESULTADO
----************************
SELECT FL.perRegistrado
, FL.fclFacPerCod
, FL.fclFacCtrCod
, FL.fclFacCod
, FL.fclFacVersion
, FL.facFecha
, FL.fnOriginal
, FL.fnAnulada
, FL.fnCreada
, FL.fnTotal
, FL.fcltotal
, C.fclCobrado
, fclDeuda = (ROUND(FL.fclTotal, 2) - ROUND(ISNULL(C.fclCobrado, 0), 2))

, sumFacturado = SUM(FL.fcltotal) OVER()
, sumFactMensual = SUM(IIF(facZonCod = '0010', FL.fcltotal, 0)) OVER ()
, sumFactCuatrim = SUM(IIF(facZonCod <> '0010', FL.fcltotal, 0)) OVER ()

, sumCobrado = SUM(fclCobrado) OVER()
, sumCobradoMensual = SUM(IIF(facZonCod = '0010', fclCobrado, 0)) OVER ()
, sumCobradoCuatrim = SUM(IIF(facZonCod <> '0010', fclCobrado, 0)) OVER ()

, sumDeuda = SUM(ROUND(FL.fclTotal, 2) - ROUND(ISNULL(C.fclCobrado, 0), 2)) OVER()
, sumDeudaMensual = SUM(IIF(facZonCod = '0010', ROUND(FL.fclTotal, 2) - ROUND(ISNULL(C.fclCobrado, 0), 2), 0)) OVER ()
, sumDeudaCuatrim = SUM(IIF(facZonCod <> '0010', ROUND(FL.fclTotal, 2) - ROUND(ISNULL(C.fclCobrado, 0), 2), 0)) OVER ()

FROM #FL AS FL
LEFT JOIN #COB AS C
ON   FL.fclFacPerCod = C.fclFacPerCod
AND  FL.fclFacCtrCod = C.fclFacCtrCod
AND  FL.fclFacCod = C.fclFacCod
AND  FL.fclFacVersion = C.fclFacVersion
AND  FL.fclNumLinea = C.fclNumLinea
AND  C.RN=1			--Un cobro que totaliza por factura
WHERE FL.VER=1      --Ultima version de factura
ORDER BY FL.fclfacpercod, FL.perRegistrado;


IF OBJECT_ID('tempdb..#FL') IS NOT NULL
DROP TABLE dbo.#FL;

IF OBJECT_ID('tempdb..#COB') IS NOT NULL
DROP TABLE dbo.#COB;

IF OBJECT_ID('tempdb..#DEUDA') IS NOT NULL
DROP TABLE dbo.#DEUDA;

GO