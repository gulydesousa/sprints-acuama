/*
DECLARE @periodoD NVARCHAR(6) = '202101'
, @xmlUsoCodArray NVARCHAR(4000)
, @periodoH NVARCHAR(6)='202101'
, @versionD NVARCHAR(4000)
, @versionH NVARCHAR(4000)
, @zonaD NVARCHAR(4000)
, @zonaH NVARCHAR(4000)
, @fechaD NVARCHAR(4000)
, @fechaH NVARCHAR(4000)
, @contratoD NVARCHAR(4000)
, @contratoH NVARCHAR(4000)
, @verTodas BIT = 0
, @preFactura BIT = 0
, @orden NVARCHAR(5)= 'calle'
, @consuMin NVARCHAR(4000)
, @consuMax NVARCHAR(4000)
, @impoMin NVARCHAR(4000)
, @impoMax NVARCHAR(4000)
, @precision TINYINT =4

EXEC ReportingServices.RelacionFacturasPadronDetalle_BIAR
  @periodoD, @periodoH
, @xmlUsoCodArray
, @versionD, @versionH
, @zonaD, @zonaH
, @fechaD, @fechaH
, @contratoD, @contratoH
, @verTodas
, @preFactura
, @orden
, @consuMin, @consuMax
, @impoMin, @impoMax
, @precision 
*/


ALTER PROCEDURE [ReportingServices].[RelacionFacturasPadronDetalle_BIAR]
  @periodoD NVARCHAR(6)
, @periodoH NVARCHAR(6)
, @xmlUsoCodArray NVARCHAR(4000)
, @versionD NVARCHAR(4000)
, @versionH NVARCHAR(4000)
, @zonaD NVARCHAR(4000)
, @zonaH NVARCHAR(4000)
, @fechaD NVARCHAR(4000)
, @fechaH NVARCHAR(4000)
, @contratoD NVARCHAR(4000)
, @contratoH NVARCHAR(4000)
, @verTodas BIT
, @preFactura BIT
, @orden NVARCHAR(5)
, @consuMin NVARCHAR(4000)
, @consuMax NVARCHAR(4000)
, @impoMin NVARCHAR(4000)
, @impoMax NVARCHAR(4000)
, @precision TINYINT = 4

AS

DECLARE @periodo as varchar(6)
DECLARE @contrato as int
DECLARE @tipoLectura VARCHAR(2)
DECLARE @incidenciaLectura VARCHAR(35)
DECLARE @numeroFactura VARCHAR(20)
DECLARE @unidadesAgua DECIMAL(12,2)
DECLARE @serieFactura SMALLINT
DECLARE @lecturaAnterior INT
DECLARE @lecturaActual INT
DECLARE @zona VARCHAR(4)
DECLARE @codigo smallint
DECLARE @diametro as int
DECLARE @cliente as varchar(60)
DECLARE @documento as varchar(20)
DECLARE @direccion as varchar(200)
DECLARE @consumo as int
DECLARE @consumoReal as int
DECLARE @version as int

DECLARE @bloque1 as int
DECLARE @bloque2 as int
DECLARE @impBloque1 as money
DECLARE @impBloque2 as money
DECLARE @cuotaSrvAgua as money
DECLARE @SrvAgua as money
DECLARE @impIVASrvAgua as money
DECLARE @SrvRSU as money
DECLARE @impIVASrvRSU as money
DECLARE @SrvDep as money
DECLARE @impIVASrvDep as money
DECLARE @SrvOtros as money
DECLARE @impIVASrvOtros as money
DECLARE @scdImpNombre varchar(50)
--*****************************
--0: CUOTA SERV. AGUA
DECLARE @SrvAGUACUOTA AS MONEY
DECLARE @impIVASrvAGUACUOTA AS MONEY
--7: ALCANTARILLADO
DECLARE @SrvALC AS MONEY
DECLARE @impIVASrvALC AS MONEY
--*****************************
DECLARE @fcltrfsvcod as decimal(12,4) 
DECLARE @fclUnidades as decimal(12,2) 
DECLARE @fclPrecio as money
DECLARE @fclUnidades1 as decimal(12,2) 
DECLARE @fclPrecio1 as decimal(10,6) 
DECLARE @fclUnidades2 as decimal(12,2) 
DECLARE @fclPrecio2 as decimal(10,6) 
DECLARE @fclEscala1 as int
DECLARE @fclEscala2 as int

DECLARE @fclbase as money 
DECLARE @fclImpImpuesto as money 
DECLARE @fcltotal as money 

DECLARE @servicioAgua INT = ISNULL((SELECT ISNULL(pgsValor,1) FROM parametros WHERE pgsClave='SERVICIO_AGUA'),1)

IF @xmlUsoCodArray IS NOT NULL BEGIN
	--Creamos una tabla en memoria donde se van a insertar todos los valores
	DECLARE @usosExcluidos AS TABLE(usoCodigo INT) 
	--Leemos los parámetros del XML
	DECLARE @idoc INT
	EXEC sp_xml_preparedocument @idoc OUTPUT, @xmlUsoCodArray
	--Insertamos en tabla temporal
	INSERT INTO @usosExcluidos(usoCodigo)
	SELECT value
	FROM   OPENXML (@idoc, '/usoCodigo_List/usoCodigo', 2) WITH (value INT)
	--Liberamos memoria
	EXEC  sp_xml_removedocument @idoc
END

DECLARE @padron AS TABLE (
		contrato int,
		zona VARCHAR(4),
		serieFactura SMALLINT,
		numeroFactura VARCHAR(20),
		unidadesAgua DECIMAL(12,2),
		periodo varchar(6),
		documento varchar(20),
		cliente varchar(60),
		direccion varchar(200),
		diametro int,
		lecturaAnterior INT,
		lecturaActual INT,
		incidenciaLectura VARCHAR(35),
		tipoLectura VARCHAR(2),
		consumoRegistrado int,
		consumo int,
		bloque1 int,
		bloque2 int,
		impBloque1 money,
		impBloque2 money,
		cuotaSrvAgua money,
		SrvAgua money,
		impIVASrvAgua money,
		SrvDep money,
		impIVASrvDep money,
		SrvRSU money,
		impIVASrvRSU money,
		SrvOtros money,
		impIVASrvOtros money,
		scdImpNombre varchar(50)
		--0:CUOTA SERV. AGUA
		, SrvAGUACUOTA MONEY
		, impIVASrvAGUACUOTA MONEY
		--7:ALCANTARILLADO
		, SrvALC MONEY
		, impIVASrvALC MONEY);



	DECLARE cPadron CURSOR FOR
	select [facCod], [facCtrCod], facZonCod, [facversion], [facpercod], ISNULL(ctrPagNom, ctrTitNom), [inmdireccion], ISNULL(ctrPagDocIden, ctrTitDocIden),
	[facconsumofactura],
	CONVERT(INT,(SELECT TOP 1 (CASE WHEN ISNULL(fclPrecio,0) > 0 AND ISNULL(fclPrecio1,0) <= 0 THEN 
			ISNULL(fclEscala1,0)
			ELSE 
			ISNULL(fclUnidades1,0) 
		       END) +
	        ISNULL(fclUnidades2,0) + 
	        ISNULL(fclUnidades3,0) + 
			ISNULL(fclUnidades4,0) + 
			ISNULL(fclUnidades5,0) + 
			ISNULL(fclUnidades6,0) + 
			ISNULL(fclUnidades7,0) +
			ISNULL(fclUnidades8,0) + 
			ISNULL(fclUnidades9,0) 
			FROM facLin WHERE 
				fclFacCtrCod = facCtrCod AND 
				fclFacPerCod = facPerCod AND 
				fclFacVersion = facVersion AND 
				fclFacCod = facCod)),
	(SELECT conDiametro 
		FROM fContratos_ContadoresInstalados(NULL) 
		WHERE ctcCtr = facCtrCod 
	) as conDiametro,
	scdImpNombre,
	
	facLecAnt, facLecAct,
	inlMc, inlDes,
	facSerCod, facNumero,
	(SELECT 
		SUM(CASE WHEN fclTrfSvCod = @servicioAgua THEN fclUnidades ELSE 0 END)
	FROM facLin WHERE 
		fclFacCtrCod = facCtrCod AND 
		fclFacPerCod = facPerCod AND 
		fclFacVersion = facVersion AND 
		fclFacCod = facCod) AS unidadesAgua
	
from facturas 
   left join sociedades on scdcod=ISNULL(facserscdcod,ISNULL((select pgsvalor from parametros where pgsclave='SOCIEDAD_POR_DEFECTO'),1))
   inner join contratos on ctrcod = facctrcod and ctrversion = facctrversion
   inner join inmuebles on inmcod = ctrinmcod
   LEFT JOIN fFacturas_TotalFacturado(NULL, 0, NULL) ON ftfFacCod=facCod AND ftfFacPerCod=facPerCod  AND ftfFacCtrCod=facCtrCod AND ftfFacVersion=facVersion
   LEFT JOIN incilec AS incidenciaLectura ON inlCod = facLecInlCod
where (facPerCod >= @periodoD OR @periodoD IS NULL)
and (facPerCod <= @periodoH OR @periodoH IS NULL)
and (facVersion >= @versionD  OR @versionD IS NULL)
and (facVersion <= @versionH OR @versionH IS NULL)
and (facZonCod >= @zonaD  OR @zonaD IS NULL)
and (facZonCod <= @zonaH OR @zonaH IS NULL)
and (facFecha>= @fechaD OR @fechaD IS NULL)
and (facFecha<= @fechaH OR @fechaH IS NULL)
and (facCtrCod>= @contratoD OR @contratoD IS NULL)
and (facCtrCod<= @contratoH OR @contratoH IS NULL)
and (facFechaRectif IS NULL OR (facFechaRectif >@fechaH) OR @verTodas=1)   -- verTodas junto con las rectificadas
and ((facNumero IS NOT NULL and @preFactura=0) OR  (@preFactura=1) )-- Si @preFactura es 0 entonces saca las facturas definitivas y si es 1 saca todas junto con las preFACTURAS
and (@consuMin IS NULL OR @consuMin<=facConsumoFactura)
and (@consuMax IS NULL OR @consuMax>=facConsumoFactura)
and (ISNULL(ftfImporte, 0) >= @impoMin or @impoMin is null)
and (ISNULL(ftfImporte, 0) <= @impoMax or @impoMax is null)
AND NOT EXISTS(SELECT u.usoCod
		  FROM usos u 
		  INNER JOIN @usosExcluidos ON usoCodigo = u.usocod
		  WHERE u.usocod = ctrUsoCod
               )
	OPEN cPadron
	FETCH NEXT FROM cPadron
	INTO @codigo, @contrato, @zona, @version, @periodo, @cliente, @direccion, @documento, @consumoReal, @consumo, @diametro, @scdImpNombre,
		 @lecturaAnterior, @lecturaActual, @tipoLectura, @incidenciaLectura, @serieFactura, @numeroFactura, @unidadesAgua

	WHILE @@FETCH_STATUS = 0
	BEGIN

		SET @bloque1 = 0
		SET @bloque2 = 0
		SET @impBloque1 = 0
		SET @impBloque2 = 0
		SET @cuotaSrvAgua = 0
		SET @SrvAgua = 0
		SET @impIVASrvAgua = 0
		SET @SrvDep = 0
		SET @impIVASrvDep = 0
		SET @SrvRSU = 0
		SET @impIVASrvRSU = 0
		SET @SrvOtros = 0
		SET @impIVASrvOtros = 0
		--0: CUOTA SERV. AGUA 
		SET @SrvAGUACUOTA=0; 
		SET @impIVASrvAGUACUOTA = 0;
		--7: ALCANTARILLADO 
		SET @SrvALC=0; 
		SET @impIVASrvALC = 0;
		--*********************
		
		DECLARE cLineas CURSOR FOR
		
		SELECT fcltrfsvcod, fclUnidades, fclPrecio, 
		fclUnidades1, fclPrecio1, fclUnidades2, fclPrecio2, fclEscala1, fclEscala2,
		fclbase, fclImpImpuesto, fcltotal 
		FROM dbo.faclin
		WHERE fclFacCod = @codigo and fclfacpercod = @periodo and fclfacctrcod = @contrato and fclfacversion = @version
		AND((fclFecLiq>=@fechaH) OR (fclFecLiq IS NULL AND fclUsrLiq IS NULL))	
		ORDER BY fcltrfsvcod;

		OPEN cLineas
		FETCH NEXT FROM cLineas
		INTO @fcltrfsvcod, @fclUnidades, @fclPrecio, 
			@fclUnidades1, @fclPrecio1, @fclUnidades2, @fclPrecio2, @fclEscala1, @fclEscala2,
			@fclbase, @fclImpImpuesto, @fcltotal 

		WHILE @@FETCH_STATUS = 0
		BEGIN
			--1: CONSUMO DE AGUA
			IF @fcltrfsvcod = 1 
			BEGIN
				SET @bloque1 = @bloque1 + CASE WHEN @fclPrecio1 <> 0 OR (@fclPrecio = 0 AND @fclPrecio1 = 0) THEN @fclUnidades1 ELSE @fclEscala1 END
				SET @bloque2 = @bloque2 + @fclUnidades2
				SET @cuotaSrvAgua = @cuotaSrvAgua + ROUND(@fclUnidades * @fclPrecio, @precision)
				SET @impBloque1 = CASE WHEN @fclPrecio1 <> 0 OR (@fclPrecio = 0 AND @fclPrecio1 = 0) THEN @impBloque1 + ROUND(@fclUnidades1 * @fclPrecio1, @precision) ELSE @cuotaSrvAgua END
				SET @impBloque2 = @impBloque2 + ROUND(@fclUnidades2 * @fclPrecio2, @precision)
				SET @SrvAgua = @SrvAgua + @fclbase
				SET @impIVASrvAgua = @impIVASrvAgua + @fclImpImpuesto
			END 
			
			--3:MMTO. CONTADOR
			ELSE IF @fcltrfsvcod = 3 
			BEGIN
				SET @SrvRSU = @SrvRSU + @fclbase
				SET @impIVASrvRSU = @impIVASrvRSU + @fclImpImpuesto				
			END
			
			--2: CANON SANEO
			ELSE IF @fcltrfsvcod = 2 
			BEGIN
				SET @SrvDep = @SrvDep + @fclbase
				SET @impIVASrvDep = @impIVASrvDep + @fclImpImpuesto
			END
			
			--0: CUOTA SERV. AGUA
			ELSE IF @fcltrfsvcod = 0
			BEGIN
				SET @SrvAGUACUOTA = @SrvAGUACUOTA + @fclbase;
				SET @impIVASrvAGUACUOTA = @impIVASrvAGUACUOTA + @fclImpImpuesto;
			END
			--7: ALCANTARILLADO
			ELSE IF @fcltrfsvcod = 7
			BEGIN
				SET @SrvALC = @SrvALC + @fclbase;
				SET @impIVASrvALC = @impIVASrvALC + @fclImpImpuesto;
			END
			--*********************
			
			ELSE 
			BEGIN
				SET @SrvOtros = @SrvOtros + @fclbase
				SET @impIVASrvOtros = @impIVASrvOtros + @fclImpImpuesto
			END
			
			FETCH NEXT FROM cLineas
			INTO @fcltrfsvcod, @fclUnidades, @fclPrecio, 
				@fclUnidades1, @fclPrecio1, @fclUnidades2, @fclPrecio2, @fclEscala1, @fclEscala2,
				@fclbase, @fclImpImpuesto, @fcltotal 
		END --WHILE
		
		CLOSE cLineas
		DEALLOCATE cLineas
	
		INSERT INTO @padron 
				(contrato, zona, periodo, documento, cliente, direccion, diametro, consumo, consumoRegistrado,
				--1: CONSUMO DE AGUA
				 bloque1, bloque2, impBloque1, impBloque2, 
				 cuotaSrvAgua, SrvAgua, impIVASrvAgua,
				 --2: CANON SANEO
				 SrvDep, impIVASrvDep,
				 --3:MMTO. CONTADOR
				 SrvRSU, impIVASrvRSU,
				 --0: CUOTA SERV. AGUA
				 SrvAGUACUOTA, impIVASrvAGUACUOTA,
				--7: ALCANTARILLADO
				 SrvALC, impIVASrvALC,
				 --****************
				 SrvOtros, impIVASrvOtros, scdImpNombre,
				 lecturaAnterior, lecturaActual, tipoLectura, incidenciaLectura, serieFactura, numeroFactura, unidadesAgua)
		
		VALUES
			(@contrato, @zona, @periodo, @documento, @cliente, @direccion, @diametro, @consumo, @consumoReal,
			 @bloque1, @bloque2, @impBloque1, @impBloque2, 
			 @cuotaSrvAgua, @SrvAgua, @impIVASrvAgua,
			 @SrvDep, @impIVASrvDep,
			 @SrvRSU, @impIVASrvRSU,
			 --0: CUOTA SERV. AGUA
			 @SrvAGUACUOTA, @impIVASrvAGUACUOTA,
			 --7: ALCANTARILLADO
			 @SrvALC, @impIVASrvALC,
			 --****************
			 @SrvOtros, @impIVASrvOtros,@scdImpNombre,
			 @lecturaAnterior, @lecturaActual, @tipoLectura, @incidenciaLectura, @serieFactura, @numeroFactura, @unidadesAgua)

		FETCH NEXT FROM cPadron
		INTO @codigo, @contrato, @zona, @version, @periodo, @cliente, @direccion, @documento, @consumoReal, @consumo, @diametro, @scdImpNombre,
			 @lecturaAnterior, @lecturaActual, @tipoLectura, @incidenciaLectura, @serieFactura, @numeroFactura, @unidadesAgua
	END
	CLOSE cPadron
	DEALLOCATE cPadron

	--*********
	--RESULTADO
	SELECT P.* 
	FROM @padron AS P
	ORDER BY 
	  CASE @orden WHEN 'calle' THEN direccion END
	, CASE @orden WHEN 'titular' THEN cliente END
	, CASE @orden WHEN 'contratoCodigo' THEN contrato END
	, periodo;
	--*********
GO


