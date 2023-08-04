CREATE PROCEDURE [dbo].[Cobros_SelectRectificativos]
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
	INNER JOIN coblin ON cblScd = cobScd AND cblPpag = cobPpag AND cblNum = cobNum
	WHERE (cobScd=@cobScd OR @cobScd IS NULL) AND 
			(cobCtr=@cobctr OR @cobctr IS NULL) AND
			(@cblPerCod IS NULL OR cblPer = @cblPerCod) AND
			(@cblFacCod IS NULL OR cblFacCod = @cblFacCod)
	GROUP BY cobScd, cobPpag, cobCtr
	HAVING SUM(cblImporte) <> 0
	ORDER BY MIN(C.cobFecReg) ASC;

GO


