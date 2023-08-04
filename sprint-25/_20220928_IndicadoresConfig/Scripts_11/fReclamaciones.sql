--SELECT * FROM Indicadores.fReclamaciones ('20220101', '20220131', '11')

CREATE FUNCTION Indicadores.fReclamaciones
( @fDesde DATE
, @fHasta DATE
, @greclamacion VARCHAR(4) = NULL)
RETURNS TABLE
AS
RETURN(

SELECT R.rclCod, R.rclGRecCod
FROM dbo.reclamaciones AS R
WHERE R.rclFecReclama >= @fDesde AND R.rclFecReclama<@fHasta
AND (@greclamacion IS NULL OR R.rclGRecCod = @greclamacion)
)
GO

