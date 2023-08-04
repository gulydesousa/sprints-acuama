
DELETE dbo.ExcelConsultas WHERE exccod='RPT/101'

INSERT INTO dbo.ExcelConsultas VALUES
('RPT/101'
, 'Inf.Lecturas Detallado'
, 'Informe de Lecturas Detallado'
, 101
, '[InformesExcel].[CL018_InformeLecturas]'
, 'CSV'
, 'CL018_InformeLecturas'
, NULL, NULL, NULL, NULL);

SELECT * FROM errorlog WHERE erlfecha>='20221130 18:00:00'  ORDER BY erlfecha DESC


/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_error_out INT;
DECLARE @p_errMsg_out   NVARCHAR(MAX);

SET @p_params= '<NodoXML><LI><periodoD>202201</periodoD><periodoH>202202</periodoH>
						<contratista></contratista>
						<empleadoD></empleadoD><empleadoH></empleadoH>
						<fechaD></fechaD><fechaH></fechaH>
						<zonaD></zonaD><zonaH></zonaH>
						</LI></NodoXML>'

EXEC [InformesExcel].[CL018_InformeLecturas] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;

*/
