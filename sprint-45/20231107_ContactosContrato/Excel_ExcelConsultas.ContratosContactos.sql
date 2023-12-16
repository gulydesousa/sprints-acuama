/*


INSERT INTO ExcelFiltroGrupos VALUES (13, 'Zona, Dir.Suministro, Contratos, Orden')
SELECT * FROM ExcelFiltros WHERE ExFCodGrupo=13


INSERT INTO ExcelFiltros VALUES 
(13, 'zonaD', 'Zona desde'),
(13, 'zonaH', 'Zona hasta'),
(13, 'direccion', 'Dirección'),
(13, 'contratos', 'Contratos'),
(13, 'orden', 'Orden')


--SELECT * FROm excelConsultas WHERE ExcConsulta LIKE '%contac%'
INSERT INTO excelConsultas VALUES('000/002',	'Contactos Contratos',
'Contratos: Dirección, telefono y email',	13	, '[dbo].[Excel_ExcelConsultas.ContratosContactos]'
, '001', 	'Se listan los contratos con los datos de contacto, titular, pagador y ruta', 	NULL, NULL, NULL, NULL)

INSERT INTO ExcelPerfil VALUES
('000/002', 'root', 3, NULL),
('000/002', 'jefAdmon', 3, NULL)

*/

/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI><zonaD></zonaD><zonaH></zonaH><direccion></direccion><contratos>1</contratos><orden>1</orden></LI></NodoXML>'
EXEC [dbo].[Excel_ExcelConsultas.ContratosContactos] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/

ALTER PROCEDURE [dbo].[Excel_ExcelConsultas.ContratosContactos]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT

AS
	
	SET NOCOUNT ON;   
	BEGIN TRY
	
	--********************
	--DataTable[1]:  Parametros
	DECLARE @xml AS XML = @p_params;
	DECLARE @params TABLE (zonaD VARCHAR(6), zonaH VARCHAR(6), direccion VARCHAR(55), contratos INT, orden INT);

	INSERT INTO @params
	SELECT zonaD    =  M.Item.value('zonaD[1]', 'VARCHAR(6)')
		 , zonaH    =  M.Item.value('zonaH[1]', 'VARCHAR(6)')
		 , direccion=  M.Item.value('direccion[1]', 'VARCHAR(60)') 
		 , contratos=  M.Item.value('contratos[1]', 'INT')
		 , orden=  M.Item.value('orden[1]', 'INT')
	FROM @xml.nodes('NodoXML/LI')AS M(Item);

	SELECT P.zonaD
	, P.zonaH
	, GETDATE() AS fInforme
	, direccion
	, CASE contratos 
	  WHEN 0 THEN 'Todos'
	  WHEN 1 THEN 'Activos'
	  WHEN 2 THEN 'Inactivos'
	  WHEN 3 THEN 'Bajas' END 
	  AS contratos  
	FROM @params AS P

	
	--********************
	--VALIDAR PARAMETROS
	----------------------
	DECLARE @orden INT; 
	SELECT @orden= orden FROM @params;

	WITH DATA AS(
	SELECT ctrcod 
	, ctrversion
	, C.ctrTitCod
	, C.ctrTitDocIden 
	, C.ctrTitNom
	, C.ctrPagDocIden 
	, C.ctrPagNom
	, C.ctrTlf1 
	, C.ctrTlf2
	, C.ctrTlf3
	, C.ctrEmail
	, C.ctrEnvNom
	, C.ctrEnvDir
	, C.ctrEnvPob
	, C.ctrEnvPrv
	, C.ctrEnvCPos
	, ISNULL(C.ctrRuta1, ' ') AS Ruta1
	, ISNULL(C.ctrRuta2, ' ') AS Ruta2
	, ISNULL(C.ctrRuta3, ' ') AS Ruta3
	, ISNULL(C.ctrRuta4, ' ') AS Ruta4
	, ISNULL(C.ctrRuta5, ' ') AS Ruta5
	, ISNULL(C.ctrRuta6, ' ') AS Ruta6
	, C.ctrzoncod
	, I.inmDireccion
	, I.inmPobCod
	, I.inmPrvCod
	--Dos criterios para la ordenación:
	, ROW_NUMBER() OVER(ORDER BY C.ctrcod, C.ctrversion DESC) AS RN1
	, ROW_NUMBER() OVER(ORDER BY C.ctrRuta1, C.ctrRuta2, C.ctrRuta3, C.ctrRuta4, C.ctrRuta5, C.ctrRuta6) AS RN2
	FROM .dbo.contratos AS C
	LEFT JOIN dbo.inmuebles AS I
	ON I.inmcod = C.ctrinmcod
	INNER JOIN @params AS P
	ON ((P.contratos = 0) OR /*Todas las versiones*/ 
		(P.contratos=1 AND C.ctrfecanu IS NULL) OR /*Solo activas*/ 
		(P.contratos=2 AND C.ctrfecanu IS NOT NULL) OR /*Solo inactivas*/ 
		(P.contratos=3 AND C.ctrbaja = 1))/*Solo bajas*/ 
	AND (P.zonaD IS NULL OR P.zonaD = '' OR C.ctrzoncod >= P.zonaD)
	AND (P.zonaH IS NULL OR P.zonaH = '' OR C.ctrzoncod <= P.zonaH)
	AND (P.direccion IS NULL OR P.direccion = '' OR I.inmDireccion COLLATE Latin1_general_CI_AI LIKE '%'+ P.direccion + '%' COLLATE Latin1_general_CI_AI)
	)

	SELECT ctrcod AS [Contrato]
	, ctrversion AS [Versión]
	, PR.prvdes AS [Provincia]
	, PB.pobdes  AS [Población]
	, inmDireccion AS [Dirección] 
	, ctrTitCod AS [Cod.Cliente]
	, ctrTitDocIden AS [Titular]
	, ctrTitNom AS [Titular Nombre]
	, ctrPagDocIden AS [Pagador]
	, ctrPagNom AS [Pagador Nombre]
	, [Envío Nombre] = ctrEnvNom
	, [Envío Dirección] = ctrEnvDir
	, [Envío Población] = ctrEnvPob
	, [Envio Provincia] = ctrEnvPrv
	, [Envío C.P.] = ctrEnvCPos
	, ctrTlf1 AS [Telefono 1]
	, ctrTlf2 AS [Telefono 2]
	, ctrTlf3 AS [Telefono 3]
	, ctrEmail AS [Email]
	, Z.zoncod + ' - ' + Z.zondes AS [Zona]
	, FORMATMESSAGE('%s.%s.%s.%s.%s.%s', Ruta1, Ruta2, Ruta3, Ruta4, Ruta5, Ruta6) AS Ruta
	FROM DATA AS D
	LEFT JOIN dbo.provincias AS PR
	ON PR.prvcod = D.inmPrvCod
	LEFT JOIN dbo.poblaciones AS PB
	ON D.inmPrvCod = PB.pobprv
	AND D.inmPobCod = PB.pobcod
	LEFT JOIN zonas AS Z
	ON Z.zoncod = D.ctrzoncod
	ORDER BY IIF (@orden = 1, RN1, RN2)
	
	--********************
	END TRY

	BEGIN CATCH
		SELECT  @p_errId_out = ERROR_NUMBER()
			 ,  @p_errMsg_out= ERROR_MESSAGE();
	END CATCH
GO


