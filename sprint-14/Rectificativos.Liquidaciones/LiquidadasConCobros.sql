
/*
SELECT * FROM ExcelPerfil

INSERT INTO dbo.ExcelConsultas
VALUES ('000/710',	'Liquidadas con Cobros', 'Facturas liquidadas con Cobros', 0, '[InformesExcel].[LiquidadasConCobros]', '001', 'Listado de facturas con lineas liquidadas y cobros previos.');

INSERT INTO ExcelPerfil
VALUES('000/710', 'root', 5, NULL)

INSERT INTO ExcelPerfil
VALUES('000/710', 'jefeExp', 5, NULL)

INSERT INTO ExcelPerfil
VALUES('000/710', 'jefAdmon', 5, NULL)

INSERT INTO ExcelPerfil
VALUES('000/710', 'comerc', 5, NULL)

*/


/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI></LI></NodoXML>';

EXEC [InformesExcel].[LiquidadasConCobros] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/

CREATE PROCEDURE [InformesExcel].[LiquidadasConCobros]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS

	SET NOCOUNT ON;   


	--DataTable[1]:  Parametros
	DECLARE @xml AS XML = @p_params;
	
	DECLARE @params TABLE (fInforme DATETIME);

	INSERT INTO @params
	OUTPUT INSERTED.*	
	SELECT fInforme = GETDATE()
	FROM @xml.nodes('NodoXML/LI')AS M(Item);

	WITH FACT AS (
	SELECT F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion
	, facTotalLiq = SUM(IIF(FL.fclFecLiq IS NULL, 0, FL.fclTotal))
	, facTotal = SUM(FL.fclTotal) 
	, fecLiq  = MIN(FL.fclFecLiq)
	FROM dbo.facturas AS F
	INNER JOIN dbo.faclin AS FL
	ON  F.facCod = FL.fclFacCod
	AND F.facPerCod = FL.fclFacPerCod
	AND F.facCtrCod = FL.fclFacCtrCod
	AND F.facVersion = FL.fclFacVersion
	WHERE F.facFechaRectif IS NULL
	GROUP BY F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion
	HAVING MIN(FL.fclFecLiq) IS NOT NULL)

	SELECT F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion
	, [Fec.Liquidación] = MAX(F.fecLiq)
	, Liquidado = ROUND(MAX(F.facTotalLiq), 2)
	, Facturado = ROUND(MAX(facTotal), 2) 
	, [Facturado-Liquidado] = ROUND(MAX(facTotal), 2) - ROUND(MAX(F.facTotalLiq), 2)
	, Cobrado = SUM(cblImporte)
	, DEUDA = ROUND(MAX(facTotal), 2) - ROUND(MAX(F.facTotalLiq), 2) - ROUND(SUM(cblImporte), 2)
	FROM dbo.cobros AS C
	LEFT JOIN dbo.coblin AS CL
	ON  C.cobScd	= CL.cblScd 
	AND C.cobPpag	= CL.cblPpag 
	AND C.cobNum	= CL.cblNum
	--LEFT JOIN dbo.coblinDes AS CLD
	--ON  CLD.cldCblScd	= CL.cblScd 
	--AND CLD.cldCblPpag	= CL.cblPpag 
	--AND CLD.cldCblNum	= CL.cblNum 
	--AND CLD.cldCblLin	= CL.cblLin
	INNER JOIN FACT AS F
	ON F.facCod = CL.cblFacCod
	AND F.facPerCod =CL.cblPer
	AND F.facCtrCod= C.cobCtr
	AND F.facVersion = cblFacVersion
	AND C.cobFec < F.fecLiq
	GROUP BY F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion
	HAVING SUM(cblImporte)>0
	ORDER BY facPerCod, Deuda

GO