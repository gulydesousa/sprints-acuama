ALTER PROCEDURE [dbo].[Task_Schedule_SELECT] 
@tskUser AS VARCHAR(10) = NULL,
@tskType AS SMALLINT = NULL,
@tskNumber AS INT = NULL,
@tskStatus AS SMALLINT = NULL,
@tasksToExecute AS BIT = NULL, -- 0 ó NULL = Todas, 1 = Sólo tareas para ser ejecutadas ahora
@scheduledOrRunning AS BIT = NULL --1 = Sólo devuelve las tareas que están en ejecución o programadas. 0 ó NULL = Todas
AS 
	SET NOCOUNT ON; 
SELECT  top 100 [tskUser]
      ,[tskType]
	  ,[tskNumber]
      ,[tskStatus]
      ,[tskScheduledDate]
      ,[tskStartedDate]
      ,[tskFinishedDate]
      ,[tskStop]
	  ,[tskCreatedDate]
	  ,[tskPgrStep]
	  ,[tskPgrTotalSteps]
	  ,[tskErrorMsg]
 FROM dbo.[Task_Schedule] AS S WITH (NOLOCK)
 LEFT JOIN dbo.[Task_Progress] AS P WITH (NOLOCK) 
 ON  tskPgrUser = tskUser 
 AND tskPgrType = tskType 
 AND tskPgrNumber = tskNumber
LEFT JOIN dbo.Task_Types AS T  WITH (NOLOCK) 
ON S.tskType = T.tskTType
 WHERE (@tskUser IS NULL OR @tskUser = tskUser)
   AND (@tskType IS NULL OR @tskType = tskType)
   AND (@tskNumber IS NULL OR @tskNumber = tskNumber)
   AND (@tskStatus IS NULL OR @tskStatus = tskStatus)
   /*Sólo cogemos tareas que tengan parámetros, porque al tener el (NOLOCK) podría coger una tarea de la cual se acaba de insertar la cabecera, pero aún no tiene los parámetros*/
   AND (@tasksToExecute IS NULL OR @tasksToExecute = 0 OR (tskStatus = 1 AND tskScheduledDate <= GETDATE() AND T.tskTOverlapping = 1 AND EXISTS(SELECT tskpNumber FROM Task_Parameters WHERE tskUser = tskpUser AND tskType = tskpType AND tskNumber = tskpNumber)))
   AND (@scheduledOrRunning = 0 OR @scheduledOrRunning IS NULL OR (tskStatus = 2 OR (tskStatus = 1 AND tskScheduledDate IS NOT NULL AND tskStop = 0)))
ORDER BY tskScheduledDate DESC 
GO


