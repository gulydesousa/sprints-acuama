ALTER PROCEDURE [dbo].[RepLegal_SelectAutoCompletar] 
@filtro VARCHAR(500) = NULL
AS SET NOCOUNT ON; 
	
DECLARE @sql VARCHAR(MAX);

SET @sql=('SELECT DISTINCT clinom AS cliDatos
	FROM  clientes
	INNER JOIN contratos ON clinom = ctrRepresent
	WHERE ctrRepresent IS NOT NULL AND dbo.SimplificarTexto(clinom) LIKE ''%' + dbo.SimplificarTexto(@filtro) + '%'' ORDER BY clinom ASC'
)

EXEC(@sql)

GO
