/*
DECLARE @cliCod INT = NULL
DECLARE @ctrCod INT = 83

EXEC Facturas_SelectFraccionadasPendientes @cliCod, @ctrCod
*/

CREATE PROCEDURE [dbo].[Facturas_SelectFraccionadasPendientes] 
  @cliCod INT = NULL
, @ctrCod INT = NULL
	
AS

	SET NOCOUNT ON;
	
	DECLARE @FACS AS [dbo].[tFacturasPK];
	DECLARE @FAC_APERTURA AS VARCHAR(10) = '1.0.0';

	SELECT @FAC_APERTURA = P.pgsvalor 
	FROM dbo.parametros AS P 
	WHERE P.pgsclave='FAC_APERTURA';

	--Facturas con efectos pendientes no domiciliados pendientes de cobro.
	INSERT INTO @FACS(facCod, facPerCod, facCtrCod, facVersion)
	
	SELECT DISTINCT
	F.facCod, F.facPerCod, F.facCtrCod, F.facVersion
	FROM dbo.facturas AS F
	
	INNER JOIN dbo.efectosPendientes AS E
	ON  F.facCod	= E.efePdteFacCod
	AND F.facPerCod = E.efePdtePerCod
	AND F.facCtrCod = E.efePdteCtrCod
	AND F.facFechaRectif IS NULL
	--************************
	AND F.facSerScdCod IS NOT NULL	
	AND F.facSerScdCod = E.efePdteScd 
	--************************	
	AND F.facSerCod IS NOT NULL
	AND F.facNumero IS NOT NULL
	AND E.efePdteFecRechazado IS NULL
	AND E.efePdteDomiciliado = 0
	AND (@cliCod IS NULL OR F.facClicod = @cliCod)	
	AND (@ctrCod IS NULL OR F.facCtrCod = @ctrCod)	
	AND COALESCE(@cliCod, @ctrCod) IS NOT NULL

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