ALTER TRIGGER  [dbo].[faclin_InsertDesglosesSII]
			ON  [dbo].[faclin]
	   AFTER INSERT
	AS
	BEGIN
		SET NOCOUNT ON;
		--******************
		--[01]Obtenemos el nombre de la explotacion
		--El SII varía según la explotación: AVG, EMMASA, Otras:
		DECLARE @expl VARCHAR(20) = NULL;
		DECLARE @esEmmasa BIT = 0; 
		DECLARE @esAVG BIT = 0; 

		SET @expl = (SELECT pgsvalor FROM parametros WHERE pgsclave = 'EXPLOTACION');		
		SET @esEmmasa	= IIF(@expl = 'Emmasa', 1, 0);
		SET @esAVG		= IIF(@expl = 'AVG', 1, 0);

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
		ON  I.fclFacCod = F.facCod
		AND I.fclFacPerCod = F.facPerCod
		AND I.fclFacCtrCod = F.facCtrCod
		AND (I.fclFacVersion IS NULL OR F.facVersion < I.fclFacVersion) )

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



		---INSERCIÓN DEL DESGLOSE DE FACTURAS SII
		--OBTENEMOS EL MÁXIMO NÚMERO DE ENVÍO EXISTENTE EN LA TABLA FACSII PARA EL PARTICIONADO DEL NÚMERO DE LÍNEA
		--CON ESTO EN CADA NUEVO ENVÍO SE INICIALIZARÁ EL CONTADOR DEL NÚMERO DE LÍNEA DESDE 1 EN ADELANTE
		DECLARE @fclSiiNumEnvio INT = 0		
		SELECT @fclSiiNumEnvio = (SELECT ISNULL(MAX(fcSiiNumEnvio),0)
										FROM inserted i
										INNER JOIN facSII ON fcSiiFacCod = i.fclFacCod AND fcSiiFacPerCod = i.fclFacPerCod AND fcSiiFacCtrCod = i.fclFacCtrCod AND fcSiiFacVersion = i.fclFacVersion)

		--Excluir los servicios que tengan un organismo establecido, ya que estos no viajarán al SII
		DECLARE @organismo BIT = 0
		IF EXISTS(select svccod 
						 from servicios
						 inner join inserted i on i.fclTrfSvCod=svccod 
						 where svcOrgCod IS NOT NULL)
			SET @organismo = 1
		
		DECLARE @hayNumeroFactura BIT = 0
		IF EXISTS(select facCod 
						 FROM inserted i
						 INNER JOIN facturas ON i.fclFacCod=facCod AND i.fclFacPerCod=facPerCod AND i.fclFacCtrCod=facCtrCod AND i.fclFacVersion=facVersion
						 where facNumero IS NOT NULL)
			SET @hayNumeroFactura = 1
		
		--Es Factura Rectificada
		DECLARE @esRectificativa BIT = 0
		IF EXISTS(SELECT fclfaccod FROM inserted f WHERE fclfacVersion > 1)
			SET @esRectificativa = 1

		DECLARE @envioSAP BIT = ISNULL((select TOP 1 facEnvSap
												FROM inserted i
												INNER JOIN facturas ON i.fclFacCod=facCod AND i.fclFacPerCod=facPerCod AND i.fclFacCtrCod=facCtrCod AND i.fclFacVersion=facVersion
										),0)

		IF (@envioSAP = 0 AND @esRectificativa = 1)
		BEGIN
			SELECT  @envioSAP = serEnvSap
			FROM INSERTED AS I
			INNER JOIN dbo.facturas AS F
			ON  F.facCod = I.fclFacCod
			AND F.facPerCod = I.fclFacPerCod
			AND F.facCtrCod = I.fclFacCtrCod
			AND F.facVersion = I.fclFacVersion
			AND F.facNumero IS NOT NULL
			INNER JOIN dbo.series AS S
			ON S.sercod = F.facSerCod
			AND S.serscd = F.facSerScdCod;
		END
		
		IF (@organismo = 0 AND @hayNumeroFactura = 1 AND @envioSAP = 1)
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
					,@fclSiiNumEnvio as fclSiiNumEnvio
					,(select svccauExVal from servicios where svccod=fs.fclTrfSvCod) --fclSiiCausaExencion
					,(select svcFacSujNoExe from servicios where svccod=fs.fclTrfSvCod) --fclSiiTipoNoExenta
					,(select svcEntrega from servicios where svccod=fs.fclTrfSvCod)--fclSiiEntrega
					,(select fclImpuesto from faclin flSub where flSub.fclFacCod=fs.fclFacCod and flSub.fclFacPerCod=fs.fclFacPerCod and flSub.fclFacCtrCod=fs.fclFacCtrCod and flSub.fclFacVersion=fs.fclFacVersion and flSub.fclNumLinea=fs.fclNumLinea and flSub.fclTrfSvCod = fs.fclTrfSvCod and flSub.fclTrfCod=fs.fclTrfCod) --fclSiiTipoImpositivo
					,(select fclBase from faclin flSub where flSub.fclFacCod=fs.fclFacCod and flSub.fclFacPerCod=fs.fclFacPerCod and flSub.fclFacCtrCod=fs.fclFacCtrCod and flSub.fclFacVersion=fs.fclFacVersion and flSub.fclNumLinea=fs.fclNumLinea and flSub.fclTrfSvCod = fs.fclTrfSvCod and flSub.fclTrfCod=fs.fclTrfCod) --fclSiiBaseImponible
					,(select fclImpImpuesto from faclin flSub where flSub.fclFacCod=fs.fclFacCod and flSub.fclFacPerCod=fs.fclFacPerCod and flSub.fclFacCtrCod=fs.fclFacCtrCod and flSub.fclFacVersion=fs.fclFacVersion and flSub.fclNumLinea=fs.fclNumLinea and flSub.fclTrfSvCod = fs.fclTrfSvCod and flSub.fclTrfCod=fs.fclTrfCod) --fclSiiCuotaRepercutida
					,NULL --fclSiiImpPorArt7_14_Otros
					,NULL --fclSiiImpTAIReglasLoc
			FROM inserted fs
		
			DECLARE @fclSiiFacCod SMALLINT = NULL		
			DECLARE @fclSiiFacPerCod VARCHAR(6) = NULL
			DECLARE @fclSiiFacCtrCod INT = NULL
			DECLARE @fclSiiFacVersion SMALLINT = NULL
			DECLARE @fclSiiNumLinea INT = NULL

			SET @fclSiiFacCod = (select i.fclFacCod from inserted i)
			SET @fclSiiFacPerCod = (select i.fclFacPerCod from inserted i)
			SET @fclSiiFacCtrCod = (select i.fclFacCtrCod from inserted i)
			SET @fclSiiFacVersion = (select i.fclFacVersion from inserted i)
			SET @fclSiiNumLinea = (select i.fclNumLinea from inserted i)
		
		
			DECLARE @fclTotalAux MONEY = (SELECT ISNULL(SUM(i.fclTotal),0) 
													FROM faclin i
													INNER JOIN facturas fs on fs.facCod=i.fclfacCod and fs.facpercod=i.fclfacpercod and fs.facctrcod=i.fclfacctrcod and fs.facversion=i.fclfacversion
													WHERE i.fclFacCod=@fclSiiFacCod AND
														  i.fclFacPerCod=@fclSiiFacPerCod AND
														  i.fclFacCtrCod=@fclSiiFacCtrCod AND
														  i.fclFacVersion=@fclSiiFacVersion AND
														  EXISTS(select svccod from servicios where svccod=fclTrfSvCod and svcOrgCod IS NULL)) --Excluir los servicios que tengan un organismo establecido, ya que estos no viajarán al SII
		
			DECLARE @importeLinea INT = 0		
			SELECT @importeLinea = (SELECT ISNULL(i.fclTotal,0)	FROM inserted i)

			DECLARE @esAnulada BIT = 0
			IF (0=@fclTotalAux AND @importeLinea = 0)
				set @esAnulada = 1

			----------------------------------------------------	
			--CASO EN EL CUAL SE EDITA LA FACTURA CON VERSION 1 EL DÍA QUE SE CREA Y SE MODIFICA CABECERA O SUS LÍNEAS, POR EJEMPLO EL CONSUMO
			----------------------------------------------------

			IF(@fclSiiFacVersion = 1)
				BEGIN 
					update fs 
						set fs.fcSiiImporteTotal = @fclTotalAux
						from facsii fs
						WHERE fs.fcSiiFacCod = @fclSiiFacCod and
									fs.fcSiiFacPerCod = @fclSiiFacPerCod and
									fs.fcSiiFacCtrCod = @fclSiiFacCtrCod  and 
									fs.fcSiiFacVersion = @fclSiiFacVersion and
									fs.fcSiiNumEnvio = @fclSiiNumEnvio
				END
			ELSE

			----------------------------------------------------
			--CASO EN EL CUAL SE HACE UNA RECTIFICATIVA DE UNA PREFACTURA CERRADA
			----------------------------------------------------

				BEGIN				
				--PRIMERO VEMOS SI EL PERIODO ESTÁ CERRADO Y ADEMÁS ES UNA PREFACTURA EN SU VERSION ANTERIOR (facNumero IS NULL)
				--SE DEBE DEJAR EL FACSII COMO UN PRIMER NÚMERO DE ENVÍO, CON F1
				DECLARE @esPeriodoCerrado bit = 0
				EXEC Perzona_Exists	@fclSiiFacPerCod,1, @esPeriodoCerrado output, NULL
				IF(@esPeriodoCerrado=1 AND 
					EXISTS(SELECT facCod 
								 FROM facturas 
								 WHERE facCod=@fclSiiFacCod AND
									   facPerCod=@fclSiiFacPerCod AND
									   facCtrCod=@fclSiiFacCtrCod AND
									   facVersion=(@fclSiiFacVersion - 1) AND
									   facNumero IS NULL)
				  )	
				  BEGIN
					update fs 
						set fs.fcSiiImporteTotal = @fclTotalAux,
							fs.fcSiiTipoFactura = 'F1',
							fs.tipoRectificativa = NULL,
							fs.BaseRectificada=NULL,
							fs.CuotaRectificada=NULL
						from facsii fs
						WHERE fs.fcSiiFacCod = @fclSiiFacCod and
									fs.fcSiiFacPerCod = @fclSiiFacPerCod and
									fs.fcSiiFacCtrCod = @fclSiiFacCtrCod  and 
									fs.fcSiiFacVersion = @fclSiiFacVersion and
									fs.fcSiiNumEnvio = @fclSiiNumEnvio
				END	

				----------------------------------------------------				
				--RECTIFICATIVA ANULADA
				----------------------------------------------------

				ELSE IF @esAnulada=1 
					BEGIN --SI ES UNA ANULACIÓN TENEMOS QUE ACTUALIZAR EL CAMPO TIPO FACTURA DE LA TABLA FACSII AL VALOR 'AN'
							UPDATE fs 
							SET fs.fcSIITipoFactura = 'AN',
								--*****************
								fs.fcSIIFraRecNumSerieFacturaEmisor=NULL,
								fs.fcSIIFraRecFechaExpedicionFacturaEmisor=NULL,
								--*****************
								fs.fcSIINumSerieFacturaEmisor=ISNULL((select fcSIINumSerieFacturaEmisor
																from facsii fSub 
																WHERE fSub.fcSIIfacCod=fs.fcSIIfacCod and 
																		fSub.fcSIIfacPerCod=fs.fcSiiFacPerCod and 
																		fSub.fcSIIfacCtrCod=fs.fcSiiFacCtrCod and 
																		fSub.fcSIIfacVersion=(fs.fcSiiFacVersion - 1) and
																		fSub.fcSIINumEnvio=(fs.fcSiiNumEnvio - 1)),

																-- SIMPLIFICO LLAMANDO A LA FUNCIÓN
																[dbo].[Facturas_CalcularFacNumeroAqua_porPK] (@fclSiiFacCod, @fclSiiFacPerCod, @fclSiiFacCtrCod, @fclSiiFacVersion-1)),		

								fs.fcSIIFechaExpedicionFacturaEmisor=ISNULL((select fcSIIFechaExpedicionFacturaEmisor
																		from facsii fSub 
																		WHERE fSub.fcSIIfacCod=fs.fcSIIfacCod and 
																				fSub.fcSIIfacPerCod=fs.fcSiiFacPerCod and 
																				fSub.fcSIIfacCtrCod=fs.fcSiiFacCtrCod and 
																				fSub.fcSIIfacVersion=(fs.fcSiiFacVersion - 1) and
																				fSub.fcSIINumEnvio=(fs.fcSiiNumEnvio - 1)),
																  (select facfecha 
																		FROM facturas i
																		WHERE i.facCod=@fclSiiFacCod AND
																			  i.facPerCod=@fclSiiFacPerCod AND
																			  i.facCtrCod=@fclSiiFacCtrCod AND
																			  i.facVersion=(@fclSiiFacVersion - 1)
																)
															),

								--	Si es anulación cogemos el ejercicio desde la fecha de la versión anterior
							    fs.fcSiiEjercicio=CAST(YEAR(ISNULL(FV.fvFacFecha, GETDATE())) AS VARCHAR(4)),

								--fs.fcSiiEjercicio=ISNULL((select CAST(YEAR(fcSIIFechaExpedicionFacturaEmisor) AS VARCHAR(4))
								--										from facsii fSub 
								--										WHERE fSub.fcSIIfacCod=fs.fcSIIfacCod and 
								--												fSub.fcSIIfacPerCod=fs.fcSiiFacPerCod and 
								--												fSub.fcSIIfacCtrCod=fs.fcSiiFacCtrCod and 
								--												fSub.fcSIIfacVersion=(fs.fcSiiFacVersion - 1) and
								--												fSub.fcSIINumEnvio=(fs.fcSiiNumEnvio - 1)),
								--							(select CAST(YEAR(facFecha) AS VARCHAR(4))
								--										FROM facturas i
								--										WHERE i.facCod=@fclSiiFacCod AND
								--											  i.facPerCod=@fclSiiFacPerCod AND
								--											  i.facCtrCod=@fclSiiFacCtrCod AND
								--											  i.facVersion=(@fclSiiFacVersion - 1)
								--							  )
								--						),

								--	Si es anulación cogemos el periodo desde la fecha de la versión anterior
								fs.fcSIIPeriodo=RIGHT(CONCAT('00', MONTH(FV.fvFacFecha)), 2),

								--fs.fcSIIPeriodo=ISNULL((select CASE WHEN MONTH(fcSIIFechaExpedicionFacturaEmisor) < 10 THEN '0' + CAST(MONTH(fcSIIFechaExpedicionFacturaEmisor) AS VARCHAR(1)) ELSE CAST(MONTH(fcSIIFechaExpedicionFacturaEmisor) AS VARCHAR(2)) END
								--										from facsii fSub 
								--										WHERE fSub.fcSIIfacCod=fs.fcSIIfacCod and 
								--												fSub.fcSIIfacPerCod=fs.fcSiiFacPerCod and 
								--												fSub.fcSIIfacCtrCod=fs.fcSiiFacCtrCod and 
								--												fSub.fcSIIfacVersion=(fs.fcSiiFacVersion - 1) and
								--												fSub.fcSIINumEnvio=(fs.fcSiiNumEnvio - 1)),
								--								(select CASE WHEN MONTH(facFecha) < 10 THEN '0' + CAST(MONTH(facFecha) AS VARCHAR(1)) ELSE CAST(MONTH(facFecha) AS VARCHAR(2)) END 
								--										FROM facturas i
								--										WHERE i.facCod=@fclSiiFacCod AND
								--											  i.facPerCod=@fclSiiFacPerCod AND
								--											  i.facCtrCod=@fclSiiFacCtrCod AND
								--											  i.facVersion=(@fclSiiFacVersion - 1)
								--								)
								--							),

								fs.fcSiiImporteTotal = @fclTotalAux,
								fs.BaseRectificada=(SELECT ISNULL(SUM(i.fclBase),0) 
															FROM faclin i
															INNER JOIN facturas fs on fs.facCod=i.fclfacCod and fs.facpercod=i.fclfacpercod and fs.facctrcod=i.fclfacctrcod and fs.facversion=i.fclfacversion
															WHERE i.fclFacCod=@fclSiiFacCod AND
																	i.fclFacPerCod=@fclSiiFacPerCod AND
																	i.fclFacCtrCod=@fclSiiFacCtrCod AND
																	i.fclFacVersion=@fclSiiFacVersion AND
																	EXISTS(select svccod from servicios where svccod=fclTrfSvCod and svcOrgCod IS NULL)), --Excluir los servicios que tengan un organismo establecido, ya que estos no viajarán al SII
								fs.CuotaRectificada=(SELECT ISNULL(SUM(i.fclImpImpuesto),0) 
															FROM faclin i
															INNER JOIN facturas fs on fs.facCod=i.fclfacCod and fs.facpercod=i.fclfacpercod and fs.facctrcod=i.fclfacctrcod and fs.facversion=i.fclfacversion
															WHERE i.fclFacCod=@fclSiiFacCod AND
																	i.fclFacPerCod=@fclSiiFacPerCod AND
																	i.fclFacCtrCod=@fclSiiFacCtrCod AND
																	i.fclFacVersion=@fclSiiFacVersion AND
																	EXISTS(select svccod from servicios where svccod=fclTrfSvCod and svcOrgCod IS NULL)) --Excluir los servicios que tengan un organismo establecido, ya que estos no viajarán al SII
							from facsii fs
							--********************
							LEFT JOIN @FACV AS FV
							ON  fs.fcSiiFacCod = FV.fvFacCod
							AND fs.fcSiiFacCtrCod = FV.fvFacCtrCod
							AND fs.fcSiiFacPerCod = FV.fvFacPerCod
							--********************
							WHERE fs.fcSiiFacCod = @fclSiiFacCod and
										fs.fcSiiFacPerCod = @fclSiiFacPerCod and
										fs.fcSiiFacCtrCod = @fclSiiFacCtrCod  and 
										fs.fcSiiFacVersion = @fclSiiFacVersion and
										fs.fcSiiNumEnvio = @fclSiiNumEnvio
					END

					----------------------------------------------------
					--RECTIFICATIVA CON IMPORTE
					----------------------------------------------------

					ELSE
						UPDATE fs 
						SET fs.fcSIITipoFactura = CASE WHEN @esRectificativa = 1 THEN 
														(select ISNULL(facTipoEmit,'R4') /*R4 Es el resto de facturas*/ 
																from facturas fSub 
																WHERE fSub.facCod=fs.fcSiiFacCod and fSub.facPerCod=fs.fcSiiFacPerCod and fSub.facCtrCod=fs.fcSiiFacCtrCod and fSub.facVersion=fs.fcSiiFacVersion)
														ELSE 'F1'
													END

								--*****************					
								, fs.fcSIIFraRecNumSerieFacturaEmisor = 
								CASE WHEN @esEmmasa=1 
										--Cuando la explotación es EMMASA el numero se obtiene directamente de facturas.facNumeroAqua
										--FV es la versión anterior de la factura
										THEN FV.fvFacNumero
									----------------------
									----------------------
									-- SIMPLIFICO LLAMANDO A LA FUNCIÓN
									WHEN @esAVG= 1 OR FV.fvFacSerCodAlt IS NULL									
										-- La función distingue el formato que debe llevar, si es AVG o si es otra explotación, o si tiene o no código alternativo
										THEN [dbo].[Facturas_CalcularFacNumeroAqua] (fv.fvFacSerCod, fv.fvFacSerScdCod, fv.fvFacFecha, fv.fvFacNumero)
									----------------------
									ELSE 
										NULL
									END

								, fs.fcSIIFraRecFechaExpedicionFacturaEmisor = FV.fvFacFecha
								--*****************

								, fs.fcSiiImporteTotal = @fclTotalAux,
								fs.BaseRectificada = (SELECT ISNULL(SUM(i.fclBase),0) 
															FROM faclin i
															INNER JOIN facturas fs on fs.facCod=i.fclfacCod and fs.facpercod=i.fclfacpercod and fs.facctrcod=i.fclfacctrcod and fs.facversion=i.fclfacversion
															WHERE i.fclFacCod=@fclSiiFacCod AND
																	i.fclFacPerCod=@fclSiiFacPerCod AND
																	i.fclFacCtrCod=@fclSiiFacCtrCod AND
																	i.fclFacVersion=(@fclSiiFacVersion - 1) AND
																	EXISTS(select svccod from servicios where svccod=fclTrfSvCod and svcOrgCod IS NULL))--Excluir los servicios que tengan un organismo establecido, ya que estos no viajarán al SII 
								,fs.CuotaRectificada = (SELECT ISNULL(SUM(i.fclImpImpuesto),0) 
															FROM faclin i
															INNER JOIN facturas fs on fs.facCod=i.fclfacCod and fs.facpercod=i.fclfacpercod and fs.facctrcod=i.fclfacctrcod and fs.facversion=i.fclfacversion
															WHERE i.fclFacCod=@fclSiiFacCod AND
																	i.fclFacPerCod=@fclSiiFacPerCod AND
																	i.fclFacCtrCod=@fclSiiFacCtrCod AND
																	i.fclFacVersion=(@fclSiiFacVersion - 1) AND
																	EXISTS(select svccod from servicios where svccod=fclTrfSvCod and svcOrgCod IS NULL)) --Excluir los servicios que tengan un organismo establecido, ya que estos no viajarán al SII				

								,fs.fcSIINumSerieFacturaEmisor = CASE WHEN fs.fcSIITipoFactura = 'AN' THEN 
																		-- SIMPLIFICO LLAMANDO A LA FUNCIÓN
																		[dbo].[Facturas_CalcularFacNumeroAqua_porPK] (@fclSiiFacCod, @fclSiiFacPerCod, @fclSiiFacCtrCod, @fclSiiFacVersion)
	  																  ELSE fs.fcSIINumSerieFacturaEmisor END

								,fs.fcSIIFechaExpedicionFacturaEmisor = CASE WHEN fs.fcSIITipoFactura = 'AN' THEN 
																			(SELECT facfecha 
																			 FROM facturas i
																			 WHERE 
																				i.facCod=@fclSiiFacCod AND
																				i.facPerCod=@fclSiiFacPerCod AND
																				i.facCtrCod=@fclSiiFacCtrCod AND
																				i.facVersion=@fclSiiFacVersion)
																		ELSE fs.fcSIIFechaExpedicionFacturaEmisor END
								,fs.fcSiiEjercicio = CASE WHEN fs.fcSIITipoFactura = 'AN' THEN 
														 (SELECT CAST(YEAR(facFecha) AS VARCHAR(4))
														  FROM facturas i
														  WHERE 
															i.facCod=@fclSiiFacCod AND
															i.facPerCod=@fclSiiFacPerCod AND
															i.facCtrCod=@fclSiiFacCtrCod AND
															i.facVersion=@fclSiiFacVersion)
													 ELSE fs.fcSiiEjercicio END
								,fs.fcSIIPeriodo = CASE WHEN fs.fcSIITipoFactura = 'AN' THEN 
													   (SELECT 
															CASE WHEN MONTH(facFecha) < 10 THEN '0' + CAST(MONTH(facFecha) AS VARCHAR(1)) ELSE CAST(MONTH(facFecha) AS VARCHAR(2)) END 
														FROM facturas i
														WHERE i.facCod=@fclSiiFacCod AND
															  i.facPerCod=@fclSiiFacPerCod AND
															  i.facCtrCod=@fclSiiFacCtrCod AND
															  i.facVersion=@fclSiiFacVersion)
													ELSE fs.fcSIIPeriodo END
							FROM facsii AS fs
							--********************
							LEFT JOIN @FACV AS FV
							ON  fs.fcSiiFacCod = FV.fvFacCod
							AND fs.fcSiiFacCtrCod = FV.fvFacCtrCod
							AND fs.fcSiiFacPerCod = FV.fvFacPerCod
							--********************
							WHERE fs.fcSiiFacCod = @fclSiiFacCod and
							fs.fcSiiFacPerCod = @fclSiiFacPerCod and
							fs.fcSiiFacCtrCod = @fclSiiFacCtrCod  and 
							fs.fcSiiFacVersion = @fclSiiFacVersion and
							fs.fcSiiNumEnvio = @fclSiiNumEnvio
				END
			END
		END





GO


