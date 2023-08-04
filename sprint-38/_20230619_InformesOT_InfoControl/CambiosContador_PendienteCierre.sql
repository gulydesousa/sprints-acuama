DROP PROCEDURE [InformesExcel].[CambiosContador_PendienteCierre];
GO
/*  
--DELETE ExcelPerfil WHERE ExPCod='000/024'
--DELETE ExcelConsultas WHERE ExcCod='000/024'
--DROP PROCEDURE [InformesExcel].[CambiosContador_PendienteCierre]
****** CONFIGURACION ******   
INSERT INTO ExcelConsultas VALUES(  
  '000/024'   
, 'Contador Cambios Pdtes.'   
, 'Ordenes de trabajo de cambio de contador pendientes de cierre'  
, '1'  
, '[InformesExcel].[CambiosContador_PendienteCierre]'  
, '001'  
, 'Selecciona las <b>Ordenes de Trabajo</b> de <i>Cambio de Contador</i> pendientes de cierre. Muestra los datos en la APP cambio contadores..<p>Se filtra por la <b>Fecha de Creación</b>: Fecha de solicitud de la OT.<p>'  
, NULL
, NULL
, NULL
, NULL)  
  
INSERT INTO ExcelPerfil VALUES('000/024', 'root', 3, NULL)  
INSERT INTO ExcelPerfil VALUES('000/024', 'jefAdmon', 3, NULL)  
INSERT INTO ExcelPerfil VALUES('000/024', 'jefeExp', 3, NULL)  
INSERT INTO ExcelPerfil VALUES('000/024', 'direcc', 3, NULL)  
*/

/*
DECLARE @p_params NVARCHAR(MAX);  
DECLARE @p_errId_out INT;  
DECLARE @p_errMsg_out NVARCHAR(2048);  
  
SET @p_params= '<NodoXML><LI><FecDesde>20230606</FecDesde><FecHasta>20230606</FecHasta></LI></NodoXML>'  
  
  
EXEC [InformesExcel].[CambiosContador_PendienteCierre] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;  
*/  
  
  
CREATE PROCEDURE [InformesExcel].[CambiosContador_PendienteCierre] 
 @p_params NVARCHAR(MAX),  
 @p_errId_out INT OUTPUT,   
 @p_errMsg_out NVARCHAR(2048) OUTPUT  
AS  

 --**********  
 --PARAMETROS:   
 --[1]FecDesde: fecha dede  
 --[2]FecHasta: fecha hasta  
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
	 DECLARE @params TABLE (FecDesde DATE NULL, fInforme DATETIME, FecHasta DATE NULL);  
  
	 INSERT INTO @params  
	 SELECT  FecDesde = CASE WHEN M.Item.value('FecDesde[1]', 'DATE') = '19000101' THEN NULL   
			 ELSE M.Item.value('FecDesde[1]', 'DATE') END  
		, fInforme     = GETDATE()  
		, FecHasta = CASE WHEN M.Item.value('FecHasta[1]', 'DATE') = '19000101' THEN NULL   
			 ELSE M.Item.value('FecHasta[1]', 'DATE') END  
	 FROM @xml.nodes('NodoXML/LI')AS M(Item);  
   
	 UPDATE @params SET FecHasta = DATEADD(DAY, 1, FecHasta)  
	 OUTPUT DELETED.*;  
   
	 --********************  
	 --VALIDAR PARAMETROS  
	 --Fechas obligatorias  
  
	 IF EXISTS(SELECT 1 FROM @params WHERE FecDesde IS NULL OR FecHasta IS NULL)  
	  THROW 50001 , 'La fecha ''desde'' y ''hasta'' son requeridos.', 1;  
	 IF EXISTS(SELECT 1 FROM @params WHERE FecDesde>FecHasta)  
	  THROW 50002 , 'La fecha ''hasta'' debe ser posterior a la fecha ''desde''.', 1;  
   
	 --******************** 
	 --[0]Variables
	DECLARE @OT_TIPO_CC INT;
	DECLARE @EXPLOTACION VARCHAR(50);

	DECLARE @contratosPK AS dbo.tContratosPK;

	DECLARE @CtrUltimaLectura AS TABLE
	( ctrcod INT
	, ctrversion	INT
	, facLecActFec DATE
	, facLecAct	INT
	, ctrLecturaUltFec DATE
	, ctrLecturaUlt INT
	, conCamFecha	DATE
	, conCamLecIns INT
	, UltimaLectura INT)

	SELECT @OT_TIPO_CC = P.pgsvalor 
	FROM dbo.parametros AS P 
	WHERE  P.pgsclave='OT_TIPO_CC';

	--******************** 
	--[1]Seleccionamos las OT pendientes
	SELECT OT.otsercod, OT.otserscd, OT.otnum
	, OT.otCtrCod
	, OT.otEplCttCod
	, OT.otEplCod
	, OT.otfsolicitud
	, OT.otFechaReg
	, OT.otFecUltMod
	, OT.otFPrevision
	, OT.otFecRechazo 
	, OT.otfrealizacion
	, OT.otfcierre
	, OT.otObsRealizacion
	INTO #OT
	FROM dbo.ordenTrabajo AS OT
	INNER JOIN @params AS P 
	ON OT.otfsolicitud>=P.FecDesde AND OT.otfsolicitud<P.FecHasta
	WHERE OT.otottcod = @OT_TIPO_CC
	  AND OT.otfcierre IS NULL;

	--SELECT * FROM #OT;

	--******************** 
	--[2]Seleccionamos los contratos involucrados con su ultima version
	WITH CTR AS(SELECT DISTINCT otCtrCod FROM #OT)
	INSERT INTO @contratosPK(ctrCod, CtrVersion)
	SELECT V.ctrCod, V.ctrVersion 
	FROM vContratosUltimaVersion AS V
	INNER JOIN CTR 
	ON CTR.otCtrCod = V.ctrCod;

	--SELECT * FROM @contratosPK;
	--******************** 
	--[3]Obtenemos las ultimas lecturas para los contratos que nos interesan en ele informe
	INSERT INTO @CtrUltimaLectura
	EXEC dbo.Contratos_ObtenerUltimaLecturaContratos @contratosPK;
	
	--SELECT * FROM @CtrUltimaLectura;

	--******************** 
	--[9]Resultado
	WITH VALOR AS(
	--Valores de los datos por OT
	SELECT OT.otserscd
	, OT.otsercod
	, OT.otnum
	, OT.otCtrCod
	, V.otdvValor
	, [Col] = CASE D.odtCodigo
				WHEN 600 THEN '_conCamLecRet'
				WHEN 601 THEN '_inicio'
				WHEN 602 THEN '_fin'
				WHEN 603 THEN '_conNumSerie'		
				WHEN 604 THEN '_conMcnDes'
				WHEN 605 THEN '_conMdlDes'
				WHEN 606 THEN '_conDiametro'
				WHEN 607 THEN '_conCaudal'
				WHEN 608 THEN '_conCamLecIns'
				WHEN 609 THEN '_conCamPrecinto'
			END
	
	FROM #OT AS OT

	INNER JOIN dbo.otDatosValor AS V
	ON  OT.otserscd = V.otdvOtSerScd
	AND OT.otsercod = V.otdvOtSerCod
	AND OT.otnum = V.otdvOtNum

	INNER JOIN dbo.otDatos AS D
	ON D.odtCodigo=V.otdvOdtCodigo

	), DATOS AS(
	--Pivotamos las filas de datos a columnas
	SELECT * FROM 
	(SELECT otserscd, otsercod, otNum, otdvValor, Col FROM VALOR) AS T
	PIVOT 
	(MAX(otdvValor) FOR Col IN ([_conCamLecRet],
								[_inicio],
								[_fin],							
								[_conNumSerie],
								[_conMcnDes],
								[_conMdlDes],
								[_conDiametro],
								[_conCaudal],
								[_conCamLecIns],
								[_conCamPrecinto]))AS PP)

		

	--********* R E S U L T A D O ********************						
	
	SELECT [OT Serie] = OT.otsercod
	, [OT Scd.] = OT.otserscd
	, [OT Num.] = OT.otnum
	, [F.Creación] = CAST(OT.otfsolicitud AS DATE)
	, [F.Realización]  = CAST(OT.otfrealizacion AS DATE) --Ha pasado las validaciones de la APP pero por alguna razón no la pudo cerrar
	, [F.Rechazo]  = CAST(OT.otFecRechazo AS DATE)		 --No se han pasado las validaciones de la APP
	, [Zona] = CTR.ctrzoncod
	, [Contrato] = OT.otCtrCod
	, [Dirección] = I.inmDireccion
	, [Titular] = CTR.ctrTitNom
	, [Observaciones] = CTR.ctrobs

	, [Contador Actual] = CC.conNumSerie
	, [Ultima Lectura] = CTR.ctrLecturaUlt
	, [Contador Marca] = MA0.mcndes
	, [Contador Modelo] = MO0.mdlDes
	, [Contador Calibre] = C0.conDiametro
	, [Lectura Retirada] = D._conCamLecRet

	, [Nuevo Contador] = D._conNumSerie
	, [Nuevo Marca] = D._conMcnDes
	, [Nuevo Modelo] = D._conMdlDes
	, [Nuevo Calibre] = D._conDiametro
	, [Nuevo Q3] = D._conCaudal
	, [Nuevo Lectura] = D._conCamLecIns
	, [Nuevo Precintado]  = D._conCamPrecinto

	, [Inicio] = D._inicio
	, [Fin] = D._fin
	, [OT Obsservaciones] = OT.otObsRealizacion

	, [Contratista] = CTT.cttnom
	, [Empleado] = E.eplnom
	, [Pendiente] = IIF(OT.otFecRechazo IS NOT NULL OR OT.otfrealizacion IS NOT NULL, 'ACUAMA', 'TPL')
	, [Ruta] = --FORMATMESSAGE('%010s.%010s.%010s.%010s.%010s'
				 FORMATMESSAGE('%s.%s.%s.%s.%s'
											 , ISNULL(CTR.ctrRuta1, '')
											 , ISNULL(CTR.ctrRuta2, '')
											 , ISNULL(CTR.ctrRuta3, '')
											 , ISNULL(CTR.ctrRuta4, '')
											 , ISNULL(CTR.ctrRuta5, '')
											 , ISNULL(CTR.ctrRuta6, ''))
											 
	FROM  #OT AS OT

	INNER JOIN @contratosPK AS C
	ON C.ctrCod = OT.otCtrCod 

	INNER JOIN dbo.contratos AS CTR
	ON  CTR.ctrcod = C.ctrCod
	AND CTR.ctrversion = C.ctrVersion
	
	LEFT JOIN dbo.vCambiosContador AS CC
	ON  CC.ctrCod = OT.otCtrCod
	--Para recuperar el ultimo contador aún instalado el en contrato 
	AND CC.esUltimaInstalacion = 1
	AND CC.opRetirada IS NULL
	
	LEFT JOIN dbo.contador AS C0
	ON C0.conID = CC.conId
	LEFT JOIN dbo.marcon AS MA0
	ON C0.conMcnCod = MA0.mcncod
	LEFT JOIN dbo.modcon AS MO0
	ON  MO0.mdlMcnCod = C0.conMcnCod
	AND MO0.mdlCod = C0.conMdlCod
	
	LEFT JOIN @CtrUltimaLectura AS L
	ON L.ctrcod= OT.otCtrCod
	
	LEFT JOIN dbo.inmuebles AS I
	ON I.inmcod = CTR.ctrinmcod
	
	LEFT JOIN DATOS AS D
	ON  OT.otsercod = D.otsercod
	AND OT.otserscd = D.otserscd
	AND OT.otnum = D.otnum
	
	LEFT JOIN dbo.contratistas AS CTT
	ON CTT.cttcod = OT.otEplCttCod
	LEFT JOIN dbo.empleados AS E
	ON  E.eplcttcod = OT.otEplCttCod
	AND E.eplcod = OT.otEplCod
	ORDER BY Zona, Ruta;
	
END TRY

BEGIN CATCH  
SELECT  @p_errId_out = ERROR_NUMBER()  
,  @p_errMsg_out= ERROR_MESSAGE();  
END CATCH  
  

DROP TABLE IF EXISTS #OT;

GO