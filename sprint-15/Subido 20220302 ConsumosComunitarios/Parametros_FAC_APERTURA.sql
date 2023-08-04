ALTER PROCEDURE Trabajo.Parametros_FAC_APERTURA(@version VARCHAR(25))
AS
	SET NOCOUNT ON;
	
	DECLARE @valorON BIT = IIF(@version>='2.1.0', 1, 0);
	DECLARE @OPERATION VARCHAR(25) = IIF(@valorON=1, 'ENABLE', 'DISABLE');
	DECLARE @FACCOUNT INT = (SELECT COUNT(facCod) FROM dbo.facturas);
	DECLARE @ROWS INT = 0;
	DECLARE @CLAVE VARCHAR(25) = 'FAC_APERTURA'; 
	DECLARE @VALOR VARCHAR(25) = ISNULL((SELECT pgsValor FROM dbo.parametros WHERE pgsclave = @CLAVE), '1.0.0') ; 


	DECLARE @SQL_TRIGGERS AS VARCHAR(MAX);

	SET @SQL_TRIGGERS = 'ABLE TRIGGER trgCoblin_FacTotalesUpdate ON coblin;
				ABLE TRIGGER trgCobros_FacTotalesUpdate ON cobros;
				ABLE TRIGGER trgFacLin_FacTotalesUpdate ON faclin;
				ABLE TRIGGER trgFacturas_FacTotalesDelete ON facturas;
				ABLE TRIGGER trgFacturas_FacTotalesInsert ON facturas;
				ABLE TRIGGER trgFacTotalesTrab_FacTotalesUpdate ON FacTotalesTrab;
				'

	SET @SQL_TRIGGERS = REPLACE(@SQL_TRIGGERS, 'ABLE', @OPERATION);


	--[01]Actualizar el parametro
	DELETE FROM dbo.parametros WHERE pgsclave = @CLAVE;

	INSERT INTO dbo.parametros
	VALUES(@CLAVE
	, '1.0.0; '+ CHAR(10)+
	  '2.0.0; '+ CHAR(10)+   
	  '2.0.1; '+ CHAR(10)+  
	  '2.1.0; '+ CHAR(10)+
	  '2.1.1; ' + CHAR(10)+
	  '2.1.2. Para conocer detalles de cada versión consulte la tabla Trabajo.FAC_APERTURA'
	, 2, @version, 0, 1, 0);


	--[02]Actualizar facTotales	
	IF (@valorON=1 AND @VALOR<'2.1.0')
	BEGIN
		--Borramos las excepciones y los totales
		TRUNCATE TABLE dbo.facTotalesTrab;
		TRUNCATE TABLE dbo.facTotales;
		
		--Actualizamos todo
		INSERT INTO dbo.facTotales(fctCod, fctCtrCod, fctPerCod, fctVersion, fctActiva
							 , fctBase, fctImpuestos, fctTotal
							 , fctFacturado, fctCobrado, fctEntregasCta
							 , fctTipoImp1, fctBaseTipoImp1
							 , fctTipoImp2, fctBaseTipoImp2
							 , fctTipoImp3, fctBaseTipoImp3
							 , fctTipoImp4, fctBaseTipoImp4
							 , fctTipoImp5, fctBaseTipoImp5
							 , fctTipoImp6, fctBaseTipoImp6)
		EXEC FacTotales_Select;

		SELECT @ROWS= @@ROWCOUNT;
	END

	--[03]Cambiar el estado de los triggers
	EXEC (@SQL_TRIGGERS);

	--[04]Actualizar la tabla de numeración de los cobros (cobNum)
	--INSERTAMOS Si falta alguna combinación
	INSERT INTO dbo.cobrosNum 
	SELECT V.*
	FROM dbo.vCobrosNumerador AS V
	LEFT JOIN dbo.cobrosNum AS C
	ON  C.cbnScd = V.scdcod 
	AND C.cbnPpag = V.ppagCod
	WHERE C.cbnNumero IS NULL;

	--ACTUALIZAMOS si hay alguno no sincronizado
	UPDATE C SET C.cbnNumero=V.cbnNumero
	FROM dbo.vCobrosNumerador AS V
	LEFT JOIN dbo.cobrosNum AS C
	ON  C.cbnScd = V.scdcod 
	AND C.cbnPpag = V.ppagCod
	WHERE V.cbnNumero <> C.cbnNumero;

	--**************************
	--[99]INFORMACION RESULTADO
	SELECT Clave = P.pgsclave
	, ValorAnterior = @VALOR
	--, VersiónAnterior = (SELECT fcaDescripcion FROM  Trabajo.FAC_APERTURA WHERE fcaVersion= @VALOR)
	, ValorActual = P.pgsValor
	, VersiónActual = (SELECT fcaDescripcion FROM  Trabajo.FAC_APERTURA WHERE fcaVersion= P.pgsValor)
	, FacRows = @FACCOUNT
	, FacUpdated = @ROWS
	, [ERRORLOG]		 = P3.pgsvalor
	FROM dbo.parametros AS P
	LEFT JOIN dbo.parametros AS P3
	ON P3.pgsclave = 'ERRORLOG'
	WHERE P.pgsclave = @CLAVE;

GO
