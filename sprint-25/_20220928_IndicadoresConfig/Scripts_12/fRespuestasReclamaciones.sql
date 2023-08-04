
--SELECT * FROM greclamacion
--SELECT [VALOR] = AVG(dRespuesta) FROM [Indicadores].[fRespuestasReclamaciones]('20220101', '20221201', @RECLAMACION) WHERE rclFecCierre IS NOT NULL

CREATE FUNCTION [Indicadores].[fRespuestasReclamaciones]
( @fDesde DATE
, @fHasta DATE
, @rclGRecCod VARCHAR(4)
)
RETURNS TABLE
AS
RETURN(

SELECT rclCod, rclGRecCod, rclFecReg, rclFecCierre, dRespuesta = DATEDIFF(DAY, rclFecReg, rclFecCierre) + 0.00
FROM dbo.reclamaciones AS R 
WHERE R.rclFecReclama >=@fDesde 
  AND R.rclFecReclama <@fHasta
  AND (@rclGRecCod IS NULL OR @rclGRecCod='' OR rclGRecCod=@rclGRecCod)

)
GO


