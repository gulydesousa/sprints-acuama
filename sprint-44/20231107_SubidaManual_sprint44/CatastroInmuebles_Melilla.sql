/*

INSERT INTO ExcelConsultas VALUES (
  '100/004', 'Catastro Melilla'
, 'Catastro-Inmuebles: Melilla'
, 21
, '[InformesExcel].[CatastroInmuebles_Melilla]'
, 'CSV+'
, 'Catastro de Melilla relacionado con las direcciones de los inmuebles de acuama.'
, NULL, NULL, NULL, NULL)

INSERT INTO ExcelPerfil VALUES
('100/004', 'root', 3, NULL ),
('100/004', 'direcc', 3, NULL );


--DELETE FROM ExcelPerfil WHERE ExPCod='100/004'
--DELETE FROM ExcelConsultas WHERE ExcCod='100/004'

*/

/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI><zonaD>3</zonaD><zonaH>3</zonaH></LI></NodoXML>';

EXEC [InformesExcel].[CatastroInmuebles_Melilla] @p_params, @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;

*/

ALTER PROCEDURE [InformesExcel].[CatastroInmuebles_Melilla]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS

	SET NOCOUNT ON;   	
	BEGIN TRY
		
		--DataTable[1]:  Parametros
		DECLARE @xml AS XML = @p_params;

		DECLARE @params TABLE (fInforme DATETIME, zonaD VARCHAR(4) NULL, zonaH VARCHAR(4) NULL);
		INSERT INTO @params
		SELECT fInforme = GETDATE(), zonaD = M.Item.value('zonaD[1]', 'VARCHAR(4)'), zonaH = M.Item.value('zonaH[1]', 'VARCHAR(4)')	
		FROM @xml.nodes('NodoXML/LI')AS M(Item);

		--********************
		--VALIDAR PARAMETROS
		IF EXISTS(SELECT 1 FROM @params WHERE zonaD='')
		UPDATE @params SET zonaD = (SELECT MIN(zoncod) FROM dbo.zonas);

		IF EXISTS(SELECT 1 FROM @params WHERE zonaH='')
		UPDATE @params SET zonaH = (SELECT MAX(zoncod) FROM dbo.zonas);

		--**************************
		SELECT * FROM @params;

		--********************
		--INICIO:
		--********************
		DECLARE @zonaD VARCHAR(4), @zonaH VARCHAR(4);
		SELECT @zonaD = P.zonaD, @zonaH = P.zonaH FROM @params AS P;

		--********************
		--DataTable[2]:  Grupos
		SELECT * 
		FROM (VALUES   ('INFORMES CATASTRO')
					  , ('CATASTRO_CSV')
					  , ('CONTRATOS_ACTIVOS_CSV')) 
		AS DataTables(Grupo);
	

		--********************
		--#DIR: Coincidencias por Dirección		
		--********************
		SELECT C.ctrcod, C.ctrversion, C.fnDireccion_, V.RefsxPropietario, V.RefsxDireccion, V.fnTitDocIden
		, CATASTRO_ID= V.id
		INTO #DIR
		FROM vContratosActivos AS C
		INNER JOIN vCatastro AS V
		ON  C.cnCtrActivosxDireccion=1 
		AND V.RefsxDireccion=1
		AND C.fnDireccion_  COLLATE SQL_Latin1_General_CP1_CI_AI = V.fnDireccion_ COLLATE SQL_Latin1_General_CP1_CI_AI
		WHERE (@zonaD IS NULL OR C.ctrZonCod >= @zonaD) AND (@zonaH IS NULL OR C.ctrZonCod <= @zonaH);
		
		--SELECT * FROM #DIR;
		
		--********************
		--#NIF: Coincidencias por el NIF del titular 	
		--********************
		SELECT  C.ctrcod, C.ctrversion, C.fnTitDocIden, V.RefsxPropietario, V.RefsxDireccion
		, CATASTRO_ID= V.id
		, [mismaFinca] = IIF(V.fnDireccion_ COLLATE SQL_Latin1_General_CP1_CI_AI  LIKE C.fnFinca_ + '%' COLLATE SQL_Latin1_General_CP1_CI_AI, 1, 0)
		INTO #NIF
		FROM vContratosActivos AS C
		INNER JOIN vCatastro AS V
		ON  C.cnCtrActivosxTitular = 1
		AND V.RefsxPropietario = 1 
		AND C.fnTitDocIden= V.fnTitDocIden
		WHERE (@zonaD IS NULL OR C.ctrZonCod >= @zonaD) AND (@zonaH IS NULL OR C.ctrZonCod <= @zonaH);;

		--SELECT * FROM #NIF WHERE mismaFinca=0;
		
		--********************
		--#RESULT 	
		--********************
	
		SELECT [contrato]			= C.ctrcod
			 , [zona]				= C.ctrZonCod
			 , [ruta]				= C.Ruta
			 , [svc.activos]		= C.scvActivos 
			 , [ctr.activosxtit.]	= C.cnCtrActivosxTitular 
			 , [ctr.activosxdir.]	= C.cnCtrActivosxDireccion
			 , [ctr.refcatastral]	= C.inmrefcatastral	
			 , [REFCATASTRAL]		= COALESCE (CD.REFCATASTRAL, CN.REFCATASTRAL, CC.REFCATASTRAL)
			 , [ref.existe]			= CAST(IIF(C.inmrefcatastral IS NULL, NULL, IIF(C.REFCATASTRAL IS NULL, 0, 1)) AS BIT)
			 , [REFSXPROPIETARIO]	= COALESCE(D.RefsxPropietario, N.RefsxPropietario, CC.RefsxPropietario)
			 , [REFSXDIRECCION]		= COALESCE(D.RefsxDireccion, N.RefsxDireccion, CC.RefsxDireccion)
			 --**********************************************
			 , [ctr.direccion]			= C.fnDireccion_
			 , [DIRECCION]			= COALESCE(CD.DIRECCION_, CN.DIRECCION_, CC.fnDireccion_)
			 , [xDireccion]			= CAST(IIF(D.ctrcod IS NULL, 0, 1) AS BIT)
			 --**********************************************
			 , [doc.titular]		= C.fnTitDocIden
			 , [NIF]				= COALESCE(N.fnTitDocIden, D.fnTitDocIden, CC.fnTitDocIden)
			 , [xNif]				= CAST(IIF(N.ctrcod IS NULL, 0, 1) AS BIT)
			 , [xNif+Finca]			= CAST(IIF(N.ctrcod IS NULL OR N.mismaFinca=0, 0, 1) AS BIT)
			 --**********************************************
			 , [xRefCatastral]		= CAST(IIF(N.ctrcod IS NULL AND D.ctrcod IS NULL AND CC.id IS NOT NULL, 1, 0) AS BIT)
		INTO #RESULT
		FROM vContratosActivos AS C
		LEFT JOIN #DIR AS D
		ON C.ctrcod= D.ctrcod
		AND C.ctrversion = D.ctrversion
		LEFT JOIN dbo.catastro AS CD
		ON CD.id = D.CATASTRO_ID	
		LEFT JOIN #NIF AS N
		ON C.ctrcod= N.ctrcod
		AND C.ctrversion = N.ctrversion
		LEFT JOIN dbo.catastro AS CN
		ON CN.id = N.CATASTRO_ID		
		LEFT JOIN dbo.vCatastro AS CC
		ON CC.REFCATASTRAL = C.inmrefcatastral
		WHERE (@zonaD IS NULL OR C.ctrZonCod >= @zonaD) AND (@zonaH IS NULL OR C.ctrZonCod <= @zonaH);



		--********************
		--INFORMES CATASTRO: Descripcion de los datos que se seleccionan en este informe
		--********************
		SELECT * FROM (VALUES
		('Catastro Melilla','', '', 'Datos del catastro de la Ciudad Autonoma de Melilla'),
		('Catastro Melilla','NIF', 'C.A.M', 'NIF del catastro'), 
		('Catastro Melilla','NOMBRE', 'C.A.M', 'NOMBRE del catastro'), 
		('Catastro Melilla','DIRECCION', 'C.A.M', 'DIRECCION del catastro'), 
		('Catastro Melilla','REFCATASTRAL', 'C.A.M', 'REFCATASTRAL del catastro'), 
		('Catastro Melilla','refsxpropietario', 'calculado', 'Cuantas referencias hay en el catastro con el mismo NIF de propietario'), 
		('Catastro Melilla','refsxdireccion', 'calculado', 'Cuantas referencias catastrales hay para esta misma dirección'), 
		('Catastro Melilla','dir.repetida', 'calculado', '=1 si hay más de una referencia catastral para esta misma dirección'), 
		
		('Contratos Activos','', '', 'Cruce entre los contratos activos en acuama y el catastro de la Ciudad Autonoma de Melilla'), 
		('Contratos Activos','contrato', 'acuama', 'Numero de contrato'), 
		('Contratos Activos','zona', 'acuama', 'Zona'), 
		('Contratos Activos','ruta', 'acuama', 'Ruta'), 
		('Contratos Activos','svc.activos', 'acuama', 'Numero de servicios activos para este contrato'), 
		('Contratos Activos','ctr.activosxtit.', 'calculado', 'Número de contratos activos por titular.'), 
		('Contratos Activos','ctr.activosxdir.', 'calculado', 'Número de contratos activos para la misma dirección en acuama.'), 
		('Contratos Activos','ctr.refcatastral', 'acuama', 'Referencia catastral en acuama'), 
		('Contratos Activos','REFCATASTRAL', 'C.A.M', 'Referencia catastral con la que se ha encontrado la coincidencia.'), 
		('Contratos Activos','ref.existe', 'calculado', 'La referencia catastral del contrato no existe en el catastro de Melilla'), 
		('Contratos Activos','REFSXPROPIETARIO', 'calculado', 'Cuantas referencias hay en el catastro con el mismo NIF de propietario.'), 
		('Contratos Activos','REFSXDIRECCION', 'calculado', 'Cuantas referencias catastrales hay para esta misma dirección'), 
		('Contratos Activos','ctr.direccion', 'acuama', 'Dirección del inmueble'), 
		('Contratos Activos','DIRECCION', 'C.A.M', 'Dirección de la referencia en el catastro.'), 
		('Contratos Activos','xDireccion', 'calculado', 'Verdadero si la coincidencia se ha encontrado porque las direcciones son exactas.'), 
		('Contratos Activos','doc.titular', 'acuama', 'NIF del titular'), 
		('Contratos Activos','NIF', 'C.A.M', 'NIF en el catastro'), 
		('Contratos Activos','xNif', 'calculado', 'Verdadero si la coincidencia se ha encontrado porque tienen el mismo NIF.'), 
		('Contratos Activos','xNif+Finca', 'calculado', 'Verdadero si la coincidencia es por NIF y Calle + Finca.'), 
		('Contratos Activos','xRefCatastral', 'calculado', 'Verdadero si la coincidencia es porque comparten el mismo número de referencia catastral. '), 
		('Contratos Activos','resultado', 'calculado', 'Resultado del cruce entre los contratos de acuama y las referencias catastrales de la Ciudad Autonoma de Melilla.'), 
		('Contratos Activos','resultado', 'calculado', '·        Vacía: No se ha encontrado coincidencia (xDireccion, xNif, xRefCatastral) con el catastro de la Ciudad Autonoma de Melilla.'), 
		('Contratos Activos','resultado', 'calculado', '·        NUEVA: el contrato no tenía referencia catastral asociada.'), 
		('Contratos Activos','resultado', 'calculado', '·        KO: El contrato tenía una referencia catastral asociada y es diferente a la encontrada.'), 
		('Contratos Activos','resultado', 'calculado', '·        OK: El contrato tenía una referencia catastral y es igual a la encontrada.')) AS INFO(Informe, Columna, Tipo_Resultado, Descripcion)


	
		--********************
		--Catastro Melilla CSV 	
		--********************			
		SELECT NIF = fnNif
			, NOMBRE = fnTitNom_
			, DIRECCION= fnDireccion_
			, REFCATASTRAL
			, [refsxpropietario]	= RefsxPropietario
			, [refsxdireccion]		= RefsxDireccion
			, [dir.repetida] = CAST(IIF(RefsxDireccion>1, 1, 0) AS BIT)
		FROM dbo.vCatastro
		ORDER BY DIRECCION;

		--********************
		--Contratos Activos CSV 	
		--********************
		SELECT * 
		, [resultado] = CASE WHEN REFCATASTRAL IS NULL THEN NULL
								 WHEN REFCATASTRAL =  [ctr.refcatastral] THEN  'OK'
								 WHEN REFCATASTRAL <> [ctr.refcatastral] THEN 'KO'
								 ELSE 'NUEVA' END
		FROM #RESULT
		ORDER BY zona, ruta;

	END TRY
	BEGIN CATCH
		SELECT  @p_errId_out = ERROR_NUMBER()
			 ,  @p_errMsg_out= ERROR_MESSAGE();
	END CATCH
	/*
	DROP TABLE IF EXISTS #DIR;
	DROP TABLE IF EXISTS #NIF;
	DROP TABLE IF EXISTS #RESULT;
	*/

	IF OBJECT_ID('#DIR', 'U') IS NOT NULL DROP TABLE #DIR;
	IF OBJECT_ID('#NIF', 'U') IS NOT NULL DROP TABLE #NIF; 
	IF OBJECT_ID('#RESULT', 'U') IS NOT NULL DROP TABLE #RESULT; 
	
GO