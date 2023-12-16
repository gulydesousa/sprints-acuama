/*
DECLARE @otiserscd SMALLINT = 1;
DECLARE @otisercod SMALLINT = 80;
DECLARE @otinum INT = 85488;
EXEC otInspecciones_Obtener @otiserscd, @otisercod,  @otinum
*/

ALTER PROCEDURE dbo.otInspecciones_Melilla_Obtener(@otiserscd SMALLINT, @otisercod SMALLINT, @otinum INT)
AS

SELECT * 
FROM dbo.otInspecciones_Melilla
WHERE otiserscd=@otiserscd
AND otisercod = @otisercod
AND otinum = @otinum;

GO