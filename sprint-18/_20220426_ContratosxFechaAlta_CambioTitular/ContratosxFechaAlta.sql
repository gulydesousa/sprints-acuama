/*
DELETE ExcelPerfil WHERE ExPCod='000/420';
DELETE ExcelConsultas WHERE ExcCod='000/420';

INSERT INTO dbo.ExcelConsultas VALUES
('000/420', 'Contratos fecha alta', 'Contratos por fecha alta y cambios de titular', 1, '[InformesExcel].[ContratosxFechaAlta]', '005', 
'Retorna los contratos por la fecha de alta y los servicios de consumo de vigencia mas reciente.');

INSERT INTO ExcelPerfil VALUES ('000/420', 'admon', 3, NULL);
INSERT INTO ExcelPerfil VALUES ('000/420', 'root', 3, NULL);
INSERT INTO ExcelPerfil VALUES ('000/420', 'jefeExp', 3, NULL);


*/

/*

DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_error_out INT;
DECLARE @p_errMsg_out   NVARCHAR(MAX);

SET @p_params= '<NodoXML><LI><FecDesde></FecDesde><FecHasta></FecHasta></LI></NodoXML>'

EXEC [InformesExcel].[ContratosxFechaAlta] @p_params, @p_error_out OUTPUT, @p_errMsg_out OUTPUT;
*/

CREATE PROCEDURE [InformesExcel].[ContratosxFechaAlta]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS

	--*******
	--PLANTILLA: 005
	--Se retorna: Parametros, Grupos, Raíz del grupo, Datos*
	--Grupos: Son los encabezados para el datatable de Datos*
	
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
	--DataTable[2]:  Datos
	--*******************	

	DECLARE @SVC AS TABLE(svcCod INT);

	DECLARE @CTRS AS TABLE(ctrCod INT
						 , ctrNuevo INT
						 , ctrFecIni DATE
						 , ctrInmCod INT
						 , ctrTitNom VARCHAR(100)
						 , ctrBaja BIT
						 , ctrfecanu DATETIME
						 , Raiz INT
						 , Nivel INT);

	DECLARE @fDesde DATE, @fHasta DATE;
	
	SELECT @fDesde = P.FecDesde, @fHasta = P.FecHasta
	FROM @params AS P;


	--[R00]Servicios que forman parte del informe
	INSERT INTO @SVC 
	SELECT P.pgsvalor FROM dbo.Parametros AS P  WHERE  pgsclave='SERVICIO_AGUA'
	UNION ALL	
	--VALDALIGA: Selecciona el alcantarillado
	SELECT '3' FROM dbo.Parametros AS P  WHERE  pgsclave='EXPLOTACION_CODIGO' AND pgsvalor='007';


	--*******************************	
	--Nombre de Grupos 
	WITH GRUPOS AS(
	
	SELECT SS.svcdes, S.svcCod
	FROM @SVC AS S
	INNER JOIN servicios AS SS
	ON SS.svccod = S.svcCod

	UNION ALL
	SELECT 'Cambio Titularidad', -1)
	
	SELECT svcdes AS Grupo
	FROM GRUPOS
	ORDER BY svcCod;

	--[R001]Contratos ordenados por cambio de titular
	INSERT INTO @CTRS
	EXEC dbo.Contratos_ObtenerArbolCambioTitularidad @fechaDesde=@fDesde, @fechaHasta=@fHasta;

	--[R002]Servicios por contrato
	WITH CTS AS(
	SELECT CS.* 
	--RN=1 Servicio de reciente vigencia
	, RN = ROW_NUMBER() OVER (PARTITION BY ctsctrcod, ctssrv ORDER BY IIF(ctsfecbaj IS NULL, 0, 1), ctsfecbaj DESC)
	FROM dbo.contratoServicio AS CS
	INNER JOIN @CTRS AS C
	ON C.ctrCod = CS.ctsctrcod
	INNER JOIN @SVC AS S
	ON S.svcCod = CS.ctssrv)

	SELECT CS.*
	INTO #CTS
	FROM CTS AS CS
	WHERE RN=1;

	--*******************************
	--[R03]:  Detalles de los contratos 
	SELECT [Contrato] = ctrCod
	, [Dirección Suministro] = I.inmDireccion
	, [Titular] = ctrTitNom
	, [Fecha Inicio] = ctrFecIni
	, [Baja] = ctrBaja
	, [Fecha Anulación] = ctrfecanu
	FROM @CTRS AS C
	INNER JOIN dbo.inmuebles AS I
	ON I.inmcod = C.ctrInmCod
	ORDER BY Raiz, Nivel;

	SELECT  [es Raíz] = CAST(IIF(Raiz=ctrCod, 1, 0) AS BIT)
	, [#Titulares] = COUNT(Raiz) OVER(PARTITION BY Raiz)
	, [Ctr.Raíz] = Raiz
	, [Ctr.Nivel] = ROW_NUMBER() OVER(PARTITION BY Raiz ORDER BY Nivel DESC)
	--, [Ctr.Nivel] = Nivel 
	, [Ctr.Nuevo] = ctrNuevo
	FROM @CTRS AS C
	ORDER BY Raiz, Nivel;


	--SERVICIOS
	DECLARE @svcCod INT;

	DECLARE CUR CURSOR FOR
	SELECT svcCod FROM @SVC ORDER BY svcCod;
	
	OPEN CUR
	FETCH NEXT FROM CUR INTO @svcCod;
  
	WHILE @@FETCH_STATUS = 0  
	BEGIN  

		SELECT 
		  [Cod.Servicio] = CS.ctssrv
		, [Cod.Tarifa] = CS.ctstar
		, [Tarifa] = T.trfdes
		, [Uds.] = CS.ctsuds
		, [Fecha Alta] = CS.ctsfecalt 
		, [Fecha Baja] = CS.ctsfecbaj
		FROM @CTRS AS C
		LEFT JOIN #CTS AS CS
		ON CS.ctssrv=@svcCod AND CS.ctsctrcod = C.ctrCod
		LEFT JOIN dbo.tarifas AS T
		ON T.trfsrvcod = CS.ctssrv AND T.trfcod = CS.ctstar
		ORDER BY Raiz, Nivel;
		FETCH NEXT FROM CUR INTO @svcCod;
	END

	CLOSE CUR;
	DEALLOCATE CUR;
	
	END TRY
	

	BEGIN CATCH
		IF CURSOR_STATUS('global','CUR') >= -1
		BEGIN
		IF CURSOR_STATUS('global','CUR') > -1 CLOSE CUR;
		DEALLOCATE CUR;
		END

		SELECT  @p_errId_out = ERROR_NUMBER()
			 ,  @p_errMsg_out= ERROR_MESSAGE();
	END CATCH

	IF OBJECT_ID('tempdb..#CTS') IS NOT NULL 
	DROP TABLE #CTS;   
	

	




GO


