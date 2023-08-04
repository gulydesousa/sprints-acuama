ALTER PROCEDURE [dbo].[CobLinDes_Select]
	 @cldCblScd SMALLINT = NULL
	,@cldCblPpag SMALLINT = NULL
	,@cldCblNum INT = NULL
	,@cldCblLin SMALLINT = NULL
	,@cldFacLin INT = NULL
	,@cldTrfSrvCod SMALLINT = NULL
	,@cldTrfCod SMALLINT = NULL
	,@cldImporte MONEY = NULL
AS
	SET NOCOUNT OFF;

    SELECT cldCblScd
		  ,cldCblPpag
		  ,cldCblNum
		  ,cldCblLin
		  ,cldFacLin
		  ,cldTrfSrvCod
		  ,cldTrfCod
		  ,cldImporte
    FROM dbo.cobLinDes AS CL WITH (INDEX(PK_cobLinDes))
    WHERE (@cldCblScd IS NULL OR @cldCblScd=cldCblScd)
	AND (@cldCblPpag IS NULL OR @cldCblPpag=cldCblPpag)
	AND (@cldCblNum IS NULL OR @cldCblNum=cldCblNum)
	AND (@cldCblLin IS NULL OR @cldCblLin=cldCblLin)
	AND (@cldFacLin IS NULL OR @cldFacLin=cldFacLin)
	AND (@cldTrfSrvCod IS NULL OR @cldTrfSrvCod=cldTrfSrvCod)
	AND (@cldTrfCod IS NULL OR @cldTrfCod=cldTrfCod)
	AND (@cldImporte IS NULL OR @cldImporte=cldImporte)

	OPTION(RECOMPILE);


	  
GO


