
/*
INSERT INTO dbo.ExcelConsultas
VALUES ('000/603',	'Lecturas x Factura', 'Datos Lectura', 18, '[InformesExcel].[LecturasxFactura]', '005', 'Detalle de lecturas por contrato');

INSERT INTO ExcelPerfil
VALUES('000/603', 'root', 4, NULL)

INSERT INTO ExcelPerfil
VALUES('000/603', 'jefeExp', 4, NULL)

INSERT INTO ExcelPerfil
VALUES('000/603', 'jefAdmon', 4, NULL)

*/

/*

	DECLARE @p_params NVARCHAR(MAX);
	DECLARE @p_errId_out INT;
	DECLARE @p_error_out INT;
	DECLARE @p_errMsg_out   NVARCHAR(MAX);

	SET @p_params= '<NodoXML><LI><periodoD>202302</periodoD><periodoH>202302</periodoH><zonaD></zonaD><zonaH></zonaH></LI></NodoXML>'

	EXEC [InformesExcel].[LecturasxFactura]  @p_params, @p_error_out OUTPUT, @p_errMsg_out OUTPUT;
*/

CREATE PROCEDURE [InformesExcel].[LecturasxFactura]
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
		
		 , fInforme = GETDATE()
		
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

	--[001]Facturas que forman parte del periodo de seleccion 	
	--#FACS
	SELECT ROW_NUMBER() OVER (ORDER BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion) AS ID
	, F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion
	, F.facCtrVersion
	, F.facNumero
	, F.facFecha
	, F.facFecReg
	, F.facFechaRectif
	, F.facLecActFec
	, F.facLecAct
	, F.facLecAntFec
	, F.facZonCod
	, F.facConsumoFactura
	, F.facEnvSERES
	, F.facEnvSap
	, F.facLecAnt
	, F.facLecInlCod
	, DATEDIFF(DAY, CAST(F.facLecAntFec AS DATE), CAST(ISNULL(F.facLecLectorFec, F.facLecActFec) AS DATE)) AS diasEntreLecturas
	
	, C.ctrfecini AS ctrFecha
	, C.ctrVersion
	, C.ctrFace
	
	, IIF(pgsvalor='AVG', CAST(F.facLecAntFec AS DATE), CAST(PZ.przfPeriodoD AS DATE)) AS fechaDesde
	, IIF(pgsvalor='AVG', CAST(F.facLecActFec AS DATE), CAST(PZ.przfPeriodoH AS DATE)) AS fechaHasta

	, PZ.przfPeriodoD
	, PZ.przfPeriodoH	
	, DATEDIFF(DAY, CAST(PZ.przfPeriodoD AS DATE), CAST(PZ.przfPeriodoH	 AS DATE)) + 1 AS diasPeriodo

	, CAST(NULL AS INT) AS ctrNuevo
	, CAST(NULL AS BIT) AS AVG_esAltaSuministro
	, CAST(NULL AS BIT) AS AVG_tieneCuotaContratacion
	, CAST(NULL AS BIT) AS esCtrNuevo
	, CAST(NULL AS VARCHAR(12)) AS facPerCod_Anterior
	, CAST(NULL AS VARCHAR(25)) AS facNumero_Anterior
	, CAST(NULL AS VARCHAR(50)) AS ctrValorc1
	, CAST(NULL AS INT) AS ctrUsoCod
	, CAST(NULL AS DATETIME) AS ctrFecIni
	, CAST(NULL AS INT) AS ctrBaja
	, CAST(NULL AS DATETIME) AS ctrFecAnu
	, CAST(NULL AS BIT) AS esAltaPosterior
	, CAST(NULL AS BIT) AS instalacionPosterior
	, CAST(NULL AS DATE) AS fecInstalacionPosterior
	, CAST(NULL AS VARCHAR(250)) AS Inmueble
	, P.*
	INTO #FACS
	FROM dbo.facturas AS F
	INNER JOIN dbo.contratos AS C
	ON C.ctrCod = F.facCtrCod
	AND C.ctrVersion = F.facCtrVersion
	LEFT JOIN dbo.perzona AS PZ
	ON  PZ.przcodzon = F.facZonCod
	AND PZ.przcodper = F.facPerCod
	LEFT JOIN dbo.parametros AS PP
	ON PP.pgsclave = 'EXPLOTACION' 
	INNER JOIN @params AS P
	ON  F.facPerCod>=P.periodoD
	AND F.facPerCod<=P.periodoH
	AND F.facFechaRectif IS NULL
	AND (P.zonaD IS NULL OR P.zonaD = '' OR F.facZonCod>=P.zonaD)
	AND (P.zonaH IS NULL OR P.zonaH = '' OR F.facZonCod<=P.zonaH);

	--[002]Ultima version del contrato
	WITH CTRS AS (
	--Contratos asociados a las facturas en consulta
	SELECT DISTINCT facCtrCod AS ctrCod 
	FROM #FACS

	), CTRNUEVO AS(
	SELECT C.ctrCod
	FROM CTRS AS C
	WHERE EXISTS(SELECT 1 FROM dbo.contratos AS CC WHERE CC.ctrNuevo = C.ctrCod)

	), CTR AS (
	--Versiones de los contratos
	SELECT C.ctrCod
	, C.ctrVersion
	, C.ctrValorc1
	, C.ctrUsoCod
	, C.ctrFecIni
	, C.ctrBaja
	, C.ctrFecAnu
	, C.ctrNuevo
	, C.ctrinmCod
	--RN=1: Ultima versión del contrato
	, ROW_NUMBER() OVER (PARTITION BY C.ctrCod ORDER BY C.ctrVersion DESC) AS RN
	FROM  dbo.contratos AS C
	INNER JOIN CTRS AS CC
	ON CC.ctrCod = C.ctrCod
	
	) , FACX AS(
	--Facturas anteriormente registradas y vigentes a la fecha del registro
	SELECT F0.facCtrCod
		 , F0.facPerCod
		 , F0.facCod
		 , F0.facVersion
		 , F0.facNumero
		 , F.facPerCod AS facPerCodKey
		 , facFecha  = MAX(F0.facFecha)
		 , facFecReg = MAX(F0.facFecReg)
		 , facNumLineas = COUNT(FL.fclFacCod)
		 --AVG:CUOTA DE CONTRATACION (100)
		 , cuotasContratacion = SUM(IIF(FL.fclTrfSvCod = 100, 1, 0))
	FROM #FACS AS F
	INNER JOIN dbo.facturas AS F0
	ON  F0.facCtrCod = F.facCtrCod
	AND F0.facPerCod <> F.facPerCod
	AND F0.facNumero IS NOT NULL
	AND F0.facFecha <= F.facFecReg
	AND (F0.facFechaRectif IS NULL OR F0.facFechaRectif>F.facFecReg)
	LEFT JOIN dbo.facLin AS FL
	ON  F0.facCod = FL.fclFacCod
	AND F0.facperCod = FL.fclFacPerCod
	AND F0.facCtrCod = FL.fclFacCtrCod
	AND F0.facVersion = FL.fclFacVersion
	GROUP BY F0.facCtrCod
		   , F0.facPerCod
		   , F0.facCod
		   , F0.facVersion 
		   , F0.facNumero
		   , F.facPerCod
		 
	), FACS AS(
	SELECT F.facCtrCod
		 , F.facPerCod
		 , F.facCod
		 , F.facVersion
		 , F.facNumero
		 , F.facPerCodKey
		 , esAltaSuministro	= IIF(F.facPerCod='000005', 1, 0)
		 , tieneCuotaContratacion = IIF(F.cuotasContratacion > 0, 1, 0)
		 --RN=1: Factura mas reciente, predecesora de la actual
		 , RN = ROW_NUMBER() OVER (PARTITION BY F.facCtrCod, F.facPerCodKey  ORDER BY F.facFecha DESC, F.facFecReg DESC, F.facNumero DESC) 
	FROM FACX AS F
	--Facturas con lineas
	WHERE F.facNumLineas>0
	
	), CONT AS(
	SELECT C.ctrCod
	, conCamFecha = MAX(CC.conCamFecha)
	FROM dbo.contadorCambio AS CC
	INNER JOIN dbo.ordenTrabajo AS OT 
	ON  CC.conCamOtSerCod = OT.otSerCod 
	AND CC.conCamOtSerScd = OT.otSerScd 
	AND CC.conCamOtNum = OT.otNum
	INNER JOIN CTR AS C
	ON  C.CtrCod= OT.otCtrCod 
	AND C.RN=1
	GROUP BY C.ctrCod)
		
	UPDATE F
	SET F.ctrValorc1 = C.ctrValorc1
	, F.ctrUsoCod = C.ctrUsoCod
	, F.ctrFecIni = C.ctrfecini
	, F.ctrBaja = C.ctrBaja
	, F.ctrFecAnu = C.ctrFecAnu
	, F.ctrNuevo = C.ctrNuevo
	, F.facPerCod_Anterior= F0.facPerCod
	, F.facNumero_Anterior= F0.facNumero
	, F.AVG_esAltaSuministro = F0.esAltaSuministro
	, F.AVG_tieneCuotaContratacion = F0.tieneCuotaContratacion
	, F.esCtrNuevo = IIF(N.ctrCod IS NULL, 0, 1)
	, F.esAltaPosterior = IIF(C.ctrfecini > F.przfPeriodoD, 1, 0)
	, F.instalacionPosterior = IIF(CC.conCamFecha IS NOT NULL AND CC.conCamFecha>F.przfPeriodoD, 1, 0)
	, F.fecInstalacionPosterior = CC.conCamFecha
	, F.Inmueble = I.inmDireccion
	FROM #FACS AS F
	INNER JOIN  CTR AS C
	ON  C.ctrcod = F.facCtrCod
	AND C.RN=1
	LEFT JOIN FACS AS F0 
	ON F.facCtrCod = F0.facCtrCod
	AND F.facPerCod = F0.facPerCodKey 
	AND F0.RN=1
	LEFT JOIN CTRNUEVO AS N
	ON C.ctrCod = N.ctrCod
	LEFT JOIN CONT AS CC
	ON C.ctrCod = CC.ctrCod
	LEFT JOIN dbo.inmuebles AS I
	ON I.inmCod = C.ctrInmCod;


	--[301]CONTADOR POR FACTURA
	--#CONTADORES
	SELECT F.facCod
	, F.facCtrCod
	, F.facPerCod
	, F.facVersion
	, F.facFecha
	, CC.conID
	, CC.conNumSerie
	, CC.conDiametro
	, RN= ROW_NUMBER() OVER (PARTITION BY F.facCod, F.facCtrCod, F.facPerCod, F.facVersion ORDER BY CC.[I.ctcFec] DESC)
	INTO #CONTADORES
	FROM #FACS AS F
	INNER JOIN dbo.vCambiosContador AS CC
	ON F.facCtrCod = CC.ctrCod
	AND CC.[I.ctcFec]< ISNULL(F.facLecActFec, @AHORA)
	AND ((CC.[R.ctcFec] IS NOT NULL AND CC.[R.ctcFec]>= ISNULL(F.facLecActFec, @AHORA)) OR  CC.[R.ctcFec] IS NULL);


	--*******************************	
	--[R01] Nombre de Grupos 
	SELECT * FROM (VALUES('FACTURA')) 
	AS DataTables(Grupo);
	
	--*******************************
	--[R02] Raíz de los datos: Facturas 	
	SELECT 
	  F.facZonCod AS [Zona]
	, F.facCtrCod AS [Contrato]
	, F.facPerCod AS [Cod.Periodo]
	, F.ctrUsoCod AS [Ctr.Uso]
	, F.Inmueble

	, [Contrato Nuevo] = F.ctrNuevo	
	, F.facEnvSERES AS [SERES Envío]
	
	, F.ctrFecIni AS [Ctr.Fecha]
	, F.ctrBaja	AS [Ctr.Baja]
	, F.ctrfecAnu AS [Ctr.Fecha Anulación]
	FROM #FACS AS F
	--IMPORTANTE mantener el orden
	ORDER BY ID ASC;
	
	
	--*******************************
	--[R03]:  Detalles de las facturas 
	SELECT  ISNULL(C.ctrTitDocIden, '***') AS [NIF]
	, C.ctrTitNom AS [Cliente]
	, F.facFecReg AS [Fecha Registro]
	, F.facFecha AS [Fecha Factura]
	, F.facNumero AS [Nº Factura Oficial]
	, F.facVersion AS [Fac.Versión]

	, F.diasEntreLecturas/90.00*3.00 AS [Factor Meses Lecturas]
	
	, CCC.conDiametro AS [Contador Calibre]
	, CCC.conNumSerie AS [Contador N.Serie]
	
	, F.facConsumoFactura AS [Cns.]
	, F.facLecAnt AS [Lectura Anterior]
	, F.facLecAntFec AS [Fec.Lectura Anterior]
	, F.facLecAct AS [Lectura Actual]
	, F.facLecActFec AS [Fec.Lectura]
	, I.inldes AS [Incidencia Lec.]
	
	FROM #FACS AS F
	LEFT JOIN dbo.contratos AS C
	ON C.ctrCod = F.facCtrCod
	AND C.ctrVersion = F.facCtrVersion
	LEFT JOIN dbo.incilec AS I
	ON I.inlcod=F.facLecInlCod
	LEFT JOIN  #CONTADORES AS CCC
	ON  CCC.facCod = F.facCod
	AND CCC.facPerCod = F.facPerCod
	AND CCC.facCtrCod = F.facCtrCod
	AND CCC.facVersion = F.facVersion
	AND CCC.RN=1
	--IMPORTANTE mantener el orden
	ORDER BY ID ASC;

	IF OBJECT_ID('tempdb.dbo.#FACS', 'U') IS NOT NULL 
	DROP TABLE #FACS;

	IF OBJECT_ID('tempdb.dbo.#CONTADORES', 'U') IS NOT NULL 
	DROP TABLE #CONTADORES;
GO


