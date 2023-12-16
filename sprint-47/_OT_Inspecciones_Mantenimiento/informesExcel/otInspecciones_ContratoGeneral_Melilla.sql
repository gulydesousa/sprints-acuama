/*


INSERT INTO dbo.ExcelConsultas
VALUES ('000/013',	'Inspecciones: Aptas', 'Para comprobar el estado de las inspecciones de Melilla', 0, '[InformesExcel].[otInspecciones_ContratoGeneral_Melilla]', '000', 'Para comprobar el estado de las inspecciones cargadas.', NULL, NULL, NULL, NULL);

INSERT INTO ExcelPerfil
VALUES('000/013', 'root', 6, NULL)

--DELETE FROM  ExcelPerfil WHERE ExpCod='000/013'
--DELETE FROM dbo.ExcelConsultas WHERE ExcCod='000/013'


*/


/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI><Fecha></Fecha></LI></NodoXML>';


EXEC [InformesExcel].[otInspecciones_ContratoGeneral_Melilla] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/

CREATE PROCEDURE [InformesExcel].[otInspecciones_ContratoGeneral_Melilla]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS
	SET @p_params= '<NodoXML><LI><Fecha></Fecha></LI></NodoXML>';


	EXEC [InformesExcel].[otInspecciones_ContratoGeneralPorFechaActualizacion_Melilla] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;

GO






