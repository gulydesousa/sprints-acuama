
ALTER PROCEDURE [dbo].[RemesasTrab_ObtenerTotales] 
@remUsrCod VARCHAR(10) = NULL,
@remTskType SMALLINT = NULL,
@remTskNumber INT = NULL,
--**************************************
@totalFacturado DECIMAL(16,2) = 0 OUT,
@totalPagado DECIMAL(16,2) = 0 OUT,
@totalRemesar DECIMAL(16,2) = 0 OUT

AS 
	SET NOCOUNT ON; 

	--Si uno de los dos ids de la tarea son nulo
	IF(@remTskType IS NULL OR @remTskNumber IS NULL)
		SELECT @remTskType=NULL, @remTskNumber=NULL;

	SELECT @totalFacturado = ISNULL(SUM([remFacTotal]) ,0)
      ,@totalPagado = ISNULL(SUM([remPagado]), 0)
      ,@totalRemesar = ISNULL(SUM(ISNULL(efePdteImporte, remFacTotal - remPagado)), 0)
	FROM dbo.remesasTrab AS R
	LEFT JOIN efectosPendientes ON efePdteCod = remEfePdteCod AND efePdteCtrCod = remCtrCod AND efePdteFacCod = remFacCod AND efePdtePerCod = remPerCod AND efePdteScd = remSerScdCod
	WHERE (remUsrCod = @remUsrCod OR @remUsrCod IS NULL) 
	--Filtrar por tarea o pendientes de enviar por tarea
	 AND ((@remTskType IS NULL AND R.remTskType IS NULL)OR 
		  (R.remTskType=@remTskType AND R.remTskNumber = @remTskNumber))

GO


