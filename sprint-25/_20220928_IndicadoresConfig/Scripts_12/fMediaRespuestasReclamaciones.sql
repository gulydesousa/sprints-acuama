
--SELECT * FROM Indicadores.fContratos ('20220101', '20220131', NULL, 1)

CREATE FUNCTION [Indicadores].[fMediaRespuestasReclamaciones]
( @fDesde DATE
, @fHasta DATE
)
RETURNS TABLE
AS
RETURN(

select sum(datediff(D,rclFecReg, rclFecCierre))/count(*) as media from reclamaciones where rclGRecCod = 'RS'

and reclamaciones.rclFecReclama >=@fDesde and reclamaciones.rclFecReclama <@fHasta


)
GO
