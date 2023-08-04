/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI><Fecha>20221205</Fecha></LI></NodoXML>';


EXEC [InformesExcel].[Indicadores_IDbox_Afecha] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;

*/



ALTER PROCEDURE [InformesExcel].[Indicadores_IDbox_Afecha]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS

	SET @p_params= REPLACE( @p_params, '</LI></NodoXML>', '<Frecuencia>F</Frecuencia></LI></NodoXML>');

	EXEC [InformesExcel].[Indicadores_IDbox] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
	
GO


