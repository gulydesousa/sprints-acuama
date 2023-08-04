
/*
***** CONFIGURACION ******
--SELECT * FROM excelConsultas WHERE ExcCod='000/801'

--DELETE  FROM excelConsultas WHERE ExcCod='000/801'
--DELETE FROM ExcelPerfil WHERE ExPCod='000/801'


INSERT INTO dbo.ExcelConsultas
VALUES ('000/801',	'Cobros-Desglose Dif.', 'Cobros: Facturas y diferencias en el desglose de lineas', 0, '[InformesExcel].[Cobros_DiferenciasDesglose]', '005', '<b>Para localizar fallos en el desglose de cobros por lineas de factura:</b><br>Emite un listado de las facturas en las que al menos uno de sus cobros el desglose por lineas de factura no coincide con el total de las lineas.', NULL, NULL, NULL, NULL);

INSERT INTO ExcelPerfil
VALUES('000/801', 'root', 5, NULL)

INSERT INTO ExcelPerfil
VALUES('000/801', 'jefeExp', 5, NULL)

INSERT INTO ExcelPerfil
VALUES('000/801', 'jefAdmon', 5, NULL)

*/


/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);


SET @p_params= '<NodoXML><LI></LI></NodoXML>'

EXEC  [InformesExcel].[Cobros_DiferenciasDesglose] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/

CREATE PROCEDURE [InformesExcel].[Cobros_DiferenciasDesglose]
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

	

	--********************
	--DataTable[2]:  Nombre de Grupos 
	SELECT * 
	FROM (VALUES('Totales Facturado/Cobrado (€)'), ('Detalle Cobros')) 
	AS DataTables(Grupo);

	--********************
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

	--Identificamos las facturas en las que algun coblindes no difiera con el coblin
	DECLARE @facs AS dbo.tFacturasPK;

	INSERT INTO @facs(facCod, facPerCod, facCtrCod, facVersion  )
	SELECT DISTINCT facCod, facPerCod, facCtrCod, facVersion  
	FROM #CLD 
	WHERE ROUND(cldTotal, 2) <> ROUND(cblImporte, 2);

	--Totalizamos las facturas que vamos a reportar  con el detalle de los cobros
	SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion
	, facFechaRectif = MAX(F.facFechaRectif)
	, facTotal = ISNULL(SUM(fcltotal), 0)
	INTO #FACT
	FROM @facs AS FF
	INNER JOIN dbo.facturas AS F 
	ON FF.facCod = F.facCod
	AND FF.facCtrCod = F.facCtrCod
	AND FF.facPerCod = F.facPerCod
	AND FF.facVersion = F.facVersion
	LEFT JOIN dbo.faclin AS FL
	ON  F.facCod = FL.fclFacCod
	AND F.facPerCod = FL.fclFacPerCod
	AND F.facCtrCod = FL.fclFacCtrCod
	AND F.facVersion = FL.fclFacVersion
	AND FL.fclFecLiq IS NULL
	GROUP BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion;

	--Sacamos el listado de las facturas y todos sus cobros 
	SELECT F.facCtrCod
	, F.facPerCod
	, F.facCod
	, F.facVersion
	, F.facFechaRectif
	, F.facTotal
	, [facTotal(€)] = ROUND(F.facTotal, 2)
	, [cobTotal(€)] = SUM(cblImporte) OVER(PARTITION BY F.facCtrCod, F.facPerCod, F.facCod, F.facVersion)
	, [cobDesgloseTotal] = SUM(cldTotal) OVER(PARTITION BY F.facCtrCod, F.facPerCod, F.facCod, F.facVersion)
	, C.cobScd
	, C.cobPpag
	, C.cobNum
	, C.cblLin
	, C.cobFec
	, C.cblImporte
	, C.cldTotal
	, [revisar (coblin-des)] = IIF(ROUND(cldTotal, 2) <> ROUND(cblImporte, 2), '*', '')
	--Importante para mantener el orden en cada grupo de selección
	, [RN] = ROW_NUMBER() OVER (ORDER BY F.facCtrCod, F.facPerCod, F.facCod, F.facVersion, C.cobFec, C.cobNum, C.cblLin)
	INTO #RESULT
	FROM #FACT AS F
	LEFT JOIN #CLD AS C
	ON C.facCod = F.facCod
	AND C.facPerCod = F.facPerCod
	AND C.facCtrCod = F.facCtrCod
	AND C.facVersion = F.facVersion;

	--OUTPUT:
	SELECT facCtrCod, facPerCod, facCod, facVersion, facFechaRectif, facTotal
	FROM #RESULT ORDER BY RN;

	
	SELECT [facTotal(€)], [cobTotal(€)], [cldTotal(€)] = ROUND([cobDesgloseTotal], 2), [deuda(€)] = [facTotal(€)] - ROUND([cobTotal(€)], 2)  
	FROM #RESULT ORDER BY RN;

	SELECT cobScd, cobPpag, cobNum, cobFec, cblImporte, cldTotal, [revisar (coblin-des)]  
	FROM #RESULT ORDER BY RN;

	END TRY

	BEGIN CATCH
		SELECT  @p_errId_out = ERROR_NUMBER()
			 ,  @p_errMsg_out= ERROR_MESSAGE();
	END CATCH

	DROP TABLE IF EXISTS #CLD;
	DROP TABLE IF EXISTS #FACT;
	DROP TABLE IF EXISTS #RESULT;
	

GO


