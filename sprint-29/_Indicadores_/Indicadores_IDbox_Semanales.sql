

ALTER PROCEDURE [InformesExcel].[Indicadores_IDbox_Semanales]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS
	
	SET @p_params= REPLACE( @p_params, '</LI></NodoXML>', '<Frecuencia>S</Frecuencia></LI></NodoXML>');
	
	EXEC [InformesExcel].[Indicadores_IDbox] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
	
GO


