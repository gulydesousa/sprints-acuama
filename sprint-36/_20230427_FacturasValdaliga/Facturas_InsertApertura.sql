/*
DECLARE @soloAnyadirServicios BIT = 0; 
DECLARE @facPerCod VARCHAR(6)='202101';
DECLARE @facCtrCod INT=1300;            
DECLARE @facCtrVersion SMALLINT=3;     
DECLARE @facClicod INT=4370;              
DECLARE @facZonCod VARCHAR(4)=66;       
DECLARE @facLecAnt INT = 11143;       
DECLARE @facLecAntFec DATETIME ='20201021';
DECLARE @user VARCHAR(10) = NULL;    

--Para obtener los precios de las tarifas	
DECLARE @ctrFecIni DATETIME='20210305';         
DECLARE @ctrFecAnu DATETIME;         
DECLARE @fechaPeriodoDesde DATETIME='20210101';
DECLARE @fechaPeriodoHasta DATETIME='20210331';

--Parámetros de salida
DECLARE @serviciosInsertados INT = 0;
DECLARE @facturaInsertada BIT = 0;

EXEC  [dbo].[Facturas_InsertApertura] @soloAnyadirServicios
, @facPerCod
, @facCtrCod
, @facCtrVersion
, @facClicod
, @facZonCod
, @facLecAnt
, @facLecAntFec
, @user
, @ctrFecIni
, @ctrFecAnu
, @fechaPeriodoDesde
, @fechaPeriodoHasta
, @serviciosInsertados
, @facturaInsertada
*/

ALTER PROCEDURE [dbo].[Facturas_InsertApertura]
    @soloAnyadirServicios BIT = NULL, --Si es TRUE sólo añade servicios nuevos a la factura existente, no crea cabecera
	@facPerCod VARCHAR(6),       --Periodo
	@facCtrCod INT,              --Código del contrato
	@facCtrVersion SMALLINT,     --Versión del contrato
	@facClicod INT,              --Cliente
	@facZonCod VARCHAR(4),       --Zona
	@facLecAnt INT = NULL,       --Lectura anterior
	@facLecAntFec DATETIME = NULL,--Fecha lectura anterior
	@user VARCHAR(10) = NULL,    --Usuario que realiza la acción

	--Para obtener los precios de las tarifas	
	@ctrFecIni DATETIME,         --fechaAltaContrato
	@ctrFecAnu DATETIME,         --fechaBajaContrato
	@fechaPeriodoDesde DATETIME,
	@fechaPeriodoHasta DATETIME,

	--Parámetros de salida
	@serviciosInsertados INT = 0 OUT,
	@facturaInsertada BIT = 0 OUT

AS
BEGIN
	SET NOCOUNT ON;
	--**********
	--AVG LEEME:
	--[01]Los desgloses de las tarifas se hacen por la FECHA DE LECTURA
	--
	--[02]Si NO HAY DIAS ENTRE LECTURAS se utiliza la FECHA DEL PERIODO para recuperar los servicios
	--Aunque una vez cargadas las lecturas las tarifas pueden cambiar.
	---
	--[03]Si es la PRIMERA FACTURA DE CONSUMO tras el alta las fechas que se usan para el prorrateo son:
	--[F.LECTURA ANTERIOR - F.PERIODO HASTA]
	--
	--[04]Si haces ampliación de apertura con desglose de tarifas: 
	--En la tabla @DESGLOSECONSUMOS al final de este SP hace una actualización por fechas
	--
	--[05]Si llamaras la funcionalidad para desglose de lineas y necesitas volver a ampliar la apertura
	--Debes borrar la fecha en perzona PRZFECULTIMODESGLOSE
	--Debes borrar las lineas de la tabla de desglose FACLINDESGLOSE
	--**********
	
	--****DEBUG*********
	--SELECT 'IA', soloAnyadirServicios=@soloAnyadirServicios, @facPerCod, @facCtrCod, @facCtrVersion, @facClicod, @facZonCod, @facLecAnt, @facLecAntFec, @user, [@ctrFecIni]= @ctrFecIni, @ctrFecAnu, fechaPeriodoDesde=@fechaPeriodoDesde, @fechaPeriodoHasta;
	--******************

	--*********************************************
	--Para obtener el facCod a insertar, ya puede ser > 1 desde AVG en el momento de dar de baja un contrato si previamente crearon otra factura de baja para devolver fianza
	DECLARE @facCod INT = 1;
	DECLARE @esBaja BIT = IIF(@facPerCod = '000002', 1, 0);
	
	--***Control Errores***
	DECLARE @erlNumber as INT 
	DECLARE @erlSeverity as INT 
	DECLARE @erlState as  INT
	DECLARE @erlProcedure as  nvarchar(128) 
	DECLARE @erlLine as int
	DECLARE @erlMessage as nvarchar(4000)
	DECLARE @erlParams varchar(500);
	--********************
			
	DECLARE @explotacion AS VARCHAR(50) = NULL;
	SELECT @explotacion = CAST(ISNULL(pgsvalor,'') AS VARCHAR) FROM parametros WHERE pgsclave = 'EXPLOTACION';
	
	--********************
	--Precision
	DECLARE @facePrecision INT; --FacE: Precisión del redondeo (facE: 2, default:4)
	DECLARE @basePrecision INT; --Base: Precisión del redondeo (Base: 2, default:4)
	DECLARE @fecLin2Dec DATE = DATEADD(YEAR, 10, GETDATE()); 		
	DECLARE @facFecReg DATE = dbo.GETACUAMADATE(); 		

	--********************
	--Partiendo de esta fecha se dejarán a 4 decimales únicamente los precios
	--Redondeamos la BASE a 2 decimales, sobre esta base calculamos el importe del impuesto y el total
	SELECT @fecLin2Dec = P.pgsvalor FROM dbo.parametros AS P WHERE P.pgsclave='LINEAS_2DECIMALES';

	SELECT @facFecReg = F.facFecReg 
	FROM dbo.facturas AS F 
	WHERE F.facCod = @facCod AND F.facPerCod = @facPerCod AND F.facCtrCod = @facCtrCod AND F.facVersion = 1;

	SELECT @facePrecision = IIF(C.ctrFace=1, 2, 4) 				--FacE: Precisión del redondeo (facE: 2, default:4)
		 , @basePrecision = IIF(@facFecReg>= @fecLin2Dec, 2, 4)--Base: Precisión del redondeo (Base: 2, default:4)
	FROM dbo.contratos AS C
	WHERE C.ctrcod = @facCtrCod AND C.ctrversion = @facCtrVersion

	--********************
	--VALORES POR DEFECTO
	SET @soloAnyadirServicios = ISNULL(@soloAnyadirServicios, 0)
		
	--SÓLO COJO FACCOD + 1 SI VOY A INSERTAR UNA BAJA, 
	--LO HACEMOS ASÍ PORQUE EN AVG EN OCASIONES HACEN FACTURAS DE BAJA PARA DEVOLVER FIANZA, Y DESPUÉS DAN DE BAJA EL CONTRATO
	--POR LO TANTO PARA ESE CASO TENDRÍA QUE SER FACCOD = 2
	IF (@explotacion='AVG' AND @facPerCod = '000002')
	BEGIN
		SET @facCod = (isnull((SELECT max(facCod) + 1 from facturas where facCtrCod = @facCtrCod and facPerCod = @facPerCod), 1))
	END

	--INICIALIZAR VARIABLES DE SALIDA
	SET @facturaInsertada = 0
	SET @serviciosInsertados = 0
		
	--VARIABLES PARA EL LOG
	DECLARE @spName as varchar(100)
	SET @spName = object_name(@@procid)
	DECLARE @spParams as VARCHAR(500)
	--Contiene el código del error
	DECLARE @myError int
	--Texto para errores
	DECLARE @errorStr AS VARCHAR(800)

	--*********************************************************
	--PARA PRORRATEO DE ALTAS, QUE NO CAMBIOS DE TITULAR EN AVG. 
	--[SYR-233990]Lo hemos modificado y trasladado mas abajo para usar la fecha de registro de la factura.
	
	/*	
	IF (@explotacion='AVG' AND @ctrFecIni > @fechaPeriodoDesde )
	BEGIN		
		SET @AltaAVG = (SELECT COUNT(*) FROM FACTURAS inner join faclin on facPerCod = fclFacPerCod and 
		facCod = fclFacCod and facCtrCod = fclFacCtrCod and facVersion = fclFacVersion 
		WHERE facPerCod = '000005' AND fclTrfSvCod =100 AND facCtrCod = @facCtrCod)

		IF (@AltaAVG > 0 ) 
		BEGIN
			--SET @ctrFecIni  = @facLecAntFec --Trae en este caso la de instalacion del contador
			SELECT TOP 1 @ctrFecIni = conCamFecha
			FROM contadorCambio
			INNER JOIN ordenTrabajo ON conCamOtSerCod = otSerCod AND conCamOtSerScd = otSerScd AND conCamOtNum = otNum
			WHERE otCtrCod = @facCtrCod
			ORDER BY conCamFecha DESC
		END
		ELSE 
		BEGIN
		    SET @ctrFecIni = (select DATEADD(d,-90,@fechaPeriodoDesde)) --En el resto de casos ponemos fecha -90 para que no haga prorateos
		END
	END
	*/
	--*********************************************************
	--CABECERA DE FACTURA
	IF @soloAnyadirServicios = 0 
	BEGIN
		--ESTABLECER EL VALOR DE ENVÍO SAP QUE TIENE LA SERIE CONSUMO, EL CÓDIGO DE LA SERIE CONSUMO LO DEBEMOS TENER
		--ALMACENADO EN UN PARÁMETRO CON LA CLAVE SERIE_CONSUMO
		--DECLARE @serieConsumo AS INTEGER = (SELECT ISNULL(pgsvalor, 0) FROM parametros WHERE pgsclave = 'SERIE_CONSUMO')
		--DECLARE @facEnvSap AS BIT = (SELECT ISNULL(serEnvSap, 0) FROM series WHERE sercod = @serieConsumo)
		
		DECLARE @facEnvSap AS BIT = 0;
		
		SELECT @facEnvSap = S.serEnvSap 
		FROM dbo.series AS S
		INNER JOIN dbo.parametros AS SC
		ON SC.pgsclave = 'SERIE_CONSUMO'
		AND SC.pgsvalor = S.sercod
		INNER JOIN dbo.parametros AS P
		ON P.pgsclave='SOCIEDAD_POR_DEFECTO'
		AND P.pgsvalor = S.serscd;


		/*
		* La fecha de lectura anterior obtenida con Contratos_ObtenerUltimaLectura es la fecha que se grabara en la fecha de lectura actual 
		* y fecha de lectura anterior de la nueva factura a insertar en la apertura, es decir .
		*		facLecActFec = @facLecAntFec
		*		facLecAntFec = @facLecAntFec
		*
		* Se pide que para Ribadesella, SVB, y Valdaliga :
		* 
		*  Para aquellos contratos que no tienen activo el servicio agua, dado que no se graba la fecha de lectura.
		*  se pide que en la fecha ACTUAL DE LECTURA sea la fecha de finalizacion del periodo que se esta aperturando
		*/
				
		DECLARE @facLecACTFec DATETIME = @facLecAntFec;

		IF EXISTS(	select value
					from dbo.Split('Ribadesella,San Vicente de la Barquera,VALDALIGA',',')
					where @explotacion = value)
		BEGIN
			-- comprobamos que el contrato no tenga servicio AGUA
			IF not exists(	select ctsctrcod
							from contratoServicio
							inner join tarifas		on trfsrvcod= ctssrv
													and trfcod	= ctstar
													and ctsctrcod= @facCtrCod
							inner join servicios	on svccod	=  trfsrvcod
											        and svccod	= 1)
			BEGIN
				-- PARA ESTOS CONTRATOS CAMBIAMOS @facLecACTFec
				SET @facLecACTFec = @fechaPeriodoHasta																
			END
		END
									   
		--***********************
		--CABECERA DE LA FACTURA
		INSERT INTO dbo.facturas(facCod, facPerCod, facCtrCod, facVersion
		, facCtrVersion
		, facClicod
		, facZonCod
		, facLecAct    
		, facLecActFec 
		, facLecAnt
		, facLecAntFec
		, facConsumoReal
		, facConsumoFactura
		, facUsrReg
		, facEnvSap)				
		VALUES (@facCod, @facPerCod, @facCtrCod, 1 
		, @facCtrVersion
		, @facClicod
		, @facZonCod
		, @facLecAnt --8
		, @facLecACTFec
		, @facLecAnt
		, @facLecAntFec
		, 0 --facConsumoReal
		, 0 --facConsumoFactura
		, @user
		, @facEnvSap);
		--***********************

		SET @myError = @@ERROR IF @myError <> 0 GOTO HANDLE_ERROR;

		--***********************
		--MARCAMOS LA FACTURA COMO INSERTADA: Asignamos la precisión de redondeo
		SELECT @facturaInsertada = 1;
	END --::IF @soloAnyadirServicios = 0  
	
	ELSE 
	BEGIN
		--Si lo que vamos a hacer es ampliar los servicios de la factura, vamos a comprobar que esa factura está en estado de apertura
		IF NOT EXISTS(SELECT facCod FROM facturas WHERE facNumero IS NULL AND facFechaRectif IS NULL AND facVersion = 1 AND facCod = @facCod AND facCtrCod = @facCtrCod AND facPerCod = @facPerCod) 
		BEGIN
			SET @errorStr = 'La factura del contrato ' + CAST(@facCtrCod AS VARCHAR) + ' no está en estado de apertura en el periodo ' + @facPerCod
			RAISERROR (@errorStr, 16, 1)
			SET @myError = @@ERROR IF @myError <> 0 GOTO HANDLE_ERROR
		END 
	END  --::ELSE @soloAnyadirServicios <> 0

	--*********************************************************
	--PARA PRORRATEO DE ALTAS, QUE NO CAMBIOS DE TITULAR EN AVG. 
	--[SYR-233990]Viene de arriba, se ha cambiado para usar la fecha de registro de la factura.
	DECLARE @AltaAVG AS INT = 0;
	IF (@explotacion='AVG')
	BEGIN		
		DECLARE @esContratacionAVG AS BIT = 0; 
		DECLARE @esCambioTitular AS BIT = 0; 
		DECLARE @tieneCtrNuevo AS BIT = 0; 
		DECLARE @esAltaSuministro AS BIT = 0; 
		DECLARE @esAltaPosterior AS BIT = IIF(@ctrFecIni > @fechaPeriodoDesde, 1, 0);
		
		--Ultimo cambio de contador:
		DECLARE @CAMBIOCONTADOR AS TABLE(contador INT, fechaReg DATETIME, fecha DATETIME, lectura INT, operacion VARCHAR(1));

		INSERT INTO @CAMBIOCONTADOR
		SELECT TOP 1 ctcCon, ctcFecReg, ctcFec, ctcLec, ctcOperacion 
		FROM dbo.ctrcon AS CC 
		WHERE ctcCtr= @facCtrCod
		ORDER BY ctcFec DESC, ctcFecReg DESC;
		  
		--La factura mas reciente
		--¿Es una contratación?	
		WITH F AS(
		SELECT facCod
		, facPerCod
		, facCtrCod
		, facVersion
		, facCtrVersion
		, facFecReg 
		FROM dbo.facturas 
		WHERE facCod = @facCod
		AND facPerCod = @facPerCod
		AND facCtrCod = @facCtrCod
		AND facVersion = 1
		
		), FACX AS (
		--Facturas anteriormente registradas y vigentes a la fecha del registro
		SELECT F0.facCtrCod
			 , F0.facPerCod
			 , F0.facCod
			 , F0.facVersion
			 , facFecha  = MAX(F0.facFecha)
			 , facFecReg = MAX(F0.facFecReg)
			 , facNumLineas = COUNT(FL.fclFacCod)
			 --AVG:CUOTA DE CONTRATACION (100)
			 , cuotasContratacion = SUM(IIF(FL.fclTrfSvCod = 100, 1, 0))
		FROM F
		INNER JOIN dbo.facturas AS F0
		ON  F0.facCtrCod = F.facCtrCod
		AND F0.facPerCod <> F.facPerCod
		AND F0.facNumero IS NOT NULL
		AND F0.facFecReg <= F.facFecReg
		AND (F0.facFechaRectif IS NULL OR F0.facFechaRectif>F.facFecReg)
		LEFT JOIN dbo.facLin AS FL
		ON  F0.facCod = FL.fclFacCod
		AND F0.facperCod = FL.fclFacPerCod
		AND F0.facCtrCod = FL.fclFacCtrCod
		AND F0.facVersion = FL.fclFacVersion
		GROUP BY F0.facCtrCod
			   , F0.facPerCod
			   , F0.facCod
			   , F0.facVersion
		
		), FACS AS(
		SELECT F.facCtrCod
			 , F.facPerCod
			 , F.facCod
			 , F.facVersion
			 , esAltaSuministro	= IIF(F.facPerCod='000005', 1, 0)
			 , tieneCuotaContratacion = IIF(F.cuotasContratacion > 0, 1, 0)
			--RN=1: Factura mas reciente, predecesora de la actual
			, RN = ROW_NUMBER() OVER (PARTITION BY F.facCtrCod ORDER BY F.facFecha DESC, F.facFecReg DESC) 
			FROM FACX AS F
			--Facturas con lineas
			WHERE F.facNumLineas>0)

		--¿Es una contratación?
		--La factura que le precede es de alta de suministro (000005) y tiene el servicio de cuota de contratación (100)
		SELECT @esContratacionAVG = IIF(esAltaSuministro=1 AND tieneCuotaContratacion=1, 1, 0) 
			 , @esAltaSuministro = esAltaSuministro
		FROM FACS 
		--RN=1: Factura mas reciente con lineas (Predecesora de la actual)
		WHERE RN=1;
		
		--¿Es un cambio de Titular?
		--Figura como ctrNuevo en otro contrato y la última factura que hay es Alta de Suministro (000005)
		SELECT @esCambioTitular = IIF(C.ctrCod IS NOT NULL AND @esAltaSuministro=1, 1, 0)
		FROM dbo.contratos AS C
		WHERE EXISTS(SELECT 1 FROM dbo.contratos AS CC WHERE CC.ctrNuevo = @facCtrCod);

		--¿Es un ctrNuevo (ha sido cambiado el titular)?
		--Vemos la ultima version del contrato:
		 SELECT TOP 1 @tieneCtrNuevo = IIF(CC.ctrNuevo IS NULL, 0, 1)
		 FROM dbo.contratos AS CC WHERE CC.ctrcod= @facCtrCod
		 ORDER BY CC.ctrVersion DESC;


		/******************************************
		** Cuando se hace un CAMBIO DE TITULARIDAD o una SUBROGACIÓN se FACTURA EL TRIMESTRE COMPLETO.
		** Cuando es un ALTA NUEVA, es decir que se instala un contador nuevo es cuando SE PRORRATEA las cuotas fijas
		** Cuota Prorrateada = DIAS(facLecAntFec; fechaPeriodoHasta)/ DIAS(fechaPeriodoDesde; fechaPeriodoHasta)
		**
		**SUBROGACIONES: Es una nueva versión del mismo contrato con un cambio en los valores del Titular.
		******************************************/
		DECLARE @ProrrateoCuotas BIT = 0;
		SET @ProrrateoCuotas = CASE WHEN @esCambioTitular=1 THEN 0		--Viene de un cambio de titular
									WHEN @tieneCtrNuevo=1 THEN 0		--Se ha hecho cambio de titular
									WHEN @esContratacionAVG=1  THEN 1 
									WHEN @esAltaPosterior=1  THEN 1		--¿Es alta posterior? La fecha de inicio del contrato es posterior al inicio del periodo: caso Reconexiónes
									ELSE 0 END							--¿Es Subrogación? o cualquier otro caso

		SET @AltaAVG = @ProrrateoCuotas;
		
		IF (@AltaAVG > 0) 
		BEGIN
		    --Si no hay contador instalado pasamos una fecha posterior para que deje la cuota en 0.00
			SELECT @ctrFecIni = DATEADD(DAY, +90, @fechaPeriodoHasta); 
 
			--Se prorratea desde la instalacion del contador
			SELECT TOP 1 @ctrFecIni = conCamFecha
			FROM dbo.contadorCambio AS CC
			INNER JOIN dbo.ordenTrabajo AS OT 
			ON  CC.conCamOtSerCod = OT.otSerCod 
			AND CC.conCamOtSerScd = OT.otSerScd 
			AND CC.conCamOtNum = OT.otNum
			WHERE OT.otCtrCod = @facCtrCod
			ORDER BY CC.conCamFecha DESC;

		END
		BEGIN 
		    SELECT @ctrFecIni = DATEADD(DAY, -90, @fechaPeriodoDesde); 
		END

		--****DEBUG*********
		DECLARE @sp_Params AS VARCHAR(500)='';
		DECLARE @sp_Message AS VARCHAR(4000)='';

		SELECT @sp_Message = FORMATMESSAGE('AltaAVG=%i, ctrFecIni=%s, esCambioTitular=%i, esContratacionAVG=%i, esAltaPosterior=%i, fechaPeriodoDesde=%s, fechaPeriodoHasta=%s'
										  , @AltaAVG, FORMAT(@ctrFecIni, 'yyyyMMdd'), CAST(@esCambioTitular AS INT), CAST(@esContratacionAVG AS INT), CAST(@esAltaPosterior AS INT), FORMAT(@fechaPeriodoDesde, 'yyyyMMdd'), FORMAT(@fechaPeriodoHasta, 'yyyyMMdd'));
		
		SELECT @sp_Message += FORMATMESSAGE(', operacionCC=%s, fechaCC=%s', CC.operacion, FORMAT(CC.fecha, 'yyyyMMdd')) 
		FROM @CAMBIOCONTADOR AS CC;

		EXEC Trabajo.errorLog_Insert
		  @spMessage=@sp_Message
		, @spName='[01]Facturas_InsertApertura'
		--*****************
	END
	
	--*********************************************************
	--INSERTO LAS LÍNEAS (UNA POR CADA SERVICIO(línea) DEL CONTRATO)
	DECLARE @codigoServicio AS SMALLINT
	DECLARE @tipoServicio AS VARCHAR(1)
	DECLARE @codigoTarifa AS SMALLINT
	DECLARE @unidades AS DECIMAL(12,2)
	DECLARE @trvCuota AS DECIMAL(10,4)
	DECLARE @svcImpuesto AS DECIMAL(4,2)
	DECLARE @trfEscala1 INT
	DECLARE @trfEscala2 INT
	DECLARE @trfEscala3 INT
	DECLARE @trfEscala4 INT
	DECLARE @trfEscala5 INT
	DECLARE @trfEscala6 INT
	DECLARE @trfEscala7 INT
	DECLARE @trfEscala8 INT
	DECLARE @trfEscala9 INT
	DECLARE @trvPrecio1 AS DECIMAL(10,6)
	DECLARE @trvPrecio2 AS DECIMAL(10,6)
	DECLARE @trvPrecio3 AS DECIMAL(10,6)
	DECLARE @trvPrecio4 AS DECIMAL(10,6)
	DECLARE @trvPrecio5 AS DECIMAL(10,6)
	DECLARE @trvPrecio6 AS DECIMAL(10,6)
	DECLARE @trvPrecio7 AS DECIMAL(10,6)
	DECLARE @trvPrecio8 AS DECIMAL(10,6)
	DECLARE @trvPrecio9 AS DECIMAL(10,6)
	DECLARE @srvFechaAlta AS DATETIME
	DECLARE @srvFechaBaja AS DATETIME
	DECLARE @total AS MONEY
	DECLARE @base AS MONEY
	DECLARE @impImpuesto AS MONEY
	DECLARE @multiplicarEscPorUds AS BIT
	DECLARE @multiplicarCuotaPorUds AS BIT
	DECLARE @numLinea INT
	DECLARE @fechaInicio DATETIME
	DECLARE @fechaFin DATETIME	


	--Si vamos a añadir servicios a una factura existente, el número de línea es el último + 1. Si no es el 1
	SELECT @numLinea = ISNULL(MAX(fclNumLinea), 0) + 1 
	FROM faclin
	WHERE @soloAnyadirServicios = 1 AND fclFacCod = @facCod AND fclFacVersion = 1 AND fclFacCtrCod = @facCtrCod AND fclFacPerCod = @facPerCod

	--Contador de servicios insertados
	SET @serviciosInsertados = 0
		
	--Inicialmente el cambio de tarifa a mitad de periodo lo dejamos solo para Guadalajara, en un futuro se dejará para todas las explotaciones
	IF (@explotacion='Guadalajara' AND @facLecAntFec IS NULL)
		SET @facLecAntFec=(SELECT facLecAntFec FROM facturas WHERE facCod=1 AND facPerCod=@facPerCod AND facCtrCod=@facCtrCod AND facVersion=1)
		
	--*************
	--AVG: Seleccionamos las tarifas por la fecha de lectura
	--No reutilizo las variables porque en el camino se cambian e intercambian (no se porque)
	DECLARE @facLecAnt_Fec AS DATE;
	DECLARE @facLecAct_Fec AS DATE;
	DECLARE @hayDiasEntreLecturas BIT = 0;
		
	SELECT @facLecAnt_Fec = F.facLecAntFec
	     , @facLecAct_Fec = F.facLecActFec 
		 , @hayDiasEntreLecturas = 1
	FROM dbo.facturas AS F
	WHERE @explotacion= 'AVG'
	AND F.facCod=@facCod AND F.facCtrCod=@facCtrCod AND F.facPerCod=@facPerCod AND F.facVersion=1
	AND F.facLecAntFec IS NOT NULL 
	AND F.facLecActFec IS NOT NULL
	AND DATEDIFF(DAY, F.facLecAntFec, F.facLecActFec) > 1 
	AND @AltaAVG = 0;

	--*************
	
	--****DEBUG*********	
	--SELECT ctstar, ctssrv, ISNULL(ctsuds,0), svctipo, svcImpuesto, ctsfecalt, ctsfecbaj
	--FROM contratoServicio c
	--INNER JOIN fServicios_Select(null) ON svccod = ctssrv
	--WHERE ctsctrcod = @facCtrCod-- AND ctssrv=1
	--AND
	--((ctsFecBaj IS NULL OR ctsFecBaj >=@fechaPeriodoDesde) OR
	-- (@explotacion='Guadalajara' AND (@facLecAntFec  IS NOT NULL AND @facLecAntFec  <= ctsFecBaj AND ctsFecBaj < DATEADD(day, -1, @fechaPeriodoDesde))) OR
	-- (@explotacion='AVG'	    AND (@facLecAnt_Fec IS NOT NULL AND @facLecAnt_Fec <= ctsFecBaj AND ctsFecBaj < DATEADD(DAY, -1, @fechaPeriodoDesde)))
	--) AND
	--(ctsFecAlt IS NULL OR @fechaPeriodoHasta >= ctsFecAlt ) AND
	--(ctsFecAlt IS NULL OR ctsFecBaj IS NULL OR ctsFecBaj > ctsFecAlt) --Si la fecha de baja es la misma que la de alta, es un servicio anulado, no aplicable
	--ORDER BY ctssrv, IIF(ctsfecbaj IS NULL, 0, 1), ctsfecbaj;
	--******************


	--*****************************************************
	--*****************  C U R S O R  *********************
	--*****************************************************
	DECLARE cServicios CURSOR FOR
	SELECT ctstar, ctssrv, ISNULL(ctsuds,0), svctipo, svcImpuesto, ctsfecalt, ctsfecbaj
	FROM contratoServicio c
	INNER JOIN fServicios_Select(null) ON svccod = ctssrv
	WHERE ctsctrcod = @facCtrCod 
	AND
	((ctsFecBaj IS NULL OR ctsFecBaj >=@fechaPeriodoDesde) OR
	 (@explotacion='Guadalajara' AND (@facLecAntFec  IS NOT NULL AND @facLecAntFec  <= ctsFecBaj AND ctsFecBaj < DATEADD(day, -1, @fechaPeriodoDesde))) OR
	 (@explotacion='AVG'	     AND (@facLecAnt_Fec IS NOT NULL AND @facLecAnt_Fec <= ctsFecBaj AND ctsFecBaj < DATEADD(DAY, -1, @fechaPeriodoDesde)))
	) AND
	(ctsFecAlt IS NULL OR @fechaPeriodoHasta >= ctsFecAlt ) AND
	(ctsFecAlt IS NULL OR ctsFecBaj IS NULL OR ctsFecBaj > ctsFecAlt) --Si la fecha de baja es la misma que la de alta, es un servicio anulado, no aplicable
	--******************
	--Cuando hay reconexion se puede repetir el mismo servico y tarifa, y el proceso solo se queda con el primero 
	--Con este ORDER nos aseguramos de considerar el de mayor vigencia
	ORDER BY ctssrv, IIF(ctsfecbaj IS NULL, 0, 1), ctsfecbaj
	----******************
	
	OPEN cServicios
	FETCH NEXT FROM cServicios
	INTO @codigoTarifa, @codigoServicio, @unidades, @tipoServicio, @svcImpuesto, @srvFechaAlta, @srvFechaBaja
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		--@soloAnyadirServicios = 0: Apertura				=> Se insertan todos los servicios de la configuracion de servicios x contrato
		--@soloAnyadirServicios = 1: Ampliación Apertura	=> Si un servicio x contrato se repite solo se toma en cuenta uno de ellos
		--Si lo único que tengo que hacer es añadir servicios, entonces sólo lo añado si la factura no lo tiene
		IF (@soloAnyadirServicios = 0 OR NOT EXISTS(SELECT fclFacCod FROM faclin WHERE fclTrfSvCod = @codigoServicio AND fclTrfCod = @codigoTarifa AND fclFacCod = @facCod AND fclFacVersion = 1 AND fclFacPerCod = @facPerCod AND fclFacCtrCod = @facCtrCod))
		BEGIN
			--Obtengo la tarifa del servicio, y de ella los escalados
			EXEC Log_Insert @user, @spName, 'Obtener tarifa del servicio y escalados'
			SELECT  @trfEscala1 = trfEscala1, 
				@trfEscala2 = trfEscala2, @trfEscala3 = trfEscala3, 
				@trfEscala4 = trfEscala4, @trfEscala5 = trfEscala5, 
				@trfEscala6 = trfEscala6, @trfEscala7 = trfEscala7, 
				@trfEscala8 = trfEscala8, @trfEscala9 = trfEscala9, 
				@multiplicarCuotaPorUds = ISNULL(trfUdsPorPrecio, 0), 
				@multiplicarEscPorUds = ISNULL(trfUdsPorEsc, 0)
			FROM tarifas
			WHERE trfsrvcod = @codigoServicio 
			AND trfcod = @codigoTarifa

			SET @myError = @@ERROR
			IF @myError <> 0
				GOTO HANDLE_ERROR

			IF (@explotacion='AVG')	
			BEGIN	
				SET @fechaInicio = IIF(@srvFechaAlta>@ctrFecIni, @srvFechaAlta, @ctrFecIni);	
			END
			ELSE
			BEGIN
				SET @fechaInicio = ISNULL(@srvFechaAlta, @ctrFecIni);		
			END
			
			SET @fechaFin = ISNULL(@srvFechaBaja, @ctrFecAnu)
			--AVG Como hemos acutalizado ctrfecIni en el caso de Altas no tocamos.
			DECLARE @altaBajaPerActual BIT = 0
			IF((@ctrFecIni >= @fechaPeriodoDesde) OR (@ctrFecAnu IS NOT NULL AND @ctrFecAnu <= @fechaPeriodoHasta))
				SET @altaBajaPerActual = 1

			--Obtengo los precios de las tarifas
			EXEC Log_Insert @user, @spName, 'Llamada al procedimiento de Cálculo de Valores de Tarifa';
				
			--**************
			--AVG: seleccionamos los valores de tarifa por la fecha de lectura cuando están indicadas en las variables que inicializa solamente en AVG
			DECLARE @trvDesde AS DATE = COALESCE(@facLecAnt_Fec, @fechaPeriodoDesde);
			DECLARE @trvHasta AS DATE = COALESCE(@facLecAct_Fec, @fechaPeriodoHasta);

			--AVG: Los cambios de titular no prorratean las cuotas
			--Cambio de titularidad NO prorratea las cuotas
			IF (@explotacion='AVG' AND @tipoServicio='U')
			BEGIN
				IF (@esCambioTitular=1 OR @tieneCtrNuevo=1)
				SELECT @fechaInicio=@trvDesde, @fechaFin=@trvHasta;	

				--Baja: Prorrateamos hasta la fecha de desinstalación del contador
				ELSE IF (@esBaja=1)
				SELECT @fechaFin = C.fecha
				FROM @CAMBIOCONTADOR AS C
				WHERE C.operacion='R';
			END

			DECLARE @conValorTarifa BIT = 1;
			--**************
				
			EXEC @myError = dbo.Facturas_ObtenerValoresTarifa @codigoServicio, @codigoTarifa, 
								@trvDesde, @trvHasta, 
								@fechaInicio, @fechaFin,
								@trvPrecio1 out, @trvPrecio2 out, @trvPrecio3 out, @trvPrecio4 out,
								@trvPrecio5 out, @trvPrecio6 out, @trvPrecio7 out, @trvPrecio8 out,
								@trvPrecio9 out, @trvCuota out, 
								@conValorTarifa OUT, 
								@altaBajaPerActual;
				
			IF @myError <> 0
				GOTO HANDLE_ERROR
			
			--****DEBUG*********
			--IF @codigoServicio=2
			--SELECT @trvCuota
			--******************

			--Insertamos la línea
			--Si el servicio es medido, insertamos los 9 valores de escala, precio y unidades
			--Si el servicio es unitario, sólo insertamos la cuota (precio y unidades)
			--Las unidades las cojo del consumo de factura
			IF @tipoServicio = 'M' --medido
			BEGIN
				SET @spParams = 'línea=' + CAST(@numLinea AS VARCHAR) + ' tarifa = ' + CAST(@codigoTarifa AS VARCHAR)  + ' servicio = ' + CAST(@codigoServicio AS VARCHAR)
				EXEC Log_Insert @user, @spName, 'Insertando Línea Factura (tarifa escalada)', @spParams
			END
			IF @tipoServicio = 'U' --unitaria
			BEGIN
				SET @trfEscala1  = 0
				SET @trfEscala2  = 0
				SET @trfEscala3  = 0
				SET @trfEscala4  = 0
				SET @trfEscala5  = 0
				SET @trfEscala6  = 0
				SET @trfEscala7  = 0
				SET @trfEscala8  = 0
				SET @trfEscala9  = 0
				SET @trvPrecio1  = 0
				SET @trvPrecio2  = 0
				SET @trvPrecio3  = 0
				SET @trvPrecio4  = 0
				SET @trvPrecio5  = 0
				SET @trvPrecio6  = 0
				SET @trvPrecio7  = 0
				SET @trvPrecio8  = 0
				SET @trvPrecio9  = 0

				SET @spParams = 'línea=' + CAST(@numLinea AS VARCHAR) + ' tarifa = ' + CAST(@codigoTarifa AS VARCHAR)  + ' servicio = ' + CAST(@codigoServicio AS VARCHAR)
				EXEC Log_Insert @user, @spName, 'Insertando Línea Factura (tarifa unitaria)', @spParams			
			END

			--Si @multiplicarCuotaPorUds = 0 entonces le cambiamos las unidades de la cuota a 1
			DECLARE @unidadesParaCuota AS DECIMAL(12,2)
			SET @unidadesParaCuota = CASE WHEN @multiplicarCuotaPorUds = 1 THEN @unidades ELSE 1 END 
			
			--******************************************	
			SET @base = ROUND(@unidadesParaCuota * ISNULL(@trvCuota,0), @facePrecision);
			SET @impImpuesto = ROUND(@base * ISNULL(@svcImpuesto,0) * 0.01, 4);
				
			--Bajamos la precisión en los totales si es necesario...
			--Ocurre cuando no se trata de una factura electrónica
			IF(@facePrecision > @basePrecision)
			BEGIN
				SET @base = ROUND(@base, @basePrecision);
				SET @impImpuesto = ROUND(@base* ISNULL(@svcImpuesto, 0) *0.01, 4);
			END
			--******************************************

			SET @total = @base + @impImpuesto;

			--Si @multiplicarEscPorUds = 0 entonces le cambiamos las unidades de los escalados a 1
			DECLARE @unidadesParaEscalados AS DECIMAL(12,2)
			SET @unidadesParaEscalados = CASE WHEN @multiplicarEscPorUds = 1 THEN @unidades ELSE 1 END
			-- SI EL CANON FIJO
			IF (@explotacion='AVG' AND @codigoServicio=19)
			BEGIN
				SET @unidadesParaCuota=@unidadesParaEscalados 
			END
		
			--*******
			--Condicionamos la inserción de la linea cuando hay valores de tarifa para el rango de fechas
			IF ((@conValorTarifa IS NOT NULL AND @conValorTarifa=1) OR @explotacion='Ute lote 6 Conversación')
			--*******
			INSERT INTO facLin(fclFacCod, fclFacPerCod, fclFacCtrCod, fclFacVersion, fclNumLinea,
			fclEscala1, fclEscala2, fclEscala3, fclEscala4, fclEscala5, 
			fclEscala6, fclEscala7, fclEscala8, fclEscala9
			, fclPrecio1, fclPrecio2, fclPrecio3, fclPrecio4, fclPrecio5
			, fclPrecio6, fclPrecio7, fclPrecio8, fclPrecio9
			, fclUnidades1, fclUnidades2, fclUnidades3, fclUnidades4, fclUnidades5
			, fclUnidades6, fclUnidades7, fclUnidades8, fclUnidades9
			, fclTrfSvCod, fclTrfCod
			, fclPrecio, fclUnidades
			, fclTotal
			, fclImpuesto
			, fclbase
			, fclImpImpuesto
			, fclCtsUds)
			VALUES(@facCod, @facPerCod, @facCtrCod, 1, @numLinea,
			CASE WHEN @trfEscala1 >= 999999999 OR (ISNULL(@trfEscala1,0) * @unidadesParaEscalados) >= 999999999 THEN 999999999 ELSE ISNULL(@trfEscala1,0) * @unidadesParaEscalados END,
			CASE WHEN @trfEscala2 >= 999999999 OR (ISNULL(@trfEscala2,0) * @unidadesParaEscalados) >= 999999999 THEN 999999999 ELSE ISNULL(@trfEscala2,0) * @unidadesParaEscalados END,
			CASE WHEN @trfEscala3 >= 999999999 OR (ISNULL(@trfEscala3,0) * @unidadesParaEscalados) >= 999999999 THEN 999999999 ELSE ISNULL(@trfEscala3,0) * @unidadesParaEscalados END,
			CASE WHEN @trfEscala4 >= 999999999 OR (ISNULL(@trfEscala4,0) * @unidadesParaEscalados) >= 999999999 THEN 999999999 ELSE ISNULL(@trfEscala4,0) * @unidadesParaEscalados END,
			CASE WHEN @trfEscala5 >= 999999999 OR (ISNULL(@trfEscala5,0) * @unidadesParaEscalados) >= 999999999 THEN 999999999 ELSE ISNULL(@trfEscala5,0) * @unidadesParaEscalados END,
			CASE WHEN @trfEscala6 >= 999999999 OR (ISNULL(@trfEscala6,0) * @unidadesParaEscalados) >= 999999999 THEN 999999999 ELSE ISNULL(@trfEscala6,0) * @unidadesParaEscalados END,
			CASE WHEN @trfEscala7 >= 999999999 OR (ISNULL(@trfEscala7,0) * @unidadesParaEscalados) >= 999999999 THEN 999999999 ELSE ISNULL(@trfEscala7,0) * @unidadesParaEscalados END,
			CASE WHEN @trfEscala8 >= 999999999 OR (ISNULL(@trfEscala8,0) * @unidadesParaEscalados) >= 999999999 THEN 999999999 ELSE ISNULL(@trfEscala8,0) * @unidadesParaEscalados END,
			CASE WHEN @trfEscala9 >= 999999999 OR (ISNULL(@trfEscala9,0) * @unidadesParaEscalados) >= 999999999 THEN 999999999 ELSE ISNULL(@trfEscala9,0) * @unidadesParaEscalados END
			, ISNULL(@trvPrecio1,0), ISNULL(@trvPrecio2,0), ISNULL(@trvPrecio3,0),ISNULL(@trvPrecio4,0), ISNULL(@trvPrecio5,0)
			, ISNULL(@trvPrecio6,0), ISNULL(@trvPrecio7,0), ISNULL(@trvPrecio8,0), ISNULL(@trvPrecio9,0)
			, 0, 0, 0, 0, 0 --Unidades 1-5
			, 0, 0, 0, 0	--Unidades 6-9
			, @codigoServicio, @codigoTarifa
			, ISNULL(@trvCuota,0), @unidadesParaCuota
			, ISNULL(@total,0)
			, ISNULL(@svcImpuesto,0)
			, ISNULL(@base,0)
			, ISNULL(@impImpuesto,0)
			, @unidades);
			
			
			SET @myError = @@ERROR IF @myError <> 0 BEGIN CLOSE cServicios DEALLOCATE cServicios GOTO HANDLE_ERROR END
			SET @serviciosInsertados = @serviciosInsertados + 1
					
			--Si hemos insertado sólo la línea (sin la cabecera), y el servicio es medido, hay que hacer
			--el reparto del consumo en esa línea, por si la cabecera ya tiene un consumo puesto.
			--Si hemos insertado la cabecera aquí, no es necesario ya que se pone un 0 como consumo
				
			IF (@facturaInsertada = 0 AND @tipoServicio = 'M') OR (@explotacion='AVG' AND @codigoServicio=19) 
			BEGIN
				EXEC @myError = Facturas_ActualizarLineas @facCod, @facPerCod, @facCtrCod, 1, NULL, NULL, NULL, @numLinea --En estado de apertura es versión 1 siempre
				SET @myError = @@ERROR IF @myError <> 0 GOTO HANDLE_ERROR
			END
	
			SET @numLinea = @numLinea + 1
		END --Si lo único que tengo que hacer es añadir servicios, entonces sólo lo añado si la factura no lo tiene
	
			
		FETCH NEXT FROM cServicios
		INTO @codigoTarifa, @codigoServicio, @unidades, @tipoServicio, @svcImpuesto, @srvFechaAlta, @srvFechaBaja
	END--WHILE @@FETCH_STATUS = 0
	
	CLOSE cServicios
	DEALLOCATE cServicios

	
	
	--*******************************************************	
	--SI HEMOS INSERTADO LA CABECERA DE LA FACTURA Y ADEMÁS
	--SE HA RETIRADO EL CONTADOR PARA ESTE CONTRATO, Y NO SE HA INSTALADO OTRO,
	--GUARDAREMOS LA LECTURA FACTURA (Y SU FECHA) Y EL CONSUMO A FACTURAR
	--DE ESTA FORMA FACTURAMOS LA "BAJA". PARA QUE SÓLO SE FACTURE DICHA BAJA UNA VEZ COMPROBAMOS QUE
	--LA FECHA DEL CAMBIO ESTÉ COMPRENDIDA ENTRE LA FECHA DE LA ÚLTIMA FACTURA Y HOY
	--*******************************************************
	IF @facturaInsertada = 1 
	BEGIN
		DECLARE @ultimaOperacion AS VARCHAR(1)
		DECLARE @fechaOperacion AS DATETIME
		DECLARE @lectura AS INT
		DECLARE @consumoAFacturar AS INT

		SET @ultimaOperacion = NULL
		SELECT TOP 1 @ultimaOperacion = ctcOperacion,
						@fechaOperacion = ctcFec,
						@lectura = ctcLec,
						@consumoAFacturar = conCamConsumoAFacturar
		FROM contadorcambio 
		INNER JOIN ordenTrabajo ON conCamOtSerScd = otSerScd AND conCamOtSerCod = otSerCod AND conCamOtNum = otNum
		INNER JOIN ctrCon ON ctcCtr = otCtrCod
		WHERE otCtrCod = @facCtrCod
		ORDER BY ctcFec DESC, ctcOperacion
		
		SET @myError = @@ERROR IF @myError <> 0 GOTO HANDLE_ERROR

		IF @ultimaOperacion = 'R' AND
			@fechaOperacion <= GETDATE() AND
			@fechaOperacion >= ISNULL((SELECT TOP 1 facFecha FROM facturas WHERE facCtrCod = @facCtrCod AND facNumero IS NOT NULL AND facFechaRectif IS NULL AND LEFT(facPerCod, 2) = '20' ORDER BY facPerCod DESC), '01/01/1900')
		BEGIN
			--Actualizar lecturas y consumo
			UPDATE facturas SET
			facLecActFec = @fechaOperacion, 
			facLecAct = ISNULL(@lectura, facLecAnt),
			facConsumoFactura = ISNULL(@consumoAFacturar, CASE WHEN (ISNULL(@lectura, facLecAnt) - facLecAnt)<0 THEN 0 ELSE ISNULL(@lectura, facLecAnt) - facLecAnt END)
			WHERE facCod = @facCod AND facVersion = 1	AND facPerCod = @facPerCod AND facCtrCod = @facCtrCod
			SET @myError = @@ERROR IF @myError <> 0 GOTO HANDLE_ERROR

			--Actualizar líneas
			EXEC @myError = Facturas_ActualizarLineas @facCod, @facPerCod, @facCtrCod, 1, NULL, NULL, NULL --En estado de apertura es versión 1 siempre
			SET @myError = @@ERROR IF @myError <> 0 GOTO HANDLE_ERROR
			
		END
	END --@facturaInsertada = 1 

--****DEBUG*********
--SELECT * FROM dbo.faclin where fclFacCtrCod=@facCtrCod AND  fclfacpercod=@facPerCod AND fclfacCod=@facCod AND fclTrfSvCod=19;
--******************

	--**********************************
	--Para servicios que se repiten en una misma factura: 
	--Una vez re-creadas todas las lineas de la factura, actualizamos las lineas de factura para actualizar el consumo
	--Se hace una distribución del consumo de manera proporcional a los días que cubren sus tarifas
	DECLARE @ID INT;
	DECLARE @FACVERSION INT = 1;
	DECLARE @FCLNUMLINEA INT;
	DECLARE @SVCTIPO VARCHAR(1);
	DECLARE @FCLPRECIO DECIMAL(10, 4);
	
	DECLARE @DESGLOSECONSUMOS AS TABLE( 
		  ID INT IDENTITY(1, 1)
		, dcFacCod INT
		, dcFacPerCod VARCHAR(6)
		, dcFacCtrCod	INT
		, dcFacVersion INT	
		, dcFclNumLinea INT	
		, svcTipo VARCHAR(1)
		, dcFclTrfSvCod INT	
		, dcFclTrfCod INT	
		, dcTrvfecha	DATE
		, dcTrvfechafin DATE
		, dcTrvCuota DECIMAL(10, 4)
		, diasEntreLecturas INT
		, diasxLinea INT
		, consumoxLinea INT
		, tarifasxLinea INT);
	
	--****LEEME*********	
	--Facturas_DesglosarConsumos lo incluimos para AVG y se probó exhaustivamente  con la ampliación del 202003 que habían saltos de tarifa por tarval y serviciosxcontrato
	--Falla cuando se hace prorrateo de cuotas
	--Hace falta revisar este método de nuevo para que funciones correctamente en todos los casos
	--Probar con los saltos de tarifa por tarval que fue para lo que se metió
	----******************
	IF(@explotacion='AVG' AND @soloAnyadirServicios = 1 AND @hayDiasEntreLecturas = 1 AND  @ProrrateoCuotas=0)
	INSERT INTO @DESGLOSECONSUMOS
	EXEC Facturas_DesglosarConsumos @codigoFactura=@facCod, @periodo=@facPerCod, @contrato=@facCtrCod, @versionFactura=@FACVERSION;
	--******************	

	--****DEBUG*********	
	--SELECT  * FROM @DESGLOSECONSUMOS;
	--EXEC Facturas_DesglosarConsumos @codigoFactura=@facCod, @periodo=@facPerCod, @contrato=@facCtrCod, @versionFactura=@FACVERSION;
	--******************

	--Para cada linea de facturas a FACTURAS_ACTUALIZARLINEAS
	SELECT @ID = MIN(ID) FROM @DESGLOSECONSUMOS;
	WHILE @ID IS NOT NULL
	BEGIN			
		SELECT @FCLNUMLINEA = D.dcFclNumLinea 
				, @SVCTIPO = D.svcTipo
				, @FCLPRECIO = IIF(D.diasEntreLecturas <> 0, D.dcTrvCuota* D.diasxLinea/D.diasEntreLecturas, 0)
		FROM @DESGLOSECONSUMOS AS D WHERE ID=@ID;
		--****DEBUG*********
		--SELECT @FCLNUMLINEA AS LINEA;
		--******************
		IF (@SVCTIPO = 'M')
			EXEC @myError = Facturas_ActualizarLineas @facturaCodigo=@facCod, @periodo=@facPerCod, @contrato=@facCtrCod, @version=@FACVERSION, @numLinea=@FCLNUMLINEA;	
		ELSE 
			EXEC @myError = Facturas_ActualizarLinea @facCod=@facCod, @facPerCod=@facPerCod, @facCtrCod=@facCtrCod, @facVersion=@FACVERSION, @fclNumLinea=@FCLNUMLINEA, @fclPrecio=@FCLPRECIO;
			
		SET @myError = @@ERROR IF @myError <> 0 GOTO HANDLE_ERROR	
	
		SELECT @ID = MIN(ID) FROM @DESGLOSECONSUMOS WHERE ID > @ID;
	END


	--****DEBUG*********
	--SELECT * FROM dbo.faclin where fclFacCtrCod=@facCtrCod AND  fclfacpercod=@facPerCod AND fclfacCod=@facCod;
	
	--SELECT 'IA', Peridodo= @facPerCod, CTR=@facCtrCod, Servicio=@codigoServicio, Tarifa=@codigoTarifa, cuota=@trvCuota,fclNumLinea, fclTotal, fclPrecio, tipoServicio=@tipoServicio
	--, udsCuota = @unidadesParaCuota, udsEscalados= @unidadesParaEscalados 
	--FROM dbo.faclin where fclFacCtrCod=@facCtrCod AND  fclfacpercod=@facPerCod AND fclfacCod=@facCod AND fclNumLinea=2;
	--******************
	
	RETURN 0

HANDLE_ERROR:

	SET @erlNumber  = (SELECT ERROR_NUMBER());
	SET @erlSeverity  = (SELECT ERROR_SEVERITY());
	SET @erlState  = (SELECT ERROR_STATE());
	SET @erlProcedure = (SELECT ERROR_PROCEDURE());
	SET @erlLine  = (SELECT ERROR_LINE());
	SET @erlMessage  = (SELECT ERROR_MESSAGE());
	
	SET @erlParams = 'ctrcod = ' + ISNULL(CAST(@FACctrCod AS VARCHAR), 'NULL') 
							+ ' ; '	+ '@fechaLecturaAnterior = ' + ISNULL(CAST(@facLecAntFec AS VARCHAR), 'NULL') 
							+ ' ; ' + '@ctrFecIni = ' + ISNULL(CAST(@ctrFecIni AS VARCHAR), 'NULL')						
							+ ' ; ' + '@existePrefactura = ' + ISNULL(CAST(@soloAnyadirServicios AS VARCHAR), 'NULL')	
    BEGIN TRAN
		EXEC ErrorLog_Insert  @explotacion, '[dbo].[Facturas_Insert_Apertura]', @erlNumber, @erlSeverity, @erlState, @erlProcedure, @erlLine, @erlMessage, @erlParams	
	COMMIT TRAN
	EXEC Log_Insert @user, @spName, 'Se ha producido un error', NULL, @myError

	RETURN @myError
END





GO


