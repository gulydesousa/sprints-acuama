
/*
****** CONFIGURACION ******
--DELETE FROM excelConsultas WHERE ExcCod='000/102'
--DELETE FROM ExcelPerfil WHERE ExPCod='000/102'

--SELECT * FROM excelConsultas

INSERT INTO dbo.ExcelConsultas
VALUES ('000/102',	'Facturas-cabeceras-', 'Facturas (cabeceras)', 12, '[InformesExcel].[FacturasCabecera]', 'CSVH', 'Selección de todas las cabeceras de facturas por periodo.');

INSERT INTO ExcelPerfil
VALUES('000/102', 'root', 4, NULL)

INSERT INTO ExcelPerfil
VALUES('000/102', 'jefeExp', 4, NULL)

INSERT INTO ExcelPerfil
VALUES('000/102', 'jefAdmon', 4, NULL)

*/

/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_error_out INT;
DECLARE @p_errMsg_out   NVARCHAR(MAX);

SET @p_params= '<NodoXML><LI><periodoD>202201</periodoD><periodoH>202201</periodoH></LI></NodoXML>'

EXEC [InformesExcel].[FacturasCabecera] @p_params, @p_error_out OUTPUT, @p_errMsg_out OUTPUT;
*/


CREATE PROCEDURE [InformesExcel].[FacturasCabecera]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS

SET NOCOUNT ON;  
BEGIN TRY

	--********************
	--INICIO: 2 DataTables
	-- 1: Paramentros del encabezado
	-- 2: Gurpos
	-- 3: Datos
	--********************
	
	--DataTable[1]:  Parametros
	DECLARE @xml AS XML = @p_params;
	
	DECLARE @params TABLE (periodoD VARCHAR(6) NULL, periodoH VARCHAR(6) NULL, fInforme DATETIME);

	INSERT INTO @params
	SELECT periodoD = M.Item.value('periodoD[1]', 'VARCHAR(6)')
		 , periodoH = M.Item.value('periodoH[1]', 'VARCHAR(6)')
		 , fInforme = GETDATE()	
	FROM @xml.nodes('NodoXML/LI')AS M(Item);

	--********************
	--VALIDAR PARAMETROS
	--********************
	UPDATE @params
	SET periodoD = IIF(periodoD IS NULL OR periodoD='', '000000', periodoD)
	  , periodoH = IIF(periodoH IS NULL OR periodoH='', '999999', periodoH)
	OUTPUT INSERTED.* ;
	
	
	
	--********************
	--DataTable[2]:  Grupos
	SELECT * 
	FROM (VALUES ('Cabecera de Facturas'))
	AS DataTables(Grupo);
	
	--********************


	--********************
	--[01]#FACS: Facturas FacE
	SELECT F.*
	FROM dbo.facturas AS F
	INNER JOIN @params AS _P
	ON  F.facPerCod >=  _P.periodoD
	AND F.facPerCod<= _P.periodoH
	ORDER BY facZonCod, facPerCod, facCtrCod, facCod, facVersion;
END TRY
	
BEGIN CATCH
	SELECT  @p_errId_out = ERROR_NUMBER()
		 ,  @p_errMsg_out= ERROR_MESSAGE();
END CATCH

GO


