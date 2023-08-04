
/*
--SELECT * FROM  dbo.ExcelConsultas WHERE exccod='RPT/101'
--DELETE dbo.ExcelConsultas WHERE exccod='RPT/101'

INSERT INTO ExcelFiltroGrupos VALUES (101, 'Facturacion/Facturacion/InformeLecturas');

INSERT INTO ExcelFiltros VALUES
(101, 'contratista', 'Contratista'),
(101, 'empleadoD', 'Empleado desde'),
(101, 'empleadoH', 'Empleado hasta'),
(101, 'periodoD', 'Periodo desde'),
(101, 'periodoH', 'Periodo hasta'),
(101, 'fechaD', 'Fecha desde'),
(101, 'fechaH', 'Fecha hasta'),
(101, 'zonaD', 'Zona desde'),
(101, 'zonaH', 'Zona hasta');

INSERT INTO dbo.ExcelConsultas VALUES
('RPT/101'
, 'Inf.Lecturas Detallado'
, 'Informe de Lecturas Detallado'
, 101
, '[InformesExcel].[CL018_InformeLecturas]'
, 'CSV'
, 'CL018_InformeLecturas'
, NULL, NULL, NULL, NULL);

*/




/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_error_out INT;
DECLARE @p_errMsg_out   NVARCHAR(MAX);

SET @p_params= '<NodoXML><LI><periodoD>202201</periodoD><periodoH>202202</periodoH>
						<contratista></contratista>
						<empleadoD></empleadoD><empleadoH></empleadoH>
						<fechaD></fechaD><fechaH></fechaH>
						<zonaD></zonaD><zonaH></zonaH>
						</LI></NodoXML>'

EXEC [InformesExcel].[CL018_InformeLecturas] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;

*/

ALTER PROCEDURE [InformesExcel].[CL018_InformeLecturas]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS

	SET NOCOUNT ON;   
	BEGIN TRY

	DECLARE @contratista AS SMALLINT;
	DECLARE @empleadoD AS SMALLINT;
	DECLARE @empleadoH AS SMALLINT;
	DECLARE @periodoD AS VARCHAR(6);
	DECLARE @periodoH AS VARCHAR(6);
	DECLARE @fechaD AS DATETIME;
	DECLARE @fechaH AS DATETIME;
	DECLARE @zonaD AS VARCHAR(4);
	DECLARE @zonaH AS VARCHAR(4);

	DECLARE @ruta1D AS VARCHAR(10);
	DECLARE @ruta1H AS VARCHAR(10);

	DECLARE @ruta2D AS VARCHAR(10);
	DECLARE @ruta2H AS VARCHAR(10);
	
	DECLARE @ruta3D AS VARCHAR(10);
	DECLARE @ruta3H AS VARCHAR(10);
	
	DECLARE @ruta4D AS VARCHAR(10);
	DECLARE @ruta4H AS VARCHAR(10);
	
	DECLARE @ruta5D AS VARCHAR(10);
	DECLARE @ruta5H AS VARCHAR(10);
	
	DECLARE @ruta6D AS VARCHAR(10);
	DECLARE @ruta6H AS VARCHAR(10);
	

	--DataTable[1]:  Parametros
	DECLARE @xml AS XML = @p_params;
	
	DECLARE @params TABLE (contratista INT
						 , periodoD VARCHAR(6), periodoH VARCHAR(6)
						 , empleadoD INT, empleadoH INT
						 , fInforme DATETIME
						 , fechaD DATETIME, fechaH DATETIME
						 , zonaD VARCHAR(4), zonaH VARCHAR(4)
						 , ruta1D VARCHAR(10), ruta1H VARCHAR(10)
						 , ruta2D VARCHAR(10), ruta2H VARCHAR(10)
						 , ruta3D VARCHAR(10), ruta3H VARCHAR(10)
						 , ruta4D VARCHAR(10), ruta4H VARCHAR(10)
						 , ruta5D VARCHAR(10), ruta5H VARCHAR(10)
						 , ruta6D VARCHAR(10), ruta6H VARCHAR(10));

	INSERT INTO @params
	OUTPUT INSERTED.*
	SELECT contratista	= CASE WHEN M.Item.value('contratista[1]', 'INT')	= 0 THEN NULL ELSE M.Item.value('contratista[1]', 'INT') END
		 , periodoD		= M.Item.value('periodoD[1]', 'VARCHAR(6)')
		 , periodoH		= M.Item.value('periodoH[1]', 'VARCHAR(6)')
		 , empleadoD	= CASE WHEN M.Item.value('empleadoD[1]', 'INT')		= 0 THEN NULL ELSE M.Item.value('empleadoD[1]', 'INT') END
		 , empleadoH	= CASE WHEN M.Item.value('empleadoH[1]', 'INT')		= 0 THEN NULL ELSE M.Item.value('empleadoH[1]', 'INT') END
		 , fInforme = GETDATE()
		 , fechaD		= CASE WHEN M.Item.value('fechaD[1]', 'DATETIME')='19000101' THEN NULL ELSE M.Item.value('fechaD[1]', 'DATETIME') END
		 , fechaH		= CASE WHEN M.Item.value('fechaH[1]', 'DATETIME')='19000101' THEN NULL ELSE M.Item.value('fechaH[1]', 'DATETIME') END
		 , zonaD		= CASE WHEN M.Item.value('zonaD[1]', 'VARCHAR(6)')= '' THEN NULL ELSE M.Item.value('zonaD[1]', 'VARCHAR(6)') END
		 , zonaH		= CASE WHEN M.Item.value('zonaH[1]', 'VARCHAR(6)')= '' THEN NULL ELSE M.Item.value('zonaH[1]', 'VARCHAR(6)') END			 	
	
		 , ruta1D		= CASE WHEN M.Item.value('ruta1D[1]', 'VARCHAR(10)')= '' THEN NULL ELSE M.Item.value('ruta1D[1]', 'VARCHAR(10)') END		
		 , ruta1H		= CASE WHEN M.Item.value('ruta1H[1]', 'VARCHAR(10)')= '' THEN NULL ELSE M.Item.value('ruta1H[1]', 'VARCHAR(10)') END		 	
	
		 , ruta2D		= CASE WHEN M.Item.value('ruta2D[1]', 'VARCHAR(10)')= '' THEN NULL ELSE M.Item.value('ruta2D[1]', 'VARCHAR(10)') END		
		 , ruta2H		= CASE WHEN M.Item.value('ruta2H[1]', 'VARCHAR(10)')= '' THEN NULL ELSE M.Item.value('ruta2H[1]', 'VARCHAR(10)') END		 	
	
		 , ruta3D		= CASE WHEN M.Item.value('ruta3D[1]', 'VARCHAR(10)')= '' THEN NULL ELSE M.Item.value('ruta3D[1]', 'VARCHAR(10)') END		
		 , ruta3H		= CASE WHEN M.Item.value('ruta3H[1]', 'VARCHAR(10)')= '' THEN NULL ELSE M.Item.value('ruta3H[1]', 'VARCHAR(10)') END		 	
	
		 , ruta4D		= CASE WHEN M.Item.value('ruta4D[1]', 'VARCHAR(10)')= '' THEN NULL ELSE M.Item.value('ruta4D[1]', 'VARCHAR(10)') END		
		 , ruta4H		= CASE WHEN M.Item.value('ruta4H[1]', 'VARCHAR(10)')= '' THEN NULL ELSE M.Item.value('ruta4H[1]', 'VARCHAR(10)') END		 	
	
		 , ruta5D		= CASE WHEN M.Item.value('ruta5D[1]', 'VARCHAR(10)')= '' THEN NULL ELSE M.Item.value('ruta5D[1]', 'VARCHAR(10)') END		
		 , ruta5H		= CASE WHEN M.Item.value('ruta5H[1]', 'VARCHAR(10)')= '' THEN NULL ELSE M.Item.value('ruta5H[1]', 'VARCHAR(10)') END		 	
	
		 , ruta6D		= CASE WHEN M.Item.value('ruta6D[1]', 'VARCHAR(10)')= '' THEN NULL ELSE M.Item.value('ruta6D[1]', 'VARCHAR(10)') END		
		 , ruta6H		= CASE WHEN M.Item.value('ruta6H[1]', 'VARCHAR(10)')= '' THEN NULL ELSE M.Item.value('ruta6H[1]', 'VARCHAR(10)') END		 	
	
	FROM @xml.nodes('NodoXML/LI')AS M(Item);

	SELECT @contratista = contratista
	, @empleadoD = empleadoD, @empleadoH= empleadoH
	, @periodoD  = periodoD	, @periodoH = periodoH
	, @fechaD	 = fechaD	, @fechaH	= fechaH
	, @zonaD	 = zonaD	, @zonaH	= zonaH
	, @ruta1D	 = ruta1D	, @ruta1H	= ruta1H
	, @ruta2D	 = ruta2D	, @ruta2H	= ruta2H
	, @ruta3D	 = ruta3D	, @ruta3H	= ruta3H
	, @ruta4D	 = ruta4D	, @ruta4H	= ruta4H
	, @ruta5D	 = ruta5D	, @ruta5H	= ruta5H
	, @ruta6D	 = ruta6D	, @ruta6H	= ruta6H
	FROM @params;

	SELECT Grupo='Facturas por fecha lectura lector';

	WITH RESULT AS(
	SELECT F.facCod, F.facCtrCod, F.facPerCod, F.facVersion
	, C.ctrRuta1, C.ctrRuta2, C.ctrRuta3, C.ctrRuta4, C.ctrRuta5, C.ctrRuta6
	, F.facZonCod
	, F.facLecAntFec
	, F.facLecAct
	, F.facLecActFec
	, F.facConsumoFactura
	, F.facLectorCttCod
	, F.facLectorEplCod
	, F.facLecLectorFec
	, F.facLecLector
	, F.facLecInlCod
	, F.facLecInspectorFec
	, F.facLecInspector
	, F.facInsInlCod

	FROM dbo.facturas AS F
	INNER JOIN dbo.empleados AS E 
	ON  E.eplcttcod = F.facLectorCttCod 
	AND E.eplcod = F.facLectorEplCod
	INNER JOIN dbo.zonas AS Z
	ON Z.zoncod = F.facZonCod
	INNER JOIN dbo.contratos AS C 
	ON C.ctrcod = F.facCtrCod 
	AND C.ctrversion = F.facCtrVersion

	WHERE F.facLectorCttCod IS NOT NULL 
	AND F.facLectorEplCod IS NOT NULL
	AND (@periodoD IS NULL		OR F.facPerCod >= @periodoD)
	AND (@periodoH IS NULL		OR F.facPerCod <= @periodoH)
	AND (@zonaD IS NULL			OR F.facZonCod >= @zonaD)
	AND (@zonaH IS NULL			OR F.facZonCod <= @zonaH)
	AND (@contratista IS NULL	OR F.facLectorCttCod = @contratista)
	AND (@empleadoD IS NULL		OR F.facLectorEplCod >= @empleadoD)
	AND (@empleadoH IS NULL		OR F.facLectorEplCod <= @empleadoH)
	AND (@fechaD IS NULL		OR F.facLecLectorFec >= @fechaD)
	AND (@fechaH IS NULL		OR F.facLecLectorFec <= @fechaH)
	AND (@fechaH IS NULL		OR F.facLecLectorFec <= @fechaH)
	AND (@fechaH IS NULL		OR F.facLecLectorFec <= @fechaH)

	AND (@ruta1D IS NULL		OR C.ctrRuta1 >= @ruta1D)
	AND (@ruta1H IS NULL		OR C.ctrRuta1 <= @ruta1H)
	
	AND (@ruta2D IS NULL		OR C.ctrRuta2 >= @ruta2D)
	AND (@ruta2H IS NULL		OR C.ctrRuta2 <= @ruta2H)
	
	AND (@ruta3D IS NULL		OR C.ctrRuta3 >= @ruta3D)
	AND (@ruta3H IS NULL		OR C.ctrRuta3 <= @ruta3H)
	
	AND (@ruta4D IS NULL		OR C.ctrRuta4 >= @ruta4D)
	AND (@ruta4H IS NULL		OR C.ctrRuta4 <= @ruta4H)
	
	AND (@ruta5D IS NULL		OR C.ctrRuta5 >= @ruta5D)
	AND (@ruta5H IS NULL		OR C.ctrRuta5 <= @ruta5H)
	
	AND (@ruta6D IS NULL		OR C.ctrRuta6 >= @ruta6D)
	AND (@ruta6H IS NULL		OR C.ctrRuta6 <= @ruta6H))

	SELECT [Ruta] = FORMATMESSAGE('%s.%s.%s.%s.%s.%s.%s', facZonCod, ISNULL(ctrRuta1, ''), ISNULL(ctrRuta2, ''), ISNULL(ctrRuta3, ''), ISNULL(ctrRuta4, ''), ISNULL(ctrRuta5, ''), ISNULL(ctrRuta6, ''))
	, [CONTRATO]				= facCtrCod
	, [PERIODO]					= facpercod
	, [FECHA LECTURA ANTERIOR]	= FORMAT(facLecAntFec, 'dd/MM/yyyy')
	, [FECHA LECTURA LECTOR]	= FORMAT(facLecLectorFec, 'dd/MM/yyyy')
	, [LECTURA LECTOR]			= facLecLector
	, [INC.LECTOR]				= facLecInlCod
	, [INCIDENCIA.Lector]		= IL.inldes
	, [FECHA INSPECCIÓN]		= FORMAT(facLecInspectorFec, 'dd/MM/yyyy')
	, [LECTURA INSPECCIÓN]		= facLecInspector
	, [INC.INSPECCIÓN]			= facInsInlCod
	, [INCIDENCIA.Inspector]	= II.inldes
	, [FECHA LECTURA FACTURA]	= FORMAT(facLecActFec, 'dd/MM/yyyy')
	, [LECTURA FACTURA]			= facLecAct
	, [CONSUMO]					= facConsumoFactura
	FROM RESULT AS R
	LEFT JOIN dbo.incilec AS IL
	ON IL.inlcod= R.facLecInlCod
	LEFT JOIN dbo.incilec AS II
	ON II.inlcod= R.facInsInlCod
	ORDER BY [Ruta], facpercod;

END TRY
	

BEGIN CATCH

	SELECT  @p_errId_out = ERROR_NUMBER()
		 ,  @p_errMsg_out= ERROR_MESSAGE();
END CATCH

GO	