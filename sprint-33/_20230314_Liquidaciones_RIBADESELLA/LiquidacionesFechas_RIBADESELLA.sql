/*
INSERT INTO dbo.ExcelConsultas
VALUES ('RIBA/003',	'Fecha Liquidaciones RIBA.', 'Fecha Liquidaciones RIBADESELLA', 0, '[InformesExcel].[LiquidacionesFechas_RIBADESELLA]', '001', 'Lista las fechas en las que se han aplicado liquidaciones en los servicios de Ribadesella', NULL, NULL, NULL, NULL);

INSERT INTO ExcelPerfil
VALUES('RIBA/003', 'root', 4, NULL)

INSERT INTO ExcelPerfil
VALUES('RIBA/003', 'jefeExp', 4, NULL)

INSERT INTO ExcelPerfil
VALUES('RIBA/003', 'jefAdmon', 4, NULL)

INSERT INTO ExcelPerfil
VALUES('RIBA/003', 'comerc', 4, NULL)

*/


/*

SELECT * FROM excelConsultas
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI></LI></NodoXML>';

EXEC [InformesExcel].[LiquidacionesFechas_RIBADESELLA] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/

CREATE PROCEDURE [InformesExcel].[LiquidacionesFechas_RIBADESELLA]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS

	SET NOCOUNT ON;   


	--DataTable[1]:  Parametros
	DECLARE @xml AS XML = @p_params;
	
	DECLARE @params TABLE (fInforme DATETIME);

	INSERT INTO @params
	OUTPUT INSERTED.*	
	SELECT fInforme = GETDATE()
	FROM @xml.nodes('NodoXML/LI')AS M(Item);


	SELECT DISTINCT 
	  [Org.Cod.]  = T.svcOrgCod
	, [Organismo] = O.orgDescripcion
	, [Fecha Liq.] = CAST(fclFecLiq AS DATE)
	, [Periodo] = fclFacPerCod
	, [Serv.Cod.] = T.svccod
	, [Servicio] = T.svcdes
	FROM dbo.faclin AS FL
	INNER JOIN dbo.vLiquidacionesTributos AS T
	ON T.svccod = FL.fclTrfSvCod
	AND liqTipoId=0
	LEFT JOIN dbo.organismos AS O
	ON O.orgCodigo = T.svcOrgCod
	WHERE FL.fclFecLiq IS NOT NULL
	ORDER BY svcOrgCod, fclFacPerCod DESC, [Fecha Liq.] DESC, svccod;


GO


