CREATE PROCEDURE dbo.Task_Parameters_UpdateLog
  @tskLog AS dbo.tLog READONLY
, @tskUser VARCHAR(10)	
, @tskType SMALLINT
, @tskNumber INT
AS
SET NOCOUNT ON;


UPDATE T
SET tskpValue=NULL
  , tskpExtraLargeValue = 
	'__;TIPO;CLAVE;VALOR;MENSAJE;FECHA' + CHAR(10)+
	(
	SELECT CONCAT(CAST(iLog AS VARCHAR) , ';' 
		 , typeLog , ';' 
		 , keyLog , ';' 
		 , valueLog , ';' 
		 , msgLog, ';' 
		 , CONVERT(VARCHAR, keyDate, 120) 
		 , CHAR(10)) 
	AS 'data()' 
	FROM @tskLog 
	ORDER BY iLog 
	FOR XML PATH(''))
FROM [dbo].[Task_Parameters] AS T
WHERE [tskpUser] = @tskUser 
  AND [tskpType] = @tskType 
  AND [tskpNumber] = @tskNumber 
  AND [tskpName]   = 'log';

GO

