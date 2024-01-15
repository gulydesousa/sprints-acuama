
--DROP PROCEDURE [InformesExcel].[ResumenGestionesxFechaLectura_MELILLA]
--SELECT * FROM ExcelConsultas
--DELETE FROM ExcelPerfil WHERE ExPCod IN ('100/002', '100/102')
--DELETE FROM dbo.ExcelConsultas WHERE ExcCod IN ('100/002', '100/102')

INSERT INTO dbo.ExcelConsultas VALUES ('100/002','Resumen gestión fechas', 'Melilla: Resumen de gestiones por fechas', 11, '[InformesExcel].[ResumenGestionesPorFechas_MELILLA]', 'CSV+', 
'<table><tr><td width="50px"><b>Bajas:</b></td><td>CONTAR(conSvcBaja=1)</td><td>&nbsp;&nbsp;</td>
<td><b>Altas: </b></td><td>conTrfContratacion=1 => SUMA(udsContratacion)</td></tr>
<tr><td colspan="5"></td></tr>
<tr><td><b>Cambio Titular:</b></td><td>CONTAR(conTrfCambioTitular=1)</td><td>&nbsp;&nbsp;</td>
<td><b>Reenganches:</b></td><td>conTrfReenganche=1 => SUMA(udsReenganche)</td></tr></table>', NULL, NULL, NULL, NULL);

INSERT INTO ExcelPerfil VALUES('100/002', 'root', 4, NULL)
INSERT INTO ExcelPerfil VALUES('100/002', 'direcc', 4, NULL)

/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);
SET @p_params='<NodoXML><LI><fechaD>20221201</fechaD><fechaH>20221231</fechaH><zonaD></zonaD><zonaH></zonaH></LI></NodoXML>'

EXEC [InformesExcel].[ResumenGestionesPorFechas_MELILLA] @p_params, @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/
