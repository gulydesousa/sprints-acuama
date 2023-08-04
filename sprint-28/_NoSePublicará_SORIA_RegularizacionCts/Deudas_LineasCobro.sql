
/*
***** CONFIGURACION ******
--SELECT * FROM excelConsultas WHERE ExcCod='000/802'

--DELETE  FROM excelConsultas WHERE ExcCod='000/802'
--DELETE FROM ExcelPerfil WHERE ExPCod='000/802'


INSERT INTO dbo.ExcelConsultas
VALUES ('000/802',	'Deuda por Factura', 'Facturas con deuda', 0, '[InformesExcel].[Deuda_Facturas]', '001', '<b>Listado de las facturas activas con deuda pendiente:</b><br>Emite un listado de las facturas en las que el importe cobrado difiere al facturado.<br>Incluye tambien las que el coblindes es diferente al total de la factura.', NULL, NULL, NULL, NULL);

INSERT INTO ExcelPerfil
VALUES('000/802', 'root', 5, NULL)

INSERT INTO ExcelPerfil
VALUES('000/802', 'jefeExp', 5, NULL)

INSERT INTO ExcelPerfil
VALUES('000/802', 'jefAdmon', 5, NULL)

*/

/*

DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);


SET @p_params= '<NodoXML><LI></LI></NodoXML>'

EXEC  [InformesExcel].[Deuda_Facturas] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/

CREATE PROCEDURE [InformesExcel].[Deuda_Facturas]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS

	--***********************************
	--Para un rango de fechas [F1, F2] se recuperan los contratos comunitarios activos en ese periodo.
	
	SET NOCOUNT ON;   
	BEGIN TRY

	--********************
	--INICIO: 3 DataTables
	-- 1: Parametros del encabezado (FecDesde, FecHasta)
	-- 2: Nombre de los Grupos
	-- 3: Contratos y contadores
	-- 4: Detalles de las facturas
	--********************

	--DataTable[1]:  Parametros
	DECLARE @xml AS XML = @p_params;
	DECLARE @params TABLE (fInforme DATETIME);

	INSERT INTO @params
	OUTPUT INSERTED.*
	SELECT  fInforme     = GETDATE()
		  
	FROM @xml.nodes('NodoXML/LI')AS M(Item);

	--Totalizamos las facturas activas y no liquidadas
	SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion
	, [facTotal] = ISNULL(SUM(fcltotal), 0)
	, [facTotal(€)] = CAST(NULL AS MONEY) 
	, [cobTotal(€)] = CAST(NULL AS MONEY) 
	, [cldTotal(€)] = CAST(NULL AS MONEY) 
	INTO #FACT
	FROM dbo.facturas AS F 
	LEFT JOIN dbo.faclin AS FL
	ON  F.facCod = FL.fclFacCod
	AND F.facPerCod = FL.fclFacPerCod
	AND F.facCtrCod = FL.fclFacCtrCod
	AND F.facVersion = FL.fclFacVersion
	AND FL.fclFecLiq IS NULL
	WHERE F.facFechaRectif IS NULL 
	GROUP BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion;
	

	--Totalizamos las lineas de cobro y el desglose por lineas
	SELECT  C.cobScd, C.cobPpag, C.cobNum, CL.cblLin
	, cobFec		= MAX(cobFec)
	, facCod		= MAX(CL.cblFacCod)
	, facPerCod		= MAX(CL.cblPer)
	, facCtrCod		= MAX(C.cobCtr)
	, facVersion	= MAX(CL.cblFacVersion)
	, cblImporte	= MAX(cblImporte)
	, cldTotal		= SUM(cldImporte)
	INTO #CLD
	FROM dbo.cobros AS C
	INNER JOIN dbo.coblin AS CL
	ON C.cobScd = CL.cblScd
	AND C.cobPpag = CL.cblPpag
	AND C.cobNum = CL.cblNum
	INNER JOIN dbo.cobLinDes AS CLD
	ON CLD.cldCblScd = CL.cblScd
	AND CLD.cldCblPpag = CL.cblPpag
	AND CLD.cldCblNum = CL.cblNum
	AND CLD.cldCblLin = CL.cblLin
	GROUP BY C.cobScd, C.cobPpag, C.cobNum, CL.cblLin;

	--Totalizamos los cobros
	SELECT facCod, facPerCod, facCtrCod, facVersion
	, [cobTotal(€)] = SUM(ROUND(cblImporte, 2))
	, [cldTotal(€)] = SUM(ROUND(cldTotal, 2))
	INTO #COBT
	FROM #CLD
	GROUP BY facCod, facPerCod, facCtrCod, facVersion;

	UPDATE F
	SET F.[cobTotal(€)] = ISNULL(C.[cobTotal(€)], 0)
	  , F.[cldTotal(€)] = ISNULL(C.[cldTotal(€)], 0)
	  , F.[facTotal(€)] = ROUND(F.facTotal, 2)
	FROM #FACT AS F
	LEFT JOIN #COBT AS C
	ON F.facCod = C.facCod
	AND F.facPerCod = C.facPerCod
	AND F.facCtrCod = C.facCtrCod
	AND F.facVersion = C.facVersion;


	SELECT *
	, [Deuda(€)]	 = [facTotal(€)] - F.[cobTotal(€)]
	, [Deuda cld(€)] = [facTotal(€)] - F.[cldTotal(€)]
	FROM #FACT AS F
	WHERE [facTotal(€)] <> F.[cobTotal(€)] 
	   OR [facTotal(€)] <> F.[cldTotal(€)]
	ORDER BY [facTotal(€)] - F.[cobTotal(€)];

	END TRY

	BEGIN CATCH
		SELECT  @p_errId_out = ERROR_NUMBER()
			 ,  @p_errMsg_out= ERROR_MESSAGE();
	END CATCH

	DROP TABLE IF EXISTS #CLD;
	DROP TABLE IF EXISTS #FACT;
	DROP TABLE IF EXISTS #COBT;
	

GO


