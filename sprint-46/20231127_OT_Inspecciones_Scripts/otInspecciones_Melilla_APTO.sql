/*

INSERT INTO dbo.ExcelConsultas
VALUES ('000/013',	'Inspecciones: Aptas', 'Para comprobar el estado de las inspecciones de Melilla', 0, '[InformesExcel].[otInspecciones_Melilla_APTO]', '000', 'Para comprobar el esado de las inspecciones cargadas', NULL, NULL, NULL, NULL);

INSERT INTO ExcelPerfil
VALUES('000/013', 'root', 6, NULL)

--DELETE FROM  ExcelPerfil WHERE ExpCod='000/013'
--DELETE FROM dbo.ExcelConsultas WHERE ExcCod='000/013'

*/


/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML></NodoXML>';

EXEC [InformesExcel].[otInspecciones_Melilla_APTO] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/

ALTER PROCEDURE [InformesExcel].[otInspecciones_Melilla_APTO]
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
	
	DECLARE @params TABLE (fInforme DATETIME);

	INSERT INTO @params
	OUTPUT INSERTED.*	
	SELECT fInforme = GETDATE()
	FROM @xml.nodes('NodoXML')AS M(Item);

	--********************
	--VALIDAR PARAMETROS
	--********************

	DECLARE @ahora DATE = GETDATE();

	--********************
	
	SELECT DISTINCT otiaServicio AS Grupo FROM otInspeccionesApto_Melilla order by otiaServicio;

	
	--********************
	DECLARE @CUR CURSOR;
	DECLARE @servicio AS VARCHAR(15);
	DECLARE @TSQL AS VARCHAR(MAX);
	DECLARE @CRITICAS AS VARCHAR(500);
	DECLARE @NO_CRITICAS AS VARCHAR(500);

	SET @CUR = CURSOR FOR
	SELECT DISTINCT otiaServicio FROM otInspeccionesApto_Melilla;

	OPEN @CUR;

	FETCH NEXT FROM @CUR INTO @servicio;

	WHILE @@FETCH_STATUS = 0
	BEGIN
    
		SELECT @CRITICAS = STRING_AGG(otiaColumna, ',') 
		FROM otInspeccionesApto_Melilla
		WHERE otiaCritico='SI' and otiaServicio=@servicio

		SELECT @NO_CRITICAS = STRING_AGG(otiaColumna, ',') 
		FROM otInspeccionesApto_Melilla
		WHERE otiaCritico='NO' and otiaServicio=@servicio

		SET @TSQL = CONCAT('SELECT objectid, otnum=otinum, ctrcod, servicio, '
		,  @CRITICAS
		,  ', [**APTO**]=otdvValor, '
		, @NO_CRITICAS
		, ' FROM otInspecciones_Melilla LEFT JOIN otDatosValor ON otdvOtSerScd=otiserscd AND otdvOtSerCod=otisercod AND otdvOtNum=otinum  AND otdvOdtCodigo=2001 WHERE servicio='''
		, @servicio
		, ''' ORDER BY CASE otdvValor WHEN ''APTO 100%'' THEN 0 WHEN ''SI'' THEN 1 ELSE 2 END, objectid');

		EXEC (@TSQL);
    
		FETCH NEXT FROM @CUR INTO @servicio;
	END;

	CLOSE @CUR;
	DEALLOCATE @CUR;

	
	
END TRY
	

BEGIN CATCH


	SELECT  @p_errId_out = ERROR_NUMBER()
	     ,  @p_errMsg_out= ERROR_MESSAGE();
END CATCH




GO






