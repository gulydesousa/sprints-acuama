
/*
****** CONFIGURACION ******

INSERT INTO dbo.ExcelConsultas
VALUES ('006/005',	'Liquidaciones RSU', 'Liquidaciones RSU (SORIA)', 12, '[InformesExcel].[LiquidacionesRSUxPeriodo_SORIA]', '005', 'SORIA: Liquidaciones de RSU por periodo de facturación');

INSERT INTO ExcelPerfil
VALUES('006/005', 'root', 4, NULL)

INSERT INTO ExcelPerfil
VALUES('006/005', 'jefeExp', 4, NULL)

INSERT INTO ExcelPerfil
VALUES('006/005', 'jefAdmon', 4, NULL)


--DELETE ExcelPerfil WHERE ExPCod='RIBA/001'
--DELETE ExcelConsultas WHERE ExcCod='RIBA/001'

*/


/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_error_out INT;
DECLARE @p_errMsg_out   NVARCHAR(MAX);

SET @p_params= '<NodoXML><LI><periodoD>201801</periodoD><periodoH>201812</periodoH></LI></NodoXML>'
EXEC [InformesExcel].[LiquidacionesRSUxPeriodo_SORIA] @p_params, @p_error_out OUTPUT, @p_errMsg_out OUTPUT;
*/

ALTER PROCEDURE [InformesExcel].[LiquidacionesRSUxPeriodo_SORIA]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS
	SET NOCOUNT ON;  
	

	SET @p_params = REPLACE(@p_params, '</LI>', '<Servicio>3</Servicio></LI>');

	EXEC [InformesExcel].[LiquidacionesServicioxPeriodo] @p_params, @p_errId_out, @p_errMsg_out;

GO