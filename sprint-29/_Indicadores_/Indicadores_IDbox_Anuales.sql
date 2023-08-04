

ALTER PROCEDURE [InformesExcel].[Indicadores_IDbox_Anuales]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS
	
	DECLARE @xml AS XML = @p_params;
	DECLARE @fecha DATE;
	--**************************************************
	--Necesitamos transformar la fecha para que el informe saque los indicadores del mes en la fecha solicitada
	SELECT @fecha	= CASE WHEN M.Item.value('Fecha[1]', 'DATE') = '19000101' THEN dbo.GetAcuamaDate()
					  ELSE M.Item.value('Fecha[1]', 'DATE') END		 
	FROM @xml.nodes('NodoXML/LI')AS M(Item);


	DECLARE @param NVARCHAR(MAX) = '<NodoXML><LI><Fecha>%s</Fecha><Frecuencia>A</Frecuencia></LI></NodoXML>';
	
	SET @p_params=  FORMATMESSAGE(@param, FORMAT(@fecha, 'yyyMMdd'));
	--SELECT @p_params
	--**************************************************
	
	EXEC [InformesExcel].[Indicadores_IDbox] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;

GO


