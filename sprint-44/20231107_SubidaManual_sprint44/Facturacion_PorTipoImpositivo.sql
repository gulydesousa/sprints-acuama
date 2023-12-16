
/*
DELETE FROM ExcelPerfil WHERE ExPCod = '000/006'
DELETE FROM ExcelConsultas WHERE ExcCod = '000/006'

INSERT INTO dbo.ExcelConsultas
VALUES ('000/006',	'Fact.Tipo Impositivo', 'Facturacion Tipo Impositivo', 18, '[InformesExcel].[Facturacion_PorTipoImpositivo]', '000'
, 'Facturas cuyos totales por tipo impositivo difiere con la totalización por linea usada por acuama. <br>Sería necesario ajustar manualmente el redondeo de los importes para que el total de los impuestos coincida en ambos totales. <b>Recueda ajustar la precisión en la columna Excel para ver los importes a 4 decimales.</b>'
, NULL, NULL, NULL, NULL);

INSERT INTO ExcelPerfil
VALUES('000/006', 'root', 4, NULL)

INSERT INTO ExcelPerfil
VALUES('000/006', 'jefeExp', 4, NULL)

INSERT INTO ExcelPerfil
VALUES('000/006', 'jefAdmon', 4, NULL)

*/
/*
	DECLARE @p_params NVARCHAR(MAX);
	DECLARE @p_errId_out INT;
	DECLARE @p_error_out INT;
	DECLARE @p_errMsg_out   NVARCHAR(MAX);

	SET @p_params= '<NodoXML><LI><periodoD>202202</periodoD><periodoH>202202</periodoH><zonaD>AZ03</zonaD><zonaH>AZ03</zonaH></LI></NodoXML>'

	EXEC [InformesExcel].[Facturacion_PorTipoImpositivo]  @p_params, @p_error_out OUTPUT, @p_errMsg_out OUTPUT;
*/

CREATE PROCEDURE [InformesExcel].[Facturacion_PorTipoImpositivo]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS


	DECLARE @AHORA DATETIME = (SELECT dbo.GETACUAMADATE());
	
	--*******
	--PARAMETROS:
	--*******
	DECLARE @xml AS XML = @p_params;

	DECLARE @params TABLE (periodoD VARCHAR(6) NULL, periodoH VARCHAR(6) NULL
						 , fInforme DATETIME
						 , zonaD VARCHAR(4) NULL, zonaH VARCHAR(4) NULL);

	INSERT INTO @params
	SELECT periodoD = M.Item.value('periodoD[1]', 'VARCHAR(6)')
		 , periodoH = M.Item.value('periodoH[1]', 'VARCHAR(6)')
		
		 , fInforme = dbo.GetAcuamaDate()
		
		 , zonaD = M.Item.value('zonaD[1]', 'VARCHAR(4)')
		 , zonaH = M.Item.value('zonaH[1]', 'VARCHAR(4)')	
	FROM @xml.nodes('NodoXML/LI')AS M(Item);

	--********************
	--VALIDAR PARAMETROS
	--********************
	IF EXISTS(SELECT 1 FROM @params WHERE periodoD='')
	UPDATE @params SET periodoD = (SELECT MIN(percod) FROM periodos);

	IF EXISTS(SELECT 1 FROM @params WHERE periodoH='')
	UPDATE @params SET periodoH = (SELECT MAX(percod) FROM periodos);

	IF EXISTS(SELECT 1 FROM @params WHERE periodoD> periodoH)
	UPDATE @params SET periodoD = periodoH , periodoH=periodoD;

	IF EXISTS(SELECT 1 FROM @params WHERE zonaD='')
	UPDATE @params SET zonaD = (SELECT MIN(zoncod) FROM dbo.zonas);

	IF EXISTS(SELECT 1 FROM @params WHERE zonaH='')
	UPDATE @params SET zonaH = (SELECT MAX(zoncod) FROM dbo.zonas);

	--**************************
	SELECT * FROM @params;
	
	--********************
	--INICIO:
	--********************
	
	--********************
	--RESULTADO
	--********************
	SELECT * FROM (VALUES('Totales por tipo impositivo', 1)) 
	AS DataTables(Grupo, ID)
	ORDER BY ID;

	--********************
	--Totales por factura
	--********************
	SELECT [Contrato] = C.ctrcod
	, [Tit.DocIden] = C.ctrTitDocIden
	, [Titular] = C.ctrTitNom
	, [Fac.Cod] = F.facCod
	, [Fac.PerCod] = F.facPerCod
	, [Fac.Version] = F.facVersion
	, [Zona] = C.ctrzoncod
	, [TotalFactura]  = T.fctFacturado
	, [TotalPorTipoImpositivo] = fctTotalTipoImp
	, [Cobrado] = fctCobrado
	, [Diferencia] = fctTotalTipoImp - fctFacturado
	FROM dbo.facTotales AS T
	INNER JOIN dbo.facturas AS F
	ON T.fctCod = F.facCod
	AND T.fctCtrCod = F.facCtrCod
	AND T.fctPerCod = F.facPerCod
	AND T.fctVersion = F.facVersion
	INNER JOIN dbo.contratos AS C
	ON C.ctrcod = F.facCtrCod AND
	C.ctrversion = F.facCtrVersion
	INNER JOIN @params AS P
	ON F.facPerCod BETWEEN P.periodoD AND P.periodoH
	AND F.facZonCod BETWEEN P.zonaD AND P.zonaH
	AND F.facFechaRectif IS NULL
	WHERE T.fctFacturado<>fctTotalTipoImp
	ORDER BY [Zona],[Contrato], [Fac.PerCod], [Fac.Cod]
GO