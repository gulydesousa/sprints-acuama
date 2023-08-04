
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

SET @p_params= '<NodoXML><LI><Fecha>20221113</Fecha><Semanas></Semanas></LI></NodoXML>';

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
	DECLARE @SELECTxSEMANA AS VARCHAR(MAX) = 
	'SELECT [Date] = FORMAT(S.[fDomingo], ''dd/MM/yyy HH:mm:ss.fff''), [Value] = ISNULL(F.[VALOR], 0), [State] = ''Normal'' FROM #FSEMANAS AS S  LEFT JOIN ([_FN_]) AS F ON F.SEMANA = S.semana ORDER BY S.[fDomingo]';

	DECLARE @SELECTxMES AS VARCHAR(MAX) = 
	'SELECT [Date] = ''[_MESHASTA_]'', [Value] = ISNULL(F.[VALOR], 0), [State] = ''Normal'' FROM ([_FN_]) AS F';
	
	DECLARE @SELECTxEXEC AS VARCHAR(250) = 
	'DECLARE @[_INDICADOR_] VARCHAR(25); ' +
	'[_FN_];' +
	'SELECT [Date] = ''[_MESHASTA_]'', [Value] = ISNULL(@[_INDICADOR_], 0), [State] = ''Normal'';';
		
	
	--******** INCLUIR MENSUALES *********
	DECLARE @Mensual VARCHAR(1) = '';

	SELECT @Mensual = 'M'  
	FROM #FSEMANAS AS S
	--La ultima semana de los semanales incluye el final del mes
	WHERE S.semana=@Semanas AND @mHasta_ BETWEEN S.fLunes and S.fDomingo ;
	
	--SELECT [@Mensual] = @Mensual;
	   
	--******** C U R S O R *********
	SELECT indAcr
	, indFuncion
	, indUnidad
	, indPeriodicidad
	INTO #CUR
	FROM Indicadores.fAplicarParametros (@wDesde, @wHasta
									   , @mDesde, @mHasta
									   , @AGUA, @ALCANTARILLADO
									   , @DOMESTICO, @MUNICIPAL, @INDUSTRIAL
									   , @LECTURANORMAL
									   , @RECLAMACION
									   , @INSPECCIONES)
	WHERE indPeriodicidad = 'S' OR indPeriodicidad=@Mensual;

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
		IF (@PER = 'S')
			SET @EXEC = @SELECTxSEMANA;
		ELSE IF(@FN LIKE 'SELECT%')
			SET @EXEC = @SELECTxMES;
		ELSE 
			SET @EXEC = @SELECTxEXEC;

		SET @EXEC =REPLACE(   
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


