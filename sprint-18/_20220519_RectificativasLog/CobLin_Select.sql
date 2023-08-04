ALTER PROCEDURE [dbo].[CobLin_Select] 
@cblScd smallint = NULL,
@cblPpag smallint = NULL,
@cblNum int = NULL,
@cblLin smallint=NULL,
@cblFacCod smallint = NULL,
@cblPer varchar(6) = NULL,
@contratoCodigo int = NULL,
@cblFacVersion smallint = NULL

AS 
	SET NOCOUNT ON; 


	SELECT [cblScd]
		  ,[cblPpag]
		  ,[cblNum]
		  ,[cblLin]
		  ,[cblFacCod]
		  ,[cblPer]
		  ,[cblFacVersion]
		  ,[cblImporte]
	FROM dbo.cobros AS C
	INNER JOIN dbo.coblin AS CL
	ON  C.cobScd = CL.cblScd
	AND C.cobPpag = CL.cblPpag
	AND C.cobNum = CL.cblNum
	AND (@cblScd IS NULL  OR CL.cblScd=@cblScd)
	AND (@cblPpag IS NULL OR CL.cblPpag=@cblPpag)
	AND (@cblNum IS NULL  OR cblNum=@cblNum)
	AND (@cblLin IS NULL  OR cblLin=@cblLin)
	AND (@contratoCodigo IS NULL OR C.cobCtr = @contratoCodigo)
	AND (@cblPer IS NULL OR CL.cblPer = @cblPer)
	AND (@cblFacCod IS NULL OR CL.cblFacCod = @cblFacCod)
	AND (@cblFacVersion IS NULL OR CL.cblFacVersion=@cblFacVersion)
	ORDER BY [cblScd]
		  ,[cblPpag]
		  ,[cblNum]
		  ,[cblLin]
	OPTION(RECOMPILE);

	/*
	SELECT [cblScd]
      ,[cblPpag]
      ,[cblNum]
      ,[cblLin]
      ,[cblFacCod]
      ,[cblPer]
      ,[cblFacVersion]
      ,[cblImporte]
	FROM [coblin]
	WHERE 
		(cblScd=@cblScd OR @cblScd IS NULL)
	AND (cblPpag=@cblPpag OR @cblPpag IS NULL)
	AND (cblNum=@cblNum OR @cblNum IS NULL)
	AND (cblLin=@cblLin OR @cblLin IS NULL)
	AND ((@cblFacCod IS NULL OR @cblPer IS NULL OR @contratoCodigo IS NULL OR @cblFacVersion IS NULL)
		  OR
		  (EXISTS(SELECT cobScd 
						 FROM cobros 
						 WHERE cblScd = cobScd AND cblPpag = cobPpag AND cblNum = cobNum AND
							   cobCtr = @contratoCodigo AND 
							   cblPer = @cblPer AND
							   cblFacCod = @cblFacCod AND
							   cblFacVersion = @cblFacVersion
				  )
		  ) 
		)
	ORDER BY cblLin
	*/

GO


