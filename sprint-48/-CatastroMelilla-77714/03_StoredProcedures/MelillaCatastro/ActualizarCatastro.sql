--DROP PROCEDURE [InformesExcel].[CatastroInmuebles_Melilla]

/*
INSERT INTO ExcelConsultas VALUES (
  '100/004', 'Catastro Melilla'
, 'Catastro-Inmuebles: Melilla'
, 21
, '[MelillaCatastro].[ActualizarCatastro]'
, 'CSV+'
, 'Catastro de Melilla relacionado con las direcciones de los inmuebles de acuama.'
, NULL, NULL, NULL, NULL)

INSERT INTO ExcelPerfil VALUES
('100/004', 'root', 3, NULL ),
('100/004', 'direcc', 3, NULL );


--DELETE FROM ExcelPerfil WHERE ExPCod='100/004'
--DELETE FROM ExcelConsultas WHERE ExcCod='100/004'
--SELECT * FROM excelfiltros ORDER BY ExFCodGrupo
*/



/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI><zonaD></zonaD><zonaH></zonaH></LI></NodoXML>';

EXEC [MelillaCatastro].[ActualizarCatastro] @p_params, @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/
CREATE PROCEDURE [MelillaCatastro].[ActualizarCatastro]
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
					  , ('CORRESPONDENCIAS')
					  , ('CONTRATOS_ACTIVOS_CSV')) 
		AS DataTables(Grupo);

		
		--********************
		--#DIR: Coincidencias por Dirección		
		--********************
		SELECT C.ctrcod, C.ctrversion, C.fnDireccion_, V.RefsxPropietario, V.RefsxDireccion, V.fnTitDocIden
		, CATASTRO_ID= V.id
		, V.DIRECCION
		, V.REFCATASTRAL
		, V.RefValidacion
		, [NIF] = V.fnNif
		INTO #DIR
		FROM vContratosActivos AS C
		INNER JOIN vCatastro AS V
		ON  C.cnCtrActivosxDireccion=1 
		AND V.RefsxDireccion=1
		AND C.fnDireccion_  COLLATE SQL_Latin1_General_CP1_CI_AI = V.fnDireccion_ COLLATE SQL_Latin1_General_CP1_CI_AI
		WHERE (@zonaD IS NULL OR C.ctrZonCod >= @zonaD) AND (@zonaH IS NULL OR C.ctrZonCod <= @zonaH);
		
		--SELECT * FROM #DIR; THROW 50000, 'Coincidencia por Direcciones', 1;

		--********************
		--#NIF: Coincidencias por el NIF del titular 	
		--********************
		SELECT  C.ctrcod, C.ctrversion, C.fnTitDocIden, V.RefsxPropietario, V.RefsxDireccion
		, CATASTRO_ID= V.id
		, [NIF] = V.fnNif
		, V.REFCATASTRAL
		, V.DIRECCION
		, V.RefValidacion
		, [mismaCalle] = dbo.fMismaCalle(V.fnDireccion_, C.calle0, C.calle1) 
		, [mismaFinca] = IIF(V.fnDireccion_ COLLATE SQL_Latin1_General_CP1_CI_AI  LIKE C.fnFinca_ + '%' COLLATE SQL_Latin1_General_CP1_CI_AI, 1, 0)
		, [mismaDireccion] = IIF(C.fnDireccion_ COLLATE SQL_Latin1_General_CP1_CI_AI= V.fnDireccion_ COLLATE SQL_Latin1_General_CP1_CI_AI, 1, 0)
		, [mismoNombre] = IIF(C.fnTitNomChars COLLATE SQL_Latin1_General_CP1_CI_AI = V.fnTitNomChars COLLATE SQL_Latin1_General_CP1_CI_AI, 1, 0)
		INTO #NIF
		FROM vContratosActivos AS C
		INNER JOIN vCatastro AS V
		ON  C.cnCtrActivosxTitular = 1
		AND V.RefsxPropietario = 1 
		AND C.fnTitDocIden= V.fnTitDocIden
		WHERE (@zonaD IS NULL OR C.ctrZonCod >= @zonaD) AND (@zonaH IS NULL OR C.ctrZonCod <= @zonaH);

		--SELECT * FROM #NIF; THROW 50000, 'Coincidencia por NIF', 1;
		--SELECT * FROM vContratosActivos WHERE cnCtrActivosxTitular = 1; THROW 50000, 'Coincidencia por NIF', 1;
		--SELECT * FROM vCatastro WHERE RefsxPropietario = 1; THROW 50000, 'Coincidencia por NIF', 1;
		
		
		--********************
		--#RESULT: En esta tabla comparamos los contratos activos y el tipo de coincidencias que tienen	
		--********************
		SELECT [contrato]			= C.ctrcod
			 , [zona]				= C.ctrZonCod
			 , [inmueble]			= C.ctrinmcod
			 , [ruta]				= C.Ruta
			 , [ctr.TitDocIdent]	= C.ctrTitDocIden
			 , [ctr.direccion]		= C.fnDireccion_
			 , [inmrefcatastral]	= C.inmrefcatastral	
			 , [refcatastral_Validar]  = IIF(LEN(C.inmrefcatastral)>0,	C.refValidacion, NULL)
			 , [svc.activos]		= C.scvActivos 
			 , [ctr.activosxtit.]	= C.cnCtrActivosxTitular 
			 , [ctr.activosxdir.]	= C.cnCtrActivosxDireccion
			 
			 --**********************************************
			  --CASO #1: Contratos coinciden x Dirección
			 , [xDireccion]				= CAST(IIF(D.ctrcod IS NULL, 0, 1) AS BIT)			
			 , [xDireccion_DIRECCION]	= D.DIRECCION
			 , [xDireccion_NIF]			= D.NIF						 
			 , [xDireccion_RCATASTRAL]	= D.REFCATASTRAL
			 , [xDireccionRef_Validar]		= D.RefValidacion
			 --, [xDireccionRegs]			= COUNT(D.ctrcod) OVER()
			 --, [xDireccionIguales]		= SUM(IIF(D.ctrcod IS NOT NULL AND LEN(C.inmrefcatastral)>0 AND D.REFCATASTRAL=C.inmrefcatastral, 1, 0)) OVER()			 
			 --, [xDireccionDiferentes]	= SUM(IIF(D.ctrcod IS NOT NULL AND LEN(C.inmrefcatastral)>0 AND D.REFCATASTRAL<>C.inmrefcatastral, 1, 0)) OVER()		 
			 --, [xDireccionNuevas]		= SUM(IIF(D.ctrcod IS NOT NULL AND LEN(C.inmrefcatastral)=0, 1, 0)) OVER()	
			 --**********************************************
			 --CASO #2: Contratos coinciden x NIF
			 , [xNif]				= CAST(IIF(N.ctrcod IS NULL, 0, 1) AS BIT)
			 , [xNif_DIRECCION]		= N.DIRECCION
			 , [xNif_NIF]			= N.NIF
			 , [xNif_RCATASTRAL]	= N.REFCATASTRAL
			 , [xNifRef_Validar]	= N.RefValidacion

			 --, [xNifRegs]			= COUNT(N.ctrcod) OVER()
			 --, [xNifIguales]		= SUM(IIF(N.ctrcod IS NOT NULL AND LEN(C.inmrefcatastral)>0 AND N.REFCATASTRAL=C.inmrefcatastral, 1, 0)) OVER()			 
			 --, [xNifDiferentes]	= SUM(IIF(N.ctrcod IS NOT NULL AND LEN(C.inmrefcatastral)>0 AND N.REFCATASTRAL<>C.inmrefcatastral, 1, 0)) OVER()		 
			 --, [xNifNuevas]		= SUM(IIF(N.ctrcod IS NOT NULL AND LEN(C.inmrefcatastral)=0, 1, 0)) OVER()
			 --**********************************************
			 --CASO #2.1: Contratos coinciden x NIF y calle 
			 , [xNif+Calle]				= CAST(IIF(N.ctrcod IS NOT NULL AND mismaCalle=1, 1, 0) AS BIT)
			 --, [xNif+CalleRegs]			= SUM(IIF(N.ctrcod IS NOT NULL AND mismaCalle=1, 1, 0)) OVER()
			 --, [xNif+CalleIguales]		= SUM(IIF(N.ctrcod IS NOT NULL AND mismaCalle=1 AND LEN(C.inmrefcatastral)>0 AND N.REFCATASTRAL=C.inmrefcatastral, 1, 0)) OVER()			 
			 --, [xNif+CalleDiferentes]	= SUM(IIF(N.ctrcod IS NOT NULL AND mismaCalle=1 AND LEN(C.inmrefcatastral)>0 AND N.REFCATASTRAL<>C.inmrefcatastral, 1, 0)) OVER()		 
			 --, [xNif+CalleNuevas]		= SUM(IIF(N.ctrcod IS NOT NULL AND mismaCalle=1 AND LEN(C.inmrefcatastral)=0, 1, 0)) OVER()
			 --**********************************************
			 --CASO #2.2: Contratos coinciden x NIF y finca			 
			 , [xNif+Finca]				= CAST(IIF(N.ctrcod IS NOT NULL AND mismaFinca=1, 1, 0) AS BIT)
			 --, [xNif+FincaRegs]			= SUM(IIF(N.ctrcod IS NOT NULL AND mismaFinca=1, 1, 0)) OVER()
			 --, [xNif+FincaIguales]		= SUM(IIF(N.ctrcod IS NOT NULL AND mismaFinca=1 AND LEN(C.inmrefcatastral)>0 AND N.REFCATASTRAL=C.inmrefcatastral, 1, 0)) OVER()			 
			 --, [xNif+FincaDiferentes]	= SUM(IIF(N.ctrcod IS NOT NULL AND mismaFinca=1 AND LEN(C.inmrefcatastral)>0 AND N.REFCATASTRAL<>C.inmrefcatastral, 1, 0)) OVER()		 
			 --, [xNif+FincaNuevas]		= SUM(IIF(N.ctrcod IS NOT NULL AND mismaFinca=1 AND LEN(C.inmrefcatastral)=0, 1, 0)) OVER()
			 --**********************************************
			 --CASO #2.3: Contratos coinciden x NIF y direccion					
			 , [xNif+Direccion]			= CAST(IIF(N.ctrcod IS NOT NULL AND mismaDireccion=1, 1, 0) AS BIT)
			 --, [xNif+DirRegs]			= SUM(IIF(N.ctrcod IS NOT NULL AND mismaDireccion=1, 1, 0)) OVER()
			 --, [xNif+DirIguales]		= SUM(IIF(N.ctrcod IS NOT NULL AND mismaDireccion=1 AND LEN(C.inmrefcatastral)>0 AND N.REFCATASTRAL=C.inmrefcatastral, 1, 0)) OVER()			 
			 --, [xNif+DirDiferentes]	= SUM(IIF(N.ctrcod IS NOT NULL AND mismaDireccion=1 AND LEN(C.inmrefcatastral)>0 AND N.REFCATASTRAL<>C.inmrefcatastral, 1, 0)) OVER()		 
			 --, [xNif+DirNuevas]		= SUM(IIF(N.ctrcod IS NOT NULL AND mismaDireccion=1 AND LEN(C.inmrefcatastral)=0, 1, 0)) OVER()
			 --**********************************************
			 --CASO #2.4: Contratos coinciden x NIF, nombre y direccion					
			, [xNif+Nombre+Dir]			= CAST(IIF(N.ctrcod IS NOT NULL AND mismaDireccion=1 AND mismoNombre=1, 1, 0) AS BIT)
			--, [xNif+DirRegs]			= SUM(IIF(N.ctrcod IS NOT NULL AND mismaDireccion=1 AND mismoNombre=1, 1, 0)) OVER()
			--, [xNif+DirIguales]			= SUM(IIF(N.ctrcod IS NOT NULL AND mismaDireccion=1 AND mismoNombre=1 AND LEN(C.inmrefcatastral)>0 AND N.REFCATASTRAL=C.inmrefcatastral, 1, 0)) OVER()			 
			--, [xNif+DirDiferentes]		= SUM(IIF(N.ctrcod IS NOT NULL AND mismaDireccion=1 AND mismoNombre=1 AND LEN(C.inmrefcatastral)>0 AND N.REFCATASTRAL<>C.inmrefcatastral, 1, 0)) OVER()		 
			--, [xNif+DirNuevas]			= SUM(IIF(N.ctrcod IS NOT NULL AND mismaDireccion=1 AND mismoNombre=1 AND LEN(C.inmrefcatastral)=0, 1, 0)) OVER()
			
			 --**********************************************
			  --CASO #3
			 , [xRefCatastral]			= CAST(IIF(CC.REFCATASTRAL IS NULL, 0, 1) AS BIT)
			 , [xRef_DIRECCION]			= CC.DIRECCION
			 , [xRef_NIF]				= CC.fnNif
			 , [REFSXPROPIETARIO]		= CC.RefsxPropietario
			 , [REFSXDIRECCION]			= CC.RefsxDireccion
			 , [xRefValidar]			= CC.RefValidacion
			 --, [xRefCatRegs]			= COUNT(CC.REFCATASTRAL) OVER()	
			, [xDir≠xNif] = IIF(D.REFCATASTRAL IS NOT NULL AND N.REFCATASTRAL IS NOT NULL AND N.mismacalle=1 AND D.REFCATASTRAL<>N.REFCATASTRAL,1, 0) 
		
		INTO #RESULT
		FROM vContratosActivos AS C
		LEFT JOIN #DIR AS D
		ON C.ctrcod= D.ctrcod
		AND C.ctrversion = D.ctrversion
		LEFT JOIN #NIF AS N
		ON C.ctrcod= N.ctrcod
		AND C.ctrversion = N.ctrversion
		LEFT JOIN dbo.vCatastro AS CC
		ON CC.REFCATASTRAL = C.inmrefcatastral
		WHERE (@zonaD IS NULL OR C.ctrZonCod >= @zonaD) AND (@zonaH IS NULL OR C.ctrZonCod <= @zonaH)
		ORDER BY C.ctrcod;

		--SELECT * FROM dbo.vCatastro --39.599
		--SELECT * FROM #RESULT WHERE [xNif+Nombre+Dir]=1 AND [xNifValidar]<>1; THROW 50000, 'Unimos todas las coincidencias en una tabla resumen', 1;
	
		--********************
		--INFORMES CATASTRO: Descripcion de los datos que se seleccionan en este informe
		--********************
		SELECT * FROM (VALUES
		('Catastro Melilla','...', '...', 'Datos del catastro de la Ciudad Autonoma de Melilla'),
		('Catastro Melilla','NIF', 'C.A.M', 'NIF del catastro'), 
		('Catastro Melilla','NOMBRE', 'C.A.M', 'NOMBRE del catastro'), 
		('Catastro Melilla','DIRECCION', 'C.A.M', 'DIRECCION del catastro'), 
		('Catastro Melilla','REFCATASTRAL', 'C.A.M', 'REFCATASTRAL del catastro'), 
		('Catastro Melilla','refsxpropietario', 'calculado', 'Cuantas referencias hay en el catastro con el mismo NIF de propietario'), 
		('Catastro Melilla','refsxdireccion', 'calculado', 'Cuantas referencias catastrales hay para esta misma dirección'), 
		('Catastro Melilla','dir.repetida', 'calculado', '=1 si hay más de una referencia catastral para esta misma dirección'),
		('Catastro Melilla','refValidacion', 'calculado', '-1: Longitud incorrecta, 0: la referencia catastral no es válida, 1: Referencia válida.'), 
		
		('Contratos Activos','...', '...', 'Cruce entre los contratos activos en acuama y el catastro de la Ciudad Autonoma de Melilla'), 
		
		('Contratos Activos', '…', '…', 'Datos de los contratos activos de acuama'),
		('Contratos Activos', 'contrato', 'acuama', 'Numero de contrato'),
		('Contratos Activos', 'zona', 'acuama', 'Zona'),
		('Contratos Activos', 'inmueble', 'acuama', 'Código del inmueble asociado a la versión mas reciente del contrato'),
		('Contratos Activos', 'ruta', 'acuama', 'Ruta'),
		('Contratos Activos', 'ctr.TitDocIdent', 'acuama', 'Documento de identidad del titular del contrato acuama'),
		('Contratos Activos', 'ctr.direccion', 'acuama', 'Dirección del inmueble'),
		('Contratos Activos', 'ctr.refcatastral', 'acuama', 'Referencia catastral en acuama'),
		('Contratos Activos', 'refcatastral_Validar', 'calculado', 'Validación del a referencia catastral asociada al contrato acuama'),
		('Contratos Activos', 'svc.activos', 'calculado', 'Número de servicios activos en el contrato'),
		('Contratos Activos', 'ctr.activosxtit.', 'calculado', 'Número de contratos activos por titular.'),
		('Contratos Activos', 'ctr.activosxdir.', 'calculado', 'Número de contratos activos para la misma dirección en acuama.'),
		('Contratos Activos', '…', '…', 'CASO #1: Coincidencias por dirección'),
		('Contratos Activos', 'xDireccion', 'FN', 'Verdadero si se ha encontrado esta misma dirección en el catastro de la CAM. Catastro: Direcciones únicas / Acuama: Dirección única en entre los contratos activos. '),
		('Contratos Activos', 'xDireccion_DIRECCION', 'CAM', 'Dirección de la referencia en el catastro CAM.'),
		('Contratos Activos', 'xDireccion_NIF', 'CAM', 'NIF de la referencia en el catastro CAM.'),
		('Contratos Activos', 'xDireccion_RCATASTRAL', 'CAM', 'Referencia catastral de la CAM con la que se ha encontrado la coincidencia por dirección.'),
		('Contratos Activos', 'xDireccionRef_Validar', 'FN', 'Validación de la referencia catastral encontrada en el catastro de la CAM.'),
		('Contratos Activos', '…', '…', 'CASO #2: Coincidencias por NIF'),
		('Contratos Activos', 'xNif', 'FN', 'Verdadero si se ha encontrado este mismo NIF en el catastro de la CAM. Catastro: Referencias catastrales únicas por propietario. / Acuama: solo contratos donde el titular aparece en un único contrato activo. '),
		('Contratos Activos', 'xNif_DIRECCION', 'CAM', 'Dirección de la referencia catastral con la que hemos encontrado coincidencia por NIF'),
		('Contratos Activos', 'xNif_NIF', 'CAM', 'NIF de la referencia en el catastro CAM.'),
		('Contratos Activos', 'xNif_RCATASTRAL', 'CAM', 'Referencia catastral de la CAM con la que se ha encontrado la coincidencia por NIF.'),
		('Contratos Activos', 'xNifRef_Validar', 'FN', 'Validación de la referencia catastral encontrada en el catastro de la CAM.'),
		
		('Contratos Activos', 'xNif+Calle', 'FN', 'Verdadero si se ha encontrado este mismo NIF en el catastro de la CAM y la calle del contrato aparece en la dirección del catastro. '),
		('Contratos Activos', 'xNif+Finca', 'FN', 'Verdadero si se ha encontrado este mismo NIF en el catastro de la CAM y la calle con el número de finca del contrato aparece en la dirección del catastro. '),
		('Contratos Activos', 'xNif+Direccion', 'FN', 'Verdadero si se ha encontrado este mismo NIF en el catastro de la CAM y la dirección entera del contrato aparece en la dirección del catastro. '),
		('Contratos Activos', 'xNif+Nombre+Dir', 'FN', 'Verdadero si se ha encontrado este mismo NIF y Nombre en el catastro de la CAM y la dirección entera del contrato aparece en la dirección del catastro. '),
		
		('Contratos Activos', '…', '…', 'CASO #3: Coincidencias por Referencia Catastral'),
		('Contratos Activos', 'xRefCatastral', 'FN', 'Verdadero si la coincidencia es porque comparten el mismo número de referencia catastral. Sin mirar ningún otro dato'),
		('Contratos Activos', 'xRef_DIRECCION', 'CAM', 'Dirección de la referencia catastral con la que hemos encontrado coincidencia por Referencia catastral.'),
		('Contratos Activos', 'xRef_NIF', 'CAM', 'NIF de la referencia catastral con la que hemos encontrado coincidencia por Referencia catastral.'),		
		('Contratos Activos', 'REFSXPROPIETARIO', 'FN', 'Cuantas referencias hay en el catastro de la CAM con el mismo NIF de propietario.'),
		('Contratos Activos', 'REFSXDIRECCION', 'FN', 'Cuantas referencias catastrales en el catastro de la CAM hay para esta misma dirección'),
		('Contratos Activos', 'xRef_Validar', 'FN', 'Validación de la referencia catastral que emite la coincidencia'),
		('Contratos Activos', 'xDir≠xNif', 'FN', '1: Si la referencia catastral encontrada por NIF y Calle es diferente a la que hemos encontrado por dirección'),	
		('Contratos Activos', '…', '…', 'Validación Referencias catastrales -Resultado: -1: Longitud incorrecta, 0: la referencia catastral no es válida, 1: Referencia válida.'),
		
		('CORRESPONDENCIAS','...', '...', 'Seleccionamos las Referencias catastrales según el grado de coincidencia.'),
		('CORRESPONDENCIAS','contrato',  'acuama', 'Numero de contrato'),
		('CORRESPONDENCIAS','inmueble',  'acuama', 'Código del inmueble asociado a la versión más reciente del contrato.'),
		('CORRESPONDENCIAS','inmrefcatastral',  'acuama', 'Referencia catastral del inmueble en acuama'),
		('CORRESPONDENCIAS','REFCATASTRAL',  'CAM', 'Referencia catastral para la que hay coincidencia con la CAM'),
		
		('CORRESPONDENCIAS','inmDireccion',  'acuama', 'Dirección del inmueble'),
		('CORRESPONDENCIAS', 'CAM_DIRECCION', 'CAM', 'Dirección de la referencia en el catastro CAM con la que se ha encontrado correspondencia'),
		
		('CORRESPONDENCIAS','titular',  'acuama', 'Documento de identidad del titular del contrato'),
		('CORRESPONDENCIAS', 'CAM_NIF', 'CAM', 'NIF de la referencia en el catastro CAM con la que se ha encontrado correspondencia'),
		('CORRESPONDENCIAS', 'Caso', 'FN', 'Criterios que se han usado para conseguir la correspondencia'),
		('CORRESPONDENCIAS', 'Orden', 'FN', 'Precendencia para aplicar la selección de la correspondencia.'),
		('CORRESPONDENCIAS', 'refsIguales', 'FN', 'Verdadero: La referencia catastral de acuama es igual a la coincidencia encontrada')
		
		) AS INFO(Informe, Columna, Tipo_Resultado, Descripcion)


	
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
			, [refValidacion] = RefValidacion
		FROM dbo.vCatastro
		ORDER BY DIRECCION;

		--********************
		--#CORRESPONDENCIAS	
		--********************
		--CASO#204: Coinciden todos los datos: Direccion, NIF y NOMBRE, nos quedamos con la referencia de la CAM si es válida	
		SELECT R.contrato
		, R.inmueble
		, R.inmrefcatastral
		, [REFCATASTRAL] = xNif_RCATASTRAL
		, [inmDireccion] = R.[ctr.direccion]
		, [titular]=R.[ctr.TitDocIdent]
		, R.[ctr.activosxtit.]
		, R.[ctr.activosxdir.]
		, [CAM_DIRECCION] = R.xNif_DIRECCION
		, [CAM_NIF] = R.xNif_NIF
		, [CASO] = 204
		INTO #CORRESPONDENCIAS
		FROM #RESULT AS R
		WHERE [xNif+Nombre+Dir]=1 
		  AND [xNifRef_Validar]=1;

		--CASO#203: Coinciden por Direccion y NIF, nos quedamos con la referencia de la CAM si es válida
		INSERT INTO #CORRESPONDENCIAS
		SELECT R.contrato
		, R.inmueble
		, R.inmrefcatastral
		, [REFCATASTRAL] = xNif_RCATASTRAL
		, [inmDireccion] = R.[ctr.direccion]
		, [titular]=R.[ctr.TitDocIdent]
		, R.[ctr.activosxtit.]
		, R.[ctr.activosxdir.]
		, [CAM_DIRECCION] = R.xNif_DIRECCION
		, [CAM_NIF] = R.xNif_NIF
		, [CASO] = 203
		FROM #RESULT AS R
		LEFT JOIN #CORRESPONDENCIAS AS C
		ON C.contrato = R.contrato
		WHERE C.contrato IS NULL 
		AND [xNif+Direccion]=1 
		AND [xNifRef_Validar]=1;
		
		--CASO#100: Las direcciones son exactas, nos quedamos con la referencia de la CAM si es válida
		INSERT INTO #CORRESPONDENCIAS
		SELECT R.contrato
		, R.inmueble
		, R.inmrefcatastral
		, [REFCATASTRAL] = xDireccion_RCATASTRAL
		, [inmDireccion] = R.[ctr.direccion]
		, [titular]=R.[ctr.TitDocIdent]
		, R.[ctr.activosxtit.]
		, R.[ctr.activosxdir.]
		, [CAM_DIRECCION] = R.xDireccion_DIRECCION
		, [CAM_NIF] = R.xDireccion_NIF
		, [CASO] = 100
		FROM #RESULT AS R
		LEFT JOIN #CORRESPONDENCIAS AS C
		ON C.contrato = R.contrato
		WHERE C.contrato IS NULL 
		AND R.[xDireccionRef_Validar] IS NOT NULL 

		--CASO#202: Mismo NIF pero las direcciones ya no son exactas coincide NIF, calle y finca
		--Nos quedamos con la referencia de la CAM si no hay referencia catastral válida en acuama
		INSERT INTO #CORRESPONDENCIAS
		SELECT R.contrato
		, R.inmueble
		, R.inmrefcatastral
		, [REFCATASTRAL] = xNif_RCATASTRAL
		, [inmDireccion] = R.[ctr.direccion]
		, [titular]=R.[ctr.TitDocIdent]
		, R.[ctr.activosxtit.]
		, R.[ctr.activosxdir.]
		, [CAM_DIRECCION] = R.xNif_DIRECCION
		, [CAM_NIF] = R.xNif_NIF
		, [CASO] = 202
		FROM #RESULT AS R
		LEFT JOIN #CORRESPONDENCIAS AS C
		ON C.contrato = R.contrato
		WHERE C.contrato IS NULL 
		AND [xNif+Finca]=1 
		AND [xNifRef_Validar]=1
		--La Referencia en acuama no existe ó no es válida
		AND (R.[refcatastral_Validar] IS NULL OR R.[refcatastral_Validar]<>1);
		
		--CASO#201: Mismo NIF pero las direcciones ya no son exactas coincide NIF y calle solamente
		--Nos quedamos con la referencia de la CAM si no hay referencia catastral válida en acuama
		INSERT INTO #CORRESPONDENCIAS
		SELECT R.contrato
		, R.inmueble
		, R.inmrefcatastral
		, [REFCATASTRAL] = xNif_RCATASTRAL
		, [inmDireccion] = R.[ctr.direccion]
		, [titular]=R.[ctr.TitDocIdent]
		, R.[ctr.activosxtit.]
		, R.[ctr.activosxdir.]
		, [CAM_DIRECCION] = R.xNif_DIRECCION
		, [CAM_NIF] = R.xNif_NIF
		, [CASO] = 201
		FROM #RESULT AS R
		LEFT JOIN #CORRESPONDENCIAS AS C
		ON C.contrato = R.contrato
		WHERE C.contrato IS NULL 
		AND [xNif+Calle]=1 
		AND [xNifRef_Validar]=1
		--La Referencia en acuama no existe ó no es válida
		AND (R.[refcatastral_Validar] IS NULL OR R.[refcatastral_Validar]<>1);

		--CASO#200: Mismo NIF pero las direcciones no se parecen
		--Nos quedamos con la referencia de la CAM si no hay referencia catastral válida en acuama
		INSERT INTO #CORRESPONDENCIAS
		SELECT R.contrato
		, R.inmueble
		, R.inmrefcatastral
		, [REFCATASTRAL] = xNif_RCATASTRAL
		, [inmDireccion] = R.[ctr.direccion]
		, [titular]=R.[ctr.TitDocIdent]
		, R.[ctr.activosxtit.]
		, R.[ctr.activosxdir.]
		, [CAM_DIRECCION] = R.xNif_DIRECCION
		, [CAM_NIF] = R.xNif_NIF
		, [CASO] = 200
		FROM #RESULT AS R
		LEFT JOIN #CORRESPONDENCIAS AS C
		ON C.contrato = R.contrato
		WHERE C.contrato IS NULL 
		AND [xNifRef_Validar]=1
		--La Referencia en acuama no existe ó no es válida
		AND (R.[refcatastral_Validar] IS NULL OR R.[refcatastral_Validar]<>1);
	
		--CASO#300: La referencia catastral coincide con una existente en la CAM
		--Nos quedamos con la referencia de la CAM si no hay referencia catastral válida en acuama
		INSERT INTO #CORRESPONDENCIAS
		SELECT R.contrato
		, R.inmueble
		, R.inmrefcatastral
		, [REFCATASTRAL] = R.inmrefcatastral
		, [inmDireccion] = R.[ctr.direccion]
		, [titular]=R.[ctr.TitDocIdent]
		, R.[ctr.activosxtit.]
		, R.[ctr.activosxdir.]
		, [CAM_DIRECCION] = R.xRef_DIRECCION
		, [CAM_NIF] = R.xRef_NIF
		, [CASO] = 300
		FROM #RESULT AS R
		LEFT JOIN #CORRESPONDENCIAS AS C
		ON C.contrato = R.contrato
		WHERE C.contrato IS NULL 
		AND [xRefValidar]=1;


		--********************
		--Correspondencias 	
		--*******************
		DELETE FROM MelillaCatastro.correspondencias;

		INSERT INTO MelillaCatastro.correspondencias
		OUTPUT INSERTED.*
		, CAST(IIF(ISNULL(INSERTED.inmrefcatastral, '') = ISNULL(INSERTED.[REFCATASTRAL], ''), 1, 0) AS BIT) AS refsIguales
		SELECT C.contrato, C.inmueble
		, C.inmrefcatastral, C.[REFCATASTRAL]
		, C.inmDireccion, C.CAM_DIRECCION, C.[ctr.activosxdir.]
		, C.titular, C.CAM_NIF, C.[ctr.activosxtit.]
		, [Caso] = T.ctDescripcion
		, [Orden] = T.ctPrecedencia
		, GETDATE()
		FROM #CORRESPONDENCIAS AS C
		INNER JOIN MelillaCatastro.coincidenciaTipo AS T
		ON C.CASO = T.ctId
		ORDER BY T.ctPrecedencia;


		--********************
		--Contratos Activos CSV 	
		--********************
		SELECT R.*
		, [Caso] = C.Caso
		, [Orden] = C.Orden
		FROM #RESULT AS R
		LEFT JOIN MelillaCatastro.correspondencias AS C
		ON R.contrato = C.contrato
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
	DROP TABLE IF EXISTS #CORRESPONDENCIAS;
	*/

	IF OBJECT_ID('tempdb.dbo.#DIR', 'U') IS NOT NULL DROP TABLE #DIR;
	IF OBJECT_ID('tempdb.dbo.#NIF', 'U') IS NOT NULL DROP TABLE #NIF;	
	IF OBJECT_ID('tempdb.dbo.#RESULT', 'U') IS NOT NULL DROP TABLE #RESULT;
	IF OBJECT_ID('tempdb.dbo.#CORRESPONDENCIAS', 'U') IS NOT NULL DROP TABLE #CORRESPONDENCIAS;	
GO


