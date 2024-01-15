
--SELECT * FROM Trabajo.ExcelConsultas_Plantillas
--SELECT * FROM ExcelConsultas
--DELETE FROM ExcelPerfil WHERE ExPCod='000/015'
--DELETE FROM dbo.ExcelConsultas WHERE ExcCod='000/015'

INSERT INTO dbo.ExcelConsultas VALUES ('000/015','Padrón x F.Lectura', 'Padrón por fecha de lecturas', 11, '[InformesExcel].[PadronxFechaLectura_EXCEL]', 'CSVH', 'Padrón por fecha de lectura', NULL, NULL, NULL, NULL);
INSERT INTO ExcelPerfil VALUES('000/015', 'root', 4, NULL)
INSERT INTO ExcelPerfil VALUES('000/015', 'direcc', 4, NULL)



/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_error_out INT;
DECLARE @p_errMsg_out   NVARCHAR(MAX);

SET @p_params='<NodoXML><LI><fechaD>20221201</fechaD><fechaH>20221231</fechaH><zonaD></zonaD><zonaH></zonaH></LI></NodoXML>'

EXEC [InformesExcel].[PadronxFechaLectura_EXCEL] @p_params, @p_error_out OUTPUT, @p_errMsg_out OUTPUT;
*/