

/*
****** CONFIGURACION ******


--DELETE FROM ExcelPerfil WHERE ExPCod= '000/800'
--DELETE FROM ExcelConsultas WHERE ExcCod='000/800'
--DROP PROCEDURE [InformesExcel].[CobrosImporteLineasxDesglose]



INSERT INTO dbo.ExcelConsultas
VALUES ('000/800',	'Cobros Validar Importes', 'Cobros: Validar Importes', 1, '[InformesExcel].[Cobros_Validar]', '000', 'Para identificar los cobros en los que hay errores en los importes desglosados por líneas.');

INSERT INTO ExcelPerfil
VALUES('000/800', 'root', 5, NULL)

INSERT INTO ExcelPerfil
VALUES('000/800', 'jefeExp', 5, NULL)

INSERT INTO ExcelPerfil
VALUES('000/800', 'jefAdmon', 5, NULL)


DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI><FecDesde>20201201</FecDesde><FecHasta>20211231</FecHasta></LI></NodoXML>'


EXEC [InformesExcel].[Cobros_Validar] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/


CREATE PROCEDURE [InformesExcel].[Cobros_Validar]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS

	--**********
	--PARAMETROS: 
	--[1]FecDesde: fecha dede
	--[2]FecHasta: fecha hasta
	--**********

	SET NOCOUNT ON;   
	BEGIN TRY
	
	--********************
	--INICIO: 2 DataTables
	-- 1: Parametros del encabezado (FecDesde, FecHasta)
	-- 2: Datos
	--********************

	--DataTable[1]:  Parametros
	DECLARE @xml AS XML = @p_params;
	DECLARE @params TABLE (FecDesde DATE NULL, fInforme DATETIME, FecHasta DATE NULL);

	INSERT INTO @params
	SELECT  FecDesde = CASE WHEN M.Item.value('FecDesde[1]', 'DATE') = '19000101' THEN NULL 
						   ELSE M.Item.value('FecDesde[1]', 'DATE') END
		  , fInforme     = GETDATE()
		  , FecHasta = CASE WHEN M.Item.value('FecHasta[1]', 'DATE') = '19000101' THEN NULL 
						   ELSE M.Item.value('FecHasta[1]', 'DATE') END
	FROM @xml.nodes('NodoXML/LI')AS M(Item);
	
	UPDATE @params SET FecHasta = DATEADD(DAY, 1, FecHasta)
	OUTPUT DELETED.*;
	
	--********************
	--VALIDAR PARAMETROS
	--Fechas obligatorias

	IF EXISTS(SELECT 1 FROM @params WHERE FecDesde IS NULL OR FecHasta IS NULL)
		THROW 50001 , 'La fecha ''desde'' y ''hasta'' son requeridos.', 1;
	IF EXISTS(SELECT 1 FROM @params WHERE FecDesde>FecHasta)
		THROW 50002 , 'La fecha ''hasta'' debe ser posterior a la fecha ''desde''.', 1;
	
	--********************
	--DataTable[2]:  Grupos
	SELECT * 
	FROM (VALUES ('Diferencias Cabecera-Lineas-Desglose')
			   , ('Diferencias Cobrado-Facturado')
			   , ('Cobrado x Líneas Liquidadas')) 
	AS DataTables(Grupo);
	
	--********************
	--[01]Diferencias entre la cabecera y las lineas o el desglose
	EXEC [InformesExcel].[CobrosTotales_Validar] @p_params, @p_errId_out, @p_errMsg_out

	--[02]Diferencias entre lo cobrado y lo facturado
	EXEC [InformesExcel].[CobrosDesglose_Validar] @p_params, @p_errId_out, @p_errMsg_out
	
	--[03]Cobrado en líneas liquidadas
	EXEC [InformesExcel].[CobrosLiquidadas_Validar] @p_params, @p_errId_out, @p_errMsg_out
	

	END TRY

	BEGIN CATCH
		SELECT  @p_errId_out = ERROR_NUMBER()
			 ,  @p_errMsg_out= ERROR_MESSAGE();
	END CATCH




GO


