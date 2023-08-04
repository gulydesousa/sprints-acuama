ALTER TRIGGER  [dbo].[facturas_SII]
   ON  [dbo].[facturas]
   AFTER INSERT,UPDATE
AS 
BEGIN
LINENO 0
	SET NOCOUNT ON;

	BEGIN TRY  
	BEGIN TRANSACTION;--TRIGGER  [dbo].[facturas_SII]

		--******************
		--[01]Obtenemos el nombre de la explotacion
		--El SII varía según la explotación: AVG, EMMASA, Otras:
		DECLARE @expl VARCHAR(20) = NULL;
		DECLARE @esEmmasa BIT = 0; 
		DECLARE @esAVG BIT = 0; 
		DECLARE @esValdaliga BIT = 0; 

		
		SET @expl = (SELECT pgsvalor FROM parametros WHERE pgsclave = 'EXPLOTACION');		

		SELECT @esEmmasa	= IIF(@expl = 'Emmasa', 1, 0),
			   @esAVG		= IIF(@expl = 'AVG', 1, 0),
			   @esValdaliga = IIF(@expl = 'VALDALIGA', 1, 0);


		--******************
		--[02]Obtener el código de la explotación
		DECLARE @explCodigo VARCHAR(20) = NULL
		SET @explCodigo = (SELECT pgsvalor FROM parametros WHERE pgsclave = 'EXPLOTACION_CODIGO')

		
		--******************
		--[03]Buscamos la información de la factura rectificada
		--En esta tabla sacamos la información de la factura en su versión anterior, si existe (RN=1)
		--@FACV
		DECLARE @FACV AS TABLE(
		  fvFacCod INT, fvFacPerCod VARCHAR(6), fvFacCtrCod INT, fvFacVersion INT
		, fvFacSerScdCod INT, fvFacSerCod INT, fvFacSerCodAlt VARCHAR(2)
		, fvFacFecha DATETIME
		, fvFacNumero VARCHAR(50));

		
		WITH FACS AS(
		SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion
		, F.facSerCod, F.facSerScdCod
		, F.facFecha
		, IIF(@esEmmasa = 1, F.facNumeroAqua, F.facNumero) AS facNumero 
		-----------
		, ROW_NUMBER() OVER (PARTITION BY F.facCod, F.facPerCod, F.facCtrCod ORDER BY F.facVersion DESC) AS RN   
		FROM INSERTED AS I
		INNER JOIN dbo.facturas AS F
		ON  I.facCod = F.facCod
		AND I.facPerCod = F.facPerCod
		AND I.facCtrCod = F.facCtrCod
		AND (I.facVersion IS NULL OR F.facVersion < I.facVersion) )

		INSERT INTO @FACV
		SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion
		, F.facSerScdCod, F.facSerCod, S.sercodAlternativo 
		, F.facFecha
		, F.facNumero
		FROM FACS AS F
		LEFT JOIN dbo.series AS S
		ON F.facSerCod = S.sercod
		AND F.facSerScdCod = S.serscd
		WHERE RN=1;
		--******************

		--******************
		--[11]RECUPERAMOS LA SOCIEDAD: Al menos una de las dos debe existir teniendo prioridad la de la remesa 
		DECLARE @scdFacturacion INT;

		SELECT TOP 1 @scdFacturacion = P.pgsvalor 
		FROM dbo.parametros AS P 
		WHERE P.pgsclave IN ('SOCIEDAD_POR_DEFECTO', 'SOCIEDAD_REMESA')	
		ORDER BY IIF(P.pgsclave='SOCIEDAD_REMESA', 0, 1); 
	
		--Si faltara la configuración de las dos sociedades, lanzamos un error
		IF (@scdFacturacion IS NULL)
			THROW 50001, 'Verifique la configuración de la tabla parametros para SOCIEDAD_POR_DEFECTO y SOCIEDAD_REMESA', 1;	
		
		--******************	
		--Con esto no permitimos que se puedan actualizar desde base de datos varios registros
		IF ((SELECT COUNT(*) FROM deleted) > 1)
			GOTO ACTUALIZAR_CABECERA

		--[12]Para cuando se actualiza una factura conocer si ha cambiado la version del contrato
		DECLARE @mismaVersionCtr BIT = 0
		IF ((SELECT facCtrVersion FROM deleted) = (SELECT facCtrVersion FROM inserted))
			SET @mismaVersionCtr = 1;

		--[13]Es Factura Rectificada
		DECLARE @esRectificativa BIT = 0
		IF EXISTS(SELECT 1 FROM inserted f WHERE facVersion > 1)
			SET @esRectificativa = 1;
			
		--[14]Es Anulación
		DECLARE @esAnulacion BIT = 0

		-- Es una anulación si tiene versión > 1 y el importe que va al SII es 0 (no necesariamente el importe total de la factura, sino el que va al SII)
		IF @esRectificativa = 1 AND  
				(SELECT ISNULL(SUM(i.fclTotal),0)
				   FROM faclin i
			 INNER JOIN inserted fs on fs.facCod=i.fclfacCod and fs.facpercod=i.fclfacpercod and fs.facctrcod=i.fclfacctrcod and fs.facversion=i.fclfacversion		     
			 AND EXISTS(select svccod from servicios where svccod=fclTrfSvCod and svcOrgCod IS NULL)) --Excluir los servicios que tengan un organismo establecido, ya que estos no viajarán al SII
				= 0
			SET @esAnulacion = 1;					
				
		--[15]@REENVIO=1 para forzar la reinserción de facSII y facSIIDesgloseFactura
		DECLARE @REENVIO BIT = IIF( EXISTS(SELECT I.facFecUltimoReenvioSII 
											FROM INSERTED AS I
											INNER JOIN DELETED AS D
											ON I.facCod = D.facCod 
											AND I.facPerCod = D.facPerCod 
											AND I.facCtrCod = D.facCtrCod 
											AND I.facVersion = D.facVersion
											AND I.facFecUltimoReenvioSII IS NOT NULL
											AND (D.facFecUltimoReenvioSII IS NULL OR I.facFecUltimoReenvioSII <> D.facFecUltimoReenvioSII)), 1, 0) ;

		--ACTUALIZAR CABECERA FACTURA, SI ACTUALIZAN EL TIPO RECTIFICATIVA NO SE DEBE INSERTAR NADA EN FACSII
		--((SELECT facCtrVersion FROM deleted) = (SELECT facCtrVersion FROM inserted)) ESTA CONDICIÓN CASO DNI NO VALIDO QUE TAMBIÉN ACTUALIZA LA FACTURA
		--CUANDO SE DISPARA EL TRIGGER [faclin_UpdateDesglosesSII] SE ACTUALIZA EL TIPO DE LA RECTIFICATIVA
		IF (((SELECT facNumero FROM deleted) = (SELECT facNumero FROM inserted)) 
			AND @mismaVersionCtr = 1
			--Si se envia la actualización de facObs se fuerza reenvio al SII
			AND @REENVIO=0)
			GOTO ACTUALIZAR_CABECERA
		ELSE

		BEGIN

		--[V01]Numero del nuevo envio:
		DECLARE @fclSiiNumEnvio INT = 0;
		SELECT @fclSiiNumEnvio = ISNULL(MAX(fcSiiNumEnvio),0) + 1
		FROM INSERTED AS I
		INNER JOIN facSII AS S 
		ON S.fcSiiFacCod = I.facCod AND S.fcSiiFacPerCod = I.facPerCod AND S.fcSiiFacCtrCod = I.facCtrCod AND S.fcSiiFacVersion = I.facVersion;
	
	
		DECLARE @facNumero nvarchar(20) = NULL				
		DECLARE @facCod SMALLINT = NULL		
		DECLARE @facPerCod VARCHAR(6) = NULL
		DECLARE @facCtrCod INT = NULL
		DECLARE @facVersion SMALLINT = NULL
		
		SET @facNumero = (SELECT i.facNumero FROM inserted i)
		SET @facCod = (SELECT i.facCod FROM inserted i)
		SET @facPerCod = (SELECT i.facPerCod FROM inserted i)
		SET @facCtrCod = (SELECT i.facCtrCod FROM inserted i)
		SET @facVersion = (SELECT i.facVersion FROM inserted i)

		--SI SE INSERTA/ACTUALIZA EL NÚMERO DE FACTURA SE DEBE INSERTAR UN REGISTRO POR CADA TABLA facSII y facSIIDesgloseFactura
		IF UPDATE(facNumero) OR @REENVIO=1
		BEGIN
			--Es tracto sucesivo (facturas a partir de 01/01/2018)
			DECLARE @esTractoSucesivo BIT = 0, @fechaDevengo DATETIME
			SELECT @esTractoSucesivo = 1, @fechaDevengo = p.perFecDevengo 
			  FROM inserted i INNER JOIN series s ON i.facSerCod = s.sercod and i.facSerScdCod = s.serscd 
							  INNER JOIN periodos p on i.facPerCod = p.percod
			 WHERE s.sertracto = 1 AND YEAR(p.perFecDevengo) >= 2018
		 
			--En rectificativas, si la factura original es de tracto sucesivo (facturas a partir de 01/01/2018)
			DECLARE @originalEsTractoSucesivo BIT = 0, @originalFechaDevengo DATETIME, @originalFacFecha DATETIME
			SELECT @originalEsTractoSucesivo = 1, @originalFechaDevengo = p.perFecDevengo
			  FROM facturas f INNER JOIN inserted i ON f.facCod = i.facCod AND f.facPerCod = i.facPerCod AND f.facCtrCod = i.facCtrCod AND f.facVersion = (i.facVersion - 1)
							  INNER JOIN series s ON f.facSerCod = s.sercod and f.facSerScdCod = s.serscd 
							  INNER JOIN periodos p on f.facPerCod = p.percod
			 WHERE s.sertracto = 1 AND YEAR(p.perFecDevengo) >= 2018

			SELECT @originalFacFecha = f.facFecha
			  FROM facturas f INNER JOIN inserted i ON f.facCod = i.facCod AND f.facPerCod = i.facPerCod AND f.facCtrCod = i.facCtrCod AND f.facVersion = (i.facVersion - 1)

			--SI NO HAY NÚMERO DE FACTURA, ES DECIR, SI ES PREFACTURA NO SE HACE NADA SOLO SE INSERTARÁ EN FACSII Y FACSIIDESGLOSEFACTURA CUANDO SEAN FACTURAS REALES
			-- Si el número de factura es negativo (caso de creación de rectificativa en Canal Averías) no debe enviarse al SII todavía
			DECLARE @hayNumeroFactura BIT = 0
			IF EXISTS(SELECT facCod FROM inserted i WHERE i.facNumero IS NOT NULL AND i.facNumero > CAST(0 AS BIGINT))
				SET @hayNumeroFactura = 1
	
			--Es Factura de contado
			DECLARE @facturaContado BIT = 0
			IF ((SELECT facPerCod FROM inserted) like '000%')
			SET @facturaContado = 1

			DECLARE @envioSAP BIT = ISNULL((SELECT facEnvSap FROM inserted),0)
			--SI EL FACENVSAP ES 0 O NULL PERO ES UNA RECTIFICATIVA DE UNA FACTURA ANTIGUA DEBEMOS COMPROBAR SI LA SERIE DE LA RECTIFICATIVA 
			--TIENE EL ENVÍO A SAP ACTIVO PARA INSERTAR LA RECTIFICATIVA EN FACSII
		
			IF (@envioSAP = 0 AND @esRectificativa = 1)				
			BEGIN
				SELECT @envioSAP = serEnvSap 
				FROM INSERTED AS I
				INNER JOIN dbo.series AS S
				ON  S.serscd = I.facSerScdCod
				AND S.sercod = I.facSerCod;
			END
	
			IF (@hayNumeroFactura = 1 AND @envioSAP = 1)
			BEGIN
			
				--Es persona física extranjera o dni no válido
				DECLARE @esExtranjero BIT = 0
				DECLARE @contratoCodigo INT = (SELECT facCtrCod FROM inserted)
				DECLARE @contratoVersion SMALLINT = (SELECT facCtrVersion FROM inserted)

				IF	(CASE WHEN (SELECT ISNULL(ctrPagDocIden, '') FROM contratos WHERE ctrcod=@contratoCodigo AND ctrversion=@contratoVersion) IS NULL THEN
						(SELECT ISNULL(ctrTitNacionalidad, ctrTitNac) FROM contratos WHERE ctrcod=@contratoCodigo AND ctrversion=@contratoVersion)
					ELSE 
						(SELECT ISNULL(ctrPagNacionalidad, ctrPagNac) FROM contratos WHERE ctrcod=@contratoCodigo AND ctrversion=@contratoVersion)
					END) <> 'ESP'		
					SET @esExtranjero = 1
			
				--POR DEFECTO SI NO EXISTE ESE PARÁMETRO SE COGE EL 3 QUE ES EL QUE TIENE ASIGNADO EL TIPO DE DOCUMENTO PARA EL PASAPORTE EN TODAS LAS EXPLOTACIONES
				DECLARE @codigoTipoDocPasaporte VARCHAR(2) = ISNULL((SELECT pgsvalor FROM parametros WHERE pgsclave = 'TIPODOC_PASAPORTE_CODIGO'),'3')
				DECLARE @esPasaporte BIT = 0
				IF (CASE WHEN (SELECT ISNULL(ctrPagDocIden, '') FROM contratos WHERE ctrcod=@contratoCodigo AND ctrversion=@contratoVersion) IS NULL THEN
						(SELECT ctrTitTipDoc FROM contratos WHERE ctrcod=@contratoCodigo AND ctrversion=@contratoVersion)
					ELSE 
						(SELECT ctrPagTipDoc FROM contratos WHERE ctrcod=@contratoCodigo AND ctrversion=@contratoVersion)
					END) = @codigoTipoDocPasaporte
					set @esPasaporte = 1
										
				--CASO EN EL CUAL SE HACE UNA RECTIFICATIVA DE UNA PREFACTURA CERRADA
				--PRIMERO VEMOS SI EL PERIODO ESTÁ CERRADO Y ADEMÁS ES UNA PREFACTURA EN SU VERSION ANTERIOR (facNumero IS NULL)
				--SE DEBE DEJAR EL FACSII COMO UN PRIMER NÚMERO DE ENVÍO, CON F1
				DECLARE @esPeriodoCerrado bit = 0
				DECLARE @esPrefacturaCerrada bit = 0
				EXEC Perzona_Exists	@facPerCod,1, @esPeriodoCerrado output, NULL
				IF(@esPeriodoCerrado=1 AND 
					EXISTS(SELECT facCod 
									FROM facturas 
									WHERE facCod=@facCod AND
										facPerCod=@facPerCod AND
										facCtrCod=@facCtrCod AND
										facVersion=(@facVersion - 1) AND
										facNumero IS NULL)
					)	
					SET @esPrefacturaCerrada=1

				INSERT INTO [dbo].[facSII]
						([fcSiiFacCod], [fcSiiFacPerCod], [fcSiiFacCtrCod], [fcSiiFacVersion], [fcSiiNumEnvio]
						,[SuministroLR]
						,[fcSiiCabIDVersion]
						,[fcSiiCabTitNombreRazon]
						,[fcSiiCabTitNifRepresentante]
						,[fcSiiCabTitNif]
						,[fcSiiCabTipoComunicacion]
						,[fcSiiEjercicio]
						,[fcSiiPeriodo]
						,[fcSiiIDEmisorFacturaNIF]
						,[fcSiiNumSerieFacturaEmisor] -- modificar si tiene codAlternativo en tabla Series
						,[fcSiiFechaExpedicionFacturaEmisor]
						,[fcSiiIDEmisorFacturaOrg]
						,[fcSiiTipoFactura]
						,[TipoRectificativa]
						,[fcSiiFraRecNumSerieFacturaEmisor]
						,[fcSiiFraRecFechaExpedicionFacturaEmisor]
						,[BaseRectificada]
						,[CuotaRectificada]
						,[fcSiiFechaOperacion]
						,[fcSiiClavRegEspOTras]
						,[fcSiiImporteTotal]
						,[DescripcionOperacion]
						,[fcSiiDetInmRefCat]
						,[fcSiiEmitidaPorTerceros]
						,[fcSiiContraparteNombreRazon]
						,[fcSiiContraparteNIFRepresentante]
						,[fcSiiContraparteNIF]
						,[fcSiiContraparteIDOtro]
						,[fcSiiContraparteIDType]
						,[fcSiiContraparteID]
						,[fcSiiLoteID]
						,[fcSiiestado]
						,[fcSiicodErr]
						,[fcSiidescErr]
						,[fcSiicsv])

				--RELLENAR CAMPOS CON LOS DATOS DE LA FACTURAS INSERTADA/ACTUALIZADA
				SELECT f.facCod, f.facPerCod, f.facCtrCod, f.facVersion, @fclSiiNumEnvio
						,'FacturasEmitidas' --SuministroLR emitidas, modificadas, registradas
						---------------
						---------------
						----- Cabecera
						,(SELECT ISNULL(pgsvalor,'1.1') FROM parametros WHERE pgsclave = 'VERSION_SII') --Versión Actual del esquema utilizado para el intercambio de información
						--datos del Titular
						,ISNULL((SELECT CASE WHEN ((ISNULL(ctrPagDocIden, '') <> '') AND @expl <> 'AVG') OR (@expl = 'AVG' AND (ISNULL(ctrPagDocIden, '') <> '') AND facPerCod <> '000013' AND facPerCod <> '000015') THEN ctrPagNom ELSE ctrTitNom END
									FROM contratos WHERE ctrcod=f.facCtrCod AND ctrversion = f.facCtrVersion),'Sin identificar')--fcSiiCabTitNombreRazon
						,NULL--fcSiiCabTitNifRepresentante
						,(SELECT CASE WHEN ((ISNULL(ctrPagDocIden, '') <> '') AND @expl <> 'AVG') OR (@expl = 'AVG' AND (ISNULL(ctrPagDocIden, '') <> '') AND facPerCod <> '000013' AND facPerCod <> '000015') THEN ctrPagDocIden ELSE ctrTitDocIden END FROM contratos WHERE ctrcod=f.facCtrCod AND ctrversion = f.facCtrVersion) --fcSiiCabTitNif
						,'A0' --A0 Alta de facturas/registro, A1 Modificación de facturas/registros (errores registrales)
						----- Fin Cabecera
						---------------

						-- El periodo de liquidación (ejercicio+periodo) a informar lo determina la fecha de operación, así que nos basamos en el mismo 
						-- esquema que para el campo de fecha de operación												
						,CASE 
							-- Hasta enero 2020 aplicábamos que ejercicio y periodo en una rectificativa tenía que ser el de la factura original.
							-- Por indicación de fiscal, se pone siempre el ejercicio y el periodo de la factura, sea rectificativa o no.
							--	-- Si es rectificativa
							--	WHEN @esRectificativa = 1 AND @esPrefacturaCerrada = 0 THEN
							----		Si la original es de tracto sucesivo, la fecha de operación es la fecha devengo del periodo de la original						
							--	(CASE WHEN @originalEsTractoSucesivo = 1 
							--		  THEN CAST(YEAR(@originalFechaDevengo) AS VARCHAR(4))  
							----		Si la original no es de tracto sucesivo, la fecha de operación es la fecha factura de la original
							--		ELSE CAST(YEAR(@originalFacFecha) AS VARCHAR(4)) END)

							--	Si es tracto sucesivo y no es rectificativa (habría pasado por el caso anterior), fecha devengo
								WHEN @esTractoSucesivo = 1 THEN CAST(YEAR(@fechaDevengo) AS VARCHAR(4)) 
							--	Si es anulación cogemos el ejercicio desde la fecha de la versión anterior
								WHEN @esAnulacion = 1 THEN CAST(YEAR(ISNULL(FV.fvFacFecha, GETDATE())) AS VARCHAR(4))
							--  Si no, cogemos el ejercicio desde la fecha de factura 
								ELSE (SELECT CAST(YEAR(ISNULL(facFecha, GETDATE())) AS VARCHAR(4))
										FROM facturas fSub 
									   WHERE fSub.facCod=f.facCod AND fSub.facPerCod=f.facPerCod AND fSub.facCtrCod=f.facCtrCod AND fSub.facVersion=f.facVersion)
							END -- fcSiiEjercicio
					
						,CASE 
							-- Hasta enero 2020 aplicábamos que ejercicio y periodo en una rectificativa tenía que ser el de la factura original.
							-- Por indicación de fiscal, se pone siempre el ejercicio y el periodo de la factura, sea rectificativa o no.
							--WHEN @esRectificativa = 1 AND @esPrefacturaCerrada = 0 THEN
							----		Si la original es de tracto sucesivo, la fecha de operación es la fecha devengo del periodo de la original						
							--	(CASE WHEN @originalEsTractoSucesivo = 1 
							--		  THEN CASE WHEN MONTH(@originalFechaDevengo) < 10 THEN '0' + CAST(MONTH(@originalFechaDevengo) AS VARCHAR(1)) 
							--					ELSE CAST(MONTH(@originalFechaDevengo) AS VARCHAR(2)) END  
							----		Si la original no es de tracto sucesivo, la fecha de operación es la fecha factura de la original
							--		  ELSE CASE WHEN MONTH(@originalFacFecha) < 10 THEN '0' + CAST(MONTH(@originalFacFecha) AS VARCHAR(1)) 
							--					ELSE CAST(MONTH(@originalFacFecha) AS VARCHAR(2)) END END)
							--	Si es tracto sucesivo y no es rectificativa (habría pasado por el caso anterior), fecha devengo
								WHEN @esTractoSucesivo = 1 THEN CASE WHEN MONTH(@fechaDevengo) < 10 THEN '0' + CAST(MONTH(@fechaDevengo) AS VARCHAR(1)) 
																	 ELSE CAST(MONTH(@fechaDevengo) AS VARCHAR(2)) END 
							--	Si es anulación cogemos el periodo desde la fecha de la versión anterior
								WHEN @esAnulacion = 1 THEN RIGHT(CONCAT('00', MONTH(FV.fvFacFecha)), 2)
							
							--	Si no, cogemos el periodo desde la fecha de factura						
								ELSE (SELECT CASE WHEN MONTH(ISNULL(facFecha, GETDATE())) < 10 THEN '0' + CAST(MONTH(ISNULL(facFecha, GETDATE())) AS VARCHAR(1)) 
																								 ELSE CAST(MONTH(ISNULL(facFecha, GETDATE())) AS VARCHAR(2)) END 
										FROM facturas fSub 
									   WHERE fSub.facCod=f.facCod AND fSub.facPerCod=f.facPerCod AND fSub.facCtrCod=f.facCtrCod AND fSub.facVersion=f.facVersion) 								 			
							END -- fcSiiPeriodo
						
						,(SELECT scdNif FROM sociedades AS SS WHERE f.facSerScdCod=SS.scdcod) --fcSiiIDEmisorFacturaNIF

						-- SIMPLIFICO LLAMANDO A LA FUNCIÓN
						,[dbo].[Facturas_CalcularFacNumeroAqua] (f.facSerCod, f.facSerScdCod, f.facFecha, f.facNumero) --fcSiiNumSerieFacturaEmisor		
						
						,(SELECT facfecha 
									FROM facturas fSub 
									WHERE fSub.facCod=f.facCod AND 
											fSub.facPerCod=f.facPerCod AND 
											fSub.facCtrCod=f.facCtrCod AND 
											fSub.facVersion=f.facVersion)--fcSiiFechaExpedicionFacturaEmisor
						,NULL --fcSiiIDEmisorFactura por si se emiten facturas de organismos, campo añadido de forma adicional, no especificado
						,CASE WHEN @esRectificativa = 1 AND @esPrefacturaCerrada = 0
								THEN (SELECT ISNULL(facTipoEmit,'R4') /*R4 Es el resto de facturas*/ FROM facturas fSub WHERE fSub.facCod=f.facCod AND fSub.facPerCod=f.facPerCod AND fSub.facCtrCod=f.facCtrCod AND fSub.facVersion=f.facVersion)
								ELSE 'F1'
							END--fcSiiTipoFactura
						,CASE WHEN @esRectificativa = 1 AND @esPrefacturaCerrada = 0
								THEN 'S'
								ELSE NULL
							END --TipoRectificativa, para Acuama solo S (Por sustitución)

							--*****************
							, fcSiiFraRecNumSerieFacturaEmisor = 
							----------------------
							CASE WHEN @esEmmasa=1  								
								--Cuando la explotación es EMMASA el numero se obtiene directamente de facturas.facNumeroAqua
								--FV es la versión anterior de la factura
								THEN FV.fvFacNumero
							----------------------
							-- SIMPLIFICO LLAMANDO A LA FUNCIÓN
							WHEN (@mismaVersionCtr = 0 OR @REENVIO=1)
								-- La función distingue el formato que debe llevar, si es AVG o si es otra explotación, o si tiene o no código alternativo
								THEN [dbo].[Facturas_CalcularFacNumeroAqua] (fv.fvFacSerCod, fv.fvFacSerScdCod, fv.fvFacFecha, fv.fvFacNumero)
								----------------------
							ELSE
								NULL
							END --fcSiiFraRecNumSerieFacturaEmisor

							, fcSiiFraRecFechaExpedicionFacturaEmisor = FV.fvFacFecha	
							--*****************

							,CASE WHEN @esRectificativa = 1 AND @esPrefacturaCerrada = 0
								THEN (SELECT  ISNULL(SUM(fclBase),0)
											FROM facturas fSub 
											INNER JOIN faclin 
											ON fclFacCod = fSub.facCod 
											AND fclFacPerCod = fSub.facPerCod 
											AND fclFacCtrCod = fSub.facCtrCod 
											AND fclFacVersion = fSub.facVersion
											WHERE fSub.facCod=f.facCod 
											AND fSub.facPerCod=f.facPerCod 
											AND fSub.facCtrCod=f.facCtrCod 
											AND fSub.facVersion=FV.fvFacVersion
											AND EXISTS(SELECT svccod FROM servicios WHERE svccod=fclTrfSvCod AND svcOrgCod IS NULL)) --Excluir los servicios que tengan un organismo establecido, ya que estos no viajarán al SII
								ELSE NULL --AQUÍ TODAVÍA NO TENEMOS LAS LÍNEAS DE FACTURA INSERTADAS POR ESO NO SE PUEDE HACER EL SUM
							END --BaseRectificada

							,CASE WHEN @esRectificativa = 1 AND @esPrefacturaCerrada = 0
								THEN (SELECT ISNULL(SUM(fclImpImpuesto),0)
											FROM facturas fSub 
											INNER JOIN faclin 
											ON fclFacCod = fSub.facCod 
											AND fclFacPerCod = fSub.facPerCod 
											AND fclFacCtrCod = fSub.facCtrCod 
											AND fclFacVersion = fSub.facVersion
											WHERE fSub.facCod=f.facCod 
											AND fSub.facPerCod=f.facPerCod 
											AND fSub.facCtrCod=f.facCtrCod 
											AND fSub.facVersion=FV.fvFacVersion
											AND EXISTS(SELECT svccod FROM servicios WHERE svccod=fclTrfSvCod AND svcOrgCod IS NULL)) --Excluir los servicios que tengan un organismo establecido, ya que estos no viajarán al SII
								ELSE NULL --AQUÍ TODAVÍA NO TENEMOS LAS LÍNEAS DE FACTURA INSERTADAS POR ESO NO SE PUEDE HACER EL SUM
							END --CuotaRectificada

							--,CASE WHEN @esRectificativa = 1 AND @esPrefacturaCerrada = 0
							--	THEN (SELECT ISNULL(facFecha, GETDATE()) FROM facturas fSub WHERE fSub.facCod=f.facCod AND fSub.facPerCod=f.facPerCod AND fSub.facCtrCod=f.facCtrCod AND fSub.facVersion=(f.facVersion - 1))
							--	ELSE ISNULL(facfecha, GETDATE())
							--END -- fcSiiFechaOperacion		
						
							-- Si es rectificativa se arrastra la fecha de operación de la factura original
							-- Hasta enero 2020 aplicábamos que ejercicio y periodo en una rectificativa tenía que ser el de la factura original.
							-- Por indicación de fiscal, se pone siempre el ejercicio y el periodo de la factura, sea rectificativa o no.
							,CASE 
							--	WHEN @esRectificativa = 1 AND @esPrefacturaCerrada = 0 THEN
							----		Si la original es de tracto sucesivo, la fecha de operación es la fecha devengo del periodo de la original						
							--	(CASE WHEN @originalEsTractoSucesivo = 1 THEN @originalFechaDevengo 
							----		Si la original no es de tracto sucesivo, la fecha de operación es la fecha factura de la original
							--	 ELSE @originalFacFecha END)
							--	Si es tracto sucesivo y no es rectificativa (habría pasado por el caso anterior), fecha devengo
								  WHEN @esTractoSucesivo = 1 THEN @fechaDevengo
							--	Si es anulación cogemos la fecha de la factura anterior
								WHEN @esAnulacion = 1 THEN CAST(YEAR(ISNULL(FV.fvFacFecha, GETDATE())) AS VARCHAR(4))
							--	Si no, fecha de factura							  
								  ELSE (SELECT ISNULL(facFecha, GETDATE())
										FROM facturas fSub 
									   WHERE fSub.facCod=f.facCod AND fSub.facPerCod=f.facPerCod AND fSub.facCtrCod=f.facCtrCod AND fSub.facVersion=f.facVersion)	
							END -- fcSiiFechaOperacion	
																									
							--,'01' --fcSiiClavRegEspOTras "Operación de régimen común"
							,CASE 
								WHEN @esTractoSucesivo = 1 
									--OR (@esRectificativa = 1 AND @originalEsTractoSucesivo = 1) 
								THEN '15' ELSE '01' END --fcSiiClavRegEspOTras "Operación de régimen común"
							,(SELECT ISNULL(SUM(fclTotal),0)
											FROM facturas fSub 
											INNER JOIN faclin ON fclFacCod = fSub.facCod AND fclFacPerCod = fSub.facPerCod AND fclFacCtrCod = fSub.facCtrCod AND fclFacVersion = fSub.facVersion
											WHERE fSub.facCod=f.facCod AND fSub.facPerCod=f.facPerCod AND fSub.facCtrCod=f.facCtrCod AND fSub.facVersion=f.facVersion
											AND EXISTS(SELECT svccod FROM servicios WHERE svccod=fclTrfSvCod AND svcOrgCod IS NULL)--Excluir los servicios que tengan un organismo establecido, ya que estos no viajarán al SII
							)--fcSiiImporteTotal 
						,(SELECT serdesc FROM dbo.series AS S WHERE S.sercod=f.facSerCod AND S.serscd=f.facSerScdCod) --DescripcionOperacion
						,(SELECT inmrefcatastral 
									FROM contratos
									inner join inmuebles on inmcod=ctrinmcod 
									WHERE ctrcod=f.facCtrCod AND ctrversion = f.facCtrVersion) --fcSiiDetInmRefCat
						,NULL --fcSiiEmitidaPorTerceros, si no se informa del campo tENDrá valor N --> No

						--DATOS CONTRAPARTE  (si fuera tipo factura F2 o R5, que no es el caso, los datos de la contraparte tendrían que ir a null)
						--si los datos del dni son correctos y es español
						, fcSiiContraparteNombreRazon =   
						  ISNULL(CASE WHEN @expl <> 'AVG' AND ISNULL(ctrPagDocIden, '') <> ''
									  THEN ctrPagNom 
									  WHEN @expl = 'AVG'  AND ISNULL(ctrPagDocIden, '') <> '' AND facPerCod NOT IN('000013','000015') 
									  THEN ctrPagNom 
									  ELSE ctrTitNom END 
								, 'Sin identificar') 
							 
							 --
						,NULL --fcSiiContraparteNIFRepresentante
						,CASE WHEN @esExtranjero = 0 OR @esExtranjero = 1 THEN 
							(SELECT CASE WHEN ((ISNULL(ctrPagDocIden, '') <> '') AND @expl <> 'AVG') OR (@expl = 'AVG' AND (ISNULL(ctrPagDocIden, '') <> '') AND facPerCod <> '000013' AND facPerCod <> '000015') THEN ctrPagDocIden ELSE ctrTitDocIden END FROM contratos WHERE ctrcod=f.facCtrCod AND ctrversion = f.facCtrVersion) 
							ELSE null
						END --fcSiiContraparteNIF
						--si los datos son de una persona EXTRANJERA, ES PASAPORTE o nos han devuelto un error por un DNI SIN IDENTIFICAR O NO VÁLIDO
						--debemos rellenar los datos de otro
						,CASE WHEN (@esExtranjero = 1 OR @esPasaporte = 1) THEN
							(SELECT patISoAlfa2 
								FROM contratos 
								inner join cat_pais on patIsoAlfa3 = CASE WHEN ((ISNULL(ctrPagDocIden, '') <> '') AND @expl <> 'AVG') OR (@expl = 'AVG' AND (ISNULL(ctrPagDocIden, '') <> '') AND facPerCod <> '000013' AND facPerCod <> '000015') THEN ISNULL(ctrPagNacionalidad, ctrPagNac) ELSE ISNULL(ctrTitNacionalidad, ctrTitNac) END
								WHERE ctrcod=f.facCtrCod AND ctrversion = f.facCtrVersion)
							ELSE null
							END --fcSiiContraparteIDOtro
						,CASE WHEN (@esExtranjero = 1 OR @esPasaporte = 1) THEN
							(SELECT didotroSII 
								FROM contratos 
								inner join dociden on didcod = CASE WHEN ((ISNULL(ctrPagDocIden, '') <> '') AND @expl <> 'AVG') OR (@expl = 'AVG' AND (ISNULL(ctrPagDocIden, '') <> '') AND facPerCod <> '000013' AND facPerCod <> '000015') THEN ctrPagTipDoc ELSE ctrTitTipDoc END
								WHERE ctrcod=f.facCtrCod AND ctrversion = f.facCtrVersion)
								ELSE null
							END --fcSiiContraparteIDType
						--Es el Documento de Identificación en cuado se cumpla que sea extranjero o hayan devuelto un error de 
						--DNI sin identificar o no válido
						,CASE WHEN (@esExtranjero = 1 OR @esPasaporte = 1) THEN
								(SELECT CASE WHEN ((ISNULL(ctrPagDocIden, '') <> '') AND @expl <> 'AVG') OR (@expl = 'AVG' AND (ISNULL(ctrPagDocIden, '') <> '') AND facPerCod <> '000013' AND facPerCod <> '000015') THEN ctrPagDocIden ELSE ctrTitDocIden END FROM contratos WHERE ctrcod=f.facCtrCod AND ctrversion = f.facCtrVersion) 
								ELSE null
							END --fcSiiContraparteID
						--FIN DATOS CONTRATPARTE
						--TECKECH
						,NULL --fcSiiLoteID
						,NULL --fcSiiestado
						,NULL --fcSiicodErr
						,NULL --fcSiidescErr
						,NULL --fcSiicsv
						--Fin Factura
					FROM inserted AS f
					--********************
					LEFT JOIN @FACV AS FV
					ON  f.facCod    = FV.fvFacCod
					AND f.facCtrCod = FV.fvFacCtrCod
					AND f.facPerCod = FV.fvFacPerCod
					LEFT JOIN contratos AS C 
					ON  C.ctrcod = f.facCtrCod 
					AND C.ctrversion = f.facCtrVersion
					--********************
					LEFT JOIN dbo.series AS S
					ON  S.sercod = F.facSerCod
					AND S.serscd = F.facSerScdCod
					--********************			
					WHERE
					(@esValdaliga = 1 AND S.serEnvSap = 1)
					OR 
					(@esValdaliga = 0 AND f.facSerScdCod = @scdFacturacion);


					DECLARE @periodo varchar(6) = (SELECT facPerCod FROM inserted)
					
					
					--********************
					--[FL01]Para insertar el desglose de la factura: No rectificativa, No hay cambio de versión en el contrato 
					--comentarios anteriores>>
					
					--CIERRE DE FACTURACIÓN: SOLO PARA LA VERSIÓN 1, LAS LÍNEAS DE LAS RECTIFICATIVAS SE INSERTARÁN EN LOS TRIGGERS DE FACLIN
					--SI ES FACTURAS DE CONSUMO HAY QUE INSERTAR LAS LÍNEAS DE DESGLOSE DE FACSII
					--((SELECT facCtrVersion FROM deleted) <> (SELECT facCtrVersion FROM inserted)) 
					--CONTROLAMOS QUE EN LAS FACTURAS DE CONTADO AL ACTUALIZAR LA VERSIÓN DEL CONTRATO EN LA FACTURA SE INSERTEN LOS DESGLOSES DEL NUEVO ENVÍO PARA ELLO
					--IF ((LEFT(@periodo,2)='20' AND @esRectificativa=0) OR ((SELECT facCtrVersion FROM deleted) <> (SELECT facCtrVersion FROM inserted)))
					--<<
					IF (@esRectificativa=0 OR @mismaVersionCtr=0 OR @REENVIO=1)
					BEGIN

						INSERT INTO [dbo].[facSIIDesgloseFactura]
							([fclSiiFacCod]
							,[fclSiiFacPerCod]
							,[fclSiiFacCtrCod]
							,[fclSiiFacVersion]
							,[fclSiiNumLinea]
							,[fclSiiNumEnvio]
							,[fclSiiCausaExencion]
							,[fclSiiTipoNoExenta]
							,[fclSiiEntrega]
							,[fclSiiTipoImpositivo]
							,[fclSiiBaseImponible]
							,[fclSiiCuotaRepercutida]
							,[fclSiiImpPorArt7_14_Otros]
							,[fclSiiImpTAIReglasLoc])

						--RELLENAR CAMPOS CON LOS DATOS DE LA FACTURAS INSERTADA/ACTUALIZADA
						SELECT fs.fclFacCod,
								fs.fclFacPerCod,
								fs.fclFacCtrCod,
								fs.fclFacVersion,
								fs.fclNumLinea
								, @fclSiiNumEnvio as fclSiiNumEnvio
								,(SELECT TOP 1 svccauExVal FROM servicios WHERE svccod=fs.fclTrfSvCod) --fclSiiCausaExencion
								,(SELECT TOP 1 svcFacSujNoExe FROM servicios WHERE svccod=fs.fclTrfSvCod) --fclSiiTipoNoExenta
								,(SELECT TOP 1 svcEntrega FROM servicios WHERE svccod=fs.fclTrfSvCod)--fclSiiEntrega
								,(SELECT fclImpuesto FROM faclin flSub WHERE flSub.fclFacCod=fs.fclFacCod AND flSub.fclFacPerCod=fs.fclFacPerCod AND flSub.fclFacCtrCod=fs.fclFacCtrCod AND flSub.fclFacVersion=fs.fclFacVersion AND flSub.fclNumLinea=fs.fclNumLinea AND flSub.fclTrfSvCod = fs.fclTrfSvCod AND flSub.fclTrfCod=fs.fclTrfCod) --fclSiiTipoImpositivo
								,(SELECT fclBase FROM faclin flSub WHERE flSub.fclFacCod=fs.fclFacCod AND flSub.fclFacPerCod=fs.fclFacPerCod AND flSub.fclFacCtrCod=fs.fclFacCtrCod AND flSub.fclFacVersion=fs.fclFacVersion AND flSub.fclNumLinea=fs.fclNumLinea AND flSub.fclTrfSvCod = fs.fclTrfSvCod AND flSub.fclTrfCod=fs.fclTrfCod) --fclSiiBaseImponible
								,(SELECT fclImpImpuesto FROM faclin flSub WHERE flSub.fclFacCod=fs.fclFacCod AND flSub.fclFacPerCod=fs.fclFacPerCod AND flSub.fclFacCtrCod=fs.fclFacCtrCod AND flSub.fclFacVersion=fs.fclFacVersion AND flSub.fclNumLinea=fs.fclNumLinea AND flSub.fclTrfSvCod = fs.fclTrfSvCod AND flSub.fclTrfCod=fs.fclTrfCod) --fclSiiCuotaRepercutida
								,NULL --fclSiiImpPorArt7_14_Otros
								,NULL --fclSiiImpTAIReglasLoc
							FROM inserted i
							inner join faclin fs on fs.fclfacCod=i.facCod AND fs.fclfacpercod=i.facpercod AND fs.fclfacctrcod=i.facctrcod AND fs.fclfacversion=i.facversion
							inner join servicios on svccod=fs.fclTrfSvCod
							WHERE svcOrgCod IS NULL --Excluir los servicios que tengan un organismo establecido, ya que estos no viajarán al SII
						
							IF @REENVIO=1 GOTO ACTUALIZAR_CABECERA;
						END

						--Al actualizar la versión del contrato en la factura y generar rectificatvia se inserta un registro de más porque se llama al actualizar factura
						--2 veces desde el código C#
						IF (EXISTS(SELECT fcsiifaccod
										FROM facsii f1
										INNER JOIN inserted i ON i.facCod=@facCod AND i.facpercod=@facPerCod AND i.facctrcod=@facCtrCod AND i.facVersion=@facVersion
										WHERE f1.fcsiifacCod=@facCod  AND
											f1.fcsiifacPerCod=@facPerCod AND
											f1.fcsiifacCtrCod=@facCtrCod AND
											f1.fcsiifacVersion=@facVersion 
											AND f1.fcsiiNumEnvio=@fclSiiNumEnvio
											AND EXISTS(SELECT fcSiiFacCod 
																FROM facsii f2
																WHERE f2.fcSiiFacCod=f1.fcSiiFacCod AND
																		f2.fcSiiFacPerCod=f1.fcSiiFacPerCod AND
																		f2.fcSiiFacCtrCod=f1.fcSiiFacCtrCod AND
																		f2.fcSiiFacVersion=f1.fcSiiFacVersion AND
																		f2.fcSiiNumEnvio = (@fclSiiNumEnvio-1) AND
																		ISNULL(f2.fcsiiNumSerieFacturaEmisor, '')=ISNULL(f1.fcsiiNumSerieFacturaEmisor, '') AND
																		ISNULL(f2.fcsiiFechaExpedicionFacturaEmisor, GETDATE())=ISNULL(f1.fcsiiFechaExpedicionFacturaEmisor,GETDATE()) AND
																		ISNULL(f2.fcsiiTipoFactura,'')=ISNULL(f1.fcsiiTipoFactura,'') AND
																		ISNULL(f2.TipoRectificativa,'')=ISNULL(f1.TipoRectificativa,'') AND
																		ISNULL(f2.fcsiiFraRecNumSerieFacturaEmisor,'')=ISNULL(f1.fcsiiFraRecNumSerieFacturaEmisor,'') AND
																		ISNULL(f2.fcsiiFraRecFechaExpedicionFacturaEmisor,GETDATE())=ISNULL(f1.fcsiiFraRecFechaExpedicionFacturaEmisor,GETDATE()) AND
																		ISNULL(f2.BaseRectificada,0)=ISNULL(f1.BaseRectificada,0) AND
																		ISNULL(f2.CuotaRectificada,0)=ISNULL(f1.CuotaRectificada,0) AND
																		ISNULL(f2.fcsiiFechaOperacion,GETDATE())=ISNULL(f1.fcsiiFechaOperacion,GETDATE()) AND
																		ISNULL(f2.DescripcionOperacion,'')=ISNULL(f1.DescripcionOperacion,'') AND
																		f2.fcsiiLoteID IS NULL AND
																		f2.fcsiiestado IS NULL AND
																		f2.fcsiicoderr IS NULL AND
																		f2.fcsiidescErr IS NULL AND
																		f2.fcsiicsv IS NULL)--segundo exists
										)--primer exists
							) --if
							BEGIN
								--Borro el registro sobrante porque desde el código C# se llama 2 veces a actualizar factura e inserta 2 facsii
								DELETE facsiidesglosefactura WHERE fclSiiFacCod=@facCod AND fclSiiFacPerCod=@facPerCod AND fclSiiFacCtrCod=@facCtrCod AND fclSiiFacVersion=@facVersion AND fclSiiNumEnvio=(@fclSiiNumEnvio-1)
								DELETE facsii WHERE fcSiiFacCod=@facCod AND fcSiiFacPerCod=@facPerCod AND fcSiiFacCtrCod=@facCtrCod AND fcSiiFacVersion=@facVersion AND fcSiiNumEnvio=(@fclSiiNumEnvio-1)
								--Actualizo el número de envío del facsii con los datos de la última versión del contrato actualizada en la factura
								ALTER TABLE facsiidesglosefactura NOCHECK CONSTRAINT ALL
								ALTER TABLE facsii NOCHECK CONSTRAINT ALL
									UPDATE facsiidesglosefactura SET fclSiiNumEnvio=(@fclSiiNumEnvio - 1) WHERE fclSiiFacCod=@facCod AND fclSiiFacPerCod=@facPerCod AND fclSiiFacCtrCod=@facCtrCod AND fclSiiFacVersion=@facVersion AND fclSiiNumEnvio=@fclSiiNumEnvio
									UPDATE facsii SET fcSiiNumEnvio=(@fclSiiNumEnvio - 1) WHERE fcSiiFacCod=@facCod AND fcSiiFacPerCod=@facPerCod AND fcSiiFacCtrCod=@facCtrCod AND fcSiiFacVersion=@facVersion AND fcSiiNumEnvio=@fclSiiNumEnvio
								ALTER TABLE facsiidesglosefactura CHECK CONSTRAINT ALL
								ALTER TABLE facsii CHECK CONSTRAINT ALL
							END
					END
			END
		END

		ACTUALIZAR_CABECERA:
		--NO HACEMOS NADA

		commit transaction; --TRIGGER  [dbo].[facturas_SII]

END TRY
BEGIN CATCH
	
	DECLARE @erlNumber INT = (SELECT ERROR_NUMBER());
	DECLARE @erlSeverity INT = (SELECT ERROR_SEVERITY());
	DECLARE @erlState INT = (SELECT ERROR_STATE());
	DECLARE @erlProcedure nvarchar(128) = (SELECT ERROR_PROCEDURE());
	DECLARE @erlLine int = (SELECT ERROR_LINE());
	DECLARE @erlMessage nvarchar(4000) = (SELECT ERROR_MESSAGE());
	
	DECLARE @erlParams varchar(500) = 'ctrcod = ' + ISNULL(CAST(@facCtrCod AS VARCHAR), 'NULL') 
							+ ' ; '	+ 'facCod = ' + ISNULL(CAST(@facCod AS VARCHAR), 'NULL') 
							+ ' ; ' + 'facPerCod = ' + ISNULL(CAST(@facPerCod AS VARCHAR), 'NULL')
							+ ' ; '	+ 'facVersion = ' + ISNULL(CAST(@facVersion AS VARCHAR), 'NULL');

	rollback transaction;
	
    BEGIN TRAN
		EXEC ErrorLog_Insert  @expl, 'TRIGGER  [dbo].[facturas_SII]', @erlNumber, @erlSeverity, @erlState, @erlProcedure, @erlLine, @erlMessage, @erlParams	
	COMMIT TRAN
	
END CATCH

END

GO


