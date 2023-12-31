
--SELECT * FROM [Indicadores].[fUsuariosActivosOV] ('20220101', '20220131')

CREATE FUNCTION [Indicadores].[fUsuariosActivosOV]
( @fDesde DATE
, @fHasta DATE
)
RETURNS TABLE
AS
RETURN(

SELECT DISTINCT usrLogin 
FROM dbo.online_Usuarios AS OU 
INNER JOIN dbo.contratos AS CC 
ON OU.usrLogin = CC.ctrTitDocIden 
OR OU.usrLogin = CC.ctrPagDocIden
WHERE CC.ctrversion = (SELECT MAX(c.ctrversion) FROM dbo.contratos AS C WHERE C.ctrcod = CC.ctrcod)
 AND (CC.ctrFecSolBaja IS NULL OR (CC.ctrFecSolBaja >=@fDesde AND CC.ctrFecSolBaja < @fHasta))



)
GO
