ALTER PROCEDURE [dbo].[Cobros_SelectRectificativos]
@cobScd smallint = NULL,
@cobctr int = NULL,
@cblPerCod varchar(6) = NULL,
@cblFacCod SMALLINT = NULL

AS 
	SET NOCOUNT ON; 

	SELECT cobScd, 
		cobPpag, 
		cobCtr, 
		SUM(cblImporte) as cobImporte
	
	FROM dbo.cobros AS C 
	INNER JOIN dbo.coblin AS CL 
	ON  CL.cblScd = C.cobScd 
	AND CL.cblPpag = C.cobPpag 
	AND CL.cblNum = C.cobNum

	WHERE(@cobScd IS NULL	 OR C.cobScd=@cobScd) AND 
		 (@cobctr IS NULL	 OR C.cobCtr=@cobctr) AND
		 (@cblPerCod IS NULL OR CL.cblPer = @cblPerCod) AND
		 (@cblFacCod IS NULL OR CL.cblFacCod = @cblFacCod)

	GROUP BY C.cobScd, C.cobPpag, C.cobCtr
	HAVING SUM(CL.cblImporte) <> 0
	ORDER BY MIN(C.cobFecReg) ASC
	OPTION(RECOMPILE);

GO


