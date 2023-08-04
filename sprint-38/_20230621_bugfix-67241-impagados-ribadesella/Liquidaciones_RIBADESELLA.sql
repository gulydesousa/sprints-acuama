/*
DECLARE @facFechaD AS DATE = NULL;
DECLARE @facFechaH AS DATE = NULL;
DECLARE @fclFecLiqD AS DATE = NULL;
DECLARE @fclFecLiqH AS DATE = NULL;
DECLARE @facPerCodD AS VARCHAR(6) = '202206';
DECLARE @facPerCodH AS VARCHAR(6) = '202206';
DECLARE @ctrZonCodD AS VARCHAR(4) = NULL;
DECLARE @ctrZonCodH AS VARCHAR(4) = NULL;

DECLARE @usrCod AS VARCHAR(10) = 'admin';
DECLARE @liqTipoId SMALLINT = 1;
DECLARE @soloConsulta BIT = 1;

EXEC Liquidaciones_RIBADESELLA @facFechaD, @facFechaH
, @fclFecLiqD, @fclFecLiqH, @facPerCodD, @facPerCodH, @ctrZonCodD, @ctrZonCodH
, @usrCod, @liqTipoId, @soloConsulta;

SELECT * FROM LiquidacionesLotes

*/

CREATE PROCEDURE [dbo].[Liquidaciones_RIBADESELLA] 
  @facFechaD AS DATE = NULL
, @facFechaH AS DATE = NULL
, @fclFecLiqD AS DATE = NULL
, @fclFecLiqH AS DATE = NULL
, @facPerCodD AS VARCHAR(6) = NULL
, @facPerCodH AS VARCHAR(6) = NULL
, @ctrZonCodD AS VARCHAR(4) = NULL
, @ctrZonCodH AS VARCHAR(4) = NULL
, @usrCod AS VARCHAR(10) = 'admin'
, @liqTipoId SMALLINT = 0
, @soloConsulta BIT = 1

AS
SET NOCOUNT ON;

DECLARE @AHORA DATETIME = [dbo].[GetAcuamaDate]();
DECLARE @DIAS INT = 0;
DECLARE @IDLOTE INT = 0;
DECLARE @PARAMETROS VARCHAR(500) = 'Liquidaciones_RIBADESELLA @facFechaD=%s, @facFechaH=%s, @fclFecLiqD=%s, @fclFecLiqH=%s, @facPerCodD=%s, @facPerCodH=%s, @ctrZonCodD=%s, @ctrZonCodH=%s, @usrCod=%s, @liqTipoId=%s' 


SET @liqTipoId = ISNULL(@liqTipoId, 0);
SET @fclFecLiqH = IIF(@fclFecLiqH IS NULL, NULL, DATEADD(DAY, 1, @fclFecLiqH)); 

BEGIN TRY

	--*********************
	--[01]ID del lote de liquidaciones
	-- ...Lo generamos cuando el SP no es de simple consulta
	IF(@soloConsulta = 0)
	BEGIN
		SET @PARAMETROS = FORMATMESSAGE(@PARAMETROS, IIF(@facFechaD  IS NULL, 'NULL', CHAR(39) + FORMAT(@facFechaD, 'yyyyMMdd') + CHAR(39))
										   , IIF(@facFechaH  IS NULL, 'NULL', CHAR(39) + FORMAT(@facFechaH, 'yyyyMMdd') + CHAR(39))
										   , IIF(@fclFecLiqD IS NULL, 'NULL', CHAR(39) + FORMAT(@fclFecLiqD,'yyyyMMdd') + CHAR(39))
										   , IIF(@fclFecLiqH IS NULL, 'NULL', CHAR(39) + FORMAT(@fclFecLiqH,'yyyyMMdd') + CHAR(39))
										   , IIF(@facPerCodD IS NULL, 'NULL', ''''+ @facPerCodD +'''')
										   , IIF(@facPerCodH IS NULL, 'NULL', ''''+ @facPerCodH +'''')
										   , IIF(@ctrZonCodD IS NULL, 'NULL', ''''+ @ctrZonCodD +'''')
										   , IIF(@ctrZonCodH IS NULL, 'NULL', ''''+ @ctrZonCodH +'''')
										   , IIF(@usrCod IS NULL, 'NULL', ''''+ @usrCod +'''')
										   , IIF(@liqTipoId IS NULL, 'NULL', CAST(@liqTipoId AS VARCHAR))
										   );

		EXEC @IDLOTE = LiquidacionesLote_RegistrarID @liqTipoId, @usrCod, @PARAMETROS;
	END
	ELSE
	BEGIN
		SET @IDLOTE = 0;
	END
	
	
	--*********************
	--[02]Dias por defecto para el pago voluntario
	SELECT @DIAS = P.pgsValor 
	FROM dbo.parametros AS P WHERE P.pgsClave = 'DIAS_PAGO_VOLUNTARIO';
	
	--*********************
	--[03]Relacion de Tributos x Servicio
	SELECT ENTEMI
	, TRIBUTO
	, CONCEPTO
	, SUBCONCEPTO_COD
	, SUBCONCEPTO_DESC
	, svcCod
	, svcDes
	, svcOrgCod
	, svctipo
	, esDescuento  
	INTO #TRIBUTOS
	FROM dbo.vLiquidacionesTributos
	WHERE liqTipoId = @liqTipoId;
	

	--*********************
	--[04]Plantilla de resultados para la salida 
	DECLARE @RESULT AS dbo.tLiquidaciones_RIBADESELLA;
		
	--*********************
	--[05]ORGOFI
	DECLARE @ORGOFI AS TABLE(DNI VARCHAR(20));

	INSERT INTO @ORGOFI
	VALUES('S3333001J'), ('P3305600C');

	--*********************
	--[10]#FACLIN: LINEAS DE FACTURA LIQUIDADAS 
	-- ...y liquidables por configuración del ayuntamiento
	SELECT F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion
	, F.facCtrVersion
	, F.facFecha
	, F.facNumero
	, F.facFechaRectif
	, [facNumLinea] = fclNumLinea
	, T.svccod
	, T.svctipo
	, A.aprNumero
	, T.ENTEMI
	, T.TRIBUTO
	, T.CONCEPTO
	, T.SUBCONCEPTO_COD
	, T.SUBCONCEPTO_DESC
	, T.esDescuento
	INTO #FACLIN
	FROM dbo.facturas AS F
	INNER JOIN dbo.faclin AS FL
	ON F.facCod = FL.fclFacCod
	AND F.facPerCod = FL.fclFacPerCod
	AND F.facCtrCod = FL.fclFacCtrCod
	AND F.facVersion = FL.fclFacVersion
	AND F.facFecha IS NOT NULL
	AND FL.fclFecLiq IS NOT NULL	
	AND FL.fclUsrLiq IS NOT NULL
	INNER JOIN dbo.contratos AS C
	ON  C.ctrCod = F.facCtrCod
	AND C.ctrVersion = F.facCtrVersion
	INNER JOIN #TRIBUTOS AS T
	ON T.svcCod = FL.fclTrfSvCod
	
	LEFT JOIN dbo.apremios AS A
	ON  A.aprFacCod = F.facCod 
	AND A.aprFacCtrCod = F.facCtrCod 
	AND A.aprFacPerCod = F.facPerCod 
	AND A.aprFacVersion = F.facVersion
	WHERE (@facFechaD IS NULL OR F.facFecha >= @facFechaD)
	  AND (@facFechaH IS NULL OR F.facFecha <= @facFechaH)
	  AND (@fclFecLiqD IS NULL OR FL.fclFecLiq >= @fclFecLiqD)
	  AND (@fclFecLiqH IS NULL OR FL.fclFecLiq < @fclFecLiqH)
	  AND (@facPerCodD IS NULL OR F.facPerCod >= @facPerCodD)
	  AND (@facPerCodH IS NULL OR F.facPerCod <= @facPerCodH)
	  AND (@ctrZonCodD IS NULL OR C.ctrZonCod >= @ctrZonCodD)
	  AND (@ctrZonCodH IS NULL OR C.ctrZonCod <= @ctrZonCodH)
	  AND (A.aprNumero IS NULL);
	  
	
	
	--*********************
	--[20]#RPT: Tabla temporal con las lineas de factura liquidadas que cumplen los filtros
	SELECT F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion
	, F.facFecha
	, F.facNumero
	, F.facFechaRectif
	
	, F.ENTEMI
	, F.TRIBUTO
	, F.CONCEPTO
	, F.SUBCONCEPTO_COD
	, F.SUBCONCEPTO_DESC

	--FFFFFFFFFFFFFFFFF
	, [RN_FAC]			= ROW_NUMBER()										OVER(PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion ORDER BY fclTrfSvCod, fclNumLinea)
	, [Base_FAC]		= SUM(ISNULL(FL.fclBase, 0))						OVER(PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion)
	, [Base2Dec_FAC]	= SUM(ROUND(ISNULL(FL.fclBase, 0), 2))				OVER(PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion)
	, [Impuesto_FAC]	= SUM(FL.fclImpImpuesto)							OVER(PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion)
	, [Impuesto2Dec_FAC]	= SUM(ROUND(ISNULL(FL.fclImpImpuesto, 0), 2))	OVER(PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion)
	--Consumo en (1)SERVICIO AGUA
	, [Consumo_FAC]		= SUM(IIF(svccod <> 1, 0,
								  ISNULL(FL.fclunidades1, 0) 
								+ ISNULL(FL.fclunidades2, 0)
								+ ISNULL(FL.fclunidades3, 0)
								+ ISNULL(FL.fclunidades4, 0)
								+ ISNULL(FL.fclunidades5, 0)
								+ ISNULL(FL.fclunidades6, 0)
								+ ISNULL(FL.fclunidades7, 0)
								+ ISNULL(FL.fclunidades8, 0)
								+ ISNULL(FL.fclunidades9, 0)))	OVER(PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion)
	--FFFFFFFFFFFFFFFFF
	
	--TTTTTTTTTTTTTTTTT
	--TOTALES X TRIBUTO (SUBCONCEPTO)
	, [RN_TRIB] = ROW_NUMBER()									OVER(PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, F.SUBCONCEPTO_COD ORDER BY fclTrfSvCod, fclNumLinea)
	, [CN_TRIB] = COUNT(FL.fclNumLinea)							OVER(PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, F.SUBCONCEPTO_COD)
	, [NumDescuentos_TRIB] = SUM(esDescuento)					OVER(PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, F.SUBCONCEPTO_COD)
	, [Base_TRIB] = SUM(FL.fclBase)								OVER(PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, F.SUBCONCEPTO_COD)
	, [Base2Dec_TRIB] = SUM(ROUND(ISNULL(FL.fclBase, 0), 2))	OVER(PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, F.SUBCONCEPTO_COD)
	, [Impuesto_TRIB] = SUM(FL.fclImpImpuesto)					OVER(PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, F.SUBCONCEPTO_COD)
	--TTTTTTTTTTTTTTTTT

	, FL.fclImpuesto
	, FL.fclImpImpuesto
	, FL.fclNumLinea
	, FL.fclTrfSvCod
	, FL.fclTrfCod
	, F.svctipo
	, FL.fclFecLiq
	, FL.fclUsrLiq
	, FL.fclBase
	, fclBase_2Dec = ROUND(ISNULL(FL.fclBase, 0), 2)
	, Consumo = 
	  ISNULL(FL.fclunidades1, 0) 
	+ ISNULL(FL.fclunidades2, 0)
	+ ISNULL(FL.fclunidades3, 0)
	+ ISNULL(FL.fclunidades4, 0)
	+ ISNULL(FL.fclunidades5, 0)
	+ ISNULL(FL.fclunidades6, 0)
	+ ISNULL(FL.fclunidades7, 0)
	+ ISNULL(FL.fclunidades8, 0)
	+ ISNULL(FL.fclunidades9, 0)
	, C.ctrZonCod
	, C.ctrTitNom
	, C.ctrTitDocIden
	, PER.perFecIniPagoVol
	, PER.perFecFinPagoVol
	, PER.pertipo
	, F.aprNumero
	, I.inmDireccion
	, [CP] = COALESCE(I.inmcpost, C.ctrTitCPos, '')
	, C.ctrTitCPos
	, I.inmcpost
	, '' tviaAbreviado --TV.tviaAbreviado 24/11
	, POB.pobdes
	, [fIniPagoVoluntario] = ISNULL(PER.perFecIniPagoVol, F.facFecha)
	, [fFinPagoVoluntario] = ISNULL(PER.perFecFinPagoVol, DATEADD(DAY, @DIAS, F.facFecha))
	, [RN_PK] = ROW_NUMBER() OVER(ORDER BY facCtrCod, facPerCod, facCod, facVersion, SUBCONCEPTO_COD, fclTrfSvCod, fclNumLinea)
	INTO #RPT
	FROM #FACLIN AS F
	INNER JOIN dbo.faclin AS FL
	ON  F.facCod = FL.fclFacCod
	AND F.facPerCod = FL.fclFacPerCod
	AND F.facCtrCod = FL.fclFacCtrCod
	AND F.facVersion = FL.fclFacVersion
	AND F.facNumLinea = FL.fclNumLinea
	INNER JOIN dbo.periodos AS PER
	ON PER.percod = F.facPerCod
	INNER JOIN dbo.contratos AS C
	ON  C.ctrCod = F.facCtrCod
	AND C.ctrVersion = F.facCtrVersion
	INNER JOIN dbo.inmuebles AS I
	ON I.inmCod = C.ctrinmCod
	LEFT JOIN dbo.calles AS CLL
	ON I.inmcllcod = CLL.cllcod
	LEFT JOIN dbo.TiposVia AS TV
	ON TV.tviaCodigo = CLL.cllTviaCodigo
	LEFT JOIN dbo.poblaciones AS POB
	ON  POB.pobprv = I.inmPrvCod
	AND POB.pobcod = I.inmPobCod;

	
	--*********************
	--[21]#TRIBUTOS: Totales por tributos
	SELECT [tribFacCod] = F.facCod
	, [tribPerCod] = F.facPerCod
	, [tribCtrCod] = F.facCtrCod
	, [tribFacVersion] = F.facVersion
	, [CODAGUA180] = SUM(IIF(SUBCONCEPTO_COD = 'AP' , 1, 0)) --'PA' 24/11
	, [IMPAGUA180] = SUM(IIF(SUBCONCEPTO_COD = 'AP', [Base2Dec_TRIB], 0)) --'PA' 24/11
	, [IVAAGUA180] = SUM(IIF(SUBCONCEPTO_COD = 'AP', [Impuesto_TRIB], 0)) --'PA' 24/11

	, [CODBASURA180] = SUM(IIF(SUBCONCEPTO_COD = 'BA', 1, 0)) 
	, [IMPBASURA180] = SUM(IIF(SUBCONCEPTO_COD = 'BA', [Base2Dec_TRIB], 0)) 
	, [IVABASURA180] = SUM(IIF(SUBCONCEPTO_COD = 'BA', [Impuesto_TRIB], 0)) 

	, [CODALC180] = SUM(IIF(SUBCONCEPTO_COD = 'AL', 1, 0)) 
	, [IMPALC180] = SUM(IIF(SUBCONCEPTO_COD = 'AL', [Base2Dec_TRIB], 0)) 
	, [IVAALC180] = SUM(IIF(SUBCONCEPTO_COD = 'AL', [Impuesto_TRIB], 0)) 

	, [CODCANON180] = SUM(IIF(SUBCONCEPTO_COD = 'CA', 1, 0)) 
	, [IMPCANON180] = SUM(IIF(SUBCONCEPTO_COD = 'CA', [Base2Dec_TRIB], 0)) 
	, [IVACANON180] = SUM(IIF(SUBCONCEPTO_COD = 'CA', [Impuesto_TRIB], 0)) 

	INTO #SUBCONCEPTOS
	FROM #RPT AS F
	WHERE RN_TRIB=1
	GROUP BY F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion;
	
	--*********************
	--[30]Insertamos las lineas en la tabla de resultados para la salida
	--	  Agrupados por tributos
	INSERT INTO @RESULT
	SELECT [EJ]				= SUBSTRING(facPerCod, 3, 2) --FORMAT(facFecha, 'yy')
		 , [ENTEMI]			= R.ENTEMI
		 , [AYTO]			= '056'
		 , [TRIBUTO]		= R.TRIBUTO
		 , [ANUALIDAD]		= FORMAT(fclFecLiq, 'yy')
		 , [NUMLIQ]			= RIGHT(CONCAT(FORMAT(0, 'D12'), facNumero), 12) 
		 , [NOMCER]			= FORMAT(facCtrCod, 'D12')
		 --, [PRINCI]			= FORMAT(CONVERT(INT, ROUND(Base_FAC, 2)*100), 'D9')	--Con ceros a la izquierda
		 , [PRINCI]			= FORMAT(CONVERT(INT, ROUND(Base2Dec_FAC, 2)*100), 'D9')	--Con ceros a la izquierda
		 , [INIVOL]			= FORMAT(fIniPagoVoluntario, 'ddMMyy')
		 , [FINVOL]			= FORMAT(fFinPagoVoluntario, 'ddMMyy')
		 , [CONTRI]			= CAST(ctrTitNom AS CHAR(40))
		 , [DNI]			= ctrTitDocIden
		 , [SIGLAS]			= tviaAbreviado
		 , [LUGAR]			= CAST(inmDireccion AS CHAR(38))
		 , [POBLACION]		= pobdes
		 , [MUNICIPIO]		= '056'
		 , [PROVINCIA]		= '33'
		 , [CPP]			= CP
		 , [CONCEPTO]		= CAST(R.CONCEPTO AS CHAR(20))
		 , [CLAVE1]			=  '0' --' ' 24/11
		 , [CONYUGE]		= ''
		 , [NIFCON]			= ''
		 , [FECHACER]		= '241121'
		 , [DETALLE]		= CONCAT('Numero de abonado : ', facCtrCod)
		 , [OTRA1]			= CONCAT('m3: ', CONVERT(INT, R.Consumo_FAC))
		 , [OTRA2]			= ''
		 , [LOTE]			= FORMAT(@IDLOTE, 'D4')  
		 , [MODONOT]		='C'
		 --Fecha de inicio del pago voluntario si existe valor configurado en el periodo
		 , [FECHALIQ]		= IIF(perFecIniPagoVol IS NULL, '000000' , FORMAT(perFecIniPagoVol, 'ddMMyy'))
		 , [PERIODO_ACUAMA] = facPerCod
		 , [PERIODO]		= IIF(pertipo='B' AND LEN(facPerCod) = 6, SUBSTRING(facPerCod, 6, 1), '0') + ISNULL(pertipo, 'A')
		 , [FECHAFIR]		= '000000' --''
		 , [REPRE]			= ''
		 , [DIREREPRE]		= ''
		 , [MUNIREPRE]		= ''
		 , [PROVIREPRE]		= ''
		 , [CPPREPRE]		= ''
		 , [IMPENT]			= '000000000'--'' 24/11
		 , [FINGRE]			= '000000'--'' 24/11
		 
		 --Organismo Oficial (00 No, 97 Si)
		 , [ORGOFI]			= '00'--IIF(O.DNI IS NULL, '00', '97')

		 , [IVA]			= FORMAT(CONVERT(INT, ROUND(Impuesto_FAC, 2)*100), 'D9')	--Con ceros a la izquierda
		 , [FECHA_APREMIO]	= '      '--'000000' 24/11
		 ------------------------------
		 , [CODAGUA180]		= 'AP' --'PA' --IIF(T.CODAGUA180>0, 'PA', '')
		 , [IMPAGUA]		= ROUND(T.IMPAGUA180, 2)
		 , [IMPAGUA180]		= FORMAT(CONVERT(INT, ROUND(T.IMPAGUA180, 2)*100), 'D8')	--IIF(T.CODAGUA180>0, FORMAT(CONVERT(INT, ROUND(T.IMPAGUA180, 2)*100), 'D8'), '')
		 , [IVAAGUA]		= ROUND(T.IVAAGUA180, 2)
		 , [IVAAGUA180]		= FORMAT(CONVERT(INT, ROUND(T.IVAAGUA180, 2)*100), 'D8')	--IIF(T.CODAGUA180>0, FORMAT(CONVERT(INT, ROUND(T.IVAAGUA180, 2)*100), 'D8'), '')

		 , [CODBASURA180]	= 'BA'--IIF(T.CODBASURA180>0, 'BA', '')
		 , [IMPBASURA]		= ROUND(T.IMPBASURA180, 2)
		 , [IMPBASURA180]	= FORMAT(CONVERT(INT, ROUND(T.IMPBASURA180, 2)*100), 'D8')	--IIF(T.CODBASURA180>0, FORMAT(CONVERT(INT, ROUND(T.IMPBASURA180, 2)*100), 'D8'), '')

		 , [CODALC180]		= 'AL' --IIF(T.CODALC180>0, 'AL', '')
		 , [IMPALC]		= ROUND(T.IMPALC180, 2)
		 , [IMPALC180]		= FORMAT(CONVERT(INT, ROUND(T.IMPALC180, 2)*100), 'D8')		--IIF(T.CODALC180>0, FORMAT(CONVERT(INT, ROUND(T.IMPALC180, 2)*100), 'D8'), '')
		 ------------------------------
		 , [CODMIN180] = ''
		 , [IMPMIN180] = ''

		 , [CODTCONT180] = ''
		 , [IMPTCONT180] = ''
		 , [IVATCONT180] = ''

		 , [CODCANON180] = IIF(T.CODCANON180>0, 'CA', '  ') --'CA'
		 , [IMPCANON]	= ROUND(T.IMPCANON180, 2)
		 , [IMPCANON180] = IIF(T.CODCANON180>0, FORMAT(CONVERT(INT, ROUND(T.IMPCANON180, 2)*100), 'D8'), '        ') --FORMAT(CONVERT(INT, ROUND(T.IMPCANON180, 2)*100), 'D8')

		 , [CODOTRO1180] = ''
		 , [IMPOTRO1180] = ''

		 , [CODOTRO2180] = ''
		 , [IMPOTRO2180] = ''

		 , [PRESCRIPCION] = ''
		 ------------------------------	
		 , [TOTAL_BASE]= ROUND(Base2Dec_FAC, 2)		 
		 , [TOTAL_IVA] = ROUND(Impuesto_FAC, 2)
		 , [RN_PK]			= [RN_PK]
	FROM #RPT AS R
	LEFT JOIN #SUBCONCEPTOS AS T
	ON R.facCtrCod	= T.tribCtrCod
	AND R.facPerCod = T.tribPerCod
	AND R.facVersion= T.tribFacVersion
	AND R.facCod	= T.tribFacCod
	LEFT JOIN @ORGOFI AS O
	ON O.DNI = R.ctrTitDocIden
	WHERE [RN_FAC]=1 AND [Base2Dec_FAC]>0;
	
	
	--*********************
	--Guardamos los contratos excluidos
	declare @observacionesNIF varchar(max) = null;
	declare @observacionesDeudaBaja varchar(max) = null;
	declare @observacionesContratosEspecificos varchar(max) = null;
	declare @facturasExcluidas int = 0;
	declare @baseExcluida money = 0;
	declare @impuestosExcluidos money = 0;

	--NIFs incorrectos
	IF(@liqTipoId = 1 AND (SELECT COUNT(PK) FROM @RESULT WHERE (DNI is null OR DNI = '' OR DNI = '00000000T')) > 0)
	BEGIN
		SELECT @observacionesNIF = STUFF(
							(   SELECT ', ' + CONVERT(NVARCHAR(100), CAST(NOMCER AS INT)) 
								FROM @RESULT
								WHERE (DNI is null OR DNI = '' OR DNI = '00000000T')
								GROUP BY NOMCER
								ORDER BY NOMCER
								FOR xml path('')
							)
							, 1
							, 1
							, '')
	
		IF(@observacionesNIF is not null AND @observacionesNIF <> '')
		BEGIN
			set @facturasExcluidas = (select COUNT(PK) from @RESULT WHERE (DNI is null OR DNI = '' OR DNI = '00000000T'))
			set @baseExcluida = (select SUM(TOTAL_BASE) from @RESULT WHERE (DNI is null OR DNI = '' OR DNI = '00000000T'))
			set @impuestosExcluidos = (select SUM(TOTAL_IVA) from @RESULT WHERE (DNI is null OR DNI = '' OR DNI = '00000000T'))

			set @observacionesNIF = (select CONCAT('Periodos filtro: ', @facPerCodD, ' - ', @facPerCodH, '. Facturas excluidas por NIF incorrecto: ', CONVERT(NVARCHAR(10), @facturasExcluidas), 
				'. Base excluida por NIF incorrecto: ', CONVERT(NVARCHAR(10), @baseExcluida), '. Impuestos excluidos por NIF incorrecto: ', CONVERT(NVARCHAR(10), @impuestosExcluidos),
				'. Contratos excluidos por NIF incorrecto: ', @observacionesNIF, '. | '))
		END

		--los borro para no incluirlos en mi fichero
		DELETE FROM @RESULT WHERE (DNI is null OR DNI = '' OR DNI = '00000000T')
	END

	--Deuda inferior a 6€
	IF(@liqTipoId = 1 AND (SELECT COUNT(PK) FROM @RESULT WHERE (CAST(PRINCI AS INT) + CAST(IVA AS INT))/100 < 6) > 0)
	BEGIN
		SELECT @observacionesDeudaBaja = STUFF(
							(   SELECT ', ' + CONVERT(NVARCHAR(100), CAST(NOMCER AS INT)) 
								FROM @RESULT
								WHERE (CAST(PRINCI AS INT) + CAST(IVA AS INT))/100 < 6
								GROUP BY NOMCER
								ORDER BY NOMCER
								FOR xml path('')
							)
							, 1
							, 1
							, '')
	
		IF(@observacionesDeudaBaja is not null AND @observacionesDeudaBaja <> '')
		BEGIN
			set @facturasExcluidas = (select COUNT(PK) from @RESULT WHERE (CAST(PRINCI AS INT) + CAST(IVA AS INT))/100 < 6)
			set @baseExcluida = (select SUM(TOTAL_BASE) from @RESULT WHERE (CAST(PRINCI AS INT) + CAST(IVA AS INT))/100 < 6)
			set @impuestosExcluidos = (select SUM(TOTAL_IVA) from @RESULT WHERE (CAST(PRINCI AS INT) + CAST(IVA AS INT))/100 < 6)

			set @observacionesDeudaBaja = (select CONCAT('Facturas excluidas por deuda inferior: ', CONVERT(NVARCHAR(10), @facturasExcluidas), 
				'. Base excluida por deuda inferior: ', CONVERT(NVARCHAR(10), @baseExcluida), '. Impuestos excluidos por deuda inferior: ', CONVERT(NVARCHAR(10), @impuestosExcluidos),
				'. Contratos excluidos por deuda inferior: ', @observacionesDeudaBaja, '. | '))
		END

		--los borro para no incluirlos en mi fichero
		DELETE FROM @RESULT WHERE (CAST(PRINCI AS INT) + CAST(IVA AS INT))/100 < 6
	END

	--Contratos y periodos específicos --SYR-306450 --SYR-319138
	IF(@liqTipoId = 1 AND (SELECT COUNT(PK) FROM @RESULT WHERE ((NOMCER in (3667459) AND PERIODO_ACUAMA IN ('202004','202005')) OR (NOMCER in (3666908) AND PERIODO_ACUAMA IN ('202103')))) > 0)
	BEGIN
		SELECT @observacionesContratosEspecificos = '3667459, 3666908'
	
		IF(@observacionesContratosEspecificos is not null AND @observacionesContratosEspecificos <> '')
		BEGIN
			set @facturasExcluidas = (select COUNT(PK) from @RESULT WHERE ((NOMCER in (3667459) AND PERIODO_ACUAMA IN ('202004','202005')) OR (NOMCER in (3666908) AND PERIODO_ACUAMA IN ('202103'))))
			set @baseExcluida = (select SUM(TOTAL_BASE) from @RESULT WHERE ((NOMCER in (3667459) AND PERIODO_ACUAMA IN ('202004','202005')) OR (NOMCER in (3666908) AND PERIODO_ACUAMA IN ('202103'))))
			set @impuestosExcluidos = (select SUM(TOTAL_IVA) from @RESULT WHERE ((NOMCER in (3667459) AND PERIODO_ACUAMA IN ('202004','202005')) OR (NOMCER in (3666908) AND PERIODO_ACUAMA IN ('202103'))))

			set @observacionesContratosEspecificos = (select CONCAT('Periodos filtro: ', @facPerCodD, ' - ', @facPerCodH, '. Facturas excluidas por petición: ', CONVERT(NVARCHAR(10), @facturasExcluidas), 
				'. Base excluida por petición: ', CONVERT(NVARCHAR(10), @baseExcluida), '. Impuestos excluidos por petición: ', CONVERT(NVARCHAR(10), @impuestosExcluidos),
				'. Contratos excluidos por petición: ', @observacionesContratosEspecificos))
		END

		--los borro para no incluirlos en mi fichero
		DELETE FROM @RESULT WHERE ((NOMCER in (3667459) AND PERIODO_ACUAMA IN ('202004','202005')) OR (NOMCER in (3666908) AND PERIODO_ACUAMA IN ('202103')))
	END

	--*********************
	--[99]RESULTADOS
	SELECT R.*
	FROM fLiquidaciones_RIBADESELLA(@RESULT, @liqTipoId) AS R
	ORDER BY PK;
	
	--*********************
	--[FIN] ACTUALIZAMOS LOS TOTALES DEL FICHERO EN LiquidacionesLotes
	WITH TOTALES AS(
	SELECT Facturas = COUNT(PK)
		 , BaseFacturado = SUM(TOTAL_BASE)
		 , Impuesto = SUM(TOTAL_IVA)
	FROM @RESULT)
	UPDATE L SET 
	  L.liqLoteFacturas = T.Facturas	
	, L.liqLoteBaseTotal = T.BaseFacturado	
	, L.liqLoteImpuestoTotal = T.Impuesto
	, L.liqLoteObservaciones = CONCAT(ISNULL(@observacionesNIF, ''), ISNULL(@observacionesDeudaBaja, ''), ISNULL(@observacionesContratosEspecificos, ''))
	FROM dbo.liquidacionesLotes AS L
	INNER JOIN TOTALES AS T
	ON  @soloConsulta = 0
	WHERE L.liqLoteTipoId=@liqTipoId
	  AND L.liqLoteNum=@IDLOTE
	  AND L.liqLoteUsr=@usrCod
	  AND L.liqLoteFecha >=@AHORA;
	
	--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	--PRUEBAS
	--WITH PRUEBA AS(
	--SELECT R.PK
	--,  R.IMPBASURA180
	--, R.IMPALC180
	--, R.IMPAGUA180, R.IVAAGUA180
	--, [IVA_AGUA_CAST] = CAST(R.IVAAGUA180 AS INT) *0.01
	--, [IVAAGUA] = ROUND(S.[IVAAGUA180], 2)
	--, R.PRINCI, R.IVA
	--, [BASE_CAST] = (CAST(R.IMPBASURA180 AS INT) + CAST(R.IMPALC180 AS INT) + CAST(R.IMPAGUA180 AS INT)) * 0.01
	--, [PRINCI_CAST] = (CAST(R.PRINCI AS INT)) * 0.01
	--, T.Base2Dec_FAC
	--, [Imp2Dec_FAC] = ROUND(T.Impuesto_FAC, 2)
	--, [IVA_CAST] = CAST((R.IVA) AS INT) *0.01
	--FROM fLiquidaciones_RIBADESELLA(@RESULT) AS R
	--INNER JOIN #RPT AS T ON T.RN_PK = R.PK
	--LEFT JOIN #SUBCONCEPTOS AS S
	--ON  T.facCod = S.tribFacCod
	--AND T.facPerCod = S.tribPerCod
	--AND T.facCtrCod = S.tribCtrCod
	--AND T.facVersion = S.tribFacVersion)

	--SELECT BASE_CAST = SUM([BASE_CAST]) 
	--, SUM([PRINCI_CAST]) 
	--, SUM(Base2Dec_FAC)
	--, IVA_CAST = SUM([IVA_CAST])
	--, Registros = COUNT(PK)
	--, SUM([Imp2Dec_FAC])
	--FROM PRUEBA
	--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
END TRY

BEGIN CATCH

END CATCH

IF OBJECT_ID(N'tempdb..#RPT') IS NOT NULL
DROP TABLE #RPT;

IF OBJECT_ID(N'tempdb..#FACLIN') IS NOT NULL
DROP TABLE #FACLIN;

IF OBJECT_ID(N'tempdb..#TRIBUTOS') IS NOT NULL
DROP TABLE #TRIBUTOS

IF OBJECT_ID(N'tempdb..#SUBCONCEPTOS') IS NOT NULL
DROP TABLE #SUBCONCEPTOS
GO


