/*
DECLARE @cliCod INT = NULL
DECLARE @ctrCod INT = NULL
DECLARE @repLegal VARCHAR(80) = 'Servicios Victoria'

EXEC Facturas_SelectFraccionadasPendientes @cliCod, @ctrCod, @repLegal;

*/
ALTER PROCEDURE [dbo].[Facturas_SelectFraccionadasPendientes] 
  @cliCod INT = NULL
, @ctrCod INT = NULL
, @repLegal VARCHAR(80) = NULL
	
AS

	SET NOCOUNT ON;
	
	DECLARE @FACS AS [dbo].[tFacturasPK];
	DECLARE @FAC_APERTURA AS VARCHAR(10) = '1.0.0';

	SELECT @FAC_APERTURA = P.pgsvalor 
	FROM dbo.parametros AS P 
	WHERE P.pgsclave='FAC_APERTURA';

	SELECT  @cliCod = IIF(@cliCod = 0, NULL, @clicod)
		  , @ctrCod = IIF(@ctrCod = 0, NULL, @ctrCod)
		  , @repLegal = IIF(LTRIM(RTRIM( @repLegal))='', NULL,  UPPER(@repLegal));


	--Facturas con efectos pendientes no domiciliados pendientes de cobro.
	INSERT INTO @FACS(facCod, facPerCod, facCtrCod, facVersion)
	SELECT DISTINCT
	F.facCod, F.facPerCod, F.facCtrCod, F.facVersion
	FROM dbo.facturas AS F
	INNER JOIN dbo.contratos AS C 
	ON  (C.ctrcod = F.facCtrCod) 
	AND (C.ctrversion = F.facCtrVersion)
	AND (@ctrCod IS NULL OR C.ctrCod = @ctrCod)
	AND (@repLegal IS NULL OR UPPER(C.ctrRepresent) = @repLegal)
	AND F.facFechaRectif IS NULL
	AND F.facSerScdCod IS NOT NULL	
	AND F.facSerCod IS NOT NULL
	AND F.facNumero IS NOT NULL
	AND (@cliCod IS NOT NULL OR  @ctrCod IS NOT NULL OR @repLegal IS NOT NULL)
	INNER JOIN dbo.clientes AS CC 
	ON  (CC.clidociden = C.ctrTitDocIden)
	AND (@cliCod IS NULL OR CC.clicod = @cliCod)
	
	INNER JOIN dbo.efectosPendientes AS E
	ON  F.facCod	= E.efePdteFacCod
	AND F.facPerCod = E.efePdtePerCod
	AND F.facCtrCod = E.efePdteCtrCod
	AND F.facSerScdCod = E.efePdteScd 
	AND E.efePdteFecRechazado IS NULL
	AND E.efePdteDomiciliado = 0
	LEFT JOIN dbo.cobLinEfectosPendientes AS CL
	ON  CL.clefePdteCod		= E.efePdteCod
	AND CL.clefePdteCtrCod	= E.efePdteCtrCod
	AND CL.clefePdtePerCod	= E.efePdtePerCod
	AND CL.clefePdteFacCod	= E.efePdteFacCod
	AND CL.clefePdteScd		= E.efePdteScd 
	--************************	
	WHERE CL.cleCblNum IS NULL;


	IF(@FAC_APERTURA>='2.1.0')
		SELECT F.*
		FROM @FACS AS F
		INNER JOIN dbo.facTotales AS T
		ON  F.facCod = T.fctCod
		AND F.facPerCod= T.fctPerCod
		AND F.facCtrCod = T.fctCtrCod
		AND F.facVersion = T.fctVersion
		AND T.fctDeuda>0;
	ELSE
		SELECT F.*
		FROM @FACS AS F
		INNER JOIN dbo.fFacturas_TotalFacturado(NULL, 0, NULL) AS FF 
		ON  FF.ftfFacCod	 = F.facCod
		AND FF.ftfFacPerCod	 = F.facPerCod
		AND FF.ftfFacVersion = F.facVersion
		AND FF.ftfFacCtrCod	 = F.facCtrCod													          																		  													          
		LEFT JOIN dbo.fFacturas_TotalCobrado(NULL) AS FC 
		ON  FC.ftcCtr	 = F.facCtrCod
		AND FC.ftcFacCod = F.facCod
		AND FC.ftcPer	 = F.facPerCod
		WHERE ISNULL((ftfImporte), 0) > ISNULL((ftcImporte), 0);
GO


