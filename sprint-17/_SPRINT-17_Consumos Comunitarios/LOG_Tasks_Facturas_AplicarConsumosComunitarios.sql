/***********************
DELETE ExcelPerfil WHERE ExPCod='LOG/001';
DELETE ExcelConsultas WHERE ExcCod='LOG/001';

INSERT INTO dbo.ExcelConsultas VALUES
('LOG/001', 'LOG Cns Comunitarios', 'ErrorLog', 1, '[InformesExcel].[LOG_Tasks_Facturas_AplicarConsumosComunitarios]', '001', 
'Consultar los tiempos de procesamiento de Tasks_Facturas_AplicarConsumosComunitarios');

INSERT INTO ExcelPerfil VALUES ('LOG/001', 'admon', 4, NULL);
INSERT INTO ExcelPerfil VALUES ('LOG/001', 'root', 4, NULL);

--SELECT * FROM ExcelConsultas
--***********************
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI><FecDesde>20220404</FecDesde><FecHasta>20230404</FecHasta></LI></NodoXML>'

EXEC [InformesExcel].[LOG_Tasks_Facturas_AplicarConsumosComunitarios] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/



ALTER PROCEDURE [InformesExcel].[LOG_Tasks_Facturas_AplicarConsumosComunitarios]
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
	--DataTable[2]:  
	
	WITH ERR AS(
	SELECT erlFecha= FORMAT(erlFecha, 'dd-MM-yyyy hh:mm:ss')
	, erlMessage
	, erlParams

	, IT = CHARINDEX('Tiempo Ejecución', erlMessage)
	, IZ =  CHARINDEX('@ctrZonCod=', erlParams)
	, IP =  CHARINDEX(', @facPerCod=', erlParams)
	, IA =  CHARINDEX(', @usarYActualizarFacCtrVersion=', erlParams)
	, IR =  CHARINDEX(', @ctrRaizCod=', erlParams)
	, IV =  CHARINDEX(', @VERSION_CNS_COMUNITARIOS=', erlParams)

	, IX =  CHARINDEX('=> ', erlMessage)
	, IT_ =  CHARINDEX(': ', erlMessage)

	, L =  LEN(erlParams)
	, LZ = LEN('@ctrZonCod=')
	, LP = LEN(', @facPerCod=')
	, LA = LEN(', @usarYActualizarFacCtrVersion=')
	, LR = LEN(', @ctrRaizCod=')
	, LV = LEN(', @VERSION_CNS_COMUNITARIOS=')
	, LT = LEN('Tiempo Ejecución')

	FROM dbo.errorLog AS E 
	INNER JOIN @params AS P
	ON E.erlFecha>= P.FecDesde
	AND E.erlFecha <P.FecHasta
	WHERE erlProcedure LIKE '%Tasks_Facturas_AplicarConsumosComunitarios'
	AND erlParams IS NOT NULL 
	AND LEN(erlParams) > 0
	)

	SELECT erlFecha
	, erlMessage
	, erlParams
	, [@ctrZonCod] = SUBSTRING(erlParams, IZ + LZ, IP-IZ-LZ)
	, [@facPerCod] = SUBSTRING(erlParams, IP + LP, IA-IP-LP)
	, [@usarYActualizarFacCtrVersion] = SUBSTRING(erlParams, IA + LA, IR-IA-LA)
	, [@ctrRaizCod] = SUBSTRING(erlParams, IR + LR, IV-IR-LR)
	, [@VERSION_CNS_COMUNITARIOS] = SUBSTRING(erlParams, IV + LV, L-IV-LV+1)
	

	, [Info] = LTRIM(IIF(IT>0, SUBSTRING(erlMessage, IT+LT, IT_-IT-LT), ''))
	, [Tiempo] = LTRIM(IIF(IT>0, SUBSTRING(erlMessage, IT_+2, L-IT_), ''))
	FROM ERR
	ORDER BY erlFecha DESC;




	END TRY

	BEGIN CATCH
		SELECT  @p_errId_out = ERROR_NUMBER()
			 ,  @p_errMsg_out= ERROR_MESSAGE();
	END CATCH


GO


