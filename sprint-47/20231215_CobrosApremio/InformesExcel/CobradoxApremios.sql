
/*
INSERT INTO dbo.ExcelConsultas
VALUES ('400/002',	'Cobrado por apremios', 'Cobrado por apremios', 1, '[InformesExcel].[CobradoxApremios]', '001'
, 'Compara que los cobros por apremios en un rango de fechas coincidan con los datos enviados en la última carga de cobros por apremios'
, NULL, NULL, NULL, NULL);

INSERT INTO ExcelPerfil
VALUES('400/002', 'root', 5, NULL)

INSERT INTO ExcelPerfil
VALUES('400/002', 'jefAdmon', 5, NULL)
*/


/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI><FecDesde>20231214</FecDesde><FecHasta>20231214</FecHasta></LI></NodoXML>';
EXEC [InformesExcel].[CobradoxApremios] @p_params, @p_errId_out, @p_errMsg_out;
*/


CREATE PROCEDURE [InformesExcel].[CobradoxApremios]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT

AS

SET NOCOUNT ON;   
BEGIN TRY	
	
	--********************
	--INICIO: 2 DataTables
	-- 1: Paramentros del encabezado
	-- 2: Grupos
	-- 3: Detalle por facturas
	-- 4: Detalle por periodos 
	--********************

	--********************
	--DataTable[1]:  Parametros
	DECLARE @xml AS XML = @p_params;
	DECLARE @params TABLE (FecDesde DATE NULL, fInforme DATETIME, FecHasta DATE NULL);

	INSERT INTO @params
	OUTPUT INSERTED.*
	SELECT  CASE WHEN M.Item.value('FecDesde[1]', 'DATE') = '19000101' THEN '19010101'
			ELSE M.Item.value('FecDesde[1]', 'DATE') END
			, GETDATE() AS fInforme
			, CASE WHEN M.Item.value('FecHasta[1]', 'DATE') = '19000101' THEN GETDATE() 
					ELSE M.Item.value('FecHasta[1]', 'DATE') END
	FROM @xml.nodes('NodoXML/LI')AS M(Item);

	--Para garantizar que el rango de fechas cubre el día completo
	UPDATE @params SET FecHasta = DATEADD(DAY, 1, FecHasta);
	
	--*****************************
	--Facturas de apremios: Actualizamos los totales de las facturas, por si acaso
	DECLARE @fctActualizacion AS DATE;
	DECLARE @hoy AS DATE = GETDATE();

	DECLARE @FACS AS dbo.tFacturasPK;

	INSERT INTO @FACS(facCod, facPerCod, facCtrCod, facVersion)
	SELECT A.aprFacCod, A.aprFacPerCod, A.aprFacCtrCod, A.aprFacVersion 
	FROM dbo.apremios AS A;

	SELECT @fctActualizacion=MIN(T.fctActualizacion) 
	FROM facTotales AS T
	INNER JOIN @FACS AS F
	ON T.fctCod= F.facCod
	AND T.fctPerCod = F.facPerCod
	AND T.fctCtrCod = F.facCtrCod
	AND T.fctVersion = F.facVersion;

	EXEC FacTotales_Update @FACS; 
	
	--*****************************
	--Trabajo.apremiosODS: El recibo de apremios no tiene nada que ver con el numero de factura de acuama
	--Hacemos un proceso para encontralos por coincidencia
	DECLARE @COINCIDENCIAS AS dbo.tApremios_ObtenerCoincidenciasOds;

	INSERT INTO @COINCIDENCIAS
	EXEC Apremios_ObtenerCoincidenciasOds;

	--Seleccionamos los cobros por apremios en el rango de fechas
	--Si es una entrega a cuentas obtenemos el periodo al que corresponde la devolución
	SELECT C.cobCtr, CL.cblPer, CL.cblFacCod, CL.cblFacVersion
	,EAC = IIF(cobConcepto LIKE 'EAC apr%' AND CHARINDEX('.', C.cobConcepto)>7, SUBSTRING(C.cobConcepto, CHARINDEX('.', C.cobConcepto)-6 , 6), NULL)
	, CL.cblImporte
	INTO #COBS
	FROM cobros AS C
	INNER JOIN dbo.coblin AS CL
	ON C.cobPpag = CL.cblPpag
	AND C.cobScd = CL.cblScd
	AND C.cobNum = CL.cblNum
	INNER JOIN @params AS P
	ON C.cobFecReg>=P.FecDesde AND C.cobFecReg < P.FecHasta 
	WHERE cobOrigen='Apremio';

	--Como no sabemos la correspondencia exacta de cada cobro...
	--Comparamos con los totales por cada factura
	WITH COBS AS(
	SELECT C.cobCtr
	, C.cblPer
	, periodo= ISNULL(EAC, C.cblPer)
	, C.cblFacCod
	, C.cblFacVersion
	, NumCobros = COUNT(cobCtr)
	, ImpCobrado = SUM(cblImporte)
	FROM #COBS AS C
	GROUP BY C.cobCtr, cblPer, ISNULL(EAC, C.cblPer), C.cblFacCod, C.cblFacVersion)


	SELECT C.EJERCICIOS
	, C.RECIBO
	, C.FECHA
	, C.NOMBRE
	, C.DEMORA
	, C.RECARGO
	, C.PRINCIPAL
	, C.COSTAS
	, C.facCtrCod
	, C.facPerCod
	, C.facCod
	, C.facVersion
	, C.facNumero
	, C.fctFacturado
	, C.fctCobrado
	, C.fctDeuda
	, NUM_PARCIALES = COUNT(RECIBO) OVER(PARTITION BY RECIBO, NOMBRE, EJERCICIOS)
	, IMP_PARCIALES  = SUM(PRINCIPAL) OVER(PARTITION BY  RECIBO, NOMBRE, EJERCICIOS)
	, CC.NumCobros
	, CC.ImpCobrado
	, [Periodo] = cc.cblPer
	, [NumParciales] = COUNT(ID) OVER (PARTITION BY facCod, facPerCod, facCtrCod, facVersion) 
	, [IndiceParcial]= ROW_NUMBER() OVER (PARTITION BY facCod, facPerCod, facCtrCod, facVersion ORDER BY FECHA, ID)
	INTO #RESULT
	FROM @COINCIDENCIAS AS C
	LEFT JOIN COBS AS CC
	ON  C.facCtrCod = CC.cobCtr
	AND C.facPerCod = CC.periodo
	AND C.facVersion = CC.cblFacVersion
	AND C.facCod = CC.cblFacCod
	WHERE C.facCtrCod IS NOT NULL;
	
	
	SELECT * 
	, NUM_OK = IIF(NUM_PARCIALES= NumCobros, 'OK', 'KO')
	, IMP_OK = IIF(IMP_PARCIALES= ImpCobrado, 'OK', 'KO')
	FROM #RESULT
	ORDER BY CAST(RECIBO AS INT), NOMBRE;

END TRY

BEGIN CATCH
	SELECT  @p_errId_out = ERROR_NUMBER()
			,  @p_errMsg_out= ERROR_MESSAGE();
END CATCH

DROP TABLE IF EXISTS #COBS;
DROP TABLE IF EXISTS #RESULT;
GO


