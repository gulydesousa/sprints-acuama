--ALTER TABLE ordenTrabajo ADD otPteRealizar BIT NULL, otCausaNoRealizacionCod SMALLINT NULL, otComentarioNoRealizacion VARCHAR(250) NULL,
--CONSTRAINT FK_ordenTrabajo_otCausaNoRealizacion FOREIGN KEY (otCausaNoRealizacionCod) REFERENCES otCausasNoRealizacion(otcnrCod);
--GO

--SELECT * FROM ordenTrabajo

ALTER PROCEDURE [dbo].[OrdenTrabajo_Insert]
(
	@otserscd smallint,
	@otsercod smallint,
	@otfsolicitud datetime = null,
	@otfrealizacion datetime = null,
	@otfcierre datetime = null,
	@otottcod varchar(4) = null,
	@otdessolicitud varchar(80) = null,
	@otdesrealizacion varchar(80) = null,
	@otobs varchar(500) = null,
	@otiptcod varchar(14) = null,
	@otcotcod varchar(6) = null,
	@otsubcotcod varchar(6) = null,
	@otalmcod varchar(4) = null,
	@otPrvCod varchar(3) = null,
	@otPobCod varchar(3) = null,
	@otdireccion varchar(200) = null,
	@otCliCod int=null,
	@otCtrCod int=null,
	@otCtrVersion smallint=null,
	@otUsuSolicitud varchar(10)=null,
	@otUsuRealizacion varchar(10)=null,
	@otUsuCierre varchar(10)=null,
	@otEplCod smallint =null,
	@otEplCttCod smallint =null,
	@otDepCod int =null,
	@otMtcCod int =null
	, @otObsRealizacion VARCHAR(MAX) = NULL
	, @otFechaReg datetime = NULL 
	, @otFPrevision datetime= NULL
	, @otPrioridad SMALLINT = NULL
	, @otFecRechazo DATETIME = NULL
	, @otUsuRechazo VARCHAR(10)= NULL
	, @otTipoOrigen VARCHAR(10) = 'ANY'
	, @otPteRealizar BIT = null
	, @otCausaNoRealizacionCod SMALLINT = NULL
	, @otComentarioNoRealizacion VARCHAR(250) = NULL
	, @otnumNuevo int OUTPUT
)
AS
	SET NOCOUNT OFF;

	DECLARE @myError AS INT
	DECLARE @TRANCOUNT AS INT SET @TRANCOUNT = @@TRANCOUNT
	IF @TRANCOUNT = 0 BEGIN TRAN T_OrdenTrabajo_Insert ELSE SAVE TRAN T_OrdenTrabajo_Insert

	SET @otnumNuevo = NULL

	-- OBTENER NUMERADOR
	UPDATE series set sernumfra = ISNULL(sernumfra, 0) + 1 WHERE sercod = @otsercod AND serscd = @otserscd
	SELECT @otnumNuevo = sernumfra FROM series WHERE sercod = @otsercod AND serscd = @otserscd

	--INSERTAR EN OT
	INSERT INTO [ordenTrabajo]
		([otserscd], [otsercod], [otnum], 
		 [otfsolicitud], [otfrealizacion], [otfcierre], 
		 [otottcod], 
		 [otdessolicitud], 
		 [otdesrealizacion], 
		 [otobs], 
		 [otiptcod], 
		 [otcotcod], 
		 [otsubcotcod], 
		 [otalmcod], 
		 [otPrvCod], [otPobCod], [otdireccion],
		 [otCliCod], [otCtrCod], [otCtrVersion],
		 [otUsuSolicitud], [otUsuRealizacion], [otUsuCierre],
		 [otEplCod], [otEplCttCod], [otDepCod],
		 [otMtcCod]
		 , [otObsRealizacion]
		 , [otFechaReg]
		 , [otFPrevision]
		 , [otPrioridad]
		 , [otFecRechazo]
		 , [otUsuRechazo]
		 , [otTipoOrigen]
		 , otPteRealizar
		 , otCausaNoRealizacionCod
		 , otComentarioNoRealizacion) 
	VALUES (@otserscd, @otsercod, @otnumNuevo, 
			@otfsolicitud, @otfrealizacion, @otfcierre, 
			@otottcod, 
			@otdessolicitud, 
			@otdesrealizacion, 
			@otobs, 
			@otiptcod, 
			@otcotcod, 
			@otsubcotcod, 
			@otalmcod, 
			@otPrvCod, @otPobCod, @otdireccion,
			@otCliCod, @otCtrCod, @otCtrVersion,
			@otUsuSolicitud, @otUsuRealizacion, @otUsuCierre,
			@otEplCod, @otEplCttCod, @otDepCod,
			@otMtcCod
			, @otObsRealizacion
			, ISNULL(@otFechaReg,GETDATE())
			, @otFPrevision
			, @otPrioridad
			, @otFecRechazo
			, @otUsuRechazo
			, @otTipoOrigen
			, @otPteRealizar
			, @otCausaNoRealizacionCod
			, @otComentarioNoRealizacion);

	SET @myError = @@error 
	IF @myError <> 0 GOTO ERROR

	IF @TRANCOUNT = 0
		COMMIT TRAN T_OrdenTrabajo_Insert

	RETURN 0

ERROR:
	ROLLBACK TRAN T_OrdenTrabajo_Insert
	RETURN @myError
GO
ALTER PROCEDURE [dbo].[OrdenTrabajo_Update]
(
	@otfsolicitud datetime,
	@otfrealizacion datetime,
	@otfcierre datetime,
	@otottcod varchar(4),
	@otdessolicitud varchar(80),
	@otdesrealizacion varchar(80),
	@otobs varchar(500),
	@otiptcod varchar(14),
	@otcotcod varchar(6),
	@otsubcotcod varchar(6),
	@otalmcod varchar(4),
	@otPrvCod varchar(3) = null,
	@otPobCod varchar(3) = null,
	@otdireccion varchar(200),
	@otCliCod int = null,
	@otCtrCod int = null,
	@otCtrVersion smallint=null,
	@otUsuSolicitud varchar(10)=null,
	@otUsuRealizacion varchar(10)=null,
	@otUsuCierre varchar(10)=null,
	@otEplCod smallint =null,
	@otEplCttCod smallint =null,
	@otDepCod int =null,
	@otMtcCod int =null
	, @otObsRealizacion VARCHAR(MAX) = NULL
	, @otFPrevision DATETIME = NULL
	, @otUsrUltMod VARCHAR(10) = NULL
	, @otFecUltMod DATETIME = NULL
	, @otPrioridad SMALLINT = NULL
	, @Original_otserscd SMALLINT
	, @Original_otsercod SMALLINT
	, @Original_otnum INT
	, @otFecRechazo DATETIME = NULL
	, @otUsuRechazo VARCHAR(10) = NULL
	, @otTipoOrigen VARCHAR(10) = 'ANY'
	, @otPteRealizar BIT = null
	, @otCausaNoRealizacionCod SMALLINT = NULL
	, @otComentarioNoRealizacion VARCHAR(250) = NULL
)
AS
	SET NOCOUNT OFF;

	UPDATE [ordenTrabajo] 
	   SET [otfsolicitud] = @otfsolicitud, 
		   [otfrealizacion] = @otfrealizacion, 
		   [otfcierre] = @otfcierre, 
		   [otottcod] = @otottcod, 
		   [otdessolicitud] = @otdessolicitud, 
		   [otdesrealizacion] = @otdesrealizacion, 
		   [otobs] = @otobs, 
		   [otiptcod] = @otiptcod, 
		   [otcotcod] = @otcotcod, 
		   [otsubcotcod] = @otsubcotcod, 
		   [otalmcod] = @otalmcod,
		   [otPrvCod]= @otPrvCod,
		   [otPobCod]= @otPobCod,
		   [otdireccion]= @otdireccion,
		   [otCliCod] = @otCliCod,
		   [otCtrCod]=@otCtrCod,
		   [otCtrVersion]=@otCtrVersion,
		   [otUsuSolicitud] = @otUsuSolicitud,
		   [otUsuRealizacion] = @otUsuRealizacion,
		   [otUsuCierre] = @otUsuCierre,
		   [otEplCod] = @otEplCod,
		   [otEplCttCod] = @otEplCttCod,
		   [otDepCod] = @otDepCod,
		   [otMtcCod] = @otMtcCod
		   , [otObsRealizacion] = @otObsRealizacion
		   , [otFPrevision]=@otFPrevision
		   , [otUsrUltMod] = @otUsrUltMod
		   , [otFecUltMod] = ISNULL(@otFecUltMod, GETDATE())
		   , [otPrioridad] = @otPrioridad
		   , [otFecRechazo] = @otFecRechazo
		   , [otUsuRechazo] = @otUsuRechazo
		   , [otTipoOrigen] = @otTipoOrigen
		   , [otPteRealizar] = @otPteRealizar
		   , [otCausaNoRealizacionCod] = @otCausaNoRealizacionCod
		   , [otComentarioNoRealizacion] = @otComentarioNoRealizacion

	WHERE (([otserscd] = @Original_otserscd) 
	  AND ([otsercod] = @Original_otsercod) 
	  AND ([otnum] = @Original_otnum) );
GO
ALTER PROCEDURE [dbo].[OrdenTrabajo_Select]
	@otserscd smallint = NULL,
	@otsercod smallint = NULL,
	@otnum int = NULL,
	@otCtrCod int = NULL,
	@otCtrVersion smallint = NULL,
	@otFechaRegDesde datetime = NULL,
	@otFechaRegHasta datetime = NULL,
	@otottcod varchar(4) = NULL,
	@anyoSolicitud INT = NULL,
	@otdessolicitud varchar(80) = NULL 
	, @otRechazada BIT = NULL
	, @otCerrada BIT = NULL
	, @otPteRealizar BIT = NULL --NULL todas, 0 No pendientes de realizar, 1 Pendientes de realizar
	, @otCausaNoRealizacionCod SMALLINT = NULL
AS SET NOCOUNT ON;

SELECT [otserscd]
      ,[otsercod]
      ,[otnum]
      ,[otfsolicitud]
      ,[otfrealizacion]
      ,[otfcierre]
      ,[otottcod]
      ,[otdessolicitud]
      ,[otdesrealizacion]
      ,[otobs]
      ,[otiptcod]
      ,[otcotcod]
      ,[otsubcotcod]
      ,[otalmcod]
	  ,[otPrvCod]
	  ,[otPobCod]
      ,[otdireccion]
      ,[otCliCod]
      ,[otCtrCod]
      ,[otCtrVersion]
      ,[otUsuSolicitud]
      ,[otUsuRealizacion]
      ,[otUsuCierre]
      ,[otEplCod]
      ,[otEplCttCod]
      ,[otDepCod]
      ,[otMtcCod]
	  ,[otObsRealizacion]
	  ,[otFPrevision]
	  ,[otFechaReg]
	  ,[otUsrUltMod]
	  ,[otFecUltMod]
	  , [otPrioridad]
	  , [otFecRechazo]
	  , [otUsuRechazo]
	  , [otTipoOrigen]
	  , [otPteRealizar]
	  , [otCausaNoRealizacionCod]
	  , [otComentarioNoRealizacion]
FROM  dbo.ordenTrabajo AS OT

WHERE  (otserscd=@otserscd OR @otserscd IS NULL) AND
	   (otsercod=@otsercod OR @otsercod IS NULL) AND
	   (otnum=@otnum OR @otnum IS NULL) AND
	   (otCtrCod=@otCtrCod OR @otCtrCod IS NULL) AND
	   (otCtrVersion=@otCtrVersion OR @otCtrVersion IS NULL) AND
	   (otFechaReg >= @otFechaRegDesde OR @otFechaRegDesde IS NULL) AND
	   (otFechaReg <= @otFechaRegHasta OR @otFechaRegHasta IS NULL) AND
	   (otottcod = @otottcod OR @otottcod IS NULL) AND
	   (YEAR(otfsolicitud) = @anyoSolicitud OR @anyoSolicitud IS NULL) AND 
	   (otdessolicitud = @otdessolicitud OR @otdessolicitud IS NULL)

	   AND (@otRechazada IS NULL OR (@otRechazada = 0 AND OT.otFecRechazo IS NULL) OR (@otRechazada = 1 AND OT.otFecRechazo IS NOT NULL))
	   AND (@otCerrada IS NULL OR (@otCerrada = 0 AND OT.otfcierre IS NULL) OR (@otCerrada = 1 AND OT.otfcierre IS NOT NULL))

	   AND (@otPteRealizar IS NULL OR (@otPteRealizar = 0 AND otPteRealizar IS NULL) OR (@otPteRealizar = 1 AND otPteRealizar = 1))
	   AND (@otCausaNoRealizacionCod IS NULL OR @otCausaNoRealizacionCod = otCausaNoRealizacionCod);
GO
ALTER PROCEDURE [dbo].[OrdenTrabajoZonasCambioContador_Select] 
	@usuario VARCHAR(10) = NULL,
	@zona VARCHAR(4) = NULL,
	@rechazadas BIT = NULL,
	@startIndex INT = 0,
	@pageSize INT = 100000000
AS SET NOCOUNT ON;
BEGIN
	DECLARE @tipoOtCC VARCHAR(4), @asignacionOtCC INT = 1, @esInspector BIT = 0;
	SELECT @tipoOtCC = pgsValor FROM parametros WHERE pgsClave = 'OT_TIPO_CC';
	SELECT @asignacionOtCC = ISNULL(pgsValor, 1) FROM parametros WHERE pgsClave = 'OTCC_ASIGNACION_OT';
	IF (@usuario IS NOT NULL) BEGIN
		SELECT @esInspector = eplInspector
		FROM empleados
		INNER JOIN usuarios ON usreplcod = eplcod AND usrcod = @usuario
	END
	SELECT otserscd, otsercod, otnum, otfsolicitud, otdessolicitud, otFecRechazo, otPrioridad, otCtrCod, otPteRealizar, otCausaNoRealizacionCod, otComentarioNoRealizacion
		, CASE WHEN otdireccion IS NULL THEN inmDireccion ELSE otdireccion END AS otdireccion 
	FROM ordenTrabajo
	INNER JOIN contratos ON otCtrCod = ctrcod AND otCtrVersion = ctrversion
	LEFT JOIN inmuebles ON ctrinmcod = inmcod
	LEFT JOIN contadorCambio ON conCamOtNum = otnum
	WHERE otottcod = @tipoOtCC
		AND otfcierre IS NULL 
		AND otfrealizacion IS NULL
		AND conCamOtNum IS NULL
		AND (@zona IS NULL OR ctrzoncod = @zona)
		AND (@rechazadas IS NULL OR (@rechazadas = 0 AND otFecRechazo IS NULL) OR (@rechazadas = 1 AND otFecRechazo IS NOT NULL))
		AND (otPteRealizar IS NULL OR otPteRealizar = 0)
		AND (@esInspector = 1 OR @usuario IS NULL OR @asignacionOtCC = 1
			OR (@asignacionOtCC = 2 AND @usuario IS NOT NULL AND (otEplCod = (SELECT usreplcod FROM usuarios WHERE usrcod = @usuario) 
				AND otEplCttCod = (SELECT usreplcttcod FROM usuarios WHERE usrcod = @usuario)))
			OR (@asignacionOtCC = 3 AND @usuario IS NOT NULL AND otEplCttCod = (SELECT usreplcttcod FROM usuarios WHERE usrcod = @usuario))
		)
	ORDER BY ctrzoncod, otPrioridad, REPLICATE('0',10-LEN(ISNULL(ctrRuta1,''))) + ISNULL(ctrRuta1,'') 
		+REPLICATE('0',10-LEN(ISNULL(ctrRuta2,''))) + ISNULL(ctrRuta2,'')
		+REPLICATE('0',10-LEN(ISNULL(ctrRuta3,''))) + ISNULL(ctrRuta3,'')
		+REPLICATE('0',10-LEN(ISNULL(ctrRuta4,''))) + ISNULL(ctrRuta4,'')
		+REPLICATE('0',10-LEN(ISNULL(ctrRuta5,''))) + ISNULL(ctrRuta5,'')
		+REPLICATE('0',10-LEN(ISNULL(ctrRuta6,''))) + ISNULL(ctrRuta6,'')
	OFFSET @startIndex ROWS  
    FETCH NEXT @pageSize ROWS ONLY
END
GO
ALTER PROCEDURE [dbo].[ZonasOtCambioContador_Select] 
	@usuario VARCHAR(10) = NULL
AS SET NOCOUNT ON;
BEGIN
	DECLARE @tipoOtCC VARCHAR(4), @asignacionOtCC INT = 1, @esInspector BIT = 0;
	SELECT @tipoOtCC = pgsValor FROM parametros WHERE pgsClave = 'OT_TIPO_CC';
	SELECT @asignacionOtCC = ISNULL(pgsValor, 1) FROM parametros WHERE pgsClave = 'OTCC_ASIGNACION_OT';
	IF (@usuario IS NOT NULL) BEGIN
		SELECT @esInspector = eplInspector
		FROM empleados
		INNER JOIN usuarios ON usreplcod = eplcod AND usrcod = @usuario
	END
	SELECT zoncod, zondes, COUNT(otnum) otAbiertas
	FROM zonas
	INNER JOIN contratos ON zoncod = ctrzoncod
	INNER JOIN ordenTrabajo ON otCtrCod = ctrcod AND otCtrVersion = ctrversion
	LEFT JOIN contadorCambio ON conCamOtNum = otnum
	WHERE otottcod = @tipoOtCC
		AND otfcierre IS NULL 
		AND otfrealizacion IS NULL
		AND (otPteRealizar IS NULL OR otPteRealizar = 0)
		AND conCamOtNum IS NULL
		AND (@esInspector = 1 OR @usuario IS NULL OR @asignacionOtCC = 1
			OR (@asignacionOtCC = 2 AND @usuario IS NOT NULL AND (otEplCod = (SELECT usreplcod FROM usuarios WHERE usrcod = @usuario) 
				AND otEplCttCod = (SELECT usreplcttcod FROM usuarios WHERE usrcod = @usuario)))
			OR (@asignacionOtCC = 3 AND @usuario IS NOT NULL AND otEplCttCod = (SELECT usreplcttcod FROM usuarios WHERE usrcod = @usuario))
		)
	GROUP BY zoncod, zondes
END
GO
