/*

INSERT INTO dbo.ExcelConsultas
VALUES ('000/004',	'Sistema facTotales', 'Sistema: Comprobar datos en facTotales', 0, '[InformesExcel].[FacTotales_Comprobar]', 'CSVH', 'Para comprobar que los totales en la tabla facTotales están todos a nivel.');

INSERT INTO ExcelPerfil
VALUES('000/004', 'root', 4, NULL)

--DELETE FROM  ExcelPerfil WHERE ExpCod='000/004'
--DELETE FROM dbo.ExcelConsultas WHERE ExcCod='000/004'

*/


/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML></NodoXML>';

EXEC [InformesExcel].[FacTotales_Comprobar] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/

ALTER PROCEDURE [InformesExcel].[FacTotales_Comprobar]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS

	--**********
	--PARAMETROS: 
	--[1]Fecha: Fecha
	--NULL=>Recuperamos las ayudas hasta la fecha actual
	--**********

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
	
	DECLARE @params TABLE (fInforme DATETIME);

	INSERT INTO @params
	OUTPUT INSERTED.*	
	SELECT fInforme = GETDATE()
	FROM @xml.nodes('NodoXML')AS M(Item);

	--********************
	--VALIDAR PARAMETROS
	--********************

	DECLARE @ahora DATE = GETDATE();

	--********************
	SELECT * 
	FROM (VALUES('FacTotales Pendientes')) 
	AS DataTables(Grupo)
	
	--********************
	EXEC Trabajo.FacTotales_Comprobar;

	
	
END TRY
	

BEGIN CATCH


	SELECT  @p_errId_out = ERROR_NUMBER()
	     ,  @p_errMsg_out= ERROR_MESSAGE();
END CATCH




GO


