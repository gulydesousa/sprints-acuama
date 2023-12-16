--EXEC Apremios_ObtenerCoincidenciasOds

CREATE PROCEDURE [dbo].[Apremios_ObtenerCoincidenciasOds]
AS
	DECLARE @COINCIDENCIAS AS TABLE(
	ID INT,
	---------------
	ctrTitNom VARCHAR(100), 
	facNumero VARCHAR(20), 
	facCtrCod INT, 
	facPerCod VARCHAR(6), 
	facVersion SMALLINT, 
	facCod SMALLINT,
	aprCobradoAcuama BIT, 
	aprFechaCobradoAcuama DATETIME, 
	NOM VARCHAR(100), 
	NOM2 VARCHAR(100), 
	ANIO INT, 
	---------------
	fctFacturado MONEY, 
	fctCobrado MONEY, 
	fctDeuda MONEY, 
	XNOMBRE VARCHAR(100),
	CN INT);

	--*****************************
	--Explotación actual
	DECLARE @explo AS INT;
	SELECT @explo = pgsvalor FROM parametros WHERE pgsclave='EXPLOTACION_CODIGO';

	DECLARE @strExplo AS VARCHAR(4)= @explo * 100;

	--*****************************
	--#APREMIOS: Facturas de apremios: Columnas auxiliares para poder comparar
	SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, F.facNumero,  F.facFecha
	, C.ctrTitNom
	, A.aprFechaCobradoAcuama
	, A.aprCobradoAcuama
	, T.fctFacturado
	, T.fctCobrado
	, T.fctDeuda
	--------------------------------
	--ANIO: Ejercicio
	, ANIO=YEAR(F.facFecha)
	--NUMFAC: Si los dos primeros caracteres coinciden con el año, lo quitamos.
	, NUMFAC =  IIF(LEFT(F.facNumero, 2) = RIGHT(YEAR(F.facFecha), 2), SUBSTRING(F.facNumero, 3, LEN(F.facNumero)), F.facNumero)	
	--NOM: Quitamos la coma, espacios dobles y recortamos a 46 caracteres
	, NOM = LEFT(RTRIM(LTRIM(REPLACE(REPLACE(C.ctrTitNom, ',', ' '), '  ', ' '))), 46)
	--NOM2: Si el nombre es un caso especial
	, NOM2 = CASE C.ctrTitNom 
				WHEN 'BANKIA SA' THEN 'CAIXABANK SA'
				ELSE ''END
	INTO #APREMIOS
	FROM dbo.facturas AS F
	INNER JOIN dbo.apremios AS A
	ON F.facCod  = A.aprFacCod
	AND F.facPerCod = A.aprFacPerCod
	AND F.facCtrCod = A.aprFacCtrCod
	AND F.facVersion = A.aprFacVersion
	INNER JOIN dbo.contratos AS C
	ON C.ctrcod = F.facCtrCod
	AND C.ctrversion = F.facCtrVersion
	INNER JOIN dbo.facTotales AS T
	ON T.fctCod = F.facCod
	AND T.fctCtrCod = F.facCtrCod
	AND T.fctPerCod = F.facPerCod
	AND T.fctVersion = F.facVersion;
		
	--*****************************
	--#APREMIOS.NUMFAC: Si el numero de la explotacion coincide con los primero caracteres de la factura
	UPDATE A SET A.NUMFAC = SUBSTRING(NUMFAC, LEN(@strExplo)+1, LEN(NUMFAC))
	FROM #APREMIOS AS A
	WHERE LEFT(A.NUMFAC, LEN(@strExplo)) = @strExplo;

	--*****************************
	--Coincidencias por numeros de factura y ejercicio
	--*****************************
	INSERT INTO @COINCIDENCIAS
	SELECT X.ID
	, A.ctrTitNom
	, A.facNumero
	, A.facCtrCod
	, A.facPerCod
	, A.facVersion
	, A.facCod
	, A.aprCobradoAcuama
	, A.aprFechaCobradoAcuama	
	, A.NOM
	, A.NOM2
	, A.ANIO
	, fctFacturado
	, fctCobrado
	, fctDeuda
	, XNOMBRE = REPLACE(X.NOMBRE, '  ', ' ')
	--CN>1: Hay mas de una coincidencia
	, CN = COUNT(ID) OVER(PARTITION BY ID)
	FROM Trabajo.apremiosODS AS X
	INNER JOIN #APREMIOS AS A
	ON X.EJERCICIOS = A.ANIO AND --Coincidencia por Ejercicio
	(X.RECIBO IN (A.facNumero, @strExplo + A.NUMFAC, RIGHT(A.ANIO, 1) + @strExplo + A.NUMFAC, A.NUMFAC));

	--*****************************
	--Como es posible que un numero de "RECIBO" coincida con mas de una factura de acuama
	--Resolvemos el empate mirando el nombre del titular
	--*****************************
	DELETE FROM @COINCIDENCIAS WHERE CN>1 AND XNOMBRE NOT IN(NOM, NOM2);
	
	--7.626
	DECLARE @RESULT AS dbo.tApremios_ObtenerCoincidenciasOds;
	INSERT INTO @RESULT
	SELECT X.*
	, C.ctrTitNom
	, C.facNumero
	, C.facCtrCod
	, C.facPerCod
	, C.facVersion
	, C.facCod
	, C.aprCobradoAcuama
	, C.aprFechaCobradoAcuama	
	, C.NOM
	, C.NOM2
	, C.ANIO
	, C.fctFacturado
	, C.fctCobrado
	, C.fctDeuda
	, XNOMBRE = REPLACE(X.NOMBRE, '  ', ' ')
	FROM Trabajo.apremiosODS AS X
	LEFT JOIN @COINCIDENCIAS AS C 
	ON X.ID = C.ID;

	SELECT * FROM @RESULT;

	--Borramos tablas temporales
	DROP TABLE IF EXISTS #APREMIOS;
	
GO

