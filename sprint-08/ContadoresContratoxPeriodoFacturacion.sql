
/*

--UPDATE ExcelConsultas SET ExcPlantilla='001' WHERE ExcCod='000/022'	

INSERT INTO ExcelConsultas VALUES(
  '000/022'	
, 'Contadores x periodo'	
, 'Contadores por periodo de facturación'
, '12'
, '[InformesExcel].[ContadoresContratoxPeriodoFacturacion]'
, '001'
, 'Listado de facturas emitidas para un periodo de facturación.<br>Permite comprobar que las facturas emitidas por periodo cuentan con servicios, líneas de factura y el <b>servicio de agua</b>. Muestra tambien los datos del <b>contador</b> actualmente instalado.' 
)

SELECT * FROM ExcelConsultas

INSERT INTO ExcelPerfil VALUES('000/022', 'root', 4, NULL)
INSERT INTO ExcelPerfil VALUES('000/022', 'jefAdmon', 4, NULL)
INSERT INTO ExcelPerfil VALUES('000/022', 'jefeExp', 4, NULL)
INSERT INTO ExcelPerfil VALUES('000/022', 'direcc', 4, NULL)

*/



/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI><periodoD>202102</periodoD><periodoH>202102</periodoH></LI></NodoXML>';

EXEC [InformesExcel].[ContadoresContratoxPeriodoFacturacion] @p_params, @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/

CREATE PROCEDURE [InformesExcel].[ContadoresContratoxPeriodoFacturacion]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS

	DECLARE @ahora DATETIME = dbo.GetAcuamaDate();
	DECLARE @svcAgua INT = 1;
	SELECT @svcAgua = pgsvalor FROM dbo.parametros WHERE pgsclave='SERVICIO_AGUA';


	--**********
	--PARAMETROS: 
	--[1]Anios: Edad
	--**********
	SET NOCOUNT ON;   
	BEGIN TRY
	
	--********************
	--INICIO: 2 DataTables
	-- 1: Parametros del encabezado (Anios)
	-- 2: Datos
	--********************

	--DataTable[1]:  Parametros
	DECLARE @xml AS XML = @p_params;
	DECLARE @params TABLE (periodoD VARCHAR(6) NULL, [(*) A la fecha actual] INT NULL, fInforme DATETIME, periodoH VARCHAR(6) NULL);

	INSERT INTO @params
	OUTPUT INSERTED.*
	SELECT periodoD = M.Item.value('periodoD[1]', 'VARCHAR(6)') 
		 , [(*)A la fecha actual] = NULL
		 , fInforme     = dbo.GetAcuamaDate()	
		 , periodoH = M.Item.value('periodoH[1]', 'VARCHAR(6)') 
		 	  			   
	FROM @xml.nodes('NodoXML/LI')AS M(Item);

	DECLARE @periodoD NVARCHAR(6);
	DECLARE @periodoH NVARCHAR(6);

	SELECT @periodoD = periodoD 
		 , @periodoH = periodoH 
	FROM @params;

	
	WITH R AS(
	SELECT C.ctrCod
	, V.conNumSerie
	, V.ctcFec
	, FL.fcltrfsvcod
	, F.faczoncod
	, F.facFecReg
	, I1.inlDes AS I1
	, I2.inlDes AS I2
	, F.facPerCod
	, [#Lineas Agua] = SUM(IIF(FL.fcltrfsvcod = @svcAgua, 1, 0)) OVER (PARTITION BY facCtrCod)
	, [Servicios Activos] = IIF(EXISTS(SELECT ctsctrcod FROM dbo.contratoServicio AS CS WHERE ctsctrcod = C.ctrcod AND (ctsFecBaj IS NULL OR @ahora < ctsFecBaj )) ,  1 ,  0)

	, RN = ROW_NUMBER() OVER (PARTITION BY facCtrCod 
						--Si hay servicio de agua es el primero
							ORDER BY IIF(FL.fcltrfsvcod IS NOT NULL AND FL.fcltrfsvcod=@svcAgua, 0, 1)
									, FL.fcltrfsvcod)
	, CS.ctsUds
	FROM dbo.contratos AS C
	INNER JOIN dbo.facturas AS F 
	ON  C.ctrcod = F.facCtrCod 
	AND C.ctrversion = F.facCtrVersion 
	AND F.facFechaRectif IS NULL
	LEFT JOIN dbo.faclin AS FL
	ON F.faccod = FL.fclfaccod 
	AND F.facpercod = FL.fclfacpercod 
	AND F.facctrcod = FL.fclfacctrcod 
	AND F.facversion = FL.fclfacversion
	AND FL.fclFecLiq IS NULL 
	AND FL.fclUsrLiq IS NULL
	LEFT JOIN fContratos_ContadoresInstalados(NULL) AS V 
	ON C.ctrcod = V.ctcCtr
	LEFT JOIN dbo.incilec AS I1 
	ON I1.inlcod = F.facLecInlCod
	LEFT JOIN dbo.incilec AS I2 
	ON I2.inlcod = F.facInsInlCod
	LEFT JOIN contratoServicio AS CS
	ON ctsctrcod = C.ctrcod 
	AND ctssrv = @svcAgua AND ctsfecbaj IS NULL
	WHERE (facPerCod >= @periodoD OR @periodoD IS NULL)
	and (facPerCod <= @periodoH OR @periodoH IS NULL)
	)

	SELECT [Contrato] = ctrCod 
	, [Periodo] = facPerCod
	, [Fac.Fecha Registro] = facFecReg

	, [Fact.Servicio Agua] = CASE WHEN fcltrfsvcod IS NULL THEN 'SIN LINEAS'
								   WHEN fcltrfsvcod = @svcAgua THEN 'SI'
								   ELSE 'NO' END 
	, [#Lineas Svc.Agua] = [#Lineas Agua] 

	, [Incidencia Lector] = I1
	, [Incidencia Lectura] = I2

	, [Contador (*)] = conNumSerie
	, [F.Instalación (*)] = ctcFec

	, [Servicios Activos (*)] = [Servicios Activos] 
	, [Uds. (*)] = ctsUds
	FROM R 
	WHERE RN=1 
	ORDER BY fcltrfsvcod DESC;

	END TRY

	BEGIN CATCH
		SELECT  @p_errId_out = ERROR_NUMBER()
			 ,  @p_errMsg_out= ERROR_MESSAGE();
	END CATCH

	--********************
	--Borrar las tablas temporales
	--IF OBJECT_ID('tempdb.dbo.#RESULT', 'U') IS NOT NULL  
	--DROP TABLE dbo.#RESULT;



GO
