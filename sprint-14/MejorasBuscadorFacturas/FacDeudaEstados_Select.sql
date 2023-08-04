--EXEC FacDeudaEstados_Select @codigo=1
CREATE PROCEDURE FacDeudaEstados_Select 
@codigo TINYINT = NULL
AS

SELECT E.fdeCod
, E.fdeDescripcion
, E.fdeCondicion
, fdeToolTip = REPLACE(REPLACE(E.fdeCondicion, 'T.fct', '') , 'AND', '&')
FROM dbo.facDeudaEstados AS E
WHERE (@codigo IS NULL OR E.fdeCod=@codigo)
ORDER BY E.fdeCod;

GO