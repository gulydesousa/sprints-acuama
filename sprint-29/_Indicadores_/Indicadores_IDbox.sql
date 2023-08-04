/*
****** CONFIGURACION ******
DROP PROCEDURE [InformesExcel].[Indicadores_Plantilla] 
DELETE ExcelPerfil WHERE ExPCod='000/901'
DELETE ExcelConsultas WHERE ExcCod='000/901'


INSERT INTO dbo.ExcelConsultas
VALUES ('000/901',	'Indicadores: IDbox', 'Indicadores: Plantilla IDbox', 20, '[InformesExcel].[Indicadores_IDbox]', 'CABECERA-DATOS', '<b>Plantilla IDbox</b>: Indicadores para envio FTP', 'IDbox.jpg');

INSERT INTO ExcelPerfil
SELECT '000/901', prfcod , 3, NULL FROM Perfiles
*/

/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI><Fecha>20221207</Fecha><Frecuencia>M</Frecuencia></LI></NodoXML>';


EXEC [InformesExcel].[Indicadores_IDbox] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;

*/

ALTER PROCEDURE [InformesExcel].[Indicadores_IDbox]
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
	DECLARE @params TABLE (Fecha DATE NULL, Semanas INT NULL, fInforme DATETIME, Frecuencia VARCHAR(25), Tipo_Frecuencia VARCHAR(250));

	INSERT INTO @params
	SELECT Fecha	= CASE WHEN M.Item.value('Fecha[1]', 'DATE') = '19000101' THEN dbo.GetAcuamaDate()
					  ELSE M.Item.value('Fecha[1]', 'DATE') END
					  
		, Semanas   = CASE WHEN M.Item.value('Semanas[1]', 'INT') = 0 THEN 12
						ELSE M.Item.value('Semanas[1]', 'INT') END

		, fInforme = GETDATE() 

		, Frecuencia = M.Item.value('Frecuencia[1]', 'VARCHAR(25)') 
		, Tipo_Frecuencia = FORMATMESSAGE('%s (%s), %s (%s), %s (%s), %s (%s)', 'A fecha', 'F', 'Semanal', 'S', 'Mensual', 'M', 'Anual', 'A')
		 
	FROM @xml.nodes('NodoXML/LI')AS M(Item);

	DECLARE @fecha DATE;
	SELECT @fecha = Fecha from @params;
	
	--***** V A R I A B L E S ******
	--***** * S E M A N A L * ******
	CREATE TABLE #FSEMANAS   (semana INT
							 , fLunes DATE
							 , fDomingo DATE
							 , _fLunes AS DATEADD(DAY, 1, fDomingo));

	DECLARE @Frecuencia VARCHAR(25);
	DECLARE @Frecuencias TABLE(ID VARCHAR(5));

	DECLARE @wDesde DATE;
	DECLARE @wHasta DATE;
	DECLARE @Semanas INT;
	DECLARE @AGUA INT = 1;
	DECLARE @ALCANTARILLADO INT = 0;
	DECLARE @DOMESTICO INT = 1;
	DECLARE @NODOMESTICO VARCHAR(25) = NULL;
	DECLARE @MUNICIPAL INT = 3;
	DECLARE @NOMUNICIPAL VARCHAR(25) = NULL;
	DECLARE @INDUSTRIAL INT = 4;
	DECLARE @LECTURANORMAL VARCHAR(250) = ' ';
	DECLARE @RECLAMACION VARCHAR(4) = '11';
	
	SELECT @Semanas = ISNULL(Semanas, 12)
	     , @Frecuencia = Frecuencia 
	FROM @params;

	INSERT INTO @Frecuencias(ID)
	SELECT DISTINCT VALUE  FROM dbo.Split(@Frecuencia, ',');


	DECLARE @USOS AS VARCHAR(50);
	SELECT @USOS = COALESCE(@USOS + ',', '') + CAST(U.usocod AS VARCHAR(5))
	FROM dbo.usos AS U;

	
	DECLARE @INSPECCIONES VARCHAR(250);
	WITH I AS (SELECT DISTINCT facInspeccion FROM facturas WHERE facInspeccion IS NOT NULL )
	SELECT @INSPECCIONES = COALESCE(@INSPECCIONES+ ',' , '') + CAST(facInspeccion AS VARCHAR(5)) 
	FROM  I ;

	DECLARE @RESULT INT = NULL;
	
		
	--***** V A R I A B L E S ******
	--***** * M E N S U A L * ******
	DECLARE @mDesde DATE;
	DECLARE @mHasta_ DATE;	
	DECLARE @mHasta DATE;
	DECLARE @mesHasta VARCHAR(25);

	SELECT @mHasta_ = DATEADD(DAY, -DAY(@fecha), @fecha);
	SELECT @mesHasta = FORMAT(@mHasta_, 'dd/MM/yyyy HH:mm:ss.fff');

	SELECT @mDesde = DATEADD(DAY, 1-DAY(@mHasta_), @mHasta_)
		 , @mHasta = DATEADD(DAY, 1, @mHasta_);
	
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

	--**********************************
	SELECT @NODOMESTICO  = COALESCE(@NODOMESTICO + ',', '') + CAST(usocod AS VARCHAR(1))
	FROM dbo.usos AS U
	INNER JOIN dbo.parametros AS P
	ON P.pgsclave = 'EXPLOTACION'
	WHERE (P.pgsvalor = 'Guadalajara' AND U.usodes IN ('INDUSTRIAL', 'USO MÓVIL', 'CONTRAINCENDIO'));

	SET @NODOMESTICO = ISNULL(@NODOMESTICO, '');

	--**********************************
	SELECT @MUNICIPAL = usocod 
	FROM dbo.usos AS U
	INNER JOIN dbo.parametros AS P
	ON P.pgsclave = 'EXPLOTACION'
	WHERE (P.pgsvalor = 'Guadalajara' AND U.usodes='MUNICIPAL');
	
	--**********************************
	SELECT @NOMUNICIPAL  = COALESCE(@NOMUNICIPAL + ',', '') + CAST(usocod AS VARCHAR(1))
	FROM dbo.usos AS U
	INNER JOIN dbo.parametros AS P
	ON P.pgsclave = 'EXPLOTACION'
	WHERE (P.pgsvalor = 'Guadalajara' AND U.usodes NOT IN ('MUNICIPAL'));

	SET @NOMUNICIPAL = ISNULL(@NOMUNICIPAL, '');

	--**********************************
	SELECT @INDUSTRIAL = usocod 
	FROM dbo.usos AS U
	INNER JOIN dbo.parametros AS P
	ON P.pgsclave = 'EXPLOTACION'
	WHERE (P.pgsvalor = 'Guadalajara' AND U.usodes='INDUSTRIAL');
	
	--**********************************
	SELECT @LECTURANORMAL = COALESCE(@LECTURANORMAL + ',', '') + CAST(I.inlcod AS VARCHAR(2))
	FROM dbo.incilec AS I
	INNER JOIN dbo.parametros AS P
	ON P.pgsclave = 'EXPLOTACION'
	WHERE P.pgsvalor = 'Guadalajara'
	AND I.inlcod IN ('83', '6', '4', '63', '30', '31', '18'
					, '17', '20', '72', '98', '3', '54', '13'
					, '53', '52', '50', '23', '90', '1'
					, '12', '19', '43', '14', 'OK', '1P', '70')

	ORDER BY  I.inldes;
	 

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
	, [Frecuencia] = Frecuencia
	, [Tipo_Frecuencia] = Tipo_Frecuencia
	FROM @params

	--******  P L A N T I L L A S  ******	
	DECLARE @SELECTxSEMANA AS VARCHAR(MAX) = 
	'SELECT [Date] = FORMAT(S.[fDomingo], ''dd/MM/yyy HH:mm:ss.fff''), [Value] = ISNULL(F.[VALOR], 0), [State] = ''Normal'' FROM #FSEMANAS AS S  LEFT JOIN ([_FN_]) AS F ON F.SEMANA = S.semana ORDER BY S.[fDomingo]';

	DECLARE @SELECTxMES AS VARCHAR(MAX) = 
	'SELECT [Date] = ''[_MESHASTA_]'', [Value] = ISNULL(F.[VALOR], 0), [State] = ''Normal'' FROM ([_FN_]) AS F';

	
	DECLARE @SELECT AS VARCHAR(MAX) = 
	'SELECT [Date], [Value], [State] = ''Normal'' FROM ([_FN_]) AS F ORDER BY [Date] ASC';
	
	DECLARE @SELECT_ANUAL AS VARCHAR(MAX) = 
	'SELECT [Date] = FORMAT([FechaMes], ''dd/MM/yyy HH:mm:ss.fff''), [Value], [State] = ''Normal'' FROM ([_FN_]) AS F ORDER BY [FechaMes] ASC';
	
	DECLARE @SELECT_AFECHA AS VARCHAR(MAX) = 
	'SELECT [Date] = FORMAT(DATEADD(MILLISECOND, -2, aFecha), ''dd/MM/yyy HH:mm:ss.fff''), [Value], [State] = ''Normal'' FROM ([_FN_]) AS F ORDER BY aFecha ASC';
	

	DECLARE @SELECTxEXEC AS VARCHAR(250) = 
	'DECLARE @[_INDICADOR_] VARCHAR(25); ' +
	'[_FN_];' +
	'SELECT [Date] = ''[_MESHASTA_]'', [Value] = ISNULL(@[_INDICADOR_], 0), [State] = ''Normal'';';
		
	
	
	--******** C U R S O R *********
	SELECT indAcr
	, indFuncion
	, indUnidad
	, indPeriodicidad
	INTO #CUR
	FROM Indicadores.fAplicarParametros (@Fecha
									   , @wDesde, @wHasta
									   , @mDesde, @mHasta
									   , @AGUA, @ALCANTARILLADO
									   , @DOMESTICO, @NODOMESTICO, @MUNICIPAL, @NOMUNICIPAL, @INDUSTRIAL
									   , @LECTURANORMAL
									   , @RECLAMACION
									   , @INSPECCIONES)

	LEFT JOIN @Frecuencias AS F
	ON F.ID = indPeriodicidad
	WHERE (@Frecuencia IS NULL OR @Frecuencia= '' OR  F.ID IS NOT NULL)
	  
	--********* G R U P O S **********************
	--DataTable[2]:  Nombre de Grupos 
	--SELECT [Grupo] = C.indAcr 
	--FROM #CUR AS C
	--ORDER BY indAcr;


	--********* R E S U L T **********************
	--DataTable[4,5]: Indicador (Encabezado, Filas) 
	DECLARE IND CURSOR FOR 
	SELECT * FROM #CUR;
	OPEN IND
	FETCH NEXT FROM IND INTO @INDICADOR, @FN, @UD, @PER;
	WHILE @@FETCH_STATUS = 0  
	BEGIN 

		--**********
		--CABECERA:
		SELECT [strSheet]=@INDICADOR
		, V.* 
		FROM Indicadores.vIndicadoresPlantilla AS V 
		WHERE [TAG:]= @INDICADOR;
		--**********
	
		--**********
		--DATOS:
		IF (@PER = 'S') --Semanal
			SET @EXEC = @SELECTxSEMANA;	
		ELSE IF (@PER = 'F') --Funcion
			SET @EXEC = @SELECT_AFECHA;
		ELSE IF (@PER = 'A') --Valor Mensual: Datos anuales
			SET @EXEC = @SELECT_ANUAL;
		ELSE IF(@FN LIKE 'SELECT%')
			SET @EXEC = @SELECTxMES;
		ELSE 
			SET @EXEC = @SELECTxEXEC;

		
		SET @EXEC =  REPLACE(   
		 			 REPLACE(
					 REPLACE(@EXEC
					, '[_FN_]', @FN)
					, '[_INDICADOR_]', @INDICADOR)
					, '[_MESHASTA_]', @mesHasta);
		

		--SELECT @EXEC;
		EXEC (@EXEC);
		--**********
		
		FETCH NEXT FROM IND INTO @INDICADOR, @FN, @UD, @PER;
	END

	CLOSE IND;
	DEALLOCATE IND;
	

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

IF OBJECT_ID('tempdb.dbo.#CUR', 'U') IS NOT NULL 
DROP TABLE #CUR;



--SELECT @p_errMsg_out;
GO


