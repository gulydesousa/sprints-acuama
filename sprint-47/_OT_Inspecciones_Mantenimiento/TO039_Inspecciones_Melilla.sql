/*
DECLARE @tipo VARCHAR(20)=NULL,--Tipo Incidencia: Lectura, Inspeccion, OT con anomalía(apto = false), OT sin anomalía (apto = true)
	@excluirNoEmision BIT = 0,
	@contratoD INT = NULL,
	@contratoH INT = NULL,
	@zonaD VARCHAR(4) = NULL,
	@zonaH VARCHAR(4) = NULL,
	--Se filtra por la ruta en las inspecciones
	@ruta1D VARCHAR(10) = NULL,
	@ruta1H VARCHAR(10) = NULL,
	@ruta2D VARCHAR(10) = NULL,
	@ruta2H VARCHAR(10) = NULL,
	@ruta3D VARCHAR(10) = NULL,
	@ruta3H VARCHAR(10) = NULL,
	@ruta4D VARCHAR(10) = NULL,
	@ruta4H VARCHAR(10) = NULL,
	@ruta5D VARCHAR(10) = NULL,
	@ruta5H VARCHAR(10) = NULL,
	@ruta6D VARCHAR(10) = NULL,
	@ruta6H VARCHAR(10) = NULL,
	@listado BIT = NULL,		 -- Si es un listado: En este SP no hacemos nada en particular.
	@legal VARCHAR(20) = 'Si',	 -- Representante legal(Si, No, Indiferente) | Si tiene representante legal debe sacar dos cartas
	@tieneEmail BIT = NULL,		
	@servicio VARCHAR(25) = NULL, --BATERIAS, CONTADORES
	@orden VARCHAR(20) = 'Ruta'	  --Orden para los registros	

	EXEC [ReportingServices].[TO039_Inspecciones_Melilla] @tipo, @excluirNoEmision, @contratoD, @contratoH, @zonaD, @zonaH 
	, @ruta1D, @ruta1H, @ruta2D, @ruta2H, @ruta3D, @ruta3H, @ruta4D, @ruta4H, @ruta5D, @ruta5H, @ruta6D, @ruta6H
	, @listado, @legal, @tieneEmail, @servicio, @orden

*/
ALTER PROCEDURE [ReportingServices].[TO039_Inspecciones_Melilla]
	@tipo VARCHAR(20)='Lectura',--Tipo Incidencia: Lectura, Inspeccion, OT con anomalía(apto = false), OT sin anomalía (apto = true), 
	@excluirNoEmision BIT = 0,
	@contratoD INT = 1,
	@contratoH INT = NULL,
	@zonaD VARCHAR(4) = NULL,
	@zonaH VARCHAR(4) = NULL,
	--Se filtra por la ruta en las inspecciones
	@ruta1D VARCHAR(10) = NULL,
	@ruta1H VARCHAR(10) = NULL,
	@ruta2D VARCHAR(10) = NULL,
	@ruta2H VARCHAR(10) = NULL,
	@ruta3D VARCHAR(10) = NULL,
	@ruta3H VARCHAR(10) = NULL,
	@ruta4D VARCHAR(10) = NULL,
	@ruta4H VARCHAR(10) = NULL,
	@ruta5D VARCHAR(10) = NULL,
	@ruta5H VARCHAR(10) = NULL,
	@ruta6D VARCHAR(10) = NULL,
	@ruta6H VARCHAR(10) = NULL,
	@listado BIT = NULL,		 -- Si es un listado: En este SP no hacemos nada en particular.
	@legal VARCHAR(20) = NULL,	 -- Representante legal(Si, No, Indiferente) | Si tiene representante legal debe sacar dos cartas
	@tieneEmail BIT = NULL,		
	@servicio VARCHAR(25) = NULL, --BATERIAS, CONTADORES
	@orden VARCHAR(20) = NULL	  --Orden para los registros	
	--****************************************
	--Omitimos estos filtros porque no tienen relevancia en la tabla de inspecciones: La busqueda es por contrato
	--@periodo VARCHAR(6)='202301',
	--@cartaTipo INT = 34,
	--@forzarTipoCarta BIT = NULL,	
	--@filtro VARCHAR(500) = NULL, --Incidencia de lectura
	--****************************************
AS

BEGIN TRY

	SET NOCOUNT ON;
	
	DECLARE @apto BIT = NULL;
	--Para sacar las inspecciones con los filtros de la pantalla de "Emisión de Notificaciones"
	SELECT  @excluirNoEmision = ISNULL(@excluirNoEmision, 1); --Por defecto siempre se excluyen los que tienen No-Emisión

	SET @apto = CASE  @tipo WHEN 'OT con anomalía' THEN 0
							WHEN 'OT sin anomalía' THEN 1
							ELSE NULL END;

	--Contadores Instalados:
	CREATE TABLE #CONTADORES(ctrcod INT PRIMARY KEY, conNumSerie VARCHAR(25), conDiametro SMALLINT, conID INT)

	INSERT INTO #CONTADORES
	SELECT DISTINCT V.ctrCod, V.conNumSerie, V.conDiametro, V.conId
	FROM vCambiosContador AS V
	LEFT JOIN dbo.otInspecciones_Melilla AS I
	ON I.ctrcod = V.ctrCod
	WHERE V.esUltimaInstalacion = 1 AND V.opRetirada IS NULL;

	SELECT S.ctsctrcod, S.ctssrv, S.ctstar, S.ctsuds, S.ctslin, T.trfdes
	--RN=1 para quedarnos con una sola linea por agua
	, RN = ROW_NUMBER() OVER (PARTITION BY  S.ctsctrcod ORDER BY S.ctslin ASC)
	, CN = COUNT(S.ctslin) OVER (PARTITION BY  S.ctsctrcod)
	INTO #AGUA
	FROM dbo.ContratoServicio AS S
	INNER JOIN dbo.tarifas AS T
	ON  T.trfsrvcod = S.ctssrv
	AND T.trfcod = S.ctstar
	WHERE S.ctssrv=1 AND S.ctsfecbaj IS NULL;

	--6164
	SELECT V.objectid, V.Servicio	
	, [REGISTROENTREGA] = V.objectid
	--WordTemplate_Contratos: OnFieldValueRequest
	, [CONTRATO] = V.ctrcod 
	, [USUARIOCOD] = CC.ctrTitCod
	, [INMUEBLECOD] = CC.ctrinmcod
	, [CALIBRE] = CCC.conDiametro
	, [INMUEBLECODPOSTAL] = II.inmcpost --CPostal
	, [MARCACONTADOR] = MA.mcndes
	, [REFCATASTRAL] = II.inmrefcatastral
	, [FISNOM] = CC.ctrTitNom	--NombreTitular
	, [BLOQUE] = V.zonCod
	, [RUTA] = FORMATMESSAGE('%05d.%05d.%05d'
			 , IIF(ISNUMERIC(I.ruta1)=1, CAST(I.ruta1 AS INT), 0)						
			 , IIF(ISNUMERIC(I.ruta2)=1, CAST(I.ruta2 AS INT), 0)
			 , IIF(ISNUMERIC(I.ruta3)=1, CAST(I.ruta3 AS INT), 0))

	, [ORDEN] = FORMATMESSAGE('%05d.%05d.%05d'
			 , IIF(ISNUMERIC(I.ruta4)=1, CAST(I.ruta4 AS INT), 0)						
			 , IIF(ISNUMERIC(I.ruta5)=1, CAST(I.ruta5 AS INT), 0)
			 , IIF(ISNUMERIC(I.ruta6)=1, CAST(I.ruta6 AS INT), 0))
	
	, [FISNIF] = CC.ctrTitDocIden --NifTitular
	, [FISDIR1]  = CC.ctrTitDir
	, [TITULARCPOSTAL] = CC.ctrTitCPos
	, [FISDIR2] = CC.ctrEnvDir
	, [ENVIOCPOSTAL] = CC.ctrEnvCPos
	, [FISTEL] = CC.ctrTlf1			--FISTEL1
	, [FISTEL2] = CC.ctrTlf2
	, [MAILDATOS] = CC.ctrEmail
	, [CONTADOR] = CCC.conNumSerie	--conNumSerie
	, [TRIMESTRE] = ISNULL(CONVERT(NVARCHAR, CC.ctrfecini, 103), '') 
	, [DOTACIONES] = A.ctsuds
	, [TARIFA] = A.ctstar
	, [NOMTARIFA] = A.trfdes
	, [CONTRATOCOMUNITARIO] = CC.ctrComunitario
	, [REPRESENTANTE] = CC.ctrRepresent
	--, CL.clinom
	, [CLI_REPRESENTANTE] = CC.ctrValorc4
	--Otros Campos:
	, CC.ctrTlfRef1
	, CC.ctrTlfRef2
	, CC.ctrTlfRef3
	, CC.ctrTlf3
	--Inmueble
	, [INMUEBLE]  = II.inmDireccion 
	, [Calle] = II.inmcalle
	, [Piso] = II.inmplanta
	, [Puerta] = II.inmpuerta
	, [Numero] = II.inmfinca
	, [Portal] = II.inmentrada
	, [ZONA] = V.zona
	--DatosOT
	, [otApta] = V.Apta
	, [otSociedad] = I.otiserscd
	, [otSerie] = I.otisercod
	, [otNum] = I.otinum
	, [otFecReg] = ot.otFechaReg --FechaOT
	--ORDER BY
	, [SujetoPasivo] = UPPER(RTRIM(LTRIM(ISNULL(CC.ctrRepresent, CC.ctrTitNom))))
	, V.INSPECCION_GENERAL
	INTO #RESULT
	FROM vOtInspecciones_Melilla AS V --Usamos V porque en esta vista estan las inspecciones originales y una inspeccion(repetida) por cada contrato hijo
	INNER JOIN dbo.otInspecciones_Melilla AS I
	ON V.objectid = I.objectID
	LEFT JOIN dbo.vContratosUltimaVersion AS C
	ON V.ctrcod = C.ctrCod
	LEFT JOIN dbo.Contratos AS CC
	ON CC.ctrcod = C.ctrCod AND CC.ctrversion= C.ctrVersion
	LEFT JOIN inmuebles AS II 
	ON II.inmcod = C.ctrinmcod
	LEFT JOIN #CONTADORES AS CCC
	ON CCC.ctrCod = CC.ctrCod
	LEFT JOIN dbo.contador AS CO
	ON CO.conID = CCC.conID
	LEFT JOIN dbo.marcon AS MA
	ON MA.mcncod = CO.conMcnCod
	LEFT JOIN #AGUA AS A
	ON A.ctsctrcod = CC.ctrcod
	LEFT JOIN [dbo].[vEmailNotificaciones] AS E
	ON E.[contrato.ctrCod] = C.ctrCod
	AND E.[contrato.ctrVersion] = C.ctrVersion
	LEFT JOIN ordenTrabajo AS OT
	ON OT.otserscd = I.otiserscd
	AND OT.otsercod = I.otisercod
	AND OT.otnum = I.otinum
	LEFT JOIN dbo.clientes AS CL
	ON CL.clicod = CAST(CC.ctrValorc4 AS INT)

	WHERE (@excluirNoEmision=0 OR (@excluirNoEmision=1 AND (CC.ctrNoEmision IS NULL OR CC.ctrNoEmision=0)))
	AND (@contratoD IS NULL OR V.ctrcod>=@contratoD) 
	AND (@contratoH IS NULL OR V.ctrcod<=@contratoH)
	AND (@zonaD IS NULL OR V.zonCod>=@zonaD)
	AND (@zonaH IS NULL OR V.zonCod<=@zonaH) 
	----**************************************
	AND (@ruta1D IS NULL OR ISNUMERIC(@ruta1D)=0 OR (ISNUMERIC(@ruta1D)=1 AND I.ruta1 IS NOT NULL AND CAST(CASE WHEN ISNUMERIC(I.ruta1)=1 THEN I.ruta1 ELSE '0' END AS INT)>=CASE WHEN ISNUMERIC(@ruta1D)=1 THEN CAST(@ruta1D AS INT) ELSE NULL END))
	AND (@ruta1H IS NULL OR ISNUMERIC(@ruta1H)=0 OR (ISNUMERIC(@ruta1H)=1 AND I.ruta1 IS NOT NULL AND CAST(CASE WHEN ISNUMERIC(I.ruta1)=1 THEN I.ruta1 ELSE '0' END AS INT)<=CASE WHEN ISNUMERIC(@ruta1H)=1 THEN CAST(@ruta1H AS INT) ELSE NULL END))
     
	AND (@ruta2D IS NULL OR ISNUMERIC(@ruta2D)=0 OR (ISNUMERIC(@ruta2D)=1 AND I.ruta2 IS NOT NULL AND CAST(CASE WHEN ISNUMERIC(I.ruta2)=1 THEN I.ruta2 ELSE '0' END AS INT)>=CASE WHEN ISNUMERIC(@ruta2D)=1 THEN CAST(@ruta2D AS INT) ELSE NULL END))
	AND (@ruta2H IS NULL OR ISNUMERIC(@ruta2H)=0 OR (ISNUMERIC(@ruta2H)=1 AND I.ruta2 IS NOT NULL AND CAST(CASE WHEN ISNUMERIC(I.ruta2)=1 THEN I.ruta2 ELSE '0' END AS INT)<=CASE WHEN ISNUMERIC(@ruta2H)=1 THEN CAST(@ruta2H AS INT) ELSE NULL END))
	  
	AND (@ruta3D IS NULL OR ISNUMERIC(@ruta3D)=0 OR (ISNUMERIC(@ruta3D)=1 AND I.ruta3 IS NOT NULL AND CAST(CASE WHEN ISNUMERIC(I.ruta3)=1 THEN I.ruta3 ELSE '0' END AS INT)>=CASE WHEN ISNUMERIC(@ruta3D)=1 THEN CAST(@ruta3D AS INT) ELSE NULL END))
	AND (@ruta3H IS NULL OR ISNUMERIC(@ruta3H)=0 OR (ISNUMERIC(@ruta3H)=1 AND I.ruta3 IS NOT NULL AND CAST(CASE WHEN ISNUMERIC(I.ruta3)=1 THEN I.ruta3 ELSE '0' END AS INT)<=CASE WHEN ISNUMERIC(@ruta3H)=1 THEN CAST(@ruta3H AS INT) ELSE NULL END))
     	   
	AND (@ruta4D IS NULL OR ISNUMERIC(@ruta4D)=0 OR (ISNUMERIC(@ruta4D)=1 AND I.ruta4 IS NOT NULL AND CAST(CASE WHEN ISNUMERIC(I.ruta4)=1 THEN I.ruta4 ELSE '0' END AS INT)>=CASE WHEN ISNUMERIC(@ruta4D)=1 THEN CAST(@ruta4D AS INT) ELSE NULL END))
	AND (@ruta4H IS NULL OR ISNUMERIC(@ruta4H)=0 OR (ISNUMERIC(@ruta4H)=1 AND I.ruta4 IS NOT NULL AND CAST(CASE WHEN ISNUMERIC(I.ruta4)=1 THEN I.ruta4 ELSE '0' END AS INT)<=CASE WHEN ISNUMERIC(@ruta4H)=1 THEN CAST(@ruta4H AS INT) ELSE NULL END))
	  	    
	AND (@ruta5D IS NULL OR ISNUMERIC(@ruta5D)=0 OR (ISNUMERIC(@ruta5D)=1 AND I.ruta5 IS NOT NULL AND CAST(CASE WHEN ISNUMERIC(I.ruta5)=1 THEN I.ruta5 ELSE '0' END AS INT)>=CASE WHEN ISNUMERIC(@ruta5D)=1 THEN CAST(@ruta5D AS INT) ELSE NULL END))
	AND (@ruta5H IS NULL OR ISNUMERIC(@ruta5H)=0 OR (ISNUMERIC(@ruta5H)=1 AND I.ruta5 IS NOT NULL AND CAST(CASE WHEN ISNUMERIC(I.ruta5)=1 THEN I.ruta5 ELSE '0' END AS INT)<=CASE WHEN ISNUMERIC(@ruta5H)=1 THEN CAST(@ruta5H AS INT) ELSE NULL END))
          	    
	AND (@ruta6D IS NULL OR ISNUMERIC(@ruta6D)=0 OR (ISNUMERIC(@ruta6D)=1 AND I.ruta6 IS NOT NULL AND CAST(CASE WHEN ISNUMERIC(I.ruta6)=1 THEN I.ruta6 ELSE '0' END AS INT)>=CASE WHEN ISNUMERIC(@ruta6D)=1 THEN CAST(@ruta6D AS INT) ELSE NULL END))
	AND (@ruta6H IS NULL OR ISNUMERIC(@ruta6H)=0 OR (ISNUMERIC(@ruta6H)=1 AND I.ruta6 IS NOT NULL AND CAST(CASE WHEN ISNUMERIC(I.ruta6)=1 THEN I.ruta6 ELSE '0' END AS INT)<=CASE WHEN ISNUMERIC(@ruta6H)=1 THEN CAST(@ruta6H AS INT) ELSE NULL END))

	AND (@legal IS NULL OR @legal = 'Indiferente' OR (@legal='Si' AND CC.ctrRepresent IS NOT NULL AND CC.ctrRepresent<>'') OR (@legal='No' AND (CC.ctrRepresent IS NULL OR CC.ctrRepresent='')))
	AND (@tieneEmail IS NULL OR (@tieneEmail = 1 AND E.[emailTo*] IS NOT NULL AND  LEN(E.[emailTo*]) > 0) OR (@tieneEmail = 0 AND (E.[emailTo*] IS NULL OR  LEN(E.[emailTo*]) = 0)))	
	AND (@servicio IS NULL OR @servicio='' OR I.servicio = @servicio)
	AND (@apto IS NULL OR (@apto=1 AND V.Apta IN ('APTO 100%', 'SI')) OR (@apto=0 AND V.Apta IN ('NO')));


	--Buscamos los representantes de los contratos generales 
	INSERT INTO #RESULT
	SELECT  objectid, Servicio	
	, [REGISTROENTREGA]
	--WordTemplate_Contratos: OnFieldValueRequest
	, [CONTRATO] 
	, [USUARIOCOD] = C.clicod
	, [INMUEBLECOD] 
	, [CALIBRE]
	, [INMUEBLECODPOSTAL] 
	, [MARCACONTADOR]
	, [REFCATASTRAL] 
	, [FISNOM] = C.clinom
	, [BLOQUE]
	, [RUTA] 
	, [ORDEN]
	, [FISNIF] = C.clidociden
	, [FISDIR1]  = C.clicdomicilio
	, [TITULARCPOSTAL] = C.clicpostal
	, [FISDIR2] 
	, [ENVIOCPOSTAL] 
	, [FISTEL] = C.clitelefono1
	, [FISTEL2] = C.clitelefono2
	, [MAILDATOS] = C.climail
	, [CONTADOR] 
	, [TRIMESTRE]
	, [DOTACIONES]
	, [TARIFA] 
	, [NOMTARIFA] 
	, [CONTRATOCOMUNITARIO] 
	, [REPRESENTANTE]
	--, CL.clinom
	, [CLI_REPRESENTANTE] 
	--Otros Campos:
	, ctrTlfRef1 = C.clireftelf1
	, ctrTlfRef2
	, ctrTlfRef3
	, ctrTlf3
	--Inmueble
	, [INMUEBLE] 
	, [Calle] 
	, [Piso] 
	, [Puerta] 
	, [Numero] 
	, [Portal] 
	, [ZONA] 
	--DatosOT
	, [otApta] 
	, [otSociedad] 
	, [otSerie] 
	, [otNum] 
	, [otFecReg] 
	--ORDER BY
	, [SujetoPasivo] 
	, INSPECCION_GENERAL = -1
	FROM #RESULT AS R
	INNER JOIN dbo.clientes AS C
	ON CLI_REPRESENTANTE IS NOT NULL
	AND INSPECCION_GENERAL = 1
	AND C.clicod = R.CLI_REPRESENTANTE

	SELECT * 
	FROM #RESULT
	ORDER BY IIF(@orden='ruta', [RUTA], '')
	, IIF(@orden='ruta', [ORDEN], '')
	, IIF(@orden='suministro', [FISDIR1], '')
	, IIF(@orden='sujeto pasivo', [SujetoPasivo], '')
	, IIF(@orden='doc.iden', [FISNIF], '')
	, IIF(@orden='Representante',  UPPER([REPRESENTANTE]), '')
	, contrato, objectid 

END TRY
BEGIN CATCH

END CATCH

	DROP TABLE IF EXISTS #CONTADORES;
	DROP TABLE IF EXISTS #RESULT;
	DROP TABLE IF EXISTS #AGUA;

	--IF OBJECT_ID('tempdb..#CONTADORES') IS NOT NULL DROP TABLE #CONTADORES;	
	--IF OBJECT_ID('tempdb..#RESULT') IS NOT NULL DROP TABLE #RESULT;
	--IF OBJECT_ID('tempdb..#AGUA') IS NOT NULL DROP TABLE #AGUA;
GO