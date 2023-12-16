/*
DECLARE @xmlUsoCodArray NVARCHAR(4000)
, @periodoD NVARCHAR(6)
, @periodoH NVARCHAR(6)
, @versionD NVARCHAR(4000)
, @versionH NVARCHAR(4000)
, @zonaD NVARCHAR(2)=NULL
, @zonaH NVARCHAR(2)=NULL
, @fechaD NVARCHAR(4000)='20220101'
, @fechaH NVARCHAR(4000)='20221201'
, @contratoD NVARCHAR(4000)
, @contratoH NVARCHAR(4000)
, @verTodas BIT=0
, @preFactura BIT=0
, @consuMin NVARCHAR(4000)
, @consuMax NVARCHAR(4000)
, @impoMin NVARCHAR(4000)
, @impoMax NVARCHAR(4000)
, @orden NVARCHAR(5)='calle'
, @precision TINYINT=4


EXEC ReportingServices.RelacionFacturasPadronDetalle_AVG 
 @xmlUsoCodArray 
, @periodoD, @periodoH
, @versionD, @versionH
, @zonaD, @zonaH
, @fechaD, @fechaH
, @contratoD, @contratoH
, @verTodas
, @preFactura
, @consuMin, @consuMax
, @impoMin, @impoMax
, @orden
*/


CREATE PROCEDURE [ReportingServices].[RelacionFacturasPadronDetalle_AVG]
  @xmlUsoCodArray NVARCHAR(4000)
, @periodoD NVARCHAR(6)
, @periodoH NVARCHAR(6)
, @versionD NVARCHAR(4000)
, @versionH NVARCHAR(4000)
, @zonaD NVARCHAR(2)
, @zonaH NVARCHAR(2)
, @fechaD NVARCHAR(4000)
, @fechaH NVARCHAR(4000)
, @contratoD NVARCHAR(4000)
, @contratoH NVARCHAR(4000)
, @verTodas BIT
, @preFactura BIT
, @consuMin NVARCHAR(4000)
, @consuMax NVARCHAR(4000)
, @impoMin NVARCHAR(4000)
, @impoMax NVARCHAR(4000)
, @orden  NVARCHAR(5)
, @precision TINYINT=4

AS

SET NOCOUNT ON;
DECLARE @periodo as varchar(6)
DECLARE @contrato as int
DECLARE @tipoLectura VARCHAR(2)
DECLARE @uso VARCHAR(40)
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
DECLARE @bloque3 as int
DECLARE @bloque4 as int
DECLARE @impBloque1 as money
DECLARE @impBloque2 as money
DECLARE @impBloque3 as money
DECLARE @impBloque4 as money

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

DECLARE @fcltrfsvcod as decimal(12,4) 
DECLARE @fclUnidades as decimal(12,2) 

DECLARE @fclUnidades1 as decimal(12,2) 
DECLARE @fclUnidades2 as decimal(12,2) 
DECLARE @fclUnidades3 as decimal(12,2) 
DECLARE @fclUnidades4 as decimal(12,2) 
DECLARE @fclPrecio1 as decimal(10,6) 
DECLARE @fclPrecio as money
DECLARE @fclPrecio2 as decimal(10,6) 
DECLARE @fclPrecio3 as decimal(10,6) 
DECLARE @fclPrecio4 as decimal(10,6) 
DECLARE @fclEscala1 as int
DECLARE @fclEscala2 as int
DECLARE @fclEscala3 as int
DECLARE @fclEscala4 as int

DECLARE @fclbase as money 
DECLARE @fclImpImpuesto as money 
DECLARE @fcltotal as money 

DECLARE @facFecha datetime
DECLARE @conNumSerie varchar(50)
DECLARE @estadoCtr varchar(10)

DECLARE @servicioAgua INT = ISNULL((SELECT ISNULL(pgsValor,1) FROM parametros WHERE pgsClave='SERVICIO_AGUA'), 1);

BEGIN TRY

	--******************
	--[01]Usos Excluidos
	IF @xmlUsoCodArray IS NOT NULL BEGIN
		--Creamos una tabla en memoria donde se van a insertar todos los valores
		DECLARE @usosExcluidos AS TABLE(usoCodigo INT); 
		--Leemos los parámetros del XML
		DECLARE @idoc INT;
		EXEC sp_xml_preparedocument @idoc OUTPUT, @xmlUsoCodArray;
		--Insertamos en tabla temporal
		INSERT INTO @usosExcluidos(usoCodigo)
		SELECT value
		FROM   OPENXML (@idoc, '/usoCodigo_List/usoCodigo', 2) WITH (value INT);
		--Liberamos memoria
		EXEC  sp_xml_removedocument @idoc;
	END
	
	--******************
	--[02]@padron: Tabla para el cursor
	DECLARE @padron as TABLE (contrato int,
							  zona VARCHAR(4),
							  serieFactura SMALLINT,
							  numeroFactura VARCHAR(20),
							  unidadesAgua DECIMAL(12,2),
							  periodo varchar(6),
							  documento varchar(20),
							  cliente varchar(60),
							  direccion varchar(200),
							  uso varchar(40),
							  diametro int,
							  lecturaAnterior INT,
							  lecturaActual INT,
							  incidenciaLectura VARCHAR(35),
							  tipoLectura VARCHAR(2),
							  consumoRegistrado int,
							  consumo int,
							  bloque1 int,
							  bloque2 int,
							  bloque3 int,
							  bloque4 int,
							  impBloque1 money,
							  impBloque2 money,
							  impBloque3 money,
							  impBloque4 money,			   
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
							  ,facCod     INT			   
							  ,facVersion INT
							  ,facfecha   datetime
							  ,conNumSerie  varchar(50)
							  ,estadoCtr    varchar(10));

	--******************
	--[03]Sociedad por defecto
	DECLARE @SCD AS INT = 1;
	SELECT @SCD = pgsvalor FROM parametros AS P WHERE P.pgsclave='SOCIEDAD_POR_DEFECTO' AND P.pgsvalor IS NOT NULL;
	
	--******************
	--[11]#FAC: Filtros por los datos en las facturas
	SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion
	INTO #FAC
	FROM dbo.facturas AS F 
	LEFT JOIN fFacturas_TotalFacturado(NULL, 0, NULL) AS T 
	ON  T.ftfFacCod=F.facCod 
	AND T.ftfFacPerCod=F.facPerCod  
	AND T.ftfFacCtrCod=F.facCtrCod 
	AND T.ftfFacVersion=F.facVersion
	WHERE (F.facPerCod >= @periodoD OR @periodoD IS NULL)
	  AND (F.facPerCod <= @periodoH OR @periodoH IS NULL)
	  AND (F.facVersion >= @versionD  OR @versionD IS NULL)
	  AND (F.facVersion <= @versionH OR @versionH IS NULL)
	  AND (F.facZonCod >= @zonaD  OR @zonaD IS NULL)
	  AND (F.facZonCod <= @zonaH OR @zonaH IS NULL)
	  AND (F.facFecha>= @fechaD OR @fechaD IS NULL)
	  AND (F.facFecha<= @fechaH OR @fechaH IS NULL)
	  AND (F.facCtrCod>= @contratoD OR @contratoD IS NULL)
	  AND (F.facCtrCod<= @contratoH OR @contratoH IS NULL)
	   -- verTodas junto con las rectificadas
	  AND (F.facFechaRectif IS NULL OR (F.facFechaRectif >@fechaH) OR @verTodas=1)
	  -- Si @preFactura es 0 entonces saca las facturas definitivas y si es 1 saca todas junto con las preFACTURAS
	  AND ((F.facNumero IS NOT NULL and @preFactura=0) OR  (@preFactura=1) )
	  AND (@consuMin IS NULL OR @consuMin<=F.facConsumoFactura)
	  AND (@consuMax IS NULL OR @consuMax>=F.facConsumoFactura)
	  AND (ISNULL(T.ftfImporte, 0) >= @impoMin or @impoMin IS NULL)
	  AND (ISNULL(T.ftfImporte, 0) <= @impoMax or @impoMax IS NULL);

	--******************
	--[12]#FCL: Valores en las lineas de facturas
	SELECT FF.*
	, [unidadesAgua] = IIF(FL.fclTrfSvCod = @servicioAgua, FL.fclUnidades, 0)
	, [consumo] =   IIF(ISNULL(fclPrecio,0) > 0 AND ISNULL(fclPrecio1, 0) <= 0, ISNULL(fclEscala1,0), ISNULL(fclUnidades1,0)) +
					ISNULL(fclUnidades2,0) + 
					ISNULL(fclUnidades3,0) + 
					ISNULL(fclUnidades4,0) + 
					ISNULL(fclUnidades5,0) + 
					ISNULL(fclUnidades6,0) + 
					ISNULL(fclUnidades7,0) +
					ISNULL(fclUnidades8,0) + 
					ISNULL(fclUnidades9,0) 
	--RN=1: Para quedarnos con la primera linea, que por defecto sería la del agua
	, RN = ROW_NUMBER() OVER (PARTITION BY FF.facCod, FF.facPerCod, FF.facCtrCod, FF.facVersion ORDER BY IIF(fclTrfSvCod = @servicioAgua, 0, 1), FL.fclNumLinea)
	INTO #FCL
	FROM #FAC AS FF
	LEFT JOIN dbo.facLin AS FL
	ON FL.fclFacCtrCod = FF.facCtrCod 
	AND FL.fclFacPerCod = FF.facPerCod 
	AND FL.fclFacVersion = FF.facVersion 
	AND FL.fclFacCod = FF.facCod;

	--******************
	--[13]#CC: Ultimo contador por contrato
	WITH CTR AS(SELECT DISTINCT F.facCtrCod FROM #FAC AS F)
	SELECT CC.* 
	INTO #CC
	FROM dbo.vCambiosContador AS CC
	INNER JOIN CTR AS C
	ON C.facCtrCod = CC.ctrCod AND CC.esUltimaInstalacion=1;

	--******************
	--******************
	--[20]#CUR: Datos para el cursor
	SELECT [codigo] = F.facCod, [contrato] = F.facCtrCod, [zona] = F.facZonCod, [version] = F.facversion, [periodo]= F.facpercod
		 , [cliente] = ISNULL(C.ctrPagNom, C.ctrTitNom)
		 , [direccion] = I.inmdireccion
		 , [uso] = U.usodes
		 , [documento] = ISNULL(C.ctrPagDocIden, C.ctrTitDocIden)
		 , [consumoReal] = F.facconsumofactura
		 , [consumo] = FL.consumo
		 , [diametro] = CC.conDiametro
		 , [scdImpNombre] = S.scdImpNombre
		 , [lecturaAnterior] = F.facLecAnt, [lecturaActual] = F.facLecAct
		 , [tipoLectura] = IX.inlMc, [incidenciaLectura] = IX.inlDes
		 , [serieFactura] = F.facSerCod, [numeroFactura] = F.facNumero
		 , [unidadesAgua] = FL.unidadesAgua
		 , [facFecha] = F.facFecha
		 , [conNumSerie] = CC.conNumSerie
		 , [estadoCtr] = IIF(C.ctrfecsolbaja IS NOT NULL AND C.ctrfecanu IS NOT NULL,'Baja','En vigor') 
	INTO #CUR
	FROM #FAC AS FF
	INNER JOIN dbo.facturas AS F 
	ON F.facCod = FF.facCod AND F.facPerCod = FF.facPerCod AND F.facCtrCod = FF.facCtrCod AND F.facVersion = FF.facVersion
	INNER JOIN dbo.contratos AS C 
	ON C.ctrcod = F.facctrcod AND C.ctrversion = F.facctrversion
	INNER JOIN dbo.usos AS U 
	ON U.usoCod = C.ctrUsoCod
	INNER JOIN dbo.inmuebles AS I 
	ON I.inmcod = C.ctrinmcod
	LEFT JOIN dbo.sociedades AS S 
	ON S.scdcod=ISNULL(F.facserscdcod, @SCD)
	LEFT JOIN dbo.incilec AS IX 
	ON IX.inlCod = F.facLecInlCod
	LEFT JOIN @usosExcluidos AS UX  ON UX.usoCodigo = C.ctrUsoCod
	--Buscamos el ultimo contador asociado al contrato
	LEFT JOIN #CC AS CC  
	ON CC.ctrCod = F.facCtrCod
	--Primera linea de las facturas
	LEFT JOIN #FCL AS FL
	ON FL.facCtrCod = FF.facCtrCod 
	AND FL.facPerCod = FF.facPerCod 
	AND FL.facVersion = FF.facVersion 
	AND FL.facCod = FF.facCod
	AND FL.RN=1
	--*****************************************
	--Usos no excluidos
	WHERE UX.usoCodigo IS NULL;


	DECLARE cPadron 
	CURSOR FOR
	SELECT * FROM #CUR;	
	OPEN cPadron
	FETCH NEXT FROM cPadron
	INTO @codigo, @contrato, @zona, @version, @periodo, @cliente, @direccion, @uso, @documento, @consumoReal, @consumo, @diametro, @scdImpNombre,
         @lecturaAnterior, @lecturaActual, @tipoLectura, @incidenciaLectura, @serieFactura, @numeroFactura, @unidadesAgua
         ,@facFecha,@conNumSerie,@estadoCtr
	WHILE @@FETCH_STATUS = 0

		BEGIN

		SET @bloque1 = 0
		SET @bloque2 = 0
		SET @bloque3 = 0
		SET @bloque4 = 0
		SET @impBloque1 = 0
		SET @impBloque2 = 0
		SET @impBloque3 = 0
		SET @impBloque4 = 0		
		SET @cuotaSrvAgua = 0
		SET @SrvAgua = 0
		SET @impIVASrvAgua = 0
		SET @SrvDep = 0
		SET @impIVASrvDep = 0
		SET @SrvRSU = 0
		SET @impIVASrvRSU = 0
		SET @SrvOtros = 0
		SET @impIVASrvOtros = 0
		
		DECLARE cLineas 
		CURSOR FOR
		select  fcltrfsvcod, fclUnidades, fclPrecio, 
		        fclUnidades1, fclPrecio1, fclUnidades2, fclPrecio2, fclUnidades3, fclPrecio3, fclUnidades4, fclPrecio4,
		        fclEscala1, fclEscala2,fclEscala3, fclEscala4,
		        fclbase, fclImpImpuesto, fcltotal 
		from faclin
		where fclFacCod = @codigo and fclfacpercod = @periodo and fclfacctrcod = @contrato and fclfacversion = @version
		AND((fclFecLiq>=@fechaH) OR (fclFecLiq IS NULL AND fclUsrLiq IS NULL))	
		order by fcltrfsvcod

		OPEN cLineas
		FETCH NEXT 
		FROM cLineas
		INTO @fcltrfsvcod, @fclUnidades, @fclPrecio, 
		     @fclUnidades1, @fclPrecio1, @fclUnidades2, @fclPrecio2,@fclUnidades3, @fclPrecio3,@fclUnidades4, @fclPrecio4,
		     @fclEscala1, @fclEscala2,@fclEscala3, @fclEscala4,
		     @fclbase, @fclImpImpuesto, @fcltotal 

		WHILE @@FETCH_STATUS = 0
			
			BEGIN

				IF @fcltrfsvcod = 1 

					BEGIN
						/*
						SET @bloque1 = @bloque1 + CASE WHEN @fclPrecio1 <> 0 THEN @fclUnidades1 ELSE @fclEscala1 END
						SET @bloque2 = @bloque2 + @fclUnidades2
						SET @cuotaSrvAgua = @cuotaSrvAgua + ROUND(@fclUnidades * @fclPrecio,2)
						SET @impBloque1 = CASE WHEN @fclPrecio1 <> 0 THEN @impBloque1 + ROUND(@fclUnidades1 * @fclPrecio1, 2) ELSE @cuotaSrvAgua END
						SET @impBloque2 = @impBloque2 + ROUND(@fclUnidades2 * @fclPrecio2, 2)
						SET @SrvAgua = @SrvAgua + @fclbase
						SET @impIVASrvAgua = @impIVASrvAgua + @fclImpImpuesto
						*/
						--SET @bloque1 = @bloque1 + CASE WHEN @fclPrecio1 <> 0 THEN @fclUnidades1 ELSE @fclEscala1 END
						SET @bloque1 = @bloque1 + CASE WHEN @fclPrecio1 <> 0 OR (@fclPrecio = 0 AND @fclPrecio1 = 0) THEN @fclUnidades1 ELSE @fclEscala1 END
						SET @bloque2 = @bloque2 + @fclUnidades2
						SET @bloque3 = @bloque3 + @fclUnidades3
						SET @bloque4 = @bloque4 + @fclUnidades4

						SET @cuotaSrvAgua = @cuotaSrvAgua + ROUND(@fclUnidades * @fclPrecio, @precision)
						--SET @impBloque1 = CASE WHEN @fclPrecio1 <> 0  THEN @impBloque1 + ROUND(@fclUnidades1 * @fclPrecio1, 4) ELSE @cuotaSrvAgua END
						SET @impBloque1 = CASE WHEN @fclPrecio1 <> 0 OR (@fclPrecio = 0 AND @fclPrecio1 = 0) THEN @impBloque1 + ROUND(@fclUnidades1 * @fclPrecio1, @precision) ELSE @cuotaSrvAgua END
						SET @impBloque2 = @impBloque2 + ROUND(@fclUnidades2 * @fclPrecio2, @precision)
						SET @impBloque3 = @impBloque3 + ROUND(@fclUnidades3 * @fclPrecio3, @precision)
						SET @impBloque4 = @impBloque4 + ROUND(@fclUnidades4 * @fclPrecio4, @precision)
		        
						SET @SrvAgua = @SrvAgua + @fclbase
						SET @impIVASrvAgua = @impIVASrvAgua + @fclImpImpuesto
					END
				ELSE 
					BEGIN
						IF @fcltrfsvcod = 4 
							BEGIN
								SET @SrvRSU = @SrvRSU + @fclbase
								SET @impIVASrvRSU = @impIVASrvRSU + @fclImpImpuesto
							END
						ELSE 
							BEGIN
								IF @fcltrfsvcod = 8 
									BEGIN
										SET @SrvDep = @SrvDep + @fclbase
										SET @impIVASrvDep = @impIVASrvDep + @fclImpImpuesto
									END
								ELSE 
									BEGIN
										SET @SrvOtros = @SrvOtros + @fclbase
										SET @impIVASrvOtros = @impIVASrvOtros + @fclImpImpuesto
									END
					END
			END
			


		FETCH NEXT FROM cLineas
		INTO @fcltrfsvcod, @fclUnidades, @fclPrecio,
			 @fclUnidades1, @fclPrecio1, @fclUnidades2, @fclPrecio2, @fclUnidades3, @fclPrecio3,@fclUnidades4, @fclPrecio4,@fclEscala1, @fclEscala2,@fclEscala3, @fclEscala4,
			 @fclbase, @fclImpImpuesto, @fcltotal
          
	END
	CLOSE cLineas
	DEALLOCATE cLineas

	insert into @padron (contrato, zona, periodo, documento, cliente, direccion, uso, diametro, consumo, consumoRegistrado,
						 bloque1, bloque2,bloque3, bloque4, impBloque1, impBloque2,impBloque3, impBloque4,
						 cuotaSrvAgua, SrvAgua, impIVASrvAgua,
						 SrvDep, impIVASrvDep,
						 SrvRSU, impIVASrvRSU,
						 SrvOtros, impIVASrvOtros, scdImpNombre,
						 lecturaAnterior, lecturaActual, tipoLectura, incidenciaLectura, serieFactura, numeroFactura, unidadesAgua
						 ,facCod, facVersion
						 ,facfecha
						 ,conNumSerie
						 ,estadoCtr)
	Values (@contrato, @zona, @periodo, @documento, @cliente, @direccion, @uso, @diametro, @consumo, @consumoReal,
	        @bloque1, @bloque2,@bloque3, @bloque4,
	        @impBloque1, @impBloque2,@impBloque3, @impBloque4,
	        @cuotaSrvAgua, @SrvAgua, @impIVASrvAgua,
	        @SrvDep, @impIVASrvDep,
	        @SrvRSU, @impIVASrvRSU,
	        @SrvOtros, @impIVASrvOtros,@scdImpNombre,
	        @lecturaAnterior, @lecturaActual, @tipoLectura, @incidenciaLectura, @serieFactura, @numeroFactura, @unidadesAgua
	        ,@codigo,@version
			,@facFecha
			,@conNumSerie
			,@estadoCtr)
        
	FETCH NEXT FROM cPadron
	INTO @codigo, @contrato, @zona, @version, @periodo, @cliente, @direccion, @uso, @documento, @consumoReal, @consumo, @diametro, @scdImpNombre,
	     @lecturaAnterior, @lecturaActual, @tipoLectura, @incidenciaLectura, @serieFactura, @numeroFactura, @unidadesAgua
	    ,@facFecha,@conNumSerie,@estadoCtr
	END
	CLOSE cPadron
	DEALLOCATE cPadron;



--***************************************
--Buscamos los totales de lineas x servicio

WITH SVC AS(
SELECT FL.fclFacCod
, FL.fclFacPerCod
, FL.fclFacCtrCod
, FL.fclFacVersion
, FL.fclTrfSvCod
, 'iva' + CAST(FL.fclTrfSvCod AS VARCHAR)  AS fclTrfSvCod_iva
--, FL.fcltotal
, FL.fclbase AS fclTotal
, FL.fclImpImpuesto
FROM @padron AS P
INNER JOIN dbo.faclin AS FL
ON FL.fclFacCod = P.facCod
AND FL.fclFacPerCod = P.periodo
AND FL.fclFacCtrCod = P.contrato
AND FL.fclFacVersion = P.facVersion
WHERE (fclFecLiq IS NULL AND fclUsrLiq IS NULL) OR (fclFecLiq>=@fechaH)

), TOTAL AS (
SELECT * FROM
(SELECT fclFacCod
, fclFacPerCod
, fclFacCtrCod
, fclFacVersion
, fclTrfSvCod
, fclTotal
FROM SVC) AS SRC
--Totales
PIVOT(SUM(fclTotal)
FOR fclTrfSvCod IN
( [1], [2], [3], [4], [8]
, [11], [12], [19]
, [20]
, [42], [43], [45], [46], [47], [48], [49]
, [50], [51], [52], [53], [54], [55], [56], [57], [58], [59]
, [60]
, [90]
, [100], [101], [102], [103], [104], [105], [106], [107], [108]
, [200], [201], [202], [999], [1000], [1002])) AS P1

), IVA AS (
SELECT * FROM
(SELECT fclFacCod AS iva_fclFacCod
, fclFacPerCod AS iva_fclFacPerCod
, fclFacCtrCod AS iva_fclFacCtrCod
, fclFacVersion AS iva_fclFacVersion
, fclTrfSvCod_iva
, fclImpImpuesto
FROM SVC)  AS SRC
--iva
PIVOT(SUM(fclImpImpuesto)
FOR fclTrfSvCod_iva IN
( [iva1], [iva2], [iva3], [iva4], [iva8]
, [iva11], [iva12], [iva19]
, [iva20]
, [iva42], [iva43], [iva45], [iva46], [iva47], [iva48], [iva49]
, [iva50], [iva51], [iva52], [iva53], [iva54], [iva55], [iva56], [iva57], [iva58], [iva59]
, [iva60]
, [iva90]
, [iva100], [iva101], [iva102], [iva103], [iva104], [iva105], [iva106], [iva107], [iva108]
, [iva200], [iva201], [iva202], [iva999], [iva1000], [iva1002])) AS P1
)


SELECT *
, (ISNULL([1], 0) + ISNULL([2], 0) + ISNULL([3], 0) + ISNULL([4], 0) + ISNULL([8], 0)
+ ISNULL([11], 0) + ISNULL([12], 0) + ISNULL([19], 0)
+ ISNULL([20], 0)
+ ISNULL([42], 0) + ISNULL([43], 0) + ISNULL([45], 0) + ISNULL([46], 0) + ISNULL([47], 0) + ISNULL([48], 0) + ISNULL([49], 0)
+ ISNULL([50], 0) + ISNULL([51], 0) + ISNULL([52], 0) + ISNULL([53], 0) + ISNULL([54], 0) + ISNULL([55], 0) + ISNULL([56], 0) + ISNULL([57], 0) + ISNULL([58], 0) + ISNULL([59], 0)
+ ISNULL([60], 0)
+ ISNULL([90], 0)
+ ISNULL([100], 0) + ISNULL([101], 0) + ISNULL([102], 0) + ISNULL([103], 0) + ISNULL([104], 0) + ISNULL([105], 0) + ISNULL([106], 0) + ISNULL([107], 0) + ISNULL([108], 0)
+ ISNULL([200], 0) + ISNULL([201], 0) + ISNULL([202], 0) + ISNULL([999], 0) + ISNULL([1000], 0) + ISNULL([1002], 0)) 
AS bseServicios

,(ISNULL([iva1], 0) + ISNULL([iva2], 0) + ISNULL([iva3], 0) + ISNULL([iva4], 0) + ISNULL([iva8], 0)
+ ISNULL([iva11], 0) + ISNULL([iva12], 0) + ISNULL([iva19], 0)
+ ISNULL([iva20], 0)
+ ISNULL([iva42], 0) + ISNULL([iva43], 0) + ISNULL([iva45], 0) + ISNULL([iva46], 0) + ISNULL([iva47], 0) + ISNULL([iva48], 0) + ISNULL([iva49], 0)
+ ISNULL([iva50], 0) + ISNULL([iva51], 0) + ISNULL([iva52], 0) + ISNULL([iva53], 0) + ISNULL([iva54], 0) + ISNULL([iva55], 0) + ISNULL([iva56], 0) + ISNULL([iva57], 0) + ISNULL([iva58], 0) + ISNULL([iva59], 0)
+ ISNULL([iva60], 0)
+ ISNULL([iva90], 0)
+ ISNULL([iva100], 0) + ISNULL([iva101], 0) + ISNULL([iva102], 0) + ISNULL([iva103], 0) + ISNULL([iva104], 0) + ISNULL([iva105], 0) + ISNULL([iva106], 0) + ISNULL([iva107], 0) + ISNULL([iva108], 0)
+ ISNULL([iva200], 0) + ISNULL([iva201], 0) + ISNULL([iva202], 0) + ISNULL([iva999], 0) + ISNULL([iva1000], 0) + ISNULL([iva1002], 0)) 
AS bseServiciosIVA
FROM @padron AS P
LEFT JOIN TOTAL AS T
ON T.fclFacCod = P.facCod
AND T.fclFacPerCod = P.periodo
AND T.fclFacCtrCod = P.contrato
AND T.fclFacVersion = P.facVersion
LEFT JOIN IVA AS I
ON I.iva_fclFacCod= T.fclFacCod
AND	I.iva_fclFacPerCod = T.fclFacPerCod
AND I.iva_fclFacCtrCod = T.fclFacCtrCod
AND I.iva_fclFacVersion = T.fclFacVersion
--***************************************
ORDER BY
CASE @orden WHEN 'calle'THEN direccion END
, CASE @orden WHEN 'titular' THEN cliente END
, CASE @orden WHEN 'contratoCodigo' THEN contrato END
, periodo
, contrato
, numeroFactura;


END TRY
BEGIN CATCH
	IF OBJECT_ID('tempdb..#FAC') IS NOT NULL DROP TABLE #FAC;
	IF OBJECT_ID('tempdb..#FCL') IS NOT NULL DROP TABLE #FCL;
	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC;
	IF OBJECT_ID('tempdb..#CUR') IS NOT NULL DROP TABLE #CUR;

END CATCH
GO


