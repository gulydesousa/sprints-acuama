/*
SELECT *
--DELETE 
FROM ExcelFiltros WHERE ExFCodGrupo>102

--DELETE FROM excelCOnsultas WHERE ExcCod IN ('RPT/103', 'RPT/104')

SELECT *
--DELETE 
FROM ExcelFiltroGrupos WHERE ExcelGrupoFiltro>=102

INSERT INTO ExcelFiltroGrupos
VALUES('1000', 'Todos los filtros')

INSERT INTO ExcelFiltros VALUES
(1000, 'periodoD', 'Periodo Desde'),
(1000, 'periodoH', 'Periodo Hasta'),
(1000, 'versionD', 'Versión Desde'),
(1000, 'versionH', 'Versión Desde'),
(1000, 'zonaD', 'Zona Desde'),
(1000, 'zonaH', 'Zona Desde'),
(1000, 'fechaD', 'Fecha desde'),
(1000, 'fechaH', 'Fecha hasta'),
(1000, 'contratoD', 'Contrato desde'),
(1000, 'contratoH', 'Contrato hasta'),
(1000, 'preFactura', 'Prefacturas'),
(1000, 'consuMin', 'Cns. Min'),
(1000, 'consuMax', 'Cns. Max'),
(1000, 'empleadoD', 'Empleado desde'),
(1000, 'empleadoH', 'Empleado hasta'),
(1000, 'contratista', 'Contratista'),
(1000, 'Origen', 'Origen');

INSERT INTO ExcelFiltros VALUES
(1000, 'ruta1D', 'ruta1D'),
(1000, 'ruta1H', 'ruta1H'),
(1000, 'ruta2D', 'ruta2D'),
(1000, 'ruta2H', 'ruta2H'),
(1000, 'ruta3D', 'ruta3D'),
(1000, 'ruta3H', 'ruta3H'),
(1000, 'ruta4D', 'ruta4D'),
(1000, 'ruta4H', 'ruta4H'),
(1000, 'ruta5D', 'ruta5D'),
(1000, 'ruta5H', 'ruta5H'),
(1000, 'ruta6D', 'ruta6D'),
(1000, 'ruta6H', 'ruta6H');

SELECT *
--DELETE 
FROM ExcelConsultas WHERE ExcCod='RPT/104'

--INSERT INTO ExcelConsultas VALUES('RPT/104', 'Entrada de inspecciones', 'Entrada de inspecciones', 1000, '[InformesExcel].[CL008_inspeccionesEntrada]', 'CSV', 'CL008_inspeccionesEntrada', NULL, NULL, NULL, NULL)


*/

/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(MAX);

SET @p_params= '<NodoXML><LI><periodoD>202301</periodoD><zonaD></zonaD><contratoD>10</contratoD><contratoH>10</contratoH></LI></NodoXML>'

EXEC [InformesExcel].[CL008_inspeccionesEntrada] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;

SELECT @p_errId_out , @p_errMsg_out
*/





CREATE PROCEDURE [InformesExcel].[CL008_inspeccionesEntrada]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS

	--**********
	--PARAMETROS: 
	--**********
	SET NOCOUNT ON;   
	BEGIN TRY
	
	--********************
	--INICIO: 2 DataTables
	-- 1: Parametros del encabezado (FecDesde, FecHasta)
	-- 2: Datos
	--********************

	--DataTable[1]:  Parametros
	DECLARE @xml AS XML = @p_params;
	DECLARE @params TABLE (
	  periodo VARCHAR(6) NULL, zona  VARCHAR(4) NULL
	, fInforme  DATETIME
	, contratoD  INT NULL, contratoH  INT NULL);


	INSERT INTO @params
	SELECT   periodo = IIF(M.Item.value('periodoD[1]', 'VARCHAR(6)')='', NULL, M.Item.value('periodoD[1]', 'VARCHAR(6)'))
	, zona = IIF(M.Item.value('zonaD[1]', 'VARCHAR(6)')='', NULL, M.Item.value('zonaD[1]', 'VARCHAR(6)'))
	, fInforme     = GETDATE()
	, contratoD = IIF(M.Item.value('contratoD[1]', 'INT')=0, NULL, M.Item.value('contratoD[1]', 'VARCHAR(6)'))
	, contratoH = IIF(M.Item.value('contratoH[1]', 'INT')=0, NULL, M.Item.value('contratoH[1]', 'INT'))
	FROM @xml.nodes('NodoXML/LI')AS M(Item);

	SELECT contratoD, periodoD = periodo, ZonaD = zona, fInforme
		 , contratoH, periodoH = periodo, ZonaH = zona
	FROM @params;


	DECLARE @AGUA SMALLINT = 1;
	DECLARE @INCILEC VARCHAR(2)= NULL;

	SELECT @INCILEC = CASE UPPER(pgsvalor) WHEN  'GUADALAJARA' THEN 2 ELSE NULL END
	FROM parametros 
	WHERE pgsclave='EXPLOTACION';


	SELECT @AGUA = P.pgsvalor FROM  dbo.parametros AS P WHERE P.pgsclave  = 'SERVICIO_AGUA';

	--********************
	--VALIDAR PARAMETROS
	
	--********************
	DECLARE @periodo AS VARCHAR(6);
	DECLARE @zona AS VARCHAR(4);
	DECLARE @contratoD AS INT;
	DECLARE @contratoH AS INT;

	SELECT @periodo = periodo, @zona=zona, @contratoD = contratoD, @contratoH = contratoH
	FROM @params;

			
	--********************
	--DataTable[2]:  Grupos	
	SELECT * 
	FROM (VALUES (FORMATMESSAGE('Entrada%s_%s_%i_%i',ISNULL(@periodo, ''), ISNULL(@zona, ''),  ISNULL(@contratoD, ''), ISNULL(@contratoH, ''))))
	AS DataTables(Grupo);
	
	
	--********************
	SELECT facCod
	   ,facPerCod
       ,facCtrCod
       ,facVersion
	   ,facCtrVersion
       ,facSerScdCod
       ,facSerCod
       ,facNumero
       ,facFecha
       ,facClicod
       ,facSerieRectif
       ,facNumeroRectif
       ,facFechaRectif
       ,facLecAnt
       ,facLecAntFec
       ,facLecLector
       ,facLecLectorFec
       ,facLecInlCod
       ,facLecInspector
       ,facLecInspectorFec
       ,facInsInlCod
       ,facLecAct
       ,facLecActFec
       ,facConsumoReal
       ,facConsumoFactura
       ,facLote
       ,facLectorEplCod
       ,facLectorCttCod
       ,facInspectorEplCod
       ,facInspectorCttCod
       ,facNumeroRemesa
       ,facFechaRemesa
       ,facZonCod
       ,facInspeccion
	   ,facFecReg
       ,facOTNum
       ,facOTSerCod
	   ,facCnsFinal
	   ,facCnsComunitario
	   ,facFecContabilizacion
	   ,facFecContabilizacionAnu
	   ,facUsrContabilizacion
	   ,facUsrReg
	   ,facUsrContabilizacionAnu
	   ,facRazRectcod
	   ,facRazRectDescType
	   ,facMeRect
	   ,facMeRectType
	   ,facEnvSERES
	   ,facFecEmisionSERES
	   ,facEnvSAP
	   ,facTipoEmit
	   ,facNoRemesar
	INTO #FACS
	FROM facturas WHERE facCtrCod=-1;

	INSERT INTO #FACS
	EXEC dbo.Facturas_Select @contratoDesde=@contratoD, @contratoHasta=@contratoH, @periodo=@periodo, @zona=@zona;

	WITH CC AS(
	SELECT DISTINCT C.ctrComunitario
	FROM dbo.vContratosUltimaVersion AS C
	
	), CTR AS(
	SELECT DISTINCT facCtrCod FROM #FACS
	
	), SVC AS(	
	SELECT ctrcod= S.ctsctrcod, svcActivos=COUNT(S.ctsctrcod)
	FROM dbo.contratoServicio AS S
	INNER JOIN CTR AS C
	ON C.facCtrCod = S.ctsctrcod
	WHERE S.ctsfecbaj IS NULL OR S.ctsfecbaj > GETDATE()
	GROUP BY S.ctsctrcod
	
	), CNT AS(
	SELECT V.ctrCod
	, V.conDiametro
	, V.conNumSerie
	FROM dbo.vCambiosContador AS V
	INNER JOIN CTR AS C 
	ON C.facCtrCod = V.ctrCod
	AND V.esUltimaInstalacion=1
	
	), AGUA AS(
	SELECT S.*, T.trfdes
	FROM dbo.contratoServicio AS S
	INNER JOIN CTR AS C
	ON C.facCtrCod = S.ctsctrcod
	AND S.ctssrv = @AGUA
	INNER JOIN dbo.tarifas AS T
	ON T.trfsrvcod = S.ctssrv
	AND T.trfcod = S.ctstar
	WHERE S.ctsfecbaj IS NULL OR S.ctsfecbaj > GETDATE())
	

	SELECT [ContratoCodigo] = facCtrCod
	, [PeriodoCodigo] = facPerCod
	, [FacturaCodigo] = facCod
	, [Version] = facVersion
	--**************************
	--******* OTROS DATOS ******
	--**************************
	, [CtrComunitario] = IIF(CC.ctrComunitario IS NULL AND C.ctrComunitario IS NULL, NULL, ISNULL(C.ctrComunitario, C.CtrCod))
	, [Serv.Activos] = ISNULL(S.svcActivos, 0)
	, [Zona] = C.ctrzoncod
	--********************
	--******* DATOS ******
	--********************
	, [Uso] = U.usodes
	, [Tarifa] = A.trfdes
	, [Diámetro] = CNT.conDiametro
	--********************
	, [Lec.Ant.] = F.facLecAnt	
	, [Lec.Lector] = F.facLecLector
	, [Inc.Lector] = FORMATMESSAGE('%s-%s', ISNULL(F.facLecInlCod, ''), ISNULL(ILEC.inldes, ''))
	, [LecturaFactura] = F.facLecAct
	, [FechaLecturaFactura] = FORMAT(F.facLecActFec, 'dd/MM/yyyy')
	, [ConsumoFactura] = F.facConsumoFactura
	
	--***********  D A T O  **********************			*** ctrInspeccionesEntradaRU ***
	--, InspectorCodigoEmpleado = facInspectorEplCod		--ftbInsEntEmpleado (Empleado)
	--, InspectorCodigoContratista = F.facInspectorCttCod	--ddlInsEntContratista (Contratista)
	--, FechaLecturaInspector = F.facLecInspectorFec		--dtpInsEntFechaInspeccion (Fecha 1)
	--, FechaRegistro = F.facFecReg							--dtpInsEntFechaInspeccion(Fecha 1)
	--, FechaLecturaFactura = F.facLecActFec				--dtpInsFecLecFec (Fecha 2)
	--, LecturaInspector = F.facLecInspector				--tbInsInspeccion (Inspeccion)
	--, InspectorIncidenciaLectura = F.facInsInlCod			--tbInsObsInspector (Observaciones)
	--, LecturaFactura = F.facLecAct						--tbInsLecFactura (Lectura factura)
	--, ConsumoFactura = F.facConsumoFactura				--tbInsConsumoFactura	(Consumo)
	
	--****************************************
	--******* D A T O S   E N T R A D A ******
	--****************************************
	, FechaLecturaInspector = NULL
	, [*LecturaInspector] = F.facLecInspector
	, [*InspectorIncidenciaLectura] = ISNULL(F.facInsInlCod, @INCILEC)
	, [*LecturaFactura] = F.facLecAct
	, [*FechaLecturaFactura] = FORMAT(F.facLecActFec, 'dd/MM/yyyy')
	, [*ConsumoFactura] = F.facConsumoFactura
	FROM #FACS AS F
	INNER JOIN dbo.contratos AS C
	ON C.ctrcod = F.facCtrCod AND C.ctrversion = F.facCtrVersion
	LEFT JOIN dbo.usos AS U
	ON U.usocod = C.ctrUsoCod
	INNER JOIN inmuebles AS I
	ON I.inmcod = C.ctrinmcod
	LEFT JOIN dbo.empleados AS LEC
	ON F.facLectorCttCod = LEC.eplcttcod
	AND F.facLectorEplCod = LEC.eplcod
	LEFT JOIN dbo.empleados AS INS
	ON F.facInspectorCttCod = INS.eplcttcod
	AND F.facInspectorEplCod = INS.eplcod
	LEFT JOIN CC 
	ON CC.ctrComunitario = F.facCtrCod
	LEFT JOIN dbo.incilec AS ILEC
	ON ILEC.inlcod = F.facLecInlCod
	LEFT JOIN SVC AS S
	ON S.ctrcod = C.ctrcod
	LEFT JOIN CNT 
	ON CNT.ctrCod = F.facCtrCod	
	LEFT JOIN AGUA AS A
	ON A.ctsctrcod = F.facCtrCod

	ORDER BY facPerCod
	, IIF(CC.ctrComunitario IS NULL AND C.ctrComunitario IS NULL, 0, 1) --EsComunitario: Primero los no comunitarios
	, IIF(CC.ctrComunitario IS NULL AND C.ctrComunitario IS NULL, F.facCtrCod, ISNULL(C.ctrComunitario, F.facCtrCod)) --EsComunitario: Todos en el mismo grupo
	, IIF(CC.ctrComunitario IS NULL AND C.ctrComunitario IS NULL, F.facCtrCod, C.ctrComunitario) --EsComunitario: Primero la raiz y despues los nodos
	, F.facCtrCod
	END TRY

	BEGIN CATCH
		SELECT  @p_errId_out = ERROR_NUMBER()
			 ,  @p_errMsg_out= ERROR_MESSAGE();
	END CATCH


	DROP TABLE IF EXISTS #FACS;

	--IF OBJECT_ID('tempdb..#FACS') IS NOT NULL DROP TABLE #FACS;

GO


