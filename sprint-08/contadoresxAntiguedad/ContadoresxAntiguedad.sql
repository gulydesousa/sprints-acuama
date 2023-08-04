
/*

INSERT INTO ExcelConsultas VALUES(
  '000/021'	
, 'Contadores por Antiguedad'	
, 'Contadores por Antiguedad (edad en años)'
, '19'
, '[InformesExcel].[ContadoresxAntiguedad]'
, 'CSV'
, 'Contadores actualmente instalados con una edad minima.'
)

INSERT INTO ExcelPerfil VALUES('000/021', 'root', 3, NULL)
INSERT INTO ExcelPerfil VALUES('000/021', 'jefAdmon', 3, NULL)
INSERT INTO ExcelPerfil VALUES('000/021', 'jefeExp', 3, NULL)
*/

/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI><valor>12</valor><zonaD>0221</zonaD><zonaH>0521</zonaH></LI></NodoXML>';

EXEC [InformesExcel].[ContadoresxAntiguedad]  @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/


CREATE PROCEDURE [InformesExcel].[ContadoresxAntiguedad]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS
	DECLARE @EDAD INT;
	DECLARE @ZONAD VARCHAR(4);
	DECLARE @ZONAH VARCHAR(4);
	DECLARE @ahora DATE = dbo.GetAcuamaDate();

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
	DECLARE @params TABLE (zonaD VARCHAR(4) NULL, [Edad Desde] INT NULL, zonaH VARCHAR(4) NULL, fInforme DATETIME);

	INSERT INTO @params
	OUTPUT INSERTED.*
	SELECT zonaD = M.Item.value('zonaD[1]', 'VARCHAR(4)') 
		 , [Edad Desde] = M.Item.value('valor[1]', 'INT') 
		 , zonaH = M.Item.value('zonaH[1]', 'VARCHAR(4)')
		 , fInforme     = dbo.GetAcuamaDate()		  			   
	FROM @xml.nodes('NodoXML/LI')AS M(Item);

	--********************
	--DataTable[2]:  Nombre de Grupos 
	SELECT * 
	FROM (VALUES('Contadores por antiguedad')) 
	AS DataTables(Grupo)


	--********************
	--DataTable[2]:  Datos
	
	SELECT @EDAD = ISNULL(P.[Edad Desde] , 0)
		 , @ZONAD = ISNULL(P.zonaD, '')
		 , @ZONAH = ISNULL(P.zonaH, '')
	FROM @params AS P;
	
	WITH CC AS(
	SELECT C.*
		, [NEXT_OPERATION] = LEAD(C.ctcOperacion)  OVER (PARTITION BY C.ctcCon ORDER BY ctcFec ASC, ctcFecReg ASC) --Para validar el orden de las operaciones
		--[RN] =1: Operación de contador mas antigua 
		, [RN] = ROW_NUMBER() OVER (PARTITION BY C.ctcCon ORDER BY ctcFec ASC, ctcFecReg ASC)
		--[CN] : Operacioes hechas sobre un mismo contador 
		, [CN] =COUNT(C.ctcCtr) OVER (PARTITION BY C.ctcCon)
	FROM dbo.ctrcon AS C


	), _LAST AS(
	--Contadores Instalados a la fecha actual
	--La última operación es Instalación
	SELECT CC.*
	FROM CC
	WHERE RN=CN
	AND ctcOperacion = 'I'


	), _FIRST AS(
	--Primera operación registrada
	SELECT CC.*
	FROM CC
	INNER JOIN _LAST AS L
	ON CC.RN=1
	AND CC.ctcCon = L.ctcCon


	), EDAD AS (
	SELECT L.ctcCon
		 , L.ctcCtr
		 , L.ctcFec AS [Fec.Última Instalación]
		 , DATEDIFF(YEAR, L.ctcFec, @ahora) AS [Edad_N]--Años desde la última instalación
		 , F.ctcFec AS [Fec.Primera Instalación]
		 , F.ctcOperacion
		 , DATEDIFF(YEAR, F.ctcFec, @ahora) AS [Edad_1]--Años desde la primera instalación
		 , L.CN	AS [Num.Operaciones]
	FROM _LAST AS L
	LEFT JOIN _FIRST AS F
	ON L.ctcCon = F.ctcCon


	), CTR AS(
	--Contratos ordenados por version:
	SELECT C.ctrcod
		, C.ctrversion
		, C.ctrZonCod
		, C.ctrUsoCod
		, C.ctrInmCod
		, C.ctremplaza
		--[RN] =1: Última version del contrato	
		, [RN] =ROW_NUMBER() OVER (PARTITION BY C.ctrcod ORDER BY C.ctrversion DESC)
	FROM dbo.contratos AS C

	)
	--Contadores por edad
	--El campo EDAD es un campo que calculaba a partir del campo fecha instalación, que es una información que ya aparece en el informe  “CONTADOR ABONADOS” dentro del área Técnica. 
	-->>[Edad_N]/[Fec.Última Instalación]: Porque nos piden usar la fecha de instalación del informe “CONTADOR ABONADOS” que es la fecha de la última instalación del contador.
	-->>[Edad_0]/[Fec.Primera Instalación]: Sin embargo, para calcular la edad real consideramos que se debe usar la fecha de la primera operación en todo el historico de cambios de contador
	SELECT [Zona]					= CONCAT(CHAR(9), C.[ctrZonCod])
		 , [Contrato]				=CC.[ctcCtr]
		 , [Uso]					= U.[usodes]
		 , [Dirección Suministro]	= I.[inmDireccion]
		 , [Contador]				=CC.[ctcCon]
		 , [Diametro]				=CO.[conDiametro]
		 , [F.Instalación]			=FORMAT(CC.[Fec.Última Instalación], 'dd/MM/yyyy')
		 , [Marca]					= M.[mcndes]
		 , [Emplazamiento]			= E.[emcdes]
		 , [Edad]					=CC.[Edad_N]
	FROM EDAD AS CC
	INNER JOIN dbo.Contador AS CO
	ON CO.conID = CC.ctcCon
	--***************************
	--El archivo sólo debe contener todos los contadores en BB.DD. cuya edad sea > o = 12 años
	AND CC.[Edad_N] >= @EDAD
	--***************************
	LEFT JOIN dbo.marCon AS M
	ON M.mcncod = CO.conMcnCod
	LEFT JOIN CTR AS C
	ON C.ctrCod = CC.ctcCtr
	AND C.RN=1
	LEFT JOIN dbo.Usos AS U
	ON U.usoCod = C.ctrUsoCod
	LEFT JOIN dbo.inmuebles AS I
	ON I.inmCod = C.ctrInmCod
	LEFT JOIN dbo.emplaza AS E
	ON E.emccod = C.ctremplaza
	WHERE (LEN(@ZONAD)=0 OR  C.[ctrZonCod] >= @ZONAD)
	  AND (LEN(@ZONAH)=0 OR  C.[ctrZonCod] <= @ZONAH)
	--En orden ascendente por número de ruta (0010, 0111, ...7777), calle y número de portal (por ese orden).
	ORDER BY C.[ctrZonCod], I.inmCalle, I.inmfinca, I.inmentrada, I.inmbloque, I.inmplanta, I.inmpuerta;


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


