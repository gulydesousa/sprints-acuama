
/*
****** CONFIGURACION ******
DROP PROCEDURE [InformesExcel].[Indicadores_Acuama] 
DELETE ExcelPerfil WHERE ExPCod='000/900'
DELETE ExcelConsultas WHERE ExcCod='000/900'


INSERT INTO dbo.ExcelConsultas
VALUES ('000/900',	'Indicadores: Acuama', 'Consulta de Indicadores', 20, '[InformesExcel].[Indicadores]', '000', 'Informe preliminar para la consulta de los indicadores: Mensuales y Semanales a la fecha indicada como parámetro', NULL);

INSERT INTO ExcelPerfil
SELECT '000/900', prfcod , 3, NULL FROM Perfiles

*/

/*

DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI><Fecha></Fecha><Semanas>12</Semanas></LI></NodoXML>';

EXEC [InformesExcel].[Indicadores] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/


ALTER PROCEDURE [InformesExcel].[Indicadores]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS

	--**********
	--PARAMETROS: 
	--[1]Fecha: Fecha
	--NULL=>Recuperamos las ayudas hasta la fecha actual
	--**********

	SET NOCOUNT ON;   
	BEGIN TRY
	
	--********************
	--INICIO: 2 DataTables
	-- 1: Parametros del encabezado (Fecha)
	-- 2: Datos
	--********************

	--DataTable[1]:  Parametros
	DECLARE @xml AS XML = @p_params;
	DECLARE @params TABLE (Fecha DATE NULL, Semanas INT NULL, fInforme DATETIME);

	INSERT INTO @params
	SELECT Fecha	= CASE WHEN M.Item.value('Fecha[1]', 'DATE') = '19000101' THEN dbo.GetAcuamaDate()
					  ELSE M.Item.value('Fecha[1]', 'DATE') END
					  
		, Semanas   = CASE WHEN M.Item.value('Semanas[1]', 'INT') = 0 THEN 12
						ELSE M.Item.value('Semanas[1]', 'INT') END

		 , fInforme = GETDATE() 
	FROM @xml.nodes('NodoXML/LI')AS M(Item);

	DECLARE @fecha DATE;
	SELECT @fecha = Fecha from @params;
	
	--***** V A R I A B L E S ******
	--***** * S E M A N A L * ******
	CREATE TABLE #FSEMANAS   (semana INT
							 , fLunes DATE
							 , fDomingo DATE
							 , _fLunes AS DATEADD(DAY, 1, fDomingo));

	DECLARE @wDesde DATE;
	DECLARE @wHasta DATE;
	DECLARE @Semanas INT;
	DECLARE @AGUA INT = 1;
	DECLARE @ALCANTARILLADO INT = 0;
	DECLARE @DOMESTICO INT = 1;
	DECLARE @MUNICIPAL INT = 3;
	DECLARE @INDUSTRIAL INT = 4;
	DECLARE @LECTURANORMAL VARCHAR(25) = '1, ';
	DECLARE @RECLAMACION VARCHAR(4) = '11';
	
	SELECT @Semanas = Semanas FROM @params;

	DECLARE @USOS AS VARCHAR(50);
	SELECT @USOS = COALESCE(@USOS + ',', '') + CAST(U.usocod AS VARCHAR(5))
	FROM dbo.usos AS U;

	
	DECLARE @INSPECCIONES VARCHAR(250);
	WITH I AS (SELECT DISTINCT facInspeccion FROM facturas WHERE facInspeccion IS NOT NULL )
	SELECT @INSPECCIONES = COALESCE(@INSPECCIONES+ ',' , '') + CAST(facInspeccion AS VARCHAR(5)) 
	FROM  I ;

	DECLARE @RESULT INT = NULL;

	DECLARE @INDICADORES AS [Indicadores].[tIndicadores_Semanal];

	
	--***** V A R I A B L E S ******
	--***** * M E N S U A L * ******
	DECLARE @mDesde DATE;
	DECLARE @mHasta DATE;
	DECLARE @mesHasta VARCHAR(8);

	SELECT @mHasta = DATEADD(DAY, -DAY(@fecha), @fecha);
	SELECT @mesHasta = FORMAT(@mHasta, 'yyyyMMdd');

	SELECT @mDesde = DATEADD(DAY, 1-DAY(@mHasta), @mHasta)
		 , @mHasta = DATEADD(DAY, 1, @mHasta);
	
	--******************************
	DECLARE @INDICADOR AS VARCHAR(5);
	DECLARE @FN AS VARCHAR(MAX);
	DECLARE @PER AS  VARCHAR(1);
	DECLARE @UD AS  VARCHAR(15);
	DECLARE @DML AS VARCHAR(500);
	DECLARE @EXEC AS VARCHAR(MAX);
	

	--******************************
	SELECT @AGUA = P.pgsvalor 
	FROM dbo.parametros AS P 
	WHERE P.pgsclave= 'SERVICIO_AGUA';

	--Buscamos el alcantarillado por la explotación
	SELECT @ALCANTARILLADO = svccod 
	FROM dbo.servicios AS S
	INNER JOIN dbo.parametros AS P
	ON P.pgsclave = 'EXPLOTACION'
	WHERE (P.pgsvalor = 'Guadalajara' AND S.svcdes='Alcantarillado');

	--Buscamos el uso por la explotación
	SELECT @DOMESTICO = usocod 
	FROM dbo.usos AS U
	INNER JOIN dbo.parametros AS P
	ON P.pgsclave = 'EXPLOTACION'
	WHERE (P.pgsvalor = 'Guadalajara' AND U.usodes='DOMESTICO');

	--Buscamos el uso por la explotación
	SELECT @MUNICIPAL = usocod 
	FROM dbo.usos AS U
	INNER JOIN dbo.parametros AS P
	ON P.pgsclave = 'EXPLOTACION'
	WHERE (P.pgsvalor = 'Guadalajara' AND U.usodes='MUNICIPAL');
	
	SELECT @INDUSTRIAL = usocod 
	FROM dbo.usos AS U
	INNER JOIN dbo.parametros AS P
	ON P.pgsclave = 'EXPLOTACION'
	WHERE (P.pgsvalor = 'Guadalajara' AND U.usodes='INDUSTRIAL');
	
	SELECT @LECTURANORMAL = CONCAT(I.inlcod, ', ')
	FROM dbo.incilec AS I
	INNER JOIN dbo.parametros AS P
	ON P.pgsclave = 'EXPLOTACION'
	WHERE (P.pgsvalor = 'Guadalajara' AND I.inldes='LECTURA NORMAL');

	SELECT @RECLAMACION = R.grecod
	FROM dbo.greclamacion AS R
	INNER JOIN dbo.parametros AS P
	ON P.pgsclave = 'EXPLOTACION'
	WHERE (P.pgsvalor = 'Guadalajara' AND R.grecod='RS');



	--******************************
	INSERT INTO #FSEMANAS
	SELECT * FROM Indicadores.fSemanas(@Fecha, @Semanas);


	IF (@@ROWCOUNT= 0) RETURN;

	SELECT @wDesde = MIN(fLunes)
		 , @wHasta = DATEADD(DAY, 1, MAX(fDomingo))
	FROM #FSEMANAS;
	--******************************
	


	--******** P A R A M E T R O S ************
	--DataTable[1]:  Parametros 
	SELECT 
	  [Semanas] = (SELECT COUNT(*) FROM #FSEMANAS)
	, [Semanal Desde] = @wDesde
	, [Semanal Hasta] = DATEADD(DAY, -1, @wHasta)
	, fInforme 
	, [Mes] = UPPER(FORMAT(@mDesde, 'MMMyyyy'))
	, [Mes Desde] = @mDesde
	, [Mes Hasta] = DATEADD(D, -1, @mHasta)
	, [Fecha]
	FROM @params


	--******  P L A N T I L L A S  ******
	DECLARE @UPDATE AS VARCHAR(250) = 
	'UPDATE I SET I.[INDICADOR] = FN.VALOR FROM ([FN]) AS FN INNER JOIN #IND_SEMANAL AS I ON I.SEMANA = FN.SEMANA';
	
	DECLARE @INSERT AS VARCHAR(250) = 
	'INSERT INTO #IND_MENSUAL SELECT ''[INDICADOR]'', ([FN]), ''[UNIDAD]'';';

	DECLARE @INSERT_RESULT AS VARCHAR(250) = 
	'DECLARE @[INDICADOR] VARCHAR(25); ' +
	'[FN];' +
	'INSERT INTO #IND_MENSUAL SELECT ''[INDICADOR]'', @[INDICADOR], ''[UNIDAD]'';';
	
	DECLARE @SELECT_UDS AS VARCHAR(MAX) = 
	'SELECT SEMANA, [F.Desde], [F.Hasta]';
	
	--Necesitaremos una tabla temporal para poder hacerlo por cursor.
	SELECT * INTO #IND_SEMANAL FROM @INDICADORES;
	CREATE  TABLE #IND_MENSUAL (INDICADOR VARCHAR(5), VALOR VARCHAR(25), UNIDAD VARCHAR(15)); 

	INSERT INTO #IND_SEMANAL([SEMANA], [F.Desde], [F.Hasta])
	SELECT semana, fLunes, fDomingo FROM #FSEMANAS;

	
	--******** C U R S O R *********
	SELECT indAcr
	, indFuncion

	, DML= CASE WHEN indPeriodicidad='S' THEN @UPDATE
				WHEN UPPER(LTRIM(indFuncion)) LIKE 'SELECT%' THEN @INSERT
				ELSE @INSERT_RESULT END
	, indUnidad
	, indPeriodicidad
	INTO #CUR
	FROM Indicadores.fAplicarParametros (@wDesde, @wHasta
									   , @mDesde, @mHasta
									   , @AGUA, @ALCANTARILLADO
									   , @DOMESTICO, @MUNICIPAL, @INDUSTRIAL
									   , @LECTURANORMAL
									   , @RECLAMACION
									   , @INSPECCIONES);

	
	--********* G R U P O S **********************
	--DataTable[2]:  Nombre de Grupos 
	SELECT * 
	FROM (VALUES('INDICADORES'), ('SEMANALES'), ('MENSUALES'), ('INFO_PRUEBAS')) 
	AS DataTables(Grupo);

	
		
	
	

	--********* R E S U L T **********************
	--Rellenamos las tablas temporales (#IND_SEMANAL, #IND_MENSUAL)
	DECLARE IND CURSOR FOR 
	SELECT * FROM #CUR;
	OPEN IND
	FETCH NEXT FROM IND INTO @INDICADOR, @FN, @DML, @UD, @PER;
	WHILE @@FETCH_STATUS = 0  
	BEGIN 
		
		SET @EXEC =  REPLACE(REPLACE(REPLACE(@DML, '[INDICADOR]', @INDICADOR), '[FN]', @FN), '[UNIDAD]', @UD);					
		
		BEGIN TRY
			EXEC(@EXEC);
		END TRY
		BEGIN CATCH
			EXEC Trabajo.errorLog_Insert '[InformesExcel].[Indicadores_Acuama]', @INDICADOR, @EXEC;
		END CATCH
		
		--***********************************************************
		--El nombre de la columna de los semanales informa la unidad
		IF (@PER = 'S')
			SET @SELECT_UDS =  @SELECT_UDS + FORMATMESSAGE(', [%s (%s)] = %s', @INDICADOR, @UD, @INDICADOR);


		FETCH NEXT FROM IND INTO @INDICADOR, @FN, @DML, @UD, @PER;
	END

	CLOSE IND;
	DEALLOCATE IND;

	--******************************
	--DataTable[3]:INDICADORES
	--******************************
	SELECT [Indicador]= indAcr
	, [Descripción] = indDescripcion
	, [Periodicidad] = CASE indPeriodicidad 
					   WHEN 'M' THEN 'Mensual' 
					   WHEN 'S' THEN 'Semanal' 
					   ELSE '??' END
	, [Dato] = indFuncionInfo
	, [Activo] = indActivo
	FROM Indicadores.IndicadoresConfig 
	ORDER BY indAcr;

	
	--******************************
	--DataTable[4]:SEMANAL
	--******************************
	--SELECT * FROM #IND_SEMANAL ORDER BY SEMANA;
	EXEC(@SELECT_UDS +' FROM #IND_SEMANAL ORDER BY SEMANA');
	
	--******************************
	--DataTable[5]:MENSUAL
	--******************************
	SELECT M.INDICADOR, M.VALOR, M.UNIDAD, I.indDescripcion 
	FROM #IND_MENSUAL AS M
	LEFT JOIN Indicadores.IndicadoresConfig AS I
	ON I.indAcr = M.INDICADOR	
	ORDER BY INDICADOR;

	--***** D E B U G ********
	--DataTable[6]: DEBUG								
	SELECT C.indAcr, C.indFuncion, C.indUnidad, C.indPeriodicidad, CC.indFuncionInfo
	FROM #CUR AS C
	LEFT JOIN Indicadores.IndicadoresConfig AS CC
	ON CC.indAcr = C.indAcr
	ORDER BY indAcr;		
	--************************
	
END TRY
	

BEGIN CATCH
	IF CURSOR_STATUS('global','IND') >= -1
	BEGIN
	IF CURSOR_STATUS('global','IND') > -1 CLOSE IND;
	DEALLOCATE IND;
	END

	SELECT  @p_errId_out = ERROR_NUMBER()
		 ,  @p_errMsg_out= ERROR_MESSAGE();
END CATCH


IF OBJECT_ID('tempdb.dbo.#FSEMANAS', 'U') IS NOT NULL 
DROP TABLE #FSEMANAS;

IF OBJECT_ID('tempdb.dbo.#IND_SEMANAL', 'U') IS NOT NULL 
DROP TABLE #IND_SEMANAL;


IF OBJECT_ID('tempdb.dbo.#IND_MENSUAL', 'U') IS NOT NULL 
DROP TABLE #IND_MENSUAL;

IF OBJECT_ID('tempdb.dbo.#CUR', 'U') IS NOT NULL 
DROP TABLE #CUR;



--SELECT @p_errMsg_out;
GO


