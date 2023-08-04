--SELECT * FROM [Indicadores].[fUsuariosActivosOV] ('20220101', '20220131')

ALTER FUNCTION [Indicadores].[fUsuariosActivosOV]
( @fDesde DATE
, @fHasta DATE
)
RETURNS TABLE
AS
RETURN(

WITH CTR AS(
SELECT ctrCod, ctrVersion
, ctrTitDocIden = RTRIM(LTRIM(ISNULL(ctrTitDocIden, '')))
, ctrPagDocIden = RTRIM(LTRIM(ISNULL(ctrPagDocIden, '')))
--RN=1: Para la última versión del contrato
, RN= ROW_NUMBER() OVER (PARTITION BY ctrCod ORDER BY ctrVersion DESC)
FROM dbo.contratos AS C
WHERE C.ctrfecreg < DATEADD(DAY, 1, @fDesde) 
 AND (C.ctrfecanu IS NULL OR C.ctrfecanu < @fDesde)

), DOCS AS(
--Combinaciones de titulares y pagadores en la ultima version de contrato
SELECT DISTINCT ctrTitDocIden = RTRIM(LTRIM(ISNULL(ctrTitDocIden, '')))
              , ctrPagDocIden = RTRIM(LTRIM(ISNULL(ctrPagDocIden, '')))
FROM CTR AS C 
WHERE RN=1

), DOCIDEN AS(
--Documentos de identidad diferentes bien sea titular o pagador en los contratos
SELECT DISTINCT id= ctrTitDocIden FROM DOCS
UNION 
SELECT DISTINCT id = ctrPagDocIden FROM DOCS
)


--Usuarios de la OV que aparecen como titular o pagador en algun contrato activo en el rango de fechas
SELECT usrLogin
FROM dbo.online_Usuarios AS U
INNER JOIN DOCIDEN AS D
ON D.id = U.usrLogin

)
GO


