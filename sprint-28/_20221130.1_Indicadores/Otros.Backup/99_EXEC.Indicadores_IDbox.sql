DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI><Fecha>20221113</Fecha><Semanas></Semanas></LI></NodoXML>';

EXEC [InformesExcel].[Indicadores_IDbox] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
