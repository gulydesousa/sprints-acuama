--EXEC ContadorCambio_ObtenerUltimasLecturas 32074


ALTER PROCEDURE ContadorCambio_ObtenerUltimasLecturas(@ctrCod int)
AS
	SELECT *
	FROM dbo.vContratosUltimasLecturas AS L
	WHERE ctrcod= @ctrCod
	ORDER BY RN;
GO

