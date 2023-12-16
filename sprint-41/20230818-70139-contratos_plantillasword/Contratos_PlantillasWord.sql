/*
INSERT INTO dbo.ExcelConsultas
VALUES ('000/030',	'Plantillas Word', 'Contratos: Plantillas Word', 0, '[InformesExcel].[Contratos_PlantillasWord]', '001', 'Contratos: Plantillas Word<br>Icono Gaviotas en Contratos', NULL, NULL, NULL, NULL);

INSERT INTO ExcelPerfil
VALUES('000/030', 'root', 3, NULL)

INSERT INTO ExcelPerfil
VALUES('000/030', 'direcc', 3, NULL)

--DELETE FROM excelPerfil WHERE ExPCod='000/030'
--DELETE FROM dbo.ExcelConsultas WHERE ExcCod='000/030'

*/


/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML></NodoXML>';

EXEC [InformesExcel].[Contratos_PlantillasWord] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/

CREATE PROCEDURE [InformesExcel].[Contratos_PlantillasWord]
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
	
	--DataTable[1]:  Parametros
	DECLARE @xml AS XML = @p_params;
	
	DECLARE @params TABLE (fInforme DATETIME);

	INSERT INTO @params
	OUTPUT INSERTED.*	
	SELECT fInforme = GETDATE()
	FROM @xml.nodes('NodoXML')AS M(Item);

	
	SELECT * FROM dbo.plantillasWord WHERE pwTipo='ctr'
	ORDER BY pwPlantilla ASC;
	END TRY
	
	BEGIN CATCH
		SELECT  @p_errId_out = ERROR_NUMBER()
			 ,  @p_errMsg_out= ERROR_MESSAGE();
	END CATCH

GO


