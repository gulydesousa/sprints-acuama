/*
DECLARE @Inspeccion AS INT = 1;
EXEC otInspeccionesHijos_Obtener @Inspeccion
*/

ALTER PROCEDURE dbo.otInspeccionesContratos_Melilla_Obtener(@Inspeccion AS INT)
AS

SELECT * 
FROM otInspeccionesContratos_Melilla AS O
WHERE O.INSPECCION = @Inspeccion;

GO