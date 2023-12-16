--SELECT a= [ReportingServices].[fnDescripcionOrigenes] ('CCMASIVO, CCCONTRATO, ANY')

CREATE FUNCTION [ReportingServices].[fnDescripcionOrigenes](@origenesOT VARCHAR(500))
RETURNS VARCHAR(250)
BEGIN


DECLARE @Names VARCHAR(MAX);

WITH ORIGENES AS(
SELECT  ottoDescripcion
FROM   otTiposOrigen AS O
INNER JOIN dbo.parametros AS P
ON P.pgsclave = 'OT_TIPO_CC'
AND P.pgsvalor = O.ottoCodigo
INNER JOIN dbo.Split(@origenesOT, ',') AS X
ON X.value = O.ottoOrigen)

SELECT @Names = COALESCE(@Names + ', ', '') + ottoDescripcion
FROM ORIGENES;

RETURN @Names;

END
