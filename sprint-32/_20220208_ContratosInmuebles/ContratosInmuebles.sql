
/*

DELETE FROM ExcelPerfil WHERE ExPCod='000/430'
DELETE FROM ExcelConsultas WHERE ExcCod='000/430'

INSERT INTO dbo.ExcelConsultas
VALUES ('000/430',	'Contratos Inmuebles', 'Contratos Inmuebles', 0, '[InformesExcel].[ContratosInmuebles]', 'CSV', 'Listado de los inmuebles asociados a la ultima versión de los contratos', NULL, NULL, NULL, NULL);

INSERT INTO ExcelPerfil
VALUES('000/430', 'root', 3, NULL)

INSERT INTO ExcelPerfil
VALUES('000/430', 'jefeExp', 3, NULL)

INSERT INTO ExcelPerfil
VALUES('000/430', 'jefAdmon', 3, NULL)

INSERT INTO ExcelPerfil
VALUES('000/430', 'direcc', 3, NULL)

*/


/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI></LI></NodoXML>';

EXEC [InformesExcel].[ContratosInmuebles] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/

ALTER PROCEDURE [InformesExcel].[ContratosInmuebles]
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

	SELECT Grupo='InmueblesxContrato';

	WITH CTR AS(
	SELECT C.ctrcod
	, C.ctrversion
	, SvcActivos = SUM(IIF(CS.ctsfecbaj IS NULL OR CS.ctsfecbaj>GETDATE(), 1, 0)) 
	, NumSvc = COUNT(DISTINCT CS.ctssrv)
	FROM [dbo].[vContratosUltimaVersion] AS C
	INNER JOIN dbo.contratoServicio AS CS
	ON CS.ctsctrcod = C.ctrCod
	GROUP BY C.ctrcod, C.ctrversion)


	SELECT [Contrato] = C.ctrCod
	, [Ctr.Versión] = C.ctrVersion
	, [Titular] = C.ctrTitDocIden
	, [Tit.Nombre] = C.ctrTitNom
	, [Inmueble] = C.ctrinmcod
	, [Referencia Catastral] = char(9)+ REPLACE(I.inmrefcatastral, ';', '_')
	, [Dirección] = I.inmDireccion
	, [Provincia] = FORMATMESSAGE('%s-%s', P1.prvcod, P1.prvdes)	
	, [Población] = FORMATMESSAGE('%s-%s', P2.pobcod, P2.pobdes)
	, [Municipio] = FORMATMESSAGE('%s-%s', M1.mnccod, M1.mncdes)
	, [Tiene Ref.Catastro]	= CAST(IIF(I.inmrefcatastral IS NULL OR I.inmrefcatastral='', 0, 1) AS BIT)
	--Caso Melilla: 
	--SvcActivos= NULL: No tiene servicios asociados
	--SvcActivos=0: Tiene servicios asociados todos en baja
	--SvcActivos>0: Tiene servicios activos
	, [Servicios Activos]	= CAST(CC.SvcActivos AS INT)

	FROM dbo.vContratosUltimaVersion AS C
	INNER JOIN dbo.inmuebles AS I
	ON C.ctrinmcod = I.inmcod
	LEFT JOIN CTR AS CC 
	ON C.ctrCod= CC.ctrCod
	LEFT JOIN dbo.parametros AS P
	ON P.pgsclave='EXPLOTACION'
	LEFT JOIN provincias AS P1
	ON P1.prvcod=I.inmPrvCod
	LEFT JOIN dbo.poblaciones AS P2
	ON  P2.pobcod = I.inmPobCod
	AND P2.pobcod = I.inmPobCod
	LEFT JOIN dbo.municipios AS M1
	ON  M1.mnccod	 = I.inmmnccod
	AND M1.mncPobPrv = I.inmPrvCod
	AND M1.mncPobCod = I.inmPobCod
	
	ORDER BY C.ctrCod;

GO


