CREATE PROCEDURE [dbo].[CobLinEfectosPendientes_ObtenerEfectosPendientes]
  @cleCblScd SMALLINT
, @cleCblPpag SMALLINT 
, @cleCblNum INT 
, @cleCblLin SMALLINT 
AS
	SET NOCOUNT OFF;

	SELECT EP.* 
	, C.cleCblScd
	, C.cleCblPpag
	, C.cleCblNum
	, C.cleCblLin
	FROM cobLinEfectosPendientes AS C
	INNER JOIN dbo.efectosPendientes AS EP
	ON  EP.efePdteCod	 = C.clefePdteCod
	AND EP.efePdteCtrCod = C.clefePdteCtrCod
	AND EP.efePdtePerCod = C.clefePdtePerCod
	AND EP.efePdteFacCod = C.clefePdteFacCod
	AND EP.efePdteScd	= C.clefePdteScd
	WHERE C.cleCblScd  = @cleCblScd
	  AND C.cleCblPpag = @cleCblPpag
	  AND C.cleCblNum  = @cleCblNum
	  AND C.cleCblLin  = @cleCblLin;
	
GO


