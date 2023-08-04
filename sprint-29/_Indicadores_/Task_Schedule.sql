/*
	DECLARE @frecuencia VARCHAR(1) = 'S';
	DECLARE @fDesde AS DATE= '20221201';
	DECLARE @fHasta AS DATE= '20221231';
	DECLARE @diaEjecucion INT = 7
	DECLARE @horaEjecucion INT = '7';
	DECLARE @usuario VARCHAR(10) = 'gmdesousa';
	DECLARE @tipoEnvio INT = 3; --Email+Ftp
	
	EXEC Indicadores.Task_Schedule @frecuencia,  @fDesde, @fHasta, @diaEjecucion, @horaEjecucion, @usuario, @tipoEnvio;

	--DELETE FROM Task_Schedule WHERE tskuser='gmdesousa'

	SELECT * FROM ftpSites
*/	

ALTER PROCEDURE Indicadores.Task_Schedule
	  @frecuencia VARCHAR(1)
	, @fDesde AS DATE
	, @fHasta AS DATE
	, @diaEjecucion INT
	, @horaEjecucion INT
	, @usuario VARCHAR(10)
	, @tipoEnvio INT

AS

	DECLARE @scheduleDate DATETIME

	DECLARE @diaDesde AS DATETIME;
	DECLARE @diaHasta AS DATETIME;

	DECLARE @excCod AS VARCHAR(20);
	DECLARE @excConsulta AS VARCHAR(MAX);
	DECLARE @aFecha AS DATE = @fDesde;


	SET @excConsulta = CASE @frecuencia 	
					  WHEN 'F' THEN '%Indicadores_IDbox_Afecha%'
					  WHEN 'S' THEN '%Indicadores_IDbox_Semanales%'
					  WHEN 'M' THEN  '%Indicadores_IDbox_Mensuales%'
					  WHEN 'A' THEN '%Indicadores_IDbox_Anuales%'
					  END;


	--Los indicadores se sacan cada [dia] 1:L-7:D
	SELECT @diaDesde = Indicadores.fPrimerDiaMes(@fDesde, @diaEjecucion)
		 , @diaHasta = @fHasta
		 , @excCod = ExcCod 
	FROM dbo.ExcelConsultas AS E WHERE E.ExcConsulta LIKE @excConsulta;


	SELECT [@fDesde] = @fDesde, [@diaEjecucion]=@diaEjecucion;

	--**********************************
	--PRIMERA ITERACION
	--**********************************
	SET @aFecha = CASE @frecuencia
				  WHEN 'M' THEN --Se ejecuta el primer dia 1:L-7:D de cada mes y recupera los datos del mes  anterior
				  Indicadores.fPrimerDiaMes(@diaDesde, @diaEjecucion)
				  WHEN 'A' THEN --Se ejecuta el primer dia 1:L-7:D de cada mes y recupera los datos de los ultimos 12 meses
				  Indicadores.fPrimerDiaMes(@diaDesde, @diaEjecucion)
				  WHEN 'S'	THEN --Se ejecuta cada dia 1:L-7:D con los datos de N semanas anteriores
				  @diaDesde
				  WHEN 'F'	THEN --Se ejecuta cada dia 1:L-7:D con los datos a la fecha
				  @diaDesde
				  END



	--**********************************
	--LOOP
	--**********************************
	DECLARE @delay INT = 0;

	WHILE(@diaDesde IS NOT NULL AND @diaHasta IS NOT NULL  AND @aFecha <= @diaHasta)
	BEGIN
	
		SET  @scheduleDate = DATEADD(HOUR, @horaEjecucion, CAST(@aFecha AS DATETIME));


		--*************************************************************
		--Añadimos un delay a la fecha de programación para evitar que tareas con fecha pasada se ejecuten todas en simultaneo
		IF @scheduleDate<GETDATE()
		BEGIN
			SELECT @delay = @delay+1, @scheduleDate= DATEADD(MINUTE, @delay, GETDATE());
		END
		--*************************************************************

		--Comprobamos que la tarea no esté ya programada y pendiente antes de volver a intentar
		IF NOT EXISTS(
		SELECT S.tskUser, S.tskType, S.tskNumber
		, codID = MAX(IIF(tskpName='codId', tskpValue, NULL))
		, Fecha = MAX(IIF(tskpName='Fecha', tskpValue, NULL))
		FROM dbo.Task_Schedule AS S
		INNER JOIN dbo.Task_Parameters AS P
		ON S.tskUser = P.tskpUser
		AND S.tskType = P.tskpType
		AND S.tskNumber = P.tskpNumber
		WHERE tskUser=@usuario AND tskType=520 AND tskFinishedDate IS NULL
		GROUP BY S.tskUser, S.tskType, S.tskNumber
		HAVING  MAX(IIF(tskpName='Fecha', tskpValue, NULL)) = @aFecha
		    AND MAX(IIF(tskpName='codId', tskpValue, NULL)) = @excCod)

		EXEC  [dbo].[Task_Schedule_InformesExcel] @usuario, @excCod, @scheduleDate, @aFecha, @tipoEnvio;
		
		SELECT [@usuario] = @usuario, [@excCod] = @excCod, [@scheduleDate] = @scheduleDate, [@aFecha] = @aFecha, [@tipoEnvio] = @tipoEnvio;

		--**********************************
		--SIGUIENTE ITERACION
		--**********************************
		SET @aFecha = CASE @frecuencia 
						WHEN 'M' THEN	--Se ejecuta el primer dia 1:L-7:D de cada mes y recupera los datos del mes  anterior
						Indicadores.fPrimerDiaMes(DATEADD(MONTH, 1, @aFecha), @diaEjecucion) 
						WHEN 'A' THEN	--Se ejecuta el primer dia 1:L-7:D de cada mes y recupera los datos de los ultimos 12 meses
						Indicadores.fPrimerDiaMes(DATEADD(MONTH, 1, @aFecha), @diaEjecucion) 
						WHEN 'S' THEN	--Se ejecuta cada dia 1:L-7:D con los datos de N semanas anteriores
						DATEADD(WEEK, 1, @aFecha)
						WHEN 'F' THEN	--Se ejecuta cada dia 1:L-7:D con los datos a la fecha
						DATEADD(WEEK, 1, @aFecha)						
						END		
	END
	
GO

	
	--DELETE FROM task_Schedule WHERE tskUser='gmdesousa'