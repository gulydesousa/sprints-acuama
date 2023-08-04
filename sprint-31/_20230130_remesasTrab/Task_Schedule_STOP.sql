

ALTER PROCEDURE [dbo].[Task_Schedule_STOP] 
	@tskUser varchar(10),
	@tskType smallint,
	@tskNumber int
AS 
	SET NOCOUNT ON; 

	UPDATE [Task_Schedule]
	   SET [tskStop] = 1,
		   -- Si está en estado PARADO directamente ponemos estado CANCELADO, sino dejamos que el servicio windows se encargue de cancelarlo
		   [tskStatus] = CASE WHEN tskStatus = 1 THEN 3 ELSE tskStatus END  
	WHERE  tskUser = @tskUser AND tskType = @tskType AND tskNumber = @tskNumber;


	UPDATE T 
	SET T.remTskType=NULL, T.remTskNumber=NULL  
	FROM dbo.remesasTrab AS T
	WHERE T.remUsrCod=@tskUser 
	AND T.remTskType = @tskType
	AND T.remTskNumber = @tskNumber;
GO


