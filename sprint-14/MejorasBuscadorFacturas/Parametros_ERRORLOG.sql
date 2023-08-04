--TRUNCATE TABLE ErrorLog
--EXEC Trabajo.Parametros_ERRORLOG 1


CREATE PROCEDURE Trabajo.Parametros_ERRORLOG(@valorON BIT)
AS
	SET NOCOUNT ON;

	DECLARE @CLAVE VARCHAR(25) = 'ERRORLOG';
	DECLARE @VALOR VARCHAR(25) = (SELECT pgsValor FROM dbo.parametros WHERE pgsclave = @CLAVE) ; 
 

	--[01]Actualizar el parametro
	DELETE FROM dbo.parametros WHERE pgsclave = @CLAVE;

	INSERT INTO dbo.parametros
	VALUES(@CLAVE, 'Habilitar/Deshabilitar inserción en [dbo].[errorLog] ON/OFF', 2, IIF(@valorON=1, 'ON', 'OFF'), 0, 1, 0);

	--[02]Borramos logs antiguos
	DELETE dbo.ErrorLog WHERE DATEDIFF(DAY, erlFecha, GETDATE()) > 15


	SELECT Clave = pgsclave, ValorAnterior=@VALOR, ValorActual=P.pgsValor, LogDesde = (SELECT MIN(erlFecha) FROM dbo.ErrorLog)
	FROM dbo.parametros AS P
	WHERE P.pgsclave = @CLAVE;
GO

