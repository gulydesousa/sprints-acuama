/*

DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI><FecDesde>20210427</FecDesde><FecHasta>20210727</FecHasta></LI></NodoXML>'

EXEC [InformesExcel].[CobradoxLinea_CanonSaneo_BIAR] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;


INSERT INTO dbo.ExcelConsultas
VALUES ('011/010',	'Cobrado en Canon Saneo', 'Cobrado en Canon Saneo (por fechas)', 1, '[InformesExcel].[CobradoxLinea_CanonSaneo_BIAR]', '001', 'Lista las facturas con cobros en un rango seleccionado de fechas y el total de su deuda actual para el servicio <b>CANON DE SANEO</b>');

INSERT INTO ExcelPerfil
VALUES('011/010', 'root', 5, NULL)

INSERT INTO ExcelPerfil
VALUES('011/010', 'jefeExp', 5, NULL)

INSERT INTO ExcelPerfil
VALUES('011/010', 'jefAdmon', 5, NULL)

INSERT INTO ExcelPerfil
VALUES('011/010', 'jefExplo', 5, NULL)

INSERT INTO ExcelPerfil
VALUES('011/010', 'comerc', 5, NULL);
*/


ALTER PROCEDURE [InformesExcel].[CobradoxLinea_CanonSaneo_BIAR]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS


SET @p_params= REPLACE(@p_params, '</FecHasta></LI></NodoXML>', '</FecHasta><svcCod>2</svcCod></LI></NodoXML>');

EXEC [InformesExcel].[CobradoxLinea_Servicio] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;

GO