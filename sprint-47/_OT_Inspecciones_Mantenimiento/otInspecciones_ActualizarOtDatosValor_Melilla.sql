/*
DECLARE @ReturnValue INT;
EXEC @ReturnValue = otInspecciones_ActualizarOtDatosValor_Melilla;
SELECT @ReturnValue AS 'Return Value';
*/

CREATE PROCEDURE otInspecciones_ActualizarOtDatosValor_Melilla 
@usuario VARCHAR(10)= 'admin'
AS
SET NOCOUNT ON;

DECLARE @OTTIPO_INSPECCION VARCHAR(2) = '02';
DECLARE @CODVALOR INT = 2001;
DECLARE @RESULT INT = 0;

BEGIN TRY
	BEGIN TRAN;
	--************************************************************************
	--Seleccionamos las ultimas inspecciones por contrato con estado NO-APTA
	WITH INSP AS(
	SELECT I.objectid
	, I.ctrcod
	, I.otisercod
	, I.otiserscd
	, I.otinum
	, S.otisCod
	--RN=1: Para quedarnos con la ultima inspecciñon por contrato
	, RN = ROW_NUMBER() OVER (PARTITION BY I.ctrcod ORDER BY I.fecha_y_hora_de_entrega_efectiv DESC, objectid DESC)
	FROM dbo.otInspecciones_Melilla AS I
	INNER JOIN dbo.otInspeccionesServicios AS S
	ON S.otisDescripcion = I.servicio)

	--Inspecciones no aptas para volver a validar los campos criticos
	SELECT objectid AS ID, O.otsercod, O.otserscd, O.otnum, I.otisCod
	INTO #O
	FROM INSP AS I
	INNER JOIN dbo.ordenTrabajo AS O
	ON O.otsercod = I.otisercod
	AND O.otserscd = I.otiserscd
	AND O.otnum =I.otinum
	AND O.otottcod= @OTTIPO_INSPECCION
	AND RN=1
	INNER JOIN dbo.otDatosValor AS D
	ON D.otdvOtSerCod = O.otsercod
	AND D.otdvOtSerScd = O.otserscd
	AND D.otdvOtNum = O.otnum
	AND D.otdvValor = 'NO'
	AND D.otdvOdtCodigo = @CODVALOR;


	--************************************************************************
	DECLARE @columnasCriticas AS VARCHAR(MAX);
	DECLARE @columnasNoCriticas AS VARCHAR(MAX);

	DECLARE @fnCriticas AS VARCHAR(MAX);
	DECLARE @fnNoCriticas AS VARCHAR(MAX);

	DECLARE @fnEsApto AS VARCHAR(250) = 'CASE CAST(ISNULL(@otivColumna, '''') AS VARCHAR) WHEN NULL THEN 0 WHEN ''NO'' THEN 0 WHEN ''MALO'' THEN 0 WHEN '''' THEN 0 ELSE 1 END = 1';

	DECLARE @SQL AS VARCHAR(MAX) = 'SELECT O.*, @criticas, @noCriticas, APTA=IIF(@fnCriticas, 1, 0), APTA_OPCIONAL=IIF(@fnNoCriticas, 1, 0) FROM #O AS O INNER JOIN otInspecciones_Melilla AS I ON I.objectId=O.ID WHERE otisCod=@otisCod';
	SET @SQL = 'UPDATE D SET D.otdvValor=CASE WHEN IIF(@fnCriticas, 1, 0)=0 THEN ''NO'' WHEN  IIF(@fnNoCriticas, 1, 0)=1 THEN ''APTA 100%'' ELSE ''SI'' END FROM #O AS O INNER JOIN otInspecciones_Melilla AS I ON I.objectId=O.ID AND otisCod=@otisCod INNER JOIN dbo.otDatosValor AS D ON D.otdvOtSerCod = O.otsercod AND D.otdvOtSerScd = O.otserscd AND D.otdvOtNum = O.otnum AND D.otdvOdtCodigo = 2001 '
	DECLARE @SQL_ AS VARCHAR(MAX);

	DECLARE @otisCod AS INT; 

    DECLARE CUR CURSOR FOR 
    SELECT S.otisCod  FROM otInspeccionesServicios AS S;
    
	OPEN CUR;
    FETCH NEXT FROM CUR  INTO @otisCod;

    WHILE @@FETCH_STATUS = 0
    BEGIN

		--************************************************************************
		--Columnas
		SELECT @columnasCriticas = STRING_AGG(otivColumna, ', ')
		FROM otInspeccionesValidaciones
		WHERE otivCritica=1 AND otivServicioCod=@otisCod;
		
		SELECT @columnasNoCriticas = STRING_AGG(otivColumna, ', ')
		FROM otInspeccionesValidaciones
		WHERE otivCritica=0 AND otivServicioCod=@otisCod;
		
		--************************************************************************
		--Evaluar fnEsApto
		
		SELECT @fnCriticas = STRING_AGG(REPLACE(@fnEsApto, '@otivColumna', otivColumna ), ' AND ')
		FROM otInspeccionesValidaciones
		WHERE otivCritica = 1 AND otivServicioCod = @otisCod;

		SELECT @fnNoCriticas = STRING_AGG(REPLACE(@fnEsApto, '@otivColumna', otivColumna ), ' AND ')
		FROM otInspeccionesValidaciones
		WHERE otivCritica = 0 AND otivServicioCod = @otisCod;

		SELECT @SQL_ = REPLACE(REPLACE(@SQL, '@criticas', @columnasCriticas), '@noCriticas', @columnasNoCriticas);
		SELECT @SQL_ = REPLACE(REPLACE(REPLACE(@SQL_, '@fnCriticas', @fnCriticas), '@fnNoCriticas', @fnNoCriticas), '@otisCod', @otisCod);

		--************************************************************************
		--Ejecutamos el update en DatosValor
		EXEC (@SQL_ );

		
        FETCH NEXT FROM CUR INTO @otisCod;
    END;

	--************************************************************************
	--Si de las candidatas a evaluar ha cambiado alguna a Apta, ponemos fecha de actualización en las inspecciones
	DECLARE @ahora AS DATETIME = GETDATE();
	--SELECT *
	UPDATE I SET I.FechaActualizacion = @ahora
	FROM #O AS O
	INNER JOIN dbo.otDatosValor AS D
	ON D.otdvOtSerCod = O.otsercod
	AND D.otdvOtSerScd = O.otserscd
	AND D.otdvOtNum = O.otnum
	AND D.otdvOdtCodigo = @CODVALOR
	AND D.otdvValor<>'NO'
	INNER JOIN dbo.otInspecciones_Melilla AS I
	ON I.objectid = O.ID;

	SET @RESULT = @@ROWCOUNT;

	IF(@RESULT>0)
		EXEC [dbo].[Task_Schedule_InformesExcel] @usuario, '000/014', @ahora, @ahora, 0;
	
    CLOSE CUR;
    DEALLOCATE CUR;
	
	DROP TABLE IF EXISTS #O;
	COMMIT TRAN

	RETURN @RESULT;

END TRY
BEGIN CATCH
	SET @RESULT = 0;

	IF CURSOR_STATUS('variable', 'my_cursor') >= 0
	BEGIN
		CLOSE CUR;
		DEALLOCATE CUR;
	END
	
	
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    	
	DROP TABLE IF EXISTS #O;
	THROW;
END CATCH;

GO