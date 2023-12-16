/*
DECLARE @xmlUsoCodArray NVARCHAR(4000)
, @periodoD NVARCHAR(6)= '202001'
, @periodoH NVARCHAR(6)= '202001'
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
, @precision SMALLINT = 4

EXEC ReportingServices.RelacionFacturasPadron_VALDALIGA @xmlUsoCodArray
, @periodoD, @periodoH
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
ALTER PROCEDURE [ReportingServices].[RelacionFacturasPadron_VALDALIGA]
  @xmlUsoCodArray NVARCHAR(4000)
, @periodoD NVARCHAR(6)
, @periodoH NVARCHAR(6)
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
, @precision SMALLINT = 4
AS

DECLARE @periodo as varchar(6)
DECLARE @codigo as int
DECLARE @contrato as int
DECLARE @diametro as int
DECLARE @cliente as varchar(60)
DECLARE @documento as varchar(20)
DECLARE @direccion as varchar(200)
DECLARE @consumo as int
DECLARE @consumoReal as int
DECLARE @version as int
DECLARE @scdImpNombre as varchar(60)

DECLARE @uso as int
DECLARE @usodes as varchar(60)
DECLARE @minimo as int
DECLARE @bloque1 as int
DECLARE @bloque2 as int
DECLARE @bloque3 as int
DECLARE @bloque4 as int
DECLARE @bloque5 as int
DECLARE @bloque6 as int
DECLARE @bloque7 as int
DECLARE @bloque8 as int
DECLARE @bloque9 as int
DECLARE @impBloque1 as money
DECLARE @impBloque2 as money
DECLARE @impBloque3 as money
DECLARE @impBloque4 as money
DECLARE @impBloque5 as money
DECLARE @impBloque6 as money
DECLARE @impBloque7 as money
DECLARE @impBloque8 as money
DECLARE @impBloque9 as money
DECLARE @cuotaSrvAgua as money
DECLARE @SrvAgua as money
DECLARE @impIVASrvAgua as money
DECLARE @SrvContador as money
DECLARE @impIVASrvContador as money
DECLARE @SrvRSU as money
DECLARE @impIVASrvRSU as money

DECLARE @consumoCanon as decimal(12,2) 

DECLARE @SrvCanon as money
DECLARE @impIVASrvCanon as money
DECLARE @SrvAlcantarillado as money
DECLARE @impIVASrvAlcantarillado as money
DECLARE @SrvOtros as money
DECLARE @impIVASrvOtros as money

DECLARE @fclEsc1 as int 
DECLARE @fcltrfsvcod as decimal(12,4) 
DECLARE @fclUnidades as decimal(12,2) 
DECLARE @fclPrecio as money
DECLARE @fclUnidades1 as decimal(12,2) 
DECLARE @fclPrecio1 as decimal(10,6) 
DECLARE @fclUnidades2 as decimal(12,2) 
DECLARE @fclPrecio2 as decimal(10,6) 
DECLARE @fclUnidades3 as decimal(12,2) 
DECLARE @fclPrecio3 as decimal(10,6) 
DECLARE @fclUnidades4 as decimal(12,2) 
DECLARE @fclPrecio4 as decimal(10,6)
DECLARE @fclUnidades5 as decimal(12,2) 
DECLARE @fclPrecio5 as decimal(10,6) 
DECLARE @fclUnidades6 as decimal(12,2) 
DECLARE @fclPrecio6 as decimal(10,6) 
DECLARE @fclUnidades7 as decimal(12,2) 
DECLARE @fclPrecio7 as decimal(10,6) 
DECLARE @fclUnidades8 as decimal(12,2) 
DECLARE @fclPrecio8 as decimal(10,6)
DECLARE @fclUnidades9 as decimal(12,2) 
DECLARE @fclPrecio9 as decimal(10,6)



DECLARE @fclbase as money 
DECLARE @fclImpImpuesto as money 
DECLARE @fcltotal as money 



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


DECLARE @padron as 
		TABLE (contrato int,
                           periodo varchar(6),
                           documento varchar(20),
			   cliente varchar(60),
			   direccion varchar(200),
			   diametro int,
			   consumoRegistrado int,
			   consumo int,
			   minimo int,
			   uso int,
			   usodes varchar(60),
			   bloque1 int,
			   bloque2 int,
			   bloque3 int,
			   bloque4 int,
			   bloque5 int,
			   bloque6 int,
			   bloque7 int,
			   bloque8 int,
			   bloque9 int,
			   impBloque1 money,
			   impBloque2 money,
			   impBloque3 money,
			   impBloque4 money,
			   impBloque5 money,
			   impBloque6 money,
			   impBloque7 money,
			   impBloque8 money,
			   impBloque9 money,
			   cuotaSrvAgua money,
			   SrvAgua money,
			   impIVASrvAgua money,
			   SrvContador money,
			   impIVASrvContador money,
			   SrvRSU money,
			   impIVASrvRSU money,
			   consumoCanon INT,
			   SrvCanon money,
			   impIVASrvCanon money,
			   SrvAlcantarillado money,
			   impIVASrvAlcantarillado money,
			   SrvOtros money,
			   impIVASrvOtros money,
			   scdImpNombre varchar(50)
			)

	DECLARE cPadron CURSOR FOR
select facCod, facCtrCod, facversion, facpercod, ISNULL(ctrPagNom, ctrTitNom), inmdireccion, ISNULL(ctrPagDocIden, ctrTitDocIden), facconsumoreal, facconsumofactura,
(SELECT conDiametro 
	FROM fContratos_ContadoresInstalados(NULL) 
	WHERE ctcCtr = facCtrCod 
) as conDiametro,
ctrusocod, usodes, scdImpNombre
   from facturas  
   left join sociedades on scdcod=ISNULL(facserscdcod,ISNULL((select pgsvalor from parametros where pgsclave='SOCIEDAD_POR_DEFECTO'),1))
   inner join contratos on ctrcod = facctrcod and ctrversion = facctrversion
   inner join usos on usocod = ctrusocod 
   inner join inmuebles on inmcod = ctrinmcod
   LEFT JOIN fFacturas_TotalFacturado(NULL, 0, NULL) ON ftfFacCod=facCod AND ftfFacPerCod=facPerCod  AND ftfFacCtrCod=facCtrCod AND ftfFacVersion=facVersion
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
and ( (facNumero is not null and @preFactura=0) OR  (@preFactura=1) )-- Si @preFactura es 0 entonces saca las facturas definitivas y si es 1 saca todas junto con las preFACTURAS
and (facConsumoFactura >= @consuMin or @consuMin is null)
and (facConsumoFactura <= @consuMax or @consuMax is null)
and (ISNULL(ftfImporte, 0) >= @impoMin or @impoMin is null)
and (ISNULL(ftfImporte, 0) <= @impoMax or @impoMax is null)
AND NOT EXISTS(SELECT u.usoCod
		      FROM usos u 
		      INNER JOIN @usosExcluidos ON usoCodigo = u.usocod
		      WHERE u.usocod = ctrUsoCod
	      )
  
	OPEN cPadron
	FETCH NEXT FROM cPadron
	INTO @codigo, @contrato, @version, @periodo, @cliente, @direccion, @documento, @consumoReal, @consumo, @diametro, @uso, @usodes, @scdImpNombre

	WHILE @@FETCH_STATUS = 0
	BEGIN

		SET @minimo = 0
		SET @bloque1 = 0
		SET @bloque2 = 0
		SET @bloque3 = 0
		SET @bloque4 = 0
		SET @bloque5 = 0
		SET @bloque6 = 0
		SET @bloque7 = 0
		SET @bloque8 = 0
		SET @bloque9 = 0
		SET @impBloque1 = 0
		SET @impBloque2 = 0
		SET @impBloque3 = 0
		SET @impBloque4 = 0
		SET @impBloque5 = 0
		SET @impBloque6 = 0
		SET @impBloque7 = 0
		SET @impBloque8 = 0
		SET @impBloque9 = 0
		SET @cuotaSrvAgua = 0
		SET @SrvAgua = 0
		SET @impIVASrvAgua = 0
		SET @SrvContador = 0
		SET @impIVASrvContador = 0
		SET @SrvRSU = 0
		SET @impIVASrvRSU = 0
		SET @consumoCanon = 0
		SET @SrvCanon = 0
		SET @impIVASrvCanon = 0
		SET @SrvAlcantarillado = 0
		SET @impIVASrvAlcantarillado = 0
		SET @SrvOtros = 0
		SET @impIVASrvOtros = 0
		
		DECLARE cLineas CURSOR FOR
			select fcltrfsvcod, fclUnidades, fclPrecio, fclEscala1,
				   fclUnidades1, fclPrecio1, fclUnidades2, fclPrecio2, 
				   fclUnidades3, fclPrecio3, fclUnidades4, fclPrecio4,
				   fclUnidades5, fclPrecio5, fclUnidades6, fclPrecio6,
				   fclUnidades7, fclPrecio7, fclUnidades8, fclPrecio8,
				   fclUnidades9, fclPrecio9, 
				   fclbase, fclImpImpuesto, fcltotal 
				from faclin
				where fclfaccod = @codigo and fclfacpercod = @periodo and fclfacctrcod = @contrato and fclfacversion = @version
				AND((fclFecLiq>=@fechaH) OR (fclFecLiq IS NULL AND fclUsrLiq IS NULL))	     
				order by fcltrfsvcod
		OPEN cLineas
		FETCH NEXT FROM cLineas
		INTO @fcltrfsvcod, @fclUnidades, @fclPrecio, @fclEsc1,
			@fclUnidades1, @fclPrecio1, @fclUnidades2, @fclPrecio2, 
			@fclUnidades3, @fclPrecio3, @fclUnidades4, @fclPrecio4,
 		    @fclUnidades5, @fclPrecio5, @fclUnidades6, @fclPrecio6,
		    @fclUnidades7, @fclPrecio7, @fclUnidades8, @fclPrecio8,
		    @fclUnidades9, @fclPrecio9, 
			@fclbase, @fclImpImpuesto, @fcltotal 

		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @fcltrfsvcod = 1 BEGIN
				IF @fclEsc1 <> 999999999 BEGIN
					SET @minimo = @minimo + @fclEsc1
				END
				SET @bloque1 = @bloque1 + @fclUnidades1
				SET @bloque2 = @bloque2 + @fclUnidades2
				SET @bloque3 = @bloque3 + @fclUnidades3
				SET @bloque4 = @bloque4 + @fclUnidades4
				SET @bloque5 = @bloque5 + @fclUnidades5
				SET @bloque6 = @bloque6 + @fclUnidades6
				SET @bloque7 = @bloque7 + @fclUnidades7
				SET @bloque8 = @bloque8 + @fclUnidades8
				SET @bloque9 = @bloque9 + @fclUnidades9
				SET @impBloque1 = @impBloque1 + ROUND(@fclUnidades1 * @fclPrecio1, @precision)
				SET @impBloque2 = @impBloque2 + ROUND(@fclUnidades2 * @fclPrecio2, @precision)
				SET @impBloque3 = @impBloque3 + ROUND(@fclUnidades3 * @fclPrecio3, @precision)
				SET @impBloque4 = @impBloque4 + ROUND(@fclUnidades4 * @fclPrecio4, @precision)
				SET @impBloque5 = @impBloque5 + ROUND(@fclUnidades5 * @fclPrecio5, @precision)
				SET @impBloque6 = @impBloque6 + ROUND(@fclUnidades6 * @fclPrecio6, @precision)
				SET @impBloque7 = @impBloque7 + ROUND(@fclUnidades7 * @fclPrecio7, @precision)
				SET @impBloque8 = @impBloque8 + ROUND(@fclUnidades8 * @fclPrecio8, @precision)
				SET @impBloque9 = @impBloque9 + ROUND(@fclUnidades9 * @fclPrecio9, @precision)

				SET @cuotaSrvAgua = @cuotaSrvAgua + ROUND(@fclUnidades * @fclPrecio, @precision)

				SET @SrvAgua = @SrvAgua + @fclbase
				SET @impIVASrvAgua = @impIVASrvAgua + @fclImpImpuesto
			END 
			ELSE BEGIN
				IF @fcltrfsvcod = 2 BEGIN
					SET @SrvContador = @SrvContador + @fclbase
					SET @impIVASrvContador = @impIVASrvContador + @fclImpImpuesto
				END 
				ELSE BEGIN
					IF @fcltrfsvcod = 4 BEGIN
						SET @SrvRSU = @SrvRSU + @fclbase
						SET @impIVASrvRSU = @impIVASrvRSU + @fclImpImpuesto
					END 
					ELSE BEGIN
						IF @fcltrfsvcod = 5 BEGIN
							SET @consumoCanon = ISNULL(@fclUnidades1 + @fclUnidades2 + @fclUnidades3 + @fclUnidades4 + @fclUnidades5 + @fclUnidades6 + @fclUnidades7 + @fclUnidades8 + @fclUnidades9, 0)
							SET @SrvCanon = @SrvCanon + @fclbase
							SET @impIVASrvCanon = @impIVASrvCanon + @fclImpImpuesto
						END 
						ELSE BEGIN
							IF @fcltrfsvcod IN(3, 6) BEGIN
								SET @SrvAlcantarillado = @SrvAlcantarillado + @fclbase
								SET @impIVASrvAlcantarillado = @impIVASrvAlcantarillado + @fclImpImpuesto
							END 
							ELSE BEGIN
								SET @SrvOtros = @SrvOtros + @fclbase
								SET @impIVASrvOtros = @impIVASrvOtros + @fclImpImpuesto
							END
						END
					END
				END
			END

			FETCH NEXT FROM cLineas
			INTO @fcltrfsvcod, @fclUnidades, @fclPrecio, @fclEsc1,
				@fclUnidades1, @fclPrecio1, @fclUnidades2, @fclPrecio2, 
				@fclUnidades3, @fclPrecio3, @fclUnidades4, @fclPrecio4,
 				@fclUnidades5, @fclPrecio5, @fclUnidades6, @fclPrecio6,
				@fclUnidades7, @fclPrecio7, @fclUnidades8, @fclPrecio8,
				@fclUnidades9, @fclPrecio9, 
				@fclbase, @fclImpImpuesto, @fcltotal 
		END
		CLOSE cLineas
		DEALLOCATE cLineas
	
		insert into @padron (contrato, periodo, documento, cliente, direccion, diametro, consumo, consumoRegistrado, minimo, uso, usodes,
				 bloque1, bloque2, bloque3, bloque4, bloque5, bloque6, bloque7, bloque8, bloque9,
				 impBloque1, impBloque2, impBloque3, impBloque4, impBloque5, impBloque6, impBloque7, impBloque8, impBloque9,
				 cuotaSrvAgua, SrvAgua, impIVASrvAgua,
				 SrvContador, impIVASrvContador,
				 SrvRSU, impIVASrvRSU,
				 consumoCanon,SrvCanon, impIVASrvCanon,
				 SrvAlcantarillado, impIVASrvAlcantarillado,
				 SrvOtros, impIVASrvOtros, scdImpNombre)
		Values(@contrato, @periodo, @documento, @cliente, @direccion, @diametro, @consumo, @consumoReal, @minimo, @uso, @usodes,
			 @bloque1, @bloque2, @bloque3, @bloque4, @bloque5, @bloque6, @bloque7, @bloque8, @bloque9,
			 @impBloque1, @impBloque2, @impBloque3, @impBloque4, @impBloque5, @impBloque6, @impBloque7, @impBloque8, @impBloque9,
			 @cuotaSrvAgua, @SrvAgua, @impIVASrvAgua,
			 @SrvContador, @impIVASrvContador,
			 @SrvRSU, @impIVASrvRSU,
			 @consumoCanon, @SrvCanon, @impIVASrvCanon,
			 @SrvAlcantarillado, @impIVASrvAlcantarillado,
			 @SrvOtros, @impIVASrvOtros, @scdImpNombre)

		FETCH NEXT FROM cPadron
		INTO @codigo, @contrato, @version, @periodo, @cliente, @direccion, @documento, @consumoReal, @consumo, @diametro, @uso, @usodes, @scdImpNombre
	END
	CLOSE cPadron
	DEALLOCATE cPadron


SELECT * FROM @padron
	ORDER BY uso, 
	CASE @orden WHEN 'calle'
	THEN 
		direccion
	END,	
	CASE @orden WHEN 'titular'
                THEN
		cliente
	END,
	CASE @orden WHEN 'contratoCodigo'
	THEN
		contrato

	END,
	periodo


GO


