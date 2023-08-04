/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_error_out INT;
DECLARE @p_errMsg_out   NVARCHAR(MAX);

SET @p_params= '<NodoXML><LI><fechaD></fechaD><fechaH></fechaH><periodoD>202201</periodoD><periodoH>202204</periodoH><sectorD></sectorD><sectorH></sectorH><conFacturas>1</conFacturas></LI></NodoXML>'
EXEC [dbo].[Excel_Excelconsultas.ConsumoPorSectorM3_SORIA] @p_params, @p_error_out OUTPUT, @p_errMsg_out OUTPUT;

--SELECT @p_error_out, @p_errMsg_out
*/

ALTER PROCEDURE [dbo].[Excel_Excelconsultas.ConsumoPorSectorM3_SORIA]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS
	--**********
	--PARAMETROS: 
	--[1]fechaD: fecha desde
	--[2]fechaH: fecha hasta
	--[3]conFacturas: Retorna el listado de facturas
	--[4]periodoD: periodo desde
	--[5]periodoH: periodo hasta
	--[6]sectorD: sector desde
	--[7]sectorH: sector hasta
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
	
	DECLARE @params TABLE (fechaD DATE NULL, fechaH DATE NULL, conFacturas BIT, fInforme DATETIME
						 , periodoD VARCHAR(6) NULL, periodoH VARCHAR(6) NULL
						 , sectorD VARCHAR(6) NULL, sectorH VARCHAR(6) NULL);

	INSERT INTO @params
	OUTPUT INSERTED.*
	SELECT	  fechaD = CASE WHEN M.Item.value('fechaD[1]', 'DATE') = '19000101' THEN NULL
						   ELSE M.Item.value('fechaD[1]', 'DATE') END

			, fechaH = CASE WHEN M.Item.value('fechaH[1]', 'DATE') = '19000101' THEN NULL
						   ELSE  M.Item.value('fechaH[1]', 'DATE') END
			, conFacturas = M.Item.value('conFacturas[1]', 'INT')
			, fInforme = GETDATE()

			, periodoD = M.Item.value('periodoD[1]', 'VARCHAR(6)')
			, periodoH = M.Item.value('periodoH[1]', 'VARCHAR(6)')

			, sectorD = M.Item.value('sectorD[1]', 'VARCHAR(6)')
			, sectorH = M.Item.value('sectorH[1]', 'VARCHAR(6)')		
	FROM @xml.nodes('NodoXML/LI')AS M(Item);
	

	--********************
	--VALIDAR PARAMETROS
	IF EXISTS(SELECT 1 FROM @params WHERE periodoD='' AND periodoH='' AND fechaD IS NULL AND fechaH IS NULL)
		THROW 50003 , 'Debe filtrar las facturas por fecha y/o periodo.', 1;

	IF EXISTS(SELECT 1 FROM @params WHERE fechaD IS NOT NULL AND fechaH IS NOT NULL AND fechaD>fechaH)
		THROW 50002 , 'La fecha ''hasta'' debe ser posterior a la fecha ''desde''.', 1;
	
	IF EXISTS(SELECT 1 FROM @params WHERE periodoD<>'' AND periodoH<>'' AND periodoD>periodoH)
		THROW 50003 , 'El periodo ''hasta'' debe ser posterior al periodo ''desde''.', 1;
	
	IF EXISTS(SELECT 1 FROM @params WHERE sectorD>sectorH)
		THROW 50004 , 'El sector ''hasta'' debe ser superior al sector ''desde''.', 1;

	--UTIL: Obtenemos las tarifas de agua
	DECLARE @TRF_AGUA AS TABLE(trfCod INT, trfDes VARCHAR(50), trfTipo VARCHAR(50));
	DECLARE @AGUA INT = 1;
	
	SELECT @AGUA = CAST(pgsvalor AS INT) 
	FROM parametros 
	WHERE pgsclave='SERVICIO_AGUA';
	
	INSERT INTO @TRF_AGUA
	SELECT T.trfcod
	, REPLACE(REPLACE(T.trfdes, 'MENSUAL', ''), 'CUATRIMESTRAL', '')
	, CASE WHEN CHARINDEX('MENSUAL', T.trfdes) > 0 THEN 'MENSUAL'
		   WHEN CHARINDEX('CUATRIMESTRAL', T.trfdes) > 0 THEN 'CUATRIMESTRAL'
		   ELSE NULL END 
	FROM dbo.tarifas AS T
	WHERE T.trfsrvcod=@AGUA;
	
	--UTIL: Tabla para guardar todos los consumos
	DECLARE @M3 AS TABLE(
	  ctrSctCod VARCHAR(6) NULL
	, sctdes VARCHAR(25) NULL
	, facCtrCod INT
	, facPerCod VARCHAR(6)
	, facCod INT
	, facVersion INT
	, facCtrVersion INT
	, ctrTitDocIden VARCHAR(12)
	, ctrTitNom VARCHAR(100)
	, facNumero VARCHAR(20) NULL
	, ctrzoncod VARCHAR(4) NULL
	, zondes VARCHAR(20) NULL
	, ctrUsoCod INT NULL
	, usodes VARCHAR(40)
	, facFecha DATE NULL
	, facLecAnt INT NULL
	, facLecAct INT NULL
	, facLecturasDif INT NULL
	, facConsumoFactura INT NULL
	, facConsumoReal INT NULL
	, fclTrfCod INT NULL
	, trfDes VARCHAR(50) NULL
	, trfTipo VARCHAR(50) NULL);

	--UTIL: Tabla para guardar el ultimo contrato
	DECLARE @ULTIMO_CTR AS TABLE(
	  ctrCod INT
	, ctrVersion INT
	, ctrSctCod VARCHAR(6) NULL
	, consumo INT NULL
	, trfDes VARCHAR(50) NULL 
	, ctrTitNom VARCHAR(100) NULL
	, ctrUsocod INT NULL
	, ctrzoncod VARCHAR(4) NULL
	, ctsuds DECIMAL(12, 2) NULL);


	--DataTable[2]:  Nombre de Grupos
	IF (EXISTS(SELECT 1 FROM @params WHERE conFacturas=1))
	SELECT * 
	FROM (VALUES ('m3 Contratos'), ('m3 Sectores')) 
	AS DataTables(Grupo);
	
	ELSE
	SELECT * 
	FROM (VALUES ('m3 Sectores')) 
	AS DataTables(Grupo);

	--********************
	--DataTable[3]:  Datos

	WITH FACS AS (
	--FACTURAS
	SELECT F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facCtrVersion
	, F.facVersion
	, C.ctrTitDocIden
	, C.ctrTitNom
	, F.facFecha
	, F.facNumero
	, F.facLecAnt
	, F.facLecAct
	, F.facConsumoFactura
	, F.facConsumoReal 
	, F.facFechaRectif
	, C.ctrSctCod
	, C.ctrzoncod
	, C.ctrUsoCod
	FROM dbo.facturas AS F
	LEFT JOIN dbo.contratos AS C
	ON C.ctrcod = F.facCtrCod
	AND C.ctrversion = F.facCtrVersion
	INNER JOIN @params AS P 
	ON  (P.sectorD = '' OR C.ctrSctCod>=P.sectorD) 
	AND (P.sectorH = '' OR C.ctrSctCod<=P.sectorH)
	AND (P.periodoD = '' OR  F.facPerCod>= P.periodoD)
	AND (P.periodoH = '' OR  F.facPerCod<= P.periodoH)
	AND (P.fechaD IS NULL OR F.facFecha >=P.fechaD)
	AND (P.fechaH IS NULL OR F.facFecha <DATEADD(DAY, 1, P.fechaH))
	WHERE (F.facFechaRectif IS NULL OR (P.fechaH IS NOT NULL AND F.facFechaRectif >P.fechaH))

	), FAC AS(
	--FACTURAS DE AGUA
	SELECT F.ctrSctCod
	, F.facCtrCod
	, F.facPerCod
	, F.facCod
	, F.facVersion
	, F.facCtrVersion
	, F.ctrTitDocIden
	, F.ctrTitNom
	, F.facNumero
	, F.ctrzoncod
	, F.ctrUsoCod
	, F.facFecha 
	, F.facLecAnt
	, F.facLecAct
	, F.facConsumoFactura
	, F.facConsumoReal 
	, FL.fclTrfCod
	, T.trfDes
	, T.trfTipo
	FROM FACS AS F 
	--Solo queremos cabeceras que tengan el servicio de agua
	INNER JOIN dbo.faclin AS FL
	ON FL.fclFacCod = F.facCod
	AND FL.fclFacPerCod = F.facPerCod
	AND FL.fclFacCtrCod = F.facCtrCod
	AND FL.fclFacVersion = F.facVersion
	AND fclTrfSvCod=@AGUA
	LEFT JOIN @TRF_AGUA AS T
	ON T.trfCod = FL.fclTrfCod)

	--CONSUMO POR FACTURA
	INSERT INTO @M3
	SELECT 
	  ISNULL(ctrSctCod, '-') AS ctrSctCod
	, ISNULL(sctdes, 'N/A') AS sctdes
	, facCtrCod
	, facPerCod
	, facCod
	, facVersion
	, facCtrVersion
	, ctrTitDocIden
	, ctrTitNom
	, facNumero
	, ctrzoncod
	, zondes
	, ctrUsoCod
	, U.usodes
	, CAST(facFecha AS DATE) 
	, facLecAnt
	, facLecAct
	, (facLecAct-facLecAnt) AS facLecturasDif
	, facConsumoFactura
	, facConsumoReal 
	, F.fclTrfCod
	, F.trfDes
	, F.trfTipo
	FROM FAC AS F
	LEFT JOIN dbo.sectort AS S
	ON S.sctcod = F.ctrSctCod
	LEFT JOIN dbo.zonas AS Z
	ON Z.zoncod = F.ctrzoncod
	LEFT JOIN usos AS U
	ON U.usocod = F.ctrUsoCod;
	
	--FACTURAS
	IF (EXISTS(SELECT 1 FROM @params WHERE conFacturas=1))
	SELECT ctrSctCod AS [Sector Código]
	, sctdes AS [Sector]
	, facCtrCod AS [Nº Contrato]
	, facCtrVersion AS [Contrato Versión]
	, ctrTitDocIden AS [Titular]
	, ctrTitNom	AS [Titular Nombre]
	, facPerCod AS [Periodo]
	, facCod AS [Factura Código]  
	, facVersion AS [Factura Versión]
	, facNumero AS [Factura Numero]
	, ctrzoncod AS [Zona]
	, facFecha AS [Factura Fecha]
	, facLecAnt AS [Lectura Anterior]
	, facLecAct AS [Lectura Factura]
	, facLecturasDif
	, facConsumoFactura AS [Consumo Registrado (m3)] 
	, U.usodes AS [Uso]
	, fclTrfCod AS [Tarifa Cod]
	, trfDes  AS [Tarifa]
	, trfTipo AS [Tarifa Tipo]
	FROM @M3 AS M
	LEFT JOIN usos AS U
	ON U.usocod = M.ctrUsoCod
	ORDER BY sctdes, facCtrCod, facCtrVersion, facPerCod;
	--SELECT * FROM tarifas WHERE trfsrvcod=1; SELECT * FROM usos
	
	--CONTRATOS
	WITH M3_CTR AS (
	--Contratos con consumo en el rango de fechas
	SELECT facCtrCod AS ctrCod
	, trfDes
	, SUM(facConsumoFactura) AS consumo
	FROM @M3
	GROUP BY facCtrCod, trfDes
	
	), CTRS AS(
	--Ultima versión del contrato: RN=1
	SELECT M3.ctrcod
	, C.ctrversion
	, M3.consumo
	, M3.trfDes
	, C.ctrSctCod
	, C.ctrTitNom
	, C.ctrUsoCod
	, C.ctrzoncod
	, CS.ctsuds 
	, ROW_NUMBER() OVER (PARTITION BY M3.ctrcod, M3.trfDes ORDER BY  C.ctrversion DESC) AS RN 
	FROM M3_CTR AS M3
	INNER JOIN 	dbo.contratos AS C
	ON M3.ctrCod = C.ctrcod
	LEFT JOIN dbo.contratoServicio AS CS
	ON CS.ctsctrcod = M3.ctrCod
	AND CS.ctssrv=@AGUA)

	--Insertamos la ultima version del contrato con su total de consumo
	INSERT INTO @ULTIMO_CTR
	SELECT C.ctrcod
	, C.ctrversion
	, C.ctrSctCod
	, C.consumo
	, C.trfDes
	, C.ctrTitNom
	, C.ctrUsoCod
	, C.ctrzoncod
	, C.ctsuds
	FROM CTRS AS C
	WHERE C.RN=1;

	
	--RESULTADO POR CONTRATO
	SELECT C.ctrcod AS [Nº Contrato]
	, C.ctrTitNom AS [Titular Nombre]
	, C.trfDes AS [Tarifa] 
	
	, C.ctsuds AS [Usuarios]
	, C.consumo AS [Consumo (m3 registrados)]
	, Z.zondes AS [Zona]
	, ISNULL(S.sctdes, 'N/A') AS [Sector]

	FROM @ULTIMO_CTR AS C
	LEFT JOIN dbo.zonas AS Z
	ON Z.zoncod = C.ctrzoncod
	LEFT JOIN dbo.sectort AS S
	ON S.sctcod = C.ctrSctCod
	ORDER BY S.sctdes, Z.zondes, C.trfDes, C.ctrcod;
	
	--TOTALES POR SECTOR
	SELECT sctdes AS [Sector]
	, SUM(consumo) AS [Consumo (m3 registrados)] 
	FROM @ULTIMO_CTR AS C
	LEFT JOIN dbo.sectort AS S
	ON S.sctcod = C.ctrSctCod
	GROUP BY sctdes
	ORDER BY sctdes;
	
	END TRY


	BEGIN CATCH
		SELECT  @p_errId_out = ERROR_NUMBER()
			 ,  @p_errMsg_out= ERROR_MESSAGE();
	END CATCH

GO


