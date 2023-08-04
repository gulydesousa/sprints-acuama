/*

DECLARE @fechaFacturaD AS DATETIME = '20220101',
@fechaFacturaH AS DATETIME = '20221231',
@fechaLiquidacionD AS DATETIME = NULL,
@fechaLiquidacionH AS DATETIME = NULL,
@periodoD AS VARCHAR(6) = NULL,
@periodoH AS VARCHAR(6) = NULL,
@zonaD AS VARCHAR(4) = NULL,
@zonaH AS VARCHAR(4) = NULL
, @ctrcod AS INT --= 31810


EXEC Liquidaciones_RegistrosContratos_AVG @fechaFacturaD, @fechaFacturaH
, @fechaLiquidacionD, @fechaLiquidacionH
, @periodoD, @periodoH
, @zonaD, @zonaH
, @ctrcod;

*/

--DROP PROCEDURE [dbo].[Liquidaciones_RegistrosContratos_AVG]

CREATE PROCEDURE [dbo].[Liquidaciones_RegistrosContratos_AVG]
@fechaFacturaD AS DATETIME = NULL,
@fechaFacturaH AS DATETIME = NULL,
@fechaLiquidacionD AS DATETIME = NULL,
@fechaLiquidacionH AS DATETIME = NULL,
@periodoD AS VARCHAR(6) = NULL,
@periodoH AS VARCHAR(6) = NULL,
@zonaD AS VARCHAR(4) = NULL,
@zonaH AS VARCHAR(4) = NULL,
@ctrcod AS INT  = NULL
AS

DECLARE @facFechaD DATE;
DECLARE @facFechaH DATE;

DECLARE @fechaPerD AS DATE;
DECLARE @fechaPerH AS DATE;

SET @fechaPerD = (SELECT TOP 1 przfPeriodoD FROM dbo.perzona AS P WHERE P.przcodper = @periodoD)
SET @fechaPerH = (SELECT TOP 1 przfPeriodoH FROM dbo.perzona AS P WHERE P.przcodper = @periodoH)


SELECT @facFechaD = IIF(@fechaFacturaD IS NOT NULL, @fechaFacturaD, NULL),
	   @facFechaH = IIF(@fechaFacturaH IS NOT NULL, DATEADD(DAY, 1, @fechaFacturaH), NULL),
	   @fechaPerH = IIF(@fechaPerH IS NOT NULL, DATEADD(DAY, 1, @fechaPerH), NULL);


BEGIN TRY
	--*********************************************
	--1ro: Seleccionamos las lineas de factura que pueden formar parte de la salida 
	--2do: Nos quedamos con las cabeceras de contratos de estas facturas que representa el resultado
	
	
	--*********************************************
	--**************  # A U X  ********************
	--*********************************************
	--[01]Buscamos los datos clave según los filtros en la tabla: #AUX
	SELECT F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion
	, F.facCtrVersion
	, FL.fclNumLinea
	, FL.fclTrfSvCod
	, FL.fclTrfCod
	, C.ctrTitTipDoc
	, C.ctrTitDocIden
	, C.ctrTitNom
	, C.ctrTitDir
	, C.ctrComunitario
	, C.ctrValorc1
	, C.ctrfecreg
	, _ctrfecanu = C.ctrfecanu
	, _ctrbaja = C.ctrbaja
	, _facFechaRectif= F.facFechaRectif
	, ctrfecanu = IIF(C.ctrfecanu IS NOT NULL AND C.ctrfecanu<@facFechaH, C.ctrfecanu , NULL)
	, ctrbaja = IIF(C.ctrbaja IS NOT NULL AND C.ctrbaja=1 AND C.ctrfecanu>=@facFechaD AND C.ctrfecanu<@facFechaH, C.ctrbaja , 0)
	, I.inmrefcatastral
	, I.inmDireccion
	, [facFechaRectif] = IIF(F.facFechaRectif IS NOT NULL AND F.facFechaRectif<@facFechaH, F.facFechaRectif , NULL)
	, [Rectificada_FacVersion] = F0.facVersion
	, [Rectificada_TieneCanon] = CAST(NULL AS BIT)
	, [fclUso] = CASE WHEN FL.fclTrfSvCod = 20 THEN IIF (FL.fclTrfCod IN (101,401,501,601,701,1001,8501), 'D', 'N')
					  ELSE NULL END
	, [facUso] = CAST(NULL AS VARCHAR(1))
	, [ctrUso] = CAST(NULL AS VARCHAR(1))

	--Ctr_RN=1: Para quedarnos con un registro por Contrato
	, Ctr_RN = ROW_NUMBER() OVER(PARTITION BY C.ctrCod, C.ctrVersion ORDER BY F.facPercod, F.facCod, F.facVersion, FL.fclNumLinea) 

	INTO #AUX
	FROM dbo.facturas AS F 
	INNER JOIN dbo.contratos AS C
	ON  F.facCtrCod = C.ctrcod
	AND F.facCtrVersion = C.ctrversion
	AND (@ctrcod IS NULL OR C.ctrcod=@ctrcod)
	INNER JOIN dbo.inmuebles AS I
	ON  C.ctrinmcod= I.inmcod 
	INNER JOIN dbo.faclin AS FL 
	ON  FL.fclFacCtrCod = F.facCtrCod 
	AND FL.fclFacPerCod= F.facPerCod 
	AND FL.fclFacCod= F.facCod 
	AND FL.fclFacVersion= F.facVersion
	LEFT JOIN dbo.facturas AS F0
	ON F0.facCod = F.facCod
	AND F0.facPerCod = F.facPerCod
	AND F0.facCtrCod = F.facCtrCod
	AND F0.facFechaRectif = F.facFecha
	AND F0.facNumeroRectif = F.facNumero
	WHERE F.facFecha IS NOT NULL AND

		  (fclFecLiqImpuesto IS NOT NULL AND fclUsrLiqImpuesto IS NOT NULL) AND
		  (F.facFecha >= @facFechaD OR @fechaFacturaD IS NULL) AND
		  (F.facFecha <  @facFechaH OR @fechaFacturaH IS NULL) AND
		  (F.facFecha >= @fechaPerD OR @fechaPerD IS NULL) AND
		  (F.facFecha < @fechaPerH OR @fechaPerH IS NULL) AND
		  (fclFecLiqImpuesto >= @fechaLiquidacionD OR @fechaLiquidacionD IS NULL) AND
		  (fclFecLiqImpuesto <= @fechaLiquidacionH OR @fechaLiquidacionH IS NULL) AND
		  (((F.facPerCod >= @periodoD OR @periodoD IS NULL) AND
		  (F.facPerCod <= @periodoH OR @periodoH IS NULL))
			OR 
			((F.facPerCod like '0%') 
				AND ((F.facFecha >= @fechaPerD OR @fechaPerD IS NULL) AND (F.facFecha < @fechaPerH OR @fechaPerH IS NULL))
			)
		  ) AND
		  (ctrZonCod >= @zonaD OR @zonaD IS NULL) AND
		  (ctrZonCod <= @zonaH OR @zonaH IS NULL )
		  AND
		  (F.facFechaRectif is null

			OR
			(
				F.facFechaRectif is not null and fclTrfSvCod in (19,20)
			)
		);	


	--*********************************************
	--[02]Vemos si las rectificadas tenían el servicio de canon: #AUX.Rectificada_TieneCanon
	UPDATE A SET [Rectificada_TieneCanon] =
											IIF( EXISTS (SELECT FL.fclFacCod FROM faclin AS FL WHERE  FL.fclFacCod = A.facCod 
											AND FL.fclFacPerCod = A.facPerCod
											AND FL.fclFacCtrCod = A.facCtrCod 
											AND FL.fclFacVersion = A.Rectificada_FacVersion
											AND FL.fclTrfSvCod IN (19, 20)), 1, 0)
	FROM #AUX AS A
	WHERE A.Rectificada_FacVersion IS NOT NULL;


	--*********************************************
	--[03]Asignamos el uso según la tafifa en CANON VARIABLE(20)
	--Usos: D, N
	--En caso de que haya distintas tarifas, domésticas y no domésticas, siempre priorizo no doméstico
	WITH F AS(
	SELECT facCod, facPerCod, facCtrCod, facVersion, facCtrVersion, facUso = MAX(fclUso) 
	FROM #AUX AS A
	GROUP BY facCod, facPerCod, facCtrCod, facVersion, facCtrVersion

	), C AS(
	SELECT facCtrCod, facCtrVersion, ctrUso = MAX(facUso) 
	FROM F 
	GROUP BY  facCtrCod, facCtrVersion)

	UPDATE A SET A.facUso = F.facUso
	, A.ctrUso = C.ctrUso
	FROM #AUX AS A 
	LEFT JOIN F
	ON F.facCod = A.facCod
	AND F.facPerCod = A.facPerCod
	AND F.facCtrCod = A.facCtrCod
	AND F.facVersion = A.facVersion
	LEFT JOIN C
	ON C.facCtrCod = A.facCtrCod
	AND C.facCtrVersion = A.facCtrVersion;

	--*********************************************
	--**************  # C T R S  ******************
	--*********************************************
	--[10]Nos quedamos con los datos por contrato en la tabla: #CTR
	SELECT [ctrCod] = facCtrCod
	, [ctrVersion] = facCtrVersion
	, ctrTitDocIden
	, ctrTitTipDoc
	, ctrTitNom
	, ctrTitDir
	, ctrComunitario
	, ctrValorc1
	, [uso] = ctrUso
	, ctrfecreg
	, ctrbaja
	, ctrfecanu
	, _ctrfecanu
	, inmrefcatastral
	, inmDireccion
	, [contador] = IIF(ctrComunitario IS NULL AND ctrValorc1 > 1,  'C' , 'I')
	, [usuarios] = IIF(ctrComunitario IS NULL AND ctrValorc1 > 1, ctrValorc1, NULL)
	, [TitularAnt] = LEAD(ctrTitDocIden) OVER (PARTITION BY facCtrCod ORDER BY facCtrVersion ASC)
	, [TitularPrev] = LAG(ctrTitDocIden) OVER (PARTITION BY facCtrCod ORDER BY facCtrVersion ASC)
	, [indAlta] = CAST(NULL AS VARCHAR(1))
	, [indBaja] = CAST(NULL AS VARCHAR(1))
	INTO #CTRS
	FROM #AUX 
	WHERE Ctr_RN=1 AND --Un registro por cada version de contrato
	(facFechaRectif IS NULL OR Rectificada_TieneCanon=1);

	--*********************************************
	--[11]Los indicadores de alta y baja C, T: #CTRS.indAlta, #CTRS.indBaja
	WITH IND AS(
	SELECT ctrcod
	, ctrVersion
	, [indAlta] = CASE WHEN ctrVersion=1 AND ctrfecreg>=@facFechaD AND ctrfecreg<@facFechaH THEN 'C'
					   WHEN ctrTitDocIden<> [TitularPrev]	THEN 'T'
					   ELSE NULL END

	, [indBaja] = CASE WHEN ctrbaja=1 AND ctrfecanu>=@facFechaD AND ctrfecanu<@facFechaH THEN 'C'
					   WHEN ctrTitDocIden<> [TitularAnt] THEN 'T'
					   ELSE NULL END

	FROM #CTRS)

	UPDATE C SET C.indAlta = I.indAlta, C.indBaja = I.indBaja
	FROM #CTRS AS C
	INNER JOIN IND AS I
	ON I.ctrcod = C.ctrCod
	AND I.ctrVersion = C.ctrVersion;



	--*********************************************
	--*********** R E S U L T A D O ***************
	--*********************************************
	
	SELECT [contrato] = ctrCod
	,  [ctrVersion]= ctrVersion
	 , [Titular] = C.ctrTitDocIden
	 , [tipo]='C'
	 , [tipoIdent] = CASE WHEN C.ctrTitTipDoc IN ('0','1') THEN 'F'
						  WHEN C.ctrTitTipDoc IN ('2','4') THEN 'E'
						  ELSE 'O' END


	, [nomTit] = SUBSTRING(C.ctrTitNom,1,125)
	, [titDir] = IIF(C.ctrTitDir <> C.inmDireccion, SUBSTRING(C.ctrTitDir,1,250), NULL)
	, [titPrv] = '11'
	, [titPob] = '0337'
	, [contador]
	, [uso]
	, [usuarios]
	, [refCatastral] = IIF(LEN(TRIM(C.inmrefcatastral)) = 20, TRIM(C.inmrefcatastral), NULL)	
	, [dirAbastecida] = SUBSTRING(C.inmDireccion,1,250)
	, [periodicidad] = 3 
	, ctrfecreg
	, ctrfecanu
	, _ctrfecanu
	, ctrbaja
	, indAlta
	, indBaja
	--RN=1: Ultima versión de la combinacion contrato, titular: : De donde tomaremos los datos 
	, RN = ROW_NUMBER() OVER (PARTITION BY ctrcod, ctrTitDocIden ORDER BY  ctrVersion DESC)
	INTO #RESULT
	FROM #CTRS AS C;
	
	WITH REGC AS(
	--Ultima version del contrato
	SELECT R.contrato
	, R.ctrVersion
	, verAnterior = LAG(ctrVersion) OVER (PARTITION BY contrato ORDER BY ctrversion) 
	FROM #RESULT AS R
	WHERE RN=1
	
	), VERSIONES AS(
	--Enlazamos cada contrato con la ultima version por titular. 
	SELECT C.contrato
	, [versionC] = C.ctrVersion
	, C.verAnterior
	, R.ctrVersion 
	FROM REGC AS C
	LEFT JOIN #RESULT AS R
	ON C.contrato = R.contrato AND 
	(R.ctrVersion BETWEEN ISNULL(C.verAnterior, 0)+1 AND C.ctrVersion))
	
	SELECT R.contrato
	, R.ctrVersion
	--Los datos son los de la ultima version del titular
	, C.Titular
	, C.tipo
	, C.tipoIdent
	, C.nomTit
	, C.titDir
	, C.titPrv
	, C.titPob
	, C.contador
	, C.uso
	, C.usuarios
	, C.refCatastral
	, C.dirAbastecida
	, C.periodicidad
	, R.ctrfecreg
	, ctrfecanu = R._ctrfecanu
	, C.ctrbaja
	, R.indAlta
	, C.indBaja
	--, V.versionC
	, RN= ROW_NUMBER() OVER(ORDER BY R.contrato, R.ctrVersion)
	FROM #RESULT AS R
	INNER JOIN VERSIONES AS V
	ON  V.contrato = R.contrato
	AND V.ctrVersion = R.ctrVersion
	INNER JOIN #RESULT AS C
	ON C.contrato = V.contrato
	AND C.ctrVersion = V.versionC
	ORDER BY R.contrato, R.ctrVersion;
	
	IF @ctrcod IS NOT NULL
	BEGIN
		SELECT * FROM #AUX;
		SELECT * FROM #CTRS;
		SELECT * FROM #RESULT;
	END

END TRY

BEGIN CATCH
END CATCH


DROP TABLE IF EXISTS #AUX; 
DROP TABLE IF EXISTS #CTRS; 
DROP TABLE IF EXISTS #RESULT; 

GO