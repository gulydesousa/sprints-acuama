CREATE PROCEDURE [dbo].[CobLin_ActualizarImporte]
(
	  @cblScd smallint
     ,@cblPpag smallint
     ,@cblNum int
     ,@cblLin smallint
     ,@cblFacCod smallint
     ,@cblPer varchar(6)
     ,@cblFacVersion SMALLINT = NULL
     ,@cblImporte money
)
AS
	SET NOCOUNT OFF;

	UPDATE dbo.coblin SET [cblImporte] = @cblImporte 
	WHERE (cblScd = @cblScd AND cblPpag=@cblPpag AND cblNum=@cblNum AND cblLin=@cblLin );
 
	RETURN @@ERROR

GO


