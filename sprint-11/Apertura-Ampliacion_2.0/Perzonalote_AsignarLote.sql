/*
DECLARE @zona VARCHAR(4) = 'AZ03';
DECLARE @periodo varchar(6) = '202104';
DECLARE @RESULT  INT;

EXEC  @RESULT = [dbo].[PerzonaLote_AsignarLote] @zona, @periodo

SELECT @RESULT
*/

CREATE PROCEDURE [dbo].[PerzonaLote_AsignarLote]
  @zona VARCHAR(4)
, @periodo VARCHAR(6)
AS

	SET NOCOUNT ON;
	
	BEGIN TRY

	DECLARE @AHORA DATETIME = dbo.GetAcuamaDate();
	DECLARE @RESULT INT = 1; 
	--**************
	--ERRORLOG: Inicio
	DECLARE @spName_ VARCHAR(100) = FORMATMESSAGE('%s.%s', OBJECT_SCHEMA_NAME(@@PROCID), OBJECT_NAME(@@PROCID));
	DECLARE @spParams_ VARCHAR(500) = FORMATMESSAGE('@zona=''%s'', @periodo=''%s''', @zona, @periodo);
	DECLARE @spMessage_ VARCHAR(4000) = FORMATMESSAGE('Inicio: %s', CONVERT(VARCHAR, @AHORA, 120)); 
	EXEC Trabajo.errorLog_Insert @spName_, @spParams_, @spMessage_;
	--**************

	--*************
	DECLARE @RUTAS AS dbo.tRutaLotes;	--RUTAS SIN LOTE
	DECLARE @LOTES AS dbo.tRutaLotes;	--RUTAS CON LOTE
	DECLARE @PZLOTE AS dbo.tRutaLotes;  --TOTAL POR LOTE
	
	--*************
	--PARAMETROS
	DECLARE @RUTACORTELOTE INT = 0;
	DECLARE @LECTURASLOTE AS INT = 0;
	DECLARE @factorZona AS DECIMAL(3, 2) = 1;
	DECLARE @facturasPorLote AS INT;

	--RUTACORTELOTE: Define el  campo Ruta para corte de lote
	SELECT @RUTACORTELOTE = P.pgsvalor 
	FROM dbo.parametros AS P
	WHERE P.pgsclave = 'RUTACORTELOTE';

	--LECTURASLOTE: Define el Nº mínimo de lecturas o facturas por lote
	SELECT @LECTURASLOTE = P.pgsvalor 
	FROM dbo.parametros AS P
	WHERE P.pgsclave = 'LECTURASLOTE';

	--@factorZona
	SELECT @factorZona = ISNULL(Z.zonfac,1)
	FROM dbo.zonas AS Z
	WHERE Z.zoncod = @zona  AND Z.zonfac<>0;

	--@facturasPorLote
	SET @facturasPorLote = @LECTURASLOTE/@factorZona;

	--*************
	--SELECT [@paramRUTACORTELOTE] = @paramRUTACORTELOTE
	--	 , [@paramLECTURASLOTE]=@paramLECTURASLOTE
	--	 , [@factorZona]=@factorZona
	--	 , [@facturasPorLote= @paramLECTURASLOTE / @factorZona]=@facturasPorLote;
	
	--*************
	--[100]Consultamos las facturas para determinar la ruta a la que están asociadas
	WITH FACS AS(
	--FACTURAS
	SELECT F.facCod
		 , F.facPerCod
		 , F.facCtrCod
		 , F.facVersion
		 , F.facCtrVersion
	FROM dbo.facturas AS F
	WHERE F.facZonCod = @zona
	AND F.facPerCod=@periodo
	AND F.facFechaRectif IS NULL

	), CTR AS(
	--FACTURAS/CONTRATOS
	SELECT F.*
	, C.ctrVersion
	, ctrRuta1 = ISNULL(C.ctrRuta1, 0)
	, ctrRuta2 = ISNULL(C.ctrRuta2, 0)
	, ctrRuta3 = ISNULL(C.ctrRuta3, 0)
	, ctrRuta4 = ISNULL(C.ctrRuta4, 0)
	, ctrRuta5 = ISNULL(C.ctrRuta5, 0)
	, ctrRuta6 = ISNULL(C.ctrRuta6, 0)
	, C.ctrEmplaza
	--RN=1: Ultima version del contrato
	, RN = ROW_NUMBER() OVER(PARTITION BY C.ctrCod ORDER BY C.CtrVersion DESC)
	FROM dbo.contratos AS C
	INNER JOIN FACS AS F
	ON F.facCtrCod= C.ctrCod

	), FACTURAS AS(
	--FACTURAS + ULTIMA VERSION DE CONTRATO
	SELECT C.*
	, emccod 
	, emcFac
	FROM CTR AS C
	LEFT JOIN dbo.emplaza AS E
	ON C.ctrEmplaza = E.emcCod
	WHERE RN=1

	), STR_RUTAS AS(
	--FACTURAS + RUTAS
	SELECT F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion
	, F.facCtrVersion
	, F.ctrVersion
	, F.ctrRuta1
	, F.ctrRuta2
	, F.ctrRuta3
	, F.ctrRuta4
	, F.ctrRuta5
	, F.ctrRuta6
	--****************
	--RN_RUTA: Orden deterministico según la ruta
	, RN_RUTA = ROW_NUMBER() OVER (ORDER BY F.ctrRuta1, F.ctrRuta1, F.ctrRuta2, F.ctrRuta3, F.ctrRuta4, F.ctrRuta5, F.ctrRuta6, F.facCtrCod)

	--****************
	--RUTACORTELOTE define el  campo Ruta para corte de lote. 
	--En el caso de Guadalajara , por ejemplo, el campo que marca el cambio de lote es ctrRuta3. 
	--Una vez efectuada la consulta para sacar las rutas se van grabando los datos al fichero y cuando se detecta que el valor de este campo cambia, 
	--se genera un nuevo lote.
	, RutaLote = CONCAT( IIF(@RUTACORTELOTE >=1, RIGHT(REPLICATE('0', 10) + F.ctrRuta1, 10), '')
					   , IIF(@RUTACORTELOTE >=2, RIGHT(REPLICATE('0', 10) + F.ctrRuta2, 10), '')
					   , IIF(@RUTACORTELOTE >=3, RIGHT(REPLICATE('0', 10) + F.ctrRuta3, 10), '')
					   , IIF(@RUTACORTELOTE >=4, RIGHT(REPLICATE('0', 10) + F.ctrRuta4, 10), '')
					   , IIF(@RUTACORTELOTE >=5, RIGHT(REPLICATE('0', 10) + F.ctrRuta5, 10), '')
					   , IIF(@RUTACORTELOTE >=6, RIGHT(REPLICATE('0', 10) + F.ctrRuta6, 10), ''))

	--****************
	FROM FACTURAS AS F

	)

	SELECT * 
	--RUTA: Agrupacion por RutaLote
	, RUTA = DENSE_RANK() OVER (ORDER BY RutaLote)
	--CN_RUTA: Facturas por Agrupacion por RutaLote
	, CN_RUTA =  COUNT(RN_RUTA) OVER (PARTITION BY RutaLote)
	INTO #RUTAS
	FROM STR_RUTAS;

	--*************
	--Tenemos las rutas identificadas, las distribuimos por lotes aplicando el minimo segun LECTURASLOTE
	--LECTURASLOTE  define el Nº mínimo de lecturas o facturas por lote. 
	--Si cuando procesamos, el número de lecturas en un lote es inferior al valor de este dato, 
	--se continúa hasta el siguiente valor distinto de RUTACORTELOTE. 

	--*************
	--[101]RUTAS y numero de facturas en la ruta
	INSERT INTO @RUTAS
	SELECT DISTINCT RUTA, CN_RUTA, NULL FROM #RUTAS;
	
	--*************
	--[102]LOTE al que se envía cada RUTA
	INSERT INTO @LOTES
	SELECT * FROM dbo.fAsignarLoteRuta(@RUTAS, @LECTURASLOTE);

	--*************
	--[103]LOTE y el total de facturas por lote
	INSERT INTO @PZLOTE
	SELECT NULL, QTY = SUM(QTY), LOTE FROM @LOTES GROUP BY LOTE;

	BEGIN TRAN;
		--*************
		--[901]UPDATE facturas.facLote
		--SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, F.facLote, L.LOTE, L.QTY
		UPDATE F SET F.facLote=L.LOTE
		FROM #RUTAS AS R
		INNER JOIN @LOTES AS L
		ON R.RUTA = L.RUTA
		INNER JOIN dbo.facturas AS F
		ON  F.facCod = R.facCod
		AND F.facPerCod = R.facPerCod
		AND F.facCtrCod = R.facCtrCod
		AND F.facVersion = R.facVersion
		AND (F.facLote IS NULL OR F.facLote<>L.LOTE);

		--*************
		--[901]UPDATE perzonalote.przlnreg
		--SELECT P.przlcodzon, P.przlcodper, P.przllote, przlnreg, przlnreg = ISNULL(PP.QTY, 0)
		UPDATE P SET przlnreg = ISNULL(PP.QTY, 0)
		FROM dbo.perzonalote AS P
		LEFT JOIN @PZLOTE AS PP
		ON P.przllote = PP.LOTE
		WHERE P.przlcodzon = @zona
		AND P.przlcodper = @periodo;

		--[902]INSERT perzonalote
		INSERT INTO dbo.perzonalote (przlcodzon, przlcodper, przllote, przlNReg)
		SELECT @zona, @periodo, PP.LOTE, PP.QTY
		FROM @PZLOTE AS PP
		LEFT JOIN dbo.perzonalote AS P 
		ON P.przllote = PP.LOTE
		AND P.przlcodzon = @zona  
		AND P.przlcodper = @periodo
		WHERE P.przllote IS NULL;
	COMMIT TRAN
	SET @RESULT = 0;

	END TRY

	BEGIN CATCH
		SELECT  @spMessage_ = ERROR_MESSAGE();
		 
		IF (@@TRANCOUNT > 0) 
		ROLLBACK TRANSACTION;
	
		SET @spMessage_ = CONCAT('Error: ' , @spMessage_ );
		EXEC Trabajo.errorLog_Insert @spName_, @spParams_, @spMessage_;
	END CATCH

	IF OBJECT_ID('tempdb..#RUTAS') IS NOT NULL DROP TABLE #RUTAS;   

	--******************
	--[99]TRAZA
	SET @spMessage_ = FORMATMESSAGE('Tiempo Ejecución: %s', FORMAT(DATEDIFF(MICROSECOND, @AHORA, dbo.GetAcuamaDate()), 'N0', 'es-ES')); 
	EXEC Trabajo.errorLog_Insert @spName_, @spParams_, @spMessage_;
	--******************
	
	RETURN @RESULT;
GO


