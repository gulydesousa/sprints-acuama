/*
exec otInspeccionesValidaciones_Select @columna='',@descripcion='',@descripcionCarta='',@reqReglamentoCTE=1
*/

CREATE PROCEDURE dbo.otInspeccionesValidaciones_Select
@servicioCod INT = NULL,
@columna VARCHAR(128) = NULL,
@esCritica BIT = NULL,
@reqReglamentoCTE BIT = NULL,
@orden TINYINT = NULL,
@descripcion VARCHAR(250) = NULL,
@descripcionCarta VARCHAR(250) = NULL
AS
SET NOCOUNT ON;

SET @descripcion = UPPER(CONCAT('%', LTRIM(RTRIM(@descripcion)), '%'));
SET @descripcionCarta = UPPER(CONCAT('%', LTRIM(RTRIM(@descripcionCarta)), '%'));

SELECT I.*, S.*
FROM dbo.otInspeccionesValidaciones AS I
LEFT JOIN dbo.otInspeccionesServicios AS S
ON S.otisCod = I.otivServicioCod
WHERE (@servicioCod IS NULL OR I.otivServicioCod=@servicioCod)
AND (@columna IS NULL OR @columna='' OR I.otivColumna LIKE @columna)
AND (@esCritica IS NULL OR I.otivCritica=@esCritica)
AND (@reqReglamentoCTE IS NULL OR I.otivReqReglamentoCTE=@reqReglamentoCTE)
AND (@orden IS NULL OR I.otivOrden>=@orden)
AND (@descripcion IS NULL OR UPPER(ISNULL(I.otivDesc, '')) LIKE @descripcion)
AND (@descripcionCarta IS NULL OR UPPER(ISNULL(I.otivDescParaCartas, '')) LIKE @descripcionCarta)

ORDER BY S.otisDescripcion, I.otivColumna, IIF(I.otivCritica=1, 0, 1);

GO