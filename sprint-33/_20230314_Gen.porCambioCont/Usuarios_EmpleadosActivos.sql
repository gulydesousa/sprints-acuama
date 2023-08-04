ALTER PROCEDURE dbo.Usuarios_EmpleadosActivos
AS

SELECT U.*, E.eplnom
FROM usuarios AS U
INNER JOIN empleados AS E
ON E.eplcod = U.usreplcod
AND E.eplcttcod = U.usreplcttcod
AND (U.usrFechaBaja IS NULL OR U.usrFechaBaja>dbo.GetAcuamaDate())
AND usrprfcod NOT IN('root', 'CAM')
ORDER BY TRIM(E.eplnom)
GO


--SELECT * FROM empleados