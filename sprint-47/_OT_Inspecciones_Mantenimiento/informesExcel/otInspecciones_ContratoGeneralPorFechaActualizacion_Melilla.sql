/*

INSERT INTO dbo.ExcelConsultas
VALUES ('000/014',	'Inspecciones: Actualizadas', 'Inspecciones actualizadas por fecha', 3, '[InformesExcel].[otInspecciones_ContratoGeneralPorFechaActualizacion_Melilla]', '000', 'Para comprobar el estado de las inspecciones actualizadas', NULL, NULL, NULL, NULL);

INSERT INTO ExcelPerfil
VALUES('000/014', 'root', 6, NULL)

--DELETE FROM  ExcelPerfil WHERE ExpCod='000/014'
--DELETE FROM dbo.ExcelConsultas WHERE ExcCod='000/014'

*/


/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI><Fecha>2023-12-01 13:32:10.740</Fecha></LI></NodoXML>';


EXEC [InformesExcel].[otInspecciones_ContratoGeneralPorFechaActualizacion_Melilla] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/

CREATE PROCEDURE [InformesExcel].[otInspecciones_ContratoGeneralPorFechaActualizacion_Melilla]
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
	-- 1: Paramentros del encabezado
	-- 2: Gurpos
	-- 3: Datos
	--********************
	
	--DataTable[1]:  Parametros
	DECLARE @xml AS XML = @p_params;
	
	DECLARE @params TABLE (fInforme DATETIME, Fecha DATETIME);
	
	INSERT INTO @params
	OUTPUT INSERTED.*	
	SELECT fInforme = GETDATE()
	, Fecha	= CASE WHEN M.Item.value('Fecha[1]', 'DATETIME') = '19000101' THEN NULL
			  ELSE M.Item.value('Fecha[1]', 'DATETIME') END
	FROM @xml.nodes('NodoXML/LI')AS M(Item);
	--********************
	--VALIDAR PARAMETROS
	--********************

	DECLARE @ahora DATE = GETDATE();

	--********************
	SELECT otisDescripcion AS Grupo FROM dbo.otInspeccionesServicios order by otisDescripcion;

	
	--********************
	DECLARE @PORFECHA AS VARCHAR(250) =  ''' AND FechaActualizacion =''@fecha'' ';
	DECLARE @fecha AS VARCHAR(25) = '';

	SELECT @fecha = FORMAT(Fecha, 'yyyyMMdd HH:mm:ss.fff') FROM @params WHERE Fecha IS NOT NULL;

	IF(@fecha='')
		SET @PORFECHA = ''' ';
	ELSE
		SET @PORFECHA = REPLACE(@PORFECHA, '@fecha', @fecha)
	

	DECLARE @CUR CURSOR;
	DECLARE @svcCod AS TINYINT;
	DECLARE @svcDesc AS VARCHAR(25);

	DECLARE @TSQL AS VARCHAR(MAX);
	DECLARE @CRITICAS AS VARCHAR(500);
	DECLARE @NO_CRITICAS AS VARCHAR(500);

	SET @CUR = CURSOR FOR
	SELECT otisCod, otisDescripcion FROM dbo.otInspeccionesServicios order by otisDescripcion;

	OPEN @CUR;

	FETCH NEXT FROM @CUR INTO @svcCod, @svcDesc;

	WHILE @@FETCH_STATUS = 0
	BEGIN
    
		SELECT @CRITICAS = STRING_AGG(otivColumna, ',') 
		FROM otInspeccionesValidaciones
		WHERE otivCritica=1 and otivServicioCod=@svcCod

		SELECT @NO_CRITICAS = STRING_AGG(otivColumna, ',') 
		FROM otInspeccionesValidaciones
		WHERE otivCritica=0 and otivServicioCod=@svcCod

		SET @TSQL = CONCAT('SELECT objectid, otnum=otinum, ctrcod, servicio, fecha_Insp = fecha_y_hora_de_entrega_efectiv, '
		,  @CRITICAS
		,  ', [**APTO**]=otdvValor, FechaActualizacion, RN = ROW_NUMBER() OVER (PARTITION BY ctrcod ORDER BY fecha_y_hora_de_entrega_efectiv DESC, objectid DESC),'
		, @NO_CRITICAS
		, ' FROM otInspecciones_Melilla LEFT JOIN otDatosValor ON otdvOtSerScd=otiserscd AND otdvOtSerCod=otisercod AND otdvOtNum=otinum  AND otdvOdtCodigo=2001 WHERE servicio='''
		, @svcDesc
		, @PORFECHA
		, ' ORDER BY CASE otdvValor WHEN ''APTO 100%'' THEN 0 WHEN ''SI'' THEN 1 ELSE 2 END, objectid');

		EXEC (@TSQL);

		FETCH NEXT FROM @CUR INTO @svcCod, @svcDesc;
	END;

	CLOSE @CUR;
	DEALLOCATE @CUR;

	
	
END TRY
	

BEGIN CATCH


	SELECT  @p_errId_out = ERROR_NUMBER()
	     ,  @p_errMsg_out= ERROR_MESSAGE();
END CATCH




GO
