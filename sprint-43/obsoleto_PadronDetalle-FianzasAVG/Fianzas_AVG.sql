/*
--DROP PROCEDURE [dbo].[Excel_Excelconsultas.Fianzas_AVG]

UPDATE E SET ExcConsulta='[InformesExcel].[Fianzas_AVG]'--, ExcPlantilla='CSVH_' 
FROM excelConsultas AS E WHERE ExcCod='010/009'
*/

/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out   NVARCHAR(MAX);

SET @p_params= '<NodoXML><LI><FecDesde>20230101</FecDesde><FecHasta>20240101</FecHasta></LI></NodoXML>'

EXEC [InformesExcel].[Fianzas_AVG] @p_params, @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;

--SELECT @p_error_out, @p_errMsg_out
*/

CREATE PROCEDURE [InformesExcel].[Fianzas_AVG]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(MAX) OUTPUT
AS

	SET NOCOUNT ON;   

	/*
	Este informe consta de 3 hojas excel:
	#1: Totaliza las lineas de Fianza y Devoluci�n de fianzas
	#2: Son los datos que se totalizan en la Hoja#1
	#3: Informe de fianzas que se traslada a una plantilla txt.
		S�lo se muestra un registro con el total por contrato y servicio: Fianza Constituida (A) y Devoluci�n de fianza (B)
	
	Para cotejar los resultados:
	(1) Comparar Resumen #1 con el Detalle #2 filtrando por tipo:
	N�Registros + N�Anulaciones = Numero de filas por tipo (A, B)
	Importe				= SUMA(Importe)  
	Importe Anulaciones = SUMA(Importe)
	Agrupando por el signo del importe

	(2) Comparar Detalle #2 con el informe #3
	La diferencia entre estos dos reportes es que los totales est�n expresados todos en positivo
	Cuando en el de Detalle #2 Fianzas(+) y las Devoluciones de Fianzas(-)

	La segunda diferencia es que solo hay una linea por contrato y servicio.
	El Importe de la fianza/devoluci�n por contrato ser� entonces el total de todas las ocurrencias del mismo servicio.

	Si totalizamos por tipo este importe debe ser el mismo que aparece en la Detalle #2 y 
	Informe Situaci�n Tarifa AVG


	Se compara con el resultado en "Fac.Original Base" del informe excel: Inf. Situaci�n Tarifa AVG 
	filtrando por cada servicio: Fianza Constituida (A) y Devoluci�n de fianza (B)

	*/

	BEGIN TRY
	
	--********************
	--INICIO: 2 DataTables
	-- 1: Paramentros del encabezado
	-- 2: Encabezado de GRUPOS
	-- 3, 4, 5: Datos 
	--********************

	--DataTable[1]:  Parametros
	DECLARE @xml AS XML = @p_params;
	DECLARE @params TABLE (FecDesde DATE NULL, fInforme DATETIME, FecHasta DATE NULL);
	DECLARE @fHasta DATE;

	INSERT INTO @params
	SELECT  FecDesde = CASE WHEN M.Item.value('FecDesde[1]', 'DATE') = '19000101' THEN NULL 
						   ELSE M.Item.value('FecDesde[1]', 'DATE') END
		  , fInforme = GETDATE()
		  , FecHasta = CASE WHEN M.Item.value('FecHasta[1]', 'DATE') = '19000101' THEN NULL 
						   ELSE M.Item.value('FecHasta[1]', 'DATE') END
		  	

	FROM @xml.nodes('NodoXML/LI')AS M(Item);
	
	SELECT @fHasta = FecHasta FROM @params;

	UPDATE @params 
	SET FecHasta = DATEADD(DAY, 1, FecHasta)
	OUTPUT DELETED.*;
	
	--********************
	--VALIDAR PARAMETROS
	--Fechas obligatorias
	IF EXISTS(SELECT 1 FROM @params WHERE FecDesde IS NULL OR FecHasta IS NULL)
		THROW 50001 , 'La fecha ''desde'' y ''hasta'' son requeridos.', 1;

	IF EXISTS(SELECT 1 FROM @params WHERE FecDesde>FecHasta)
		THROW 50002 , 'La fecha ''hasta'' debe ser posterior a la fecha ''desde''.', 1;
	
	--********************
	--DataTable[2]:  Datos

	DECLARE @TIPOS AS TABLE (COD_SVC INT, TIPO VARCHAR(1))
	INSERT INTO @TIPOS VALUES (102, 'A'), (103, 'B');

	CREATE TABLE #FIANZAS
	( facCod INT
	, facPerCod VARCHAR(6) 	
	, facCtrCod INT	
	, facVersion INT	
	, facCtrVersion INT	
	, ctrVersion INT --Ultima versi�n del contrato
	, facSerCod	INT
	, facFecha	DATETIME
	, fclTrfSvCod INT
	, TIPO	VARCHAR(1)
	, facNumero VARCHAR(20)
	, Importe MONEY	
	, NumServicios INT
	, conDiametro INT
	, ctcFec DATETIME
	, ctcOperacion VARCHAR(1)
	, RN INT
	, ctrTotalTipo MONEY);

	--DataTable[2]:  Nombre de Grupos
	SELECT * FROM (VALUES 
	  ('Res�men Fianzas')
	, ('Fianzas Constituidas y Devueltas') 
	, ('Concierto de Fianzas de Arrendamientos y Suministros'))
	AS DataTables(Grupo);

	--Selecci�n detallada por facturas con lineas de fianza:
	WITH FCL AS(
	--Todas las facturas de alta y baja, con sus linea de fianza
	SELECT F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion
	, F.facCtrVersion
	, F.facSerCod
	, F.facFecha
	, FL.fclTotal
	, FL.fclTrfSvCod
	, T.TIPO
	, F.facNumero
	FROM dbo.facturas AS F
	INNER JOIN @params AS P
	ON F.facFecha>=P.FecDesde AND F.facFecha<P.FecHasta
	--000005: Alta de suministro; 000002: Bajas
	AND F.facPerCod IN ('000005', '000002') 	
	INNER JOIN dbo.faclin AS FL
	ON F.facCod = FL.fclFacCod
	AND F.facPerCod = FL.fclFacPerCod
	AND F.facCtrCod = FL.fclFacCtrCod
	AND F.facVersion = FL.fclFacVersion
	AND F.facFechaRectif IS NULL
	AND FL.fclFecLiq IS NULL
	AND FL.fclTrfSvCod IN (SELECT COD_SVC FROM @TIPOS)
	LEFT JOIN @TIPOS AS T
	ON T.COD_SVC = FL.fclTrfSvCod

	), FIANZAS AS(
	SELECT facCod
	, facPerCod
	, facCtrCod
	, facVersion
	, facCtrVersion
	, NULL AS ctrVersion
	, facSerCod
	, facFecha
	, fclTrfSvCod 
	, TIPO
	, facNumero
	, SUM(ISNULL(fclTotal, 0)) AS Importe 
	, COUNT(fclTotal) AS NumServicios
	, NULL AS conDiametro
	, NULL AS ctcFec
	, NULL AS ctcOperacion
	FROM FCL
	GROUP BY facCod, facPerCod, facCtrCod, facVersion, facCtrVersion, facSerCod, facFecha, fclTrfSvCod, TIPO, facNumero)
	
	INSERT INTO #FIANZAS
	SELECT *
	, ROW_NUMBER() OVER (PARTITION BY facCtrCod, TIPO ORDER BY facFecha DESC, facCod DESC) AS RN
	, SUM(Importe) OVER (PARTITION BY facCtrCod, TIPO) AS ctrTotalTipo
	FROM FIANZAS
	WHERE Importe <> 0;

	--***********************
	---Contador: Recuperar el ultimo contador instalado en el contrato
	--***********************
	WITH FCTRS AS(
	SELECT DISTINCT 
	  F.facCtrCod
	, F.facFecha
	FROM #FIANZAS AS F
	
	), FCON AS(
	SELECT F.facCtrCod
	, F.facFecha
	, [ctcCon] = CC.conId
	, [ctcFec] = ISNULL(CC.[R.ctcFec], CC.[I.ctcFec]) 
	, [ctcOperacion] = ISNULL(CC.opRetirada, CC.opInstalacion)
	, C.conDiametro
	, C.conNumSerie
	FROM FCTRS AS F
	LEFT JOIN dbo.vCambiosContador AS CC
	ON CC.ctrCod = F.facCtrCod
	LEFT JOIN dbo.contador AS C
	ON C.conID = CC.conId
	WHERE CC.esUltimaInstalacion=1)

	UPDATE F
	SET F.conDiametro = CC.conDiametro
	, F.ctcFec = CC.ctcFec
	, F.ctcOperacion = CC.ctcOperacion
	FROM #FIANZAS AS F
	INNER JOIN FCON AS CC
	ON CC.facCtrCod = F.facCtrCod
	AND CC.facFecha = F.facFecha;

	--***********************
	---Contrato: A la fecha m�xima de la consulta
	--***********************
	WITH CTR AS(
	SELECT DISTINCT F.facCtrCod 
	FROM #FIANZAS AS F
	
	), VCTR AS(
	SELECT CC.ctrcod
	, CC.ctrversion
	--Queremos la version de contrato a la fecha m�xima de consulta
	, ROW_NUMBER() OVER (PARTITION BY CC.ctrcod ORDER BY CC.ctrversion DESC) AS RN
	FROM CTR AS C
	INNER JOIN dbo.contratos AS CC
	ON C.facCtrCod = CC.ctrcod
	INNER JOIN @params AS P
	ON CC.ctrfecreg < P.FecHasta)

	UPDATE F
	SET F.ctrVersion = C.ctrversion
	FROM #FIANZAS AS F
	INNER JOIN VCTR AS C
	ON C.ctrcod = F.facCtrCod
	AND C.RN=1;

	--**********
	--RESULTADOS
	--**********
	
	--***********************
	---DataTable[3]:  Totales por tipos
	--***********************
	WITH RESUMEN AS(
	SELECT TIPO
	, SUM(IIF(Importe < 0, 0, 1)) AS positivos
	, SUM(IIF(Importe < 0, 0, Importe)) AS tpositivos

	, SUM(IIF(Importe > 0, 0, 1)) AS negativos
	, SUM(IIF(Importe > 0, 0, Importe)) AS tnegativos
	FROM #FIANZAS
	GROUP BY TIPO)

	SELECT CASE tipo 
	  WHEN 'A' THEN 'Registros de Alta (A)' 
	  WHEN 'B' THEN 'Registros de Baja (B)'
	  ELSE 'Otro' END
	  AS [Tipo]
	, IIF(tipo = 'A', positivos, negativos) AS [N� Registros]
	, FORMAT(IIF(tipo = 'A', tpositivos, tnegativos), 'N', 'es-ES') AS [Importe]

	, IIF(tipo = 'B', positivos, negativos) AS [N� Anulaciones]
	, FORMAT(IIF(tipo = 'B', tpositivos, tnegativos), 'N', 'es-ES') AS [Importe Anulaciones]

	, ABS(positivos - negativos) AS [N� Registros Total]
	, FORMAT(ABS(tpositivos + tnegativos), 'N', 'es-ES') AS [Importe Total]
	FROM RESUMEN;

	--***********************
	---DataTable[4]:  Fianzas constituidas y devueltas
	--***********************
	SELECT F.facCtrCod AS [Contrato]
	, facCod AS [C�digo Factura]
	, facVersion AS [Versi�n Factura]
	, facNumero AS [N�Factura]
	, facPerCod AS [Periodo]
	, F.TIPO AS [Tipo] 
	, FORMATMESSAGE('%i: %s', S.svccod,  S.svcdes) AS [Servicio]
	, M.mncdes AS [Municipio]
	, I.inmcalle AS [Calle]
	, I.inmfinca AS [N�mero]
	, I.inmcomplemento AS [Resto Direcci�n]
	, F.facFecha AS [Fecha Factura]
	, C.ctrTitNom AS [Titular]
	, CASE C.ctrTitTipDoc 
	  WHEN '0' THEN 'DNI'
	  WHEN '1' THEN 'CIF'
	  WHEN '2' THEN 'NIE'
	  WHEN '3' THEN 'PAS'
	  ELSE 'SD' END AS [Tipo Documento] 
	, C.ctrTitDocIden AS [Identificacion]
	, F.Importe
	-- , IIF(F.ctcOperacion = 'I', F.conDiametro, NULL) AS [Calibre]
	, F.conDiametro AS [Calibre]
	, U.usodes AS [Uso] 
	--Contrato: RN=1 => Factura mas reciente por tipo
	, F.RN AS [Indice] 
	FROM #FIANZAS AS F
	INNER JOIN dbo.contratos AS C
	ON C.ctrcod = F.facCtrCod
	AND C.ctrversion = F.facCtrVersion
	INNER JOIN dbo.inmuebles AS I
	ON I.inmcod = C.ctrinmcod
	INNER JOIN dbo.municipios AS M
	ON I.inmmnccod = M.mnccod 
	AND I.inmPobCod = M.mncPobCod
	AND I.inmPrvCod = M.mncPobPrv
	LEFT JOIN dbo.usos AS U
	ON U.usocod = C.ctrUsoCod
	INNER JOIN dbo.servicios AS S
	ON S.svccod = F.fclTrfSvCod
	ORDER BY facFecha ASC, facCtrCod ASC;

	--***********************
	---DataTable[5]:  Concierto de Fianzas de Arrendamientos y Suministros
	--***********************
	--Buscamos la �ltima version del contrato
	WITH DATA AS (
	SELECT * 
	FROM #FIANZAS AS F
	WHERE RN=1
	
	), CTRS AS(
	SELECT C.ctrcod
	, C.ctrversion
	, CONVERT(VARCHAR, C.ctrfecini, 103) AS ctrfecini
	, CONVERT(VARCHAR, C.ctrfecanu, 103) AS ctrfecanu
	, CONVERT(VARCHAR, C.ctrfecreg, 103) AS ctrfecreg
	, D.facFecha AS facfecha
	, C.ctrinmcod
	, REPLACE(C.ctrTitDocIden, ' ', '') AS ctrTitDocIden
	, dbo.BorrarAcentos(C.ctrTitNom) AS ctrTitNom --Los textos contenidos en el fichero ir�n en may�sculas y sin acentos		

	, REPLACE(C.ctrPagDocIden, ' ', '') AS ctrPagDocIden
	, dbo.BorrarAcentos(C.ctrPagNom) AS ctrPagNom --Los textos contenidos en el fichero ir�n en may�sculas y sin acentos		

	, D.TIPO
	, CAST((D.ctrTotalTipo) AS DECIMAL(15, 2)) AS ctrTotal
	, D.conDiametro
	, D.ctcFec
	, D.ctcOperacion
	, D.RN
	, D.Importe
	FROM DATA AS D
	INNER JOIN dbo.contratos AS C
	ON C.ctrcod = D.facCtrCod
	AND C.ctrversion = D.ctrVersion
	
	), CTR_RESULT AS(
	--Resultado para el informe
	--Transmisi�n de Concierto de Arrendamientos
	SELECT C.ctrcod
	, FORMAT(C.ctrcod, '00000000') AS contrato
	, C.ctrversion
	, C.tipo 
	, C.ctrfecini
	, C.ctrfecanu
	, C.ctrfecreg
	, facfecha
	, IIF(C.TIPO = 'B', C.ctrTotal * -1, C.ctrTotal) AS ctrTotal
	, C.conDiametro
	, C.ctcFec
	, C.ctcOperacion
	, C.Importe
	--�C�mo distinguir entre Urbano y R�stico?
	--De momento todo es (U)rbano
	, 'U' AS [inmrefcatastral_tipo]  --'U' para referencias catastrales de bienes urbanos
								     --'R' para referencias catastrales de bienes r�sticos
	, IIF(LEN(RTRIM(LTRIM(I.inmrefcatastral)))>20, NULL, RTRIM(LTRIM(I.inmrefcatastral)))  AS [inmrefcatastral]
	, I.inmcalle AS [inmcalle]
	, SUBSTRING(I.inmcalle, 1, 2) AS [inmcalle_tvia]
	, dbo.BorrarAcentos(LTRIM(SUBSTRING(I.inmcalle, CHARINDEX('/', I.inmcalle)+1, LEN(I.inmcalle)))) AS [inmcalle_nombre]
	, I.inmfinca
	, I.inmbloque
	, I.inmEntrada
	, I.inmpuerta
	, dbo.LimpiarTexto(I.inmplanta) AS [inmplanta]
	, dbo.BorrarAcentos(I.inmcomplemento) AS [inmcomplemento]
	, I.inmPrvCod
	, I.inmcpost
	--Dependiendo de la fecha: CINCLUS(titular) / ACUAMA(pagador)
	, IIF(@fHasta < '20190101', C.ctrTitDocIden, ISNULL(C.ctrPagDocIden, C.ctrTitDocIden)) AS [arrendatarioDocIden]
	, IIF(@fHasta < '20190101', C.ctrTitNom, ISNULL(C.ctrPagNom, ctrTitNom)) AS [arrendatarioNom]
	, RN
	FROM CTRS AS C
	LEFT JOIN dbo.inmuebles AS I
	ON C.ctrinmcod = I.inmcod
	WHERE ctrTotal <>0)
	
	SELECT 
	--**************************
	--IDENTIFICACI�N DEL REGISTRO
	  FORMATMESSAGE('1-1-%s', C.contrato) AS [N�mero de contrato]	--Numero de contrato (Campo de hasta 30 caracteres alfanum�ricos)
	, C.tipo AS [Tipo de registro]		--Tipo de registro (A: Alta, B: Baja, M: Modificacion fianza)
	, CASE C.tipo 
		WHEN 'A' THEN CONVERT(VARCHAR, C.ctrfecreg, 103)	--Para los registros de alta, ser� la fecha de celebraci�n del contrato.
		WHEN 'B' THEN CONVERT(VARCHAR, C.facfecha, 103)		--Para los registros de baja, ser� a la fecha de creaci�n de la factura.
		END AS [Fecha de Movimiento]	

	--**************************
	--IDENTIFICACI�N DEL INMUEBLE
	--Campo de 1 car�cter alfanum�rico para indicar si el inmueble va a venir identificado o no por la referencia catastral. Dos valores posibles �S� o �N�.
	, IIF(C.inmrefcatastral IS NULL, 'N', 'S') AS [Indicador Referencia Catastral propia]
	
	--Campo de 1 car�cter para indicar el formato de la referencia catastral. 
	, CASE WHEN  C.inmrefcatastral IS NULL THEN 'N' --En el caso de no existir la referencia catastral para el bien, se podr� dar el valor 'N' a este indicador.
		   ELSE C.inmrefcatastral_tipo END
		   AS [Tipo de referencia catastral]
	
	--Campo de 20 caracteres alfanum�ricos, que indican la referencia catastral del inmueble. 
	--Obligatorio que tenga valor. 
	--Si el campo Indicador referencia Catastral tiene le valor S, este valor corresponder� a la referencia catastral del propio inmueble,
	--en otro caso se debe indicar la referencia catastral del inmueble del que forma parte.
	, ISNULL(C.inmrefcatastral, C.ctrcod) AS [Referencia catastral]
	
	--Campo num�rico de 3 d�gitos, el cual va a indicar el % de participaci�n, entre 1 y 100.
	--% de participaci�n en la superficie del inmueble principal ( Inmueble sin referencia catastral propia)
	--Opcional que tenga valor, si el campo Indicador referencia Catastral tiene le valor N. En otro caso se debe indicar el campo como vac�o.
	, 100 AS [% Participaci�n]
	
	--Campo num�rico de 3 d�gitos, entre 1 y 999.
	--Obligatorio que tenga valor si el campo Indicador referencia Catastral tiene el valor N, en otro caso se debe indicar el campo como vac�o
	, 1 AS [N�mero de orden]

	--Campo de 2 caracteres alfanum�ricos
	, C.inmcalle_tvia AS [Tipo de v�a]

	--Campo de 60 caracteres alfanum�ricos.
	, CAST(C.[inmcalle_nombre] AS VARCHAR(60)) AS [Nombre de la v�a p�blica]

	--Campo de 3 caracteres alfanum�ricos. Los valores posibles son �KM� para kil�metro, �NUM� para n�mero de � �SN� para sin n�mero.
	, IIF(C.inmfinca='S/N', 'SN', 'NUM') AS [Tipo de numeraci�n]

	--Campo de 3 caracteres alfanum�ricos. Los valores posibles son �KM� para kil�metro, �NUM� para n�mero de � �SN� para sin n�mero.
	, CAST(IIF(C.inmfinca='S/N', '', C.inmfinca) AS VARCHAR(3)) AS [N�mero/Kil�metro]

	--Campo de 3 caracteres alfanum�ricos. (Opcional)
	, '' AS [Calificador de numeraci�n]

	--Campo de 3 caracteres alfanum�ricos. (Opcional)
	, CAST(ISNULL(C.inmbloque, '') AS VARCHAR(3)) AS [Bloque]

	--Campo de 3 caracteres alfanum�ricos. (Opcional)
	, CAST(COALESCE(C.inmEntrada, C.inmpuerta, '') AS VARCHAR(3)) AS [Letra del portal]

	--Campo de 3 caracteres alfanum�ricos. (Opcional)
	, '' AS [Escalera]

	--Campo de 3 caracteres alfanum�ricos. (Opcional)
	, CAST(ISNULL(C.inmplanta, '') AS VARCHAR(3)) AS [Piso]

	--Campo de 3 caracteres alfanum�ricos. (Opcional)
	--Omitimos algunos caracteres
	, CAST(REPLACE(dbo.LimpiarTexto(ISNULL(C.inmpuerta, '') + ISNULL(C.inmcomplemento, '')), ' ', '') AS VARCHAR(3))  AS [Puerta]
	
	--Campo de 5 caracteres alfanum�ricos. (Opcional)
	, '' AS [Local]

	--Campo de 2 caracteres alfanum�ricos, con el c�digo INE de la provincia
	, C.inmPrvCod AS [Provincia]

	--Campo de 3 caracteres alfanum�rico, con el c�digo INE del municipio
	, '033' AS [Municipio]

	--Campo de 6 caracteres alfanum�ricos, con el c�digo INE la unidad poblacional o localidad.
	, '110337' AS [Localidad]

	--Campo de 5 caracteres alfanum�ricos.
	, C.inmcpost AS [C�digo postal]

	--**************************
	--IDENTIFICACI�N DEL ARRENDATARIO
	--Campo de 9 caracteres alfanum�ricos. Obligatorio
	, RIGHT('000000000' + C.arrendatarioDocIden, 9) AS [NIF del Arrendatario]

	--Apellidos, Nombre o Raz�n Social del Arrendatario
	--Campo de 125 caracteres alfanum�ricos. Obligatorio
	, CAST(C.arrendatarioNom AS VARCHAR(125)) AS [Arrendatario]

	--Campo de 2 caracteres alfanum�ricos. Ver tabla de tipos de v�a en el anexo. Opcional
	, '' AS [Arrendatario Tipo de v�a]

	--Campo de 60 caracteres alfanum�ricos. Opcional
	, '' AS [Arrendatario Nombre de la v�a p�blica]

	--Campo de 3 caracteres alfanum�ricos. Opcional
	--Los valores posibles son �KM� para kil�metro, �NUM� para n�mero de � �SN� para sin n�mero.
	, '' AS [Arrendatario Tipo de numeraci�n]
	
	--Campo de 3 caracteres alfanum�ricos. Opcional
	, '' AS [Arrendatario N�mero/Kil�metro]

	--Campo de 3 caracteres alfanum�ricos. Opcional
	, '' AS [Arrendatario Calificador de numeraci�n]

	--Campo de 3 caracteres alfanum�ricos. Opcional
	, '' AS [Arrendatario Bloque]

	--Campo de 3 caracteres alfanum�ricos. Opcional
	, '' AS [Arrendatario Letra del portal]

	--Campo de 3 caracteres alfanum�ricos. Opcional
	, '' AS [Arrendatario Escalera]

	--Campo de 3 caracteres alfanum�ricos. Opcional
	, '' AS [Arrendatario Piso]

	--Campo de 3 caracteres alfanum�ricos. Opcional
	, '' AS [Arrendatario Puerta]

	--Campo de 3 caracteres alfanum�ricos, con el c�digo del pa�s, seg�n ISO 3166/2. Opcional
	, '' AS [Arrendatario Pais]

	--Campo de 2 caracteres alfanum�ricos, con el c�digo INE de la provincia. Opcional
	, '' AS [Arrendatario Provincia]

	--Campo de 3 caracteres alfanum�rico, con el c�digo INE del municipio. Opcional
	, '' AS [Arrendatario Municipio]

	--Campo de 6 caracteres alfanum�ricos, con el c�digo INE la unidad poblacional o localidad.. Opcional
	, '' AS [Arrendatario Localidad]

	--Campo de 5 caracteres alfanum�ricos. Opcional
	, '' AS [Arrendatario C�digo postal]

	--Opcional
	, '' AS [N�mero de tel�fono]

	--Opcional
	, '' AS [Direcci�n e-mail]

	--Campo de tipo num�rico de 13 enteros y dos decimales, seg�n el formato �xxxxxxxxxxxxx,xx�. El separador de los decimales es la coma (�,�).
	, REPLACE(FORMAT(C.ctrTotal, 'N', 'es-ES'), '.', '') AS [Importe de la fianza]

	--**************************
	--, '' AS [Duraci�n en meses]	
	--, '' AS [Uso del Inmueble]	
	--, '' AS [Importe de la renta]
	--**************************
	
	--**************************
	--ESPECIFICACIONES DEL FICHERO DE ARRENDAMIENTOS DE SUMINISTRO DE AGUA
	--Campo de 10 caracteres num�ricos
	, C.conDiametro AS [Calibre del contador]

	--Campo de 10 caracteres alfanum�ricos. Los valores posibles son DOMESTICO, COMERCIAL, INDUSTRIAL, AGRICOLA, CENTROS OFICIALES, OTROS)
	, 'OTROS' AS [Modalidad de consumo]
	FROM CTR_RESULT AS C
	ORDER BY ctrcod;

	END TRY

	BEGIN CATCH
		SELECT  @p_errId_out = ERROR_NUMBER()
			 ,  @p_errMsg_out= ERROR_MESSAGE();
	END CATCH

	IF OBJECT_ID('tempdb.dbo.#FIANZAS', 'U') IS NOT NULL 
	DROP TABLE #FIANZAS;


GO


