

--CREATE SCHEMA Trabajo
ALTER PROCEDURE [Trabajo].[errorLog_Insert]
  @spName VARCHAR(100) = ''
, @spParams VARCHAR(500) = ''
, @spMessage VARCHAR(4000) = ''
, @checkON BIT = 1
AS
INSERT INTO [dbo].[errorLog]([erlExplotacion], [erlProcedure], [erlParams], [erlMessage], [erlFecha])
SELECT E.pgsvalor AS explotacion
	, @spName AS spName
	, @spParams AS spParams
	, @spMessage AS spMessage
	, GETDATE() AS spFecha
FROM dbo.parametros AS X
LEFT JOIN dbo.parametros AS E
ON  E.pgsclave='EXPLOTACION'
WHERE X.pgsclave='ERRORLOG' 
AND (@checkON = 0 OR X.pgsvalor='ON')
GO


