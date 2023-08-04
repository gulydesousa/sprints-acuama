/*
DELETE FROM ExcelPerfil WHERE ExPCod = '000/102'
DELETE FROM ExcelConsultas WHERE ExcCod = '000/102'

INSERT INTO dbo.ExcelConsultas
VALUES ('000/102',	'Revisión Importes FacE', 'Revisión Importes FacE', 18, '[InformesExcel].[RevisionImportesFacE]', '000', 'Facturas cuyos totales por tipo impositivo (FacE) difiere con la totalización por linea usada por acuama. <br>Sería necesario ajustar manualmente el redondeo de los importes para que el total de los impuestos coincida en ambas facturas. <b>Recueda ajustar la precisión en la columna Excel para ver los importes a 4 decimales.</b>');

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

	SET @p_params= '<NodoXML><LI><periodoD></periodoD><periodoH></periodoH><zonaD></zonaD><zonaH></zonaH></LI></NodoXML>'

	EXEC [InformesExcel].[RevisionImportesFacE]  @p_params, @p_error_out OUTPUT, @p_errMsg_out OUTPUT;
*/

ALTER PROCEDURE [InformesExcel].[RevisionImportesFacE]
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
	--Validar antes de marcar como pendiente de envio a seres
	DECLARE @FACS AS dbo.tFacturasPK;

	INSERT INTO  @FACS(facCod, facPerCod, facCtrCod, facVersion)
	SELECT F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion
	FROM dbo.facturas AS F
	INNER JOIN @params AS P
	ON F.facPerCod BETWEEN P.periodoD AND P.periodoH
	AND F.facZonCod BETWEEN P.zonaD AND P.zonaH
	INNER JOIN dbo.contratos AS C
	ON  C.ctrcod = F.facCtrCod
	AND C.ctrversion = F.facCtrVersion
	AND C.ctrFace=1
	AND F.facFechaRectif IS NULL;

	--********************
	--Facturas_RevisionImportesFacE
	--********************
	CREATE TABLE #RESULT(
	  facCod SMALLINT NOT NULL	
	, facPerCod VARCHAR(6) NOT NULL	
	, facCtrCod	INT NOT NULL
	, facVersion SMALLINT NOT NULL	

	, facEnvSERES VARCHAR(1)	
	, facFecEmisionSERES DATETIME	

	, Acuama_TOTAL_BASEIMPO MONEY	
	, FacE_TOTAL_BASEIMPO MONEY	
	, Acuama_TOTAL_IMP_REP MONEY	
	, FacE_TOTAL_IMP_REP MONEY
	, Acuama_TOTAL_FACTURA MONEY
	, FacE_TOTAL_FACTURA MONEY
	
	, Acuama_TOTAL MONEY	
	, TOTAL_COBRADO MONEY	
	
	, facEDescEstado VARCHAR(100)	
	, facECodEstado VARCHAR(8)	
	, ERROR_MSG VARCHAR (250) )
	
	INSERT INTO #RESULT
	EXEC dbo.Facturas_RevisionImportesFacE  @FACS, NULL;

	--********************
	--RESULTADO
	--********************
	SELECT * FROM (VALUES('Totales por factura', 1), ('Totales por Tipo Impositivo', 2)) 
	AS DataTables(Grupo, ID)
	ORDER BY ID;

	--********************
	--Totales por factura
	--********************
	SELECT [Contrato] = facCtrCod
	, [Periodo] = facPerCod
	, [Fac.Cod] = facCod
	, [Fac.Versión] = facVersion 
	, [Total Facturado]  = Acuama_TOTAL
	, [Total Cobrado] = TOTAL_COBRADO
	, [Emisión] = CASE (facEnvSERES) WHEN 'P' THEN 'Pendiente'
										  WHEN 'E' THEN 'Enviada'
										  ELSE facEnvSERES END
	, [Fec.Emisión] = facFecEmisionSERES
	, [Estado Actual] = facECodEstado
	, [Estado_Actual] = facEDescEstado 
	, [Tipo Error] = ERROR_MSG
	, [Base Imponible_Acuama] = Acuama_TOTAL_BASEIMPO
	, [Base Imponible_FacE] = FacE_TOTAL_BASEIMPO
	
	, [Impuestos_Acuama] = Acuama_TOTAL_IMP_REP
	, [Impuestos_FacE] = FacE_TOTAL_IMP_REP
	
	, [Total_Acuama] = Acuama_TOTAL_FACTURA
	, [Total_FacE]	 = FacE_TOTAL_FACTURA
	
	FROM #RESULT 
	ORDER BY facCtrCod, facPerCod, facCod, facVersion;

	--********************
	--Totales por Tipo Impositivo
	--********************
	DECLARE @facturas AS tFacturasPK;
	INSERT INTO @facturas(facCod, facPerCod, facCtrCod, facVersion) 
	SELECT facCod, facPerCod, facCtrCod, facVersion FROM #RESULT
	

	--****************************
	--[02]#FCL: Líneas de factura
	SELECT *
	INTO #FCL
	FROM dbo.vFacturas_LineasAcuama AS FL
	INNER JOIN @facturas AS F
	ON  F.facCod = FL.fclFacCod
	AND F.facPerCod = FL.fclFacPerCod
	AND F.facCtrCod = FL.fclFacCtrCod
	AND F.facVersion = FL.fclFacVersion;

	--[03]#SERES_LIN: Lineas de la factura en SERES
	--Una linea por escala
	SELECT * 
	INTO #SERES_LIN
	FROM dbo.fLineasFacE(@facturas);

	--********************
	--[03]Comparativa por linea de factura
	--********************
	WITH FACT AS(
	SELECT fclFacCod, fclFacPerCod, fclFacCtrCod, fclFacVersion, fclImpuesto
	, [Base] = SUM(fclBase)
	, [Impuesto] = SUM(fclImpImpuesto)
	, [LineasxImpuesto] = COUNT(fclImpuesto)
	FROM #FCL 
	GROUP BY fclFacCod, fclFacPerCod, fclFacCtrCod, fclFacVersion, fclImpuesto
	
	), FACET AS(
	SELECT fclFacCod, fclFacPerCod, fclFacCtrCod, fclFacVersion, IVA
	,  [IVA_B.IMPONIBLE]
	,  [TOTAL_IMP.REP] = CAST(ROUND([IVA_B.IMPONIBLE]*IVA*0.01, 2) AS MONEY)
	FROM #SERES_LIN 
	WHERE IVA_LINEA=1)


	SELECT [Contrato] = T.fclFacCtrCod
	, [Periodo] = T.fclFacPerCod
	, [Fac.Cod] = T.fclFacCod
	, [Fac.Version] = T.fclFacVersion
	, T.IVA
	, [Base Imponible_FacE] = T.[IVA_B.IMPONIBLE]
	, [Impuestos_FacE] = T.[TOTAL_IMP.REP]
	, [Base Imponible_Acuama] = F.Base
	, [Impuestos_Acuama] = F.Impuesto
	, F.[LineasxImpuesto]
	, [Revisar] = IIF(T.[TOTAL_IMP.REP]<>F.Impuesto OR T.[IVA_B.IMPONIBLE]<>F.Base, 1, 0)
	FROM FACET AS T
	LEFT JOIN FACT AS F
	ON F.fclFacCod = T.fclFacCod
	AND F.fclFacPerCod = T.fclFacPerCod
	AND F.fclFacVersion = T.fclFacVersion
	AND F.fclFacCtrCod = T.fclFacCtrCod
	AND F.fclImpuesto = T.IVA
	ORDER BY T.fclFacCtrCod, T.fclFacPerCod, T.fclFacCod, T.fclFacVersion, T.IVA;

	IF OBJECT_ID('tempdb..#FCL') IS NOT NULL DROP TABLE #FCL;
	IF OBJECT_ID('tempdb..#RESULT') IS NOT NULL DROP TABLE #RESULT;
GO


