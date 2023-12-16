/*
--DELETE FROM ExcelPerfil WHERE ExPCod='000/014'
--DELETE FROM ExcelConsultas WHERE ExcCod='000/014'
SELECT * FROM ExcelConsultas WHERE ExcCod='000/014'
SELECT * FROM ExcelPerfil WHERE ExPCod='000/014'

INSERT INTO dbo.ExcelConsultas
VALUES ('000/014',	'Contratos sin Servicios', 'Contratos activos sin "Servicios por Contrato" asociados', 0, '[InformesExcel].[Contratos_SinServiciosAsociados]', '001', 'Listado de contratos activos para los que no existe ningún servicio (activo o no) en el histórico de servicios por contrato.', NULL, NULL, NULL, NULL);

INSERT INTO ExcelPerfil
VALUES('000/014', 'root', 3, NULL)

INSERT INTO ExcelPerfil
VALUES('000/014', 'direcc', 3, NULL)
*/


/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI></LI></NodoXML>';

EXEC [InformesExcel].[Contratos_SinServiciosAsociados] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/

ALTER PROCEDURE [InformesExcel].[Contratos_SinServiciosAsociados]
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


	WITH CTR AS(
	SELECT C.ctrcod, C.ctrfecini, ctrfecreg, ctrinmcod, ctrzoncod, ctrTitDocIden, ctrTitNom, ctrPagDocIden,  ctrPagNom, ctrRepresent
	FROM contratos AS C
	LEFT JOIN contratoServicio AS S
	ON C.ctrcod = S.ctsctrcod
	WHERE ctrfecanu IS NULL
	AND S.ctsctrcod IS NULL
	AND C.ctrfecanu IS NULL)

	SELECT [Contrato] = C.ctrcod
	, [F.Registro] = C.ctrfecreg
	, [F.Inicio] = C.ctrfecini
	, [Zona] = ctrzoncod
	, [Dirección] = I.inmDireccion
	, [Titular] = C.ctrTitDocIden
	, [Tit.Nombre] = C.ctrTitNom
	, [Pagador] = C.ctrPagDocIden
	, [Pag.Nombre] = C.ctrPagNom
	, [Representante] = ctrRepresent
	FROM CTR AS C
	INNER JOIN dbo.inmuebles AS I
	ON C.ctrinmcod = I.inmcod
	ORDER BY ctrcod;

GO


