CREATE PROCEDURE [dbo].[CobLinEfectosPendientes_Delete]
	 @cleCblScd SMALLINT = NULL
	,@cleCblPpag SMALLINT = NULL
	,@cleCblNum INT = NULL
	,@cleCblLin SMALLINT = NULL
	,@clefePdteCod INT = NULL
	,@clefePdteCtrCod INT = NULL
	,@clefePdtePerCod VARCHAR(6) = NULL
	,@clefePdteFacCod SMALLINT = NULL
	,@clefePdteScd SMALLINT = NULL

AS
	SET NOCOUNT OFF;

    DELETE FROM cobLinEfectosPendientes
    WHERE (@cleCblScd IS NULL OR @cleCblScd=cleCblScd)
	  AND (@cleCblPpag IS NULL OR @cleCblPpag=cleCblPpag)
	  AND (@cleCblNum IS NULL OR @cleCblNum=cleCblNum)
	  AND (@cleCblLin IS NULL OR @cleCblLin=cleCblLin)
	  AND (@clefePdteCod IS NULL OR @clefePdteCod=clefePdteCod)
	  AND (@clefePdteCtrCod IS NULL OR @clefePdteCtrCod=clefePdteCtrCod)
	  AND (@clefePdtePerCod IS NULL OR @clefePdtePerCod=clefePdtePerCod)
	  AND (@clefePdteFacCod IS NULL OR @clefePdteFacCod=clefePdteFacCod)
	  AND (@clefePdteScd IS NULL OR @clefePdteScd=clefePdteScd);
GO