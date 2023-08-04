--EXEC ReportingServices.PeriodosTextoLegal '202102'

CREATE PROCEDURE ReportingServices.PeriodosTextoLegal
@periodo AS VARCHAR(6) = NULL
AS
SET NOCOUNT ON

SELECT  P.*
, PP.pgsClave 
, PP.pgsValor
, [TextoLegal] = IIF(P.perTextoLegalAbv IS NULL OR P.perTextoLegalAbv=''
	           , ISNULL(PP.pgsValor, '')
			   , P.perTextoLegalAbv)
FROM dbo.periodos AS P
LEFT JOIN dbo.parametros AS PP
ON PP.pgsClave ='TLEGAL' 
WHERE @periodo IS NULL OR p.perCod=@periodo 

GO