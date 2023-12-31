
--SELECT * FROM [Indicadores].[fMediaRespuestasReclamaciones]('20220101', '20230101', 'RS')

ALTER FUNCTION [Indicadores].[fMediaRespuestasReclamaciones]
( @fDesde DATE
, @fHasta DATE
, @rclGRecCod VARCHAR(4)
)
RETURNS TABLE
AS
RETURN(

SELECT media = AVG(DATEDIFF(DAY, rclFecReg, rclFecCierre) + 0.00)
FROM dbo.reclamaciones AS R 
WHERE R.rclFecCierre IS NOT NULL
  AND R.rclFecReclama >=@fDesde 
  AND R.rclFecReclama <@fHasta
  AND (@rclGRecCod IS NULL OR @rclGRecCod='' OR rclGRecCod=@rclGRecCod)

)
GO
