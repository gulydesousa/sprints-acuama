/*
 DECLARE @objectid INT,
    @globalid UNIQUEIDENTIFIER,
    @fecha_y_hora_de_entrega_efectiv DATETIME=NULL,
    @numeroinspeccion VARCHAR(25)=NULL,
    @zona VARCHAR(10)=NULL,
    @tipologiacsv VARCHAR(25)=NULL,
    @contrato  VARCHAR(25)=NULL,
	  @ctrcod  int=NULL,
    @domicilio VARCHAR(150)=NULL,
    @ruta1 VARCHAR(10)=NULL,
    @ruta2 VARCHAR(10)=NULL,
    @ruta3 VARCHAR(10)=NULL,
    @ruta4 VARCHAR(10)=NULL,
    @ruta5 VARCHAR(10)=NULL,
    @ruta6 VARCHAR(10)=NULL,
    @incidencias VARCHAR(2)=NULL,
    @tipoincidencia VARCHAR(100)=NULL,
    @servicio VARCHAR(15)=NULL,
    @direccion_1 VARCHAR(150)=NULL,
    @viviendas SMALLINT=NULL,
    @facilacceso VARCHAR(2)=NULL,
    @armariobuenestado VARCHAR(2)=NULL,
    @arquetaconpuerta VARCHAR(2)=NULL,
    @arquetafachada VARCHAR(2)=NULL,
    @arquetanivelsuelo VARCHAR(2)=NULL,
    @caracteristicas VARCHAR(250)=NULL,
    @ncontadores INT=NULL,
    @calibrecontador SMALLINT=NULL,
    @calibre13 SMALLINT=NULL,
    @calibre15 INT=NULL,
    @calibre20 SMALLINT=NULL,
    @calibre32 INT=NULL,
    @calibre40 SMALLINT=NULL,
    @calibre50 SMALLINT=NULL,
    @materialtuberias VARCHAR(25)=NULL,
    @llavepaso VARCHAR(2)=NULL,
    @juegollaves VARCHAR(2)=NULL,
    @valvularetencion VARCHAR(2)=NULL,
    @tuberiaentrada VARCHAR(2)=NULL,
    @roscacontadore VARCHAR(2)=NULL,
    @tamanoroscae SMALLINT=NULL,
    @roscacontadors VARCHAR(2)=NULL,
    @tamanoroscas SMALLINT=NULL,
    @direccion_bat VARCHAR(250)=NULL,
    @viviendasbat SMALLINT=NULL,
    @llavescasa VARCHAR(2)=NULL,
    @llavescontadores VARCHAR(2)=NULL,
    @situacionbat VARCHAR(25)=NULL,
    @plantabaja VARCHAR(2)=NULL,
    @accesobat VARCHAR(2)=NULL,
    @usocomun VARCHAR(2)=NULL,
    @llavepasocerca VARCHAR(2)=NULL,
    @sepradogas VARCHAR(2)=NULL,
    @armarioid VARCHAR(2)=NULL,
    @armariounico VARCHAR(2)=NULL,
    @armario12 VARCHAR(2)=NULL,
    @instestanca VARCHAR(2)=NULL,
    @desague VARCHAR(2)=NULL,
    @aljibe VARCHAR(2)=NULL,
    @idvivienda VARCHAR(2)=NULL,
    @tecnicas_bat_1 SMALLINT=NULL,
    @calibrebat VARCHAR(25)=NULL,
    @tecnicas_bat_2 SMALLINT=NULL,
    @tecnicas_bat_3 SMALLINT=NULL,
    @tecnicas_bat_4 SMALLINT=NULL,
    @tecnicas_bat_5 SMALLINT=NULL,
    @tecnicas_bat_6 SMALLINT=NULL,
    @tecnicas_bat_7 SMALLINT=NULL,
    @tecnicas_bat_8 VARCHAR(25)=NULL,
    @tecnicas_bat_9 VARCHAR(2)=NULL,
    @tecnicas_bat_10 VARCHAR(2)=NULL,
    @tecnicas_bat_11 VARCHAR(2)=NULL,
    @tecnicas_bat_12 VARCHAR(2)=NULL,
    @tecnicas_bat_13 VARCHAR(2)=NULL,
    @tecnicas_bat_14 VARCHAR(2)=NULL,
    @tecnicas_bat_15 VARCHAR(2)=NULL,
    @tecnicas_bat_16 VARCHAR(2)=NULL,
    @tecnicas_bat_17 VARCHAR(2)=NULL,
    @tecnicas_bat_18 VARCHAR(2)=NULL,
    @tecnicas_bat_19 VARCHAR(2)=NULL,
    @tecnicas_bat_20 VARCHAR(2)=NULL,
    @roscacontadorebat VARCHAR(2)=NULL,
    @tamanoroscaebat SMALLINT=NULL,
    @roscacontadorsbat VARCHAR(2)=NULL,
    @tamanoroscasbat SMALLINT=NULL,
    @valvularetencionentrada VARCHAR(2)=NULL,
    @cerradura VARCHAR(2)=NULL,
    @estadobat VARCHAR(25)=NULL,
    @usuario VARCHAR(25)=NULL,
    @observaciones VARCHAR(250)=NULL,
    @apto VARCHAR(2)=NULL,
    @aptono5 VARCHAR(10)=NULL,
    @aptono6 VARCHAR(10)=NULL,
    @aptono2 VARCHAR(10)=NULL,
    @aptono3 VARCHAR(10)=NULL,
    @created_date DATETIME=NULL,
    @created_user VARCHAR(25)=NULL,
    @last_edited_date DATETIME=NULL,
    @last_edited_user VARCHAR(25)=NULL,
    @countattachments SMALLINT=NULL,
    @attachid INT=NULL,
    @url VARCHAR(250)=NULL,
    @attachid_last INT=NULL,
    @url_final VARCHAR(250)=NULL,
    @domicilio_v2 VARCHAR(250)=NULL,
    @calibre65 SMALLINT=NULL,
    @calibre80 SMALLINT=NULL,
    @calibre100 SMALLINT=NULL,
    @estadocontador VARCHAR(2)=NULL,
    @tecnicas_bat_7_1 VARCHAR(10)=NULL,
    @tecnicas_bat_7_2 VARCHAR(10)=NULL,
    @tecnicas_bat_7_3 VARCHAR(10)=NULL,
    @juegollavesbat VARCHAR(2)=NULL,
    @realizado_user VARCHAR(25)=NULL,
    @x FLOAT=NULL,
    @y FLOAT=NULL,
    @otiserscd SMALLINT=NULL,
    @otisercod SMALLINT=NULL,
    @otinum INT=NULL,
    @UsuarioCarga VARCHAR(10)=NULL,
    @FechaCarga DATETIME=NULL

SET @aptono6='NO APTO'; SET @armariobuenestado='NO'; SET @arquetaconpuerta='NO'; SET @arquetafachada='SI'; 
SET @arquetanivelsuelo='NO'; SET @calibre13=1; SET @calibrecontador=13; SET @contrato='24988'; SET @ctrcod=24988; 
SET @created_date='20231002 11:54:00'; SET @created_user='hmohamed@sacyr.com'; 
SET @direccion_1='CL/ CAMINO DE CARROS; SET  Nº S/N'; SET @direccion_bat='CL/ CAMINO DE CARROS; SET  Nº S/N'; 
SET @domicilio='CL/ CAMINO DE CARROS; SET  Nº S/N'; SET @estadocontador='SI'; 
SET @facilacceso='NO'; SET @fecha_y_hora_de_entrega_efectiv='20231002 08:40:00'; 
SET @globalid='585C0747-71D8-48DF-942A-B1BB0ABD974D'; SET @incidencias='SI'; SET @juegollaves='NO'; 
SET @last_edited_date='20231002 11:54:00'; SET @last_edited_user='hmohamed@sacyr.com'; SET @llavepaso='NO'; 
SET @materialtuberias='PE'; SET @ncontadores=1; SET @numeroinspeccion='Inspeccion_231002104038'; SET @objectid=5129; 
SET @FechaCarga='20231114 12:47:33.360'; SET @UsuarioCarga='gmdesousa'; SET @roscacontadore='SI'; SET @roscacontadors='SI'; 
SET @ruta1='9'; SET @ruta2='30'; SET @ruta3='N/A'; SET @ruta4='14545'; SET @ruta5='N/A'; SET @ruta6='N/A'; SET @servicio='CONTADORES'; 
SET @tamanoroscae=20; SET @tamanoroscas=20; SET @tipologiacsv='Contador Individual'; SET @tuberiaentrada='SI'; SET @usuario='H'; 
SET @valvularetencion='NO'; SET @viviendas=1; SET @x=-2.9504756927490234; SET @y=35.271385192871094; SET @zona='ZONA 3'
*/
ALTER PROCEDURE dbo.otInspecciones_Melilla_Insert
(
    @objectid INT,
    @globalid UNIQUEIDENTIFIER,
    @fecha_y_hora_de_entrega_efectiv DATETIME=NULL,
    @numeroinspeccion VARCHAR(25)=NULL,
    @zona VARCHAR(10)=NULL,
    @tipologiacsv VARCHAR(25)=NULL,
    @contrato  VARCHAR(25)=NULL,
    @domicilio VARCHAR(150)=NULL,
    @ruta1 VARCHAR(10)=NULL,
    @ruta2 VARCHAR(10)=NULL,
    @ruta3 VARCHAR(10)=NULL,
    @ruta4 VARCHAR(10)=NULL,
    @ruta5 VARCHAR(10)=NULL,
    @ruta6 VARCHAR(10)=NULL,
    @incidencias VARCHAR(2)=NULL,
    @tipoincidencia VARCHAR(100)=NULL,
    @servicio VARCHAR(15)=NULL,
    @direccion_1 VARCHAR(150)=NULL,
    @viviendas SMALLINT=NULL,
    @facilacceso VARCHAR(2)=NULL,
    @armariobuenestado VARCHAR(2)=NULL,
    @arquetaconpuerta VARCHAR(2)=NULL,
    @arquetafachada VARCHAR(2)=NULL,
    @arquetanivelsuelo VARCHAR(2)=NULL,
    @caracteristicas VARCHAR(250)=NULL,
    @ncontadores INT=NULL,
    @calibrecontador SMALLINT=NULL,
    @calibre13 SMALLINT=NULL,
    @calibre15 INT=NULL,
    @calibre20 SMALLINT=NULL,
    @calibre32 INT=NULL,
    @calibre40 SMALLINT=NULL,
    @calibre50 SMALLINT=NULL,
    @materialtuberias VARCHAR(25)=NULL,
    @llavepaso VARCHAR(2)=NULL,
    @juegollaves VARCHAR(2)=NULL,
    @valvularetencion VARCHAR(2)=NULL,
    @tuberiaentrada VARCHAR(2)=NULL,
    @roscacontadore VARCHAR(2)=NULL,
    @tamanoroscae SMALLINT=NULL,
    @roscacontadors VARCHAR(2)=NULL,
    @tamanoroscas SMALLINT=NULL,
    @direccion_bat VARCHAR(250)=NULL,
    @viviendasbat SMALLINT=NULL,
    @llavescasa VARCHAR(2)=NULL,
    @llavescontadores VARCHAR(2)=NULL,
    @situacionbat VARCHAR(25)=NULL,
    @plantabaja VARCHAR(2)=NULL,
    @accesobat VARCHAR(2)=NULL,
    @usocomun VARCHAR(2)=NULL,
    @llavepasocerca VARCHAR(2)=NULL,
    @sepradogas VARCHAR(2)=NULL,
    @armarioid VARCHAR(2)=NULL,
    @armariounico VARCHAR(2)=NULL,
    @armario12 VARCHAR(2)=NULL,
    @instestanca VARCHAR(2)=NULL,
    @desague VARCHAR(2)=NULL,
    @aljibe VARCHAR(2)=NULL,
    @idvivienda VARCHAR(2)=NULL,
    @tecnicas_bat_1 SMALLINT=NULL,
    @calibrebat VARCHAR(25)=NULL,
    @tecnicas_bat_2 SMALLINT=NULL,
    @tecnicas_bat_3 SMALLINT=NULL,
    @tecnicas_bat_4 SMALLINT=NULL,
    @tecnicas_bat_5 SMALLINT=NULL,
    @tecnicas_bat_6 SMALLINT=NULL,
    @tecnicas_bat_7 SMALLINT=NULL,
    @tecnicas_bat_8 VARCHAR(25)=NULL,
    @tecnicas_bat_9 VARCHAR(2)=NULL,
    @tecnicas_bat_10 VARCHAR(2)=NULL,
    @tecnicas_bat_11 VARCHAR(2)=NULL,
    @tecnicas_bat_12 VARCHAR(2)=NULL,
    @tecnicas_bat_13 VARCHAR(2)=NULL,
    @tecnicas_bat_14 VARCHAR(2)=NULL,
    @tecnicas_bat_15 VARCHAR(2)=NULL,
    @tecnicas_bat_16 VARCHAR(2)=NULL,
    @tecnicas_bat_17 VARCHAR(2)=NULL,
    @tecnicas_bat_18 VARCHAR(2)=NULL,
    @tecnicas_bat_19 VARCHAR(2)=NULL,
    @tecnicas_bat_20 VARCHAR(2)=NULL,
    @roscacontadorebat VARCHAR(2)=NULL,
    @tamanoroscaebat SMALLINT=NULL,
    @roscacontadorsbat VARCHAR(2)=NULL,
    @tamanoroscasbat SMALLINT=NULL,
    @valvularetencionentrada VARCHAR(2)=NULL,
    @cerradura VARCHAR(2)=NULL,
    @estadobat VARCHAR(25)=NULL,
    @usuario VARCHAR(25)=NULL,
    @observaciones VARCHAR(250)=NULL,
    @apto VARCHAR(2)=NULL,
    @aptono5 VARCHAR(10)=NULL,
    @aptono6 VARCHAR(10)=NULL,
    @aptono2 VARCHAR(10)=NULL,
    @aptono3 VARCHAR(10)=NULL,
    @created_date DATETIME=NULL,
    @created_user VARCHAR(25)=NULL,
    @last_edited_date DATETIME=NULL,
    @last_edited_user VARCHAR(25)=NULL,
    @countattachments SMALLINT=NULL,
    @attachid INT=NULL,
    @url VARCHAR(250)=NULL,
    @attachid_last INT=NULL,
    @url_final VARCHAR(250)=NULL,
    @domicilio_v2 VARCHAR(250)=NULL,
    @calibre65 SMALLINT=NULL,
    @calibre80 SMALLINT=NULL,
    @calibre100 SMALLINT=NULL,
    @estadocontador VARCHAR(2)=NULL,
    @tecnicas_bat_7_1 VARCHAR(10)=NULL,
    @tecnicas_bat_7_2 VARCHAR(10)=NULL,
    @tecnicas_bat_7_3 VARCHAR(10)=NULL,
    @juegollavesbat VARCHAR(2)=NULL,
    @realizado_user VARCHAR(25)=NULL,
    @x FLOAT=NULL,
    @y FLOAT=NULL,
    @otiserscd SMALLINT=NULL,
    @otisercod SMALLINT=NULL,
    @otinum INT=NULL,
    @ctrcod INT = NULL,
    @UsuarioCarga VARCHAR(10)=NULL,
    @FechaCarga DATETIME=NULL
)
AS

	SET NOCOUNT ON;

	DECLARE @sociedad INT, @serie INT, @otnum INT;
	DECLARE @usrCreated AS VARCHAR(10)='admin', @usrRealizado AS VARCHAR(10);
	DECLARE @ottcod AS VARCHAR(4);
	DECLARE @cotcod AS VARCHAR(6);
	DECLARE @obs VARCHAR(500) = CONCAT('Contrato: ' ,  @contrato ,  ' ' ,  @observaciones);
	DECLARE @otDatosAPTO INT = 2001;

	BEGIN TRY
		--Obtenemos los usuarios a partir de su email
		SELECT @usrCreated = U.usrcod 
		FROM dbo.usuarios AS U
		INNER JOIN dbo.empleados AS E
		ON  U.usreplcod = E.eplcod
		AND U.usreplcttcod = E.eplcttcod
		WHERE @created_user IS NOT NULL AND E.eplmail=@created_user;
	
		SELECT @usrRealizado = U.usrcod 
		FROM dbo.usuarios AS U
		INNER JOIN dbo.empleados AS E
		ON  U.usreplcod = E.eplcod
		AND U.usreplcttcod = E.eplcttcod
		WHERE @created_user IS NOT NULL AND E.eplnom=UPPER(@realizado_user);

		SELECT @ottcod = ottcod FROM ottipos WHERE ottdes='INSPECCIÓN';

		SELECT @cotcod = cotcod FROM [clasifot] WHERE cotdes='SIN CLASIFICACION';
		
		BEGIN TRAN;

		--Si el registro ya estaba cargado, antes de borrarlo nos quedamos con las inspecciones hijas
		DECLARE @HIJAS AS TABLE ( 
		[CONTRATO GENERAL] VARCHAR(25) NOT NULL,
		[CONTRATO ABONADO] VARCHAR(25) NOT NULL,
		[ZONA] VARCHAR(10),
		[Dir. Suministro] VARCHAR(250),
		[EMPLAZAMIENTO] VARCHAR(25),
		[INSPECCION] INT,
		UsuarioCarga VARCHAR(10),
		FechaCarga DATETIME );

		DELETE FROM dbo.otInspeccionesContratos_Melilla
		OUTPUT DELETED.[CONTRATO GENERAL]
			 , DELETED.[CONTRATO ABONADO]
			 , DELETED.[ZONA]
			 , DELETED.[Dir. Suministro]
			 , DELETED.[EMPLAZAMIENTO]
			 , DELETED.[INSPECCION]
			 , DELETED.UsuarioCarga
			 , DELETED.FechaCarga
		INTO @HIJAS  
		WHERE [INSPECCION]  = @objectid;

		
		--Si el registro ya estaba cargado, lo borramos y nos quedamos con el id de la ot
		SELECT @sociedad = T.otiserscd
				, @serie = T.otisercod
				, @otnum = T.otinum
		FROM dbo.otInspecciones_Melilla AS T
		WHERE T.objectid = @objectid;



		DELETE dbo.otInspecciones_Melilla WHERE objectid = @objectid;
		
		DELETE dbo.otDatosValor 
		WHERE otdvOtSerScd=@sociedad 
		AND otdvOtSerCod= @serie 
		AND otdvOtNum=@otnum
		AND otdvOdtCodigo=@otDatosAPTO;
		
		
		--Si no existia antes: Creamos una OT e insertamos el registro
		IF(@otnum IS NULL)
		BEGIN
			SELECT @sociedad=pgsvalor FROM dbo.parametros WHERE pgsclave LIKE 'SOCIEDAD_POR_DEFECTO';
			SELECT @serie=sercod FROM dbo.series WHERE sertipo='OT' AND serscd=@sociedad;
			
			EXEC dbo.OrdenTrabajo_Insert @otserscd=@sociedad,
			@otsercod = @serie, 
			@otfsolicitud = @created_date,
			@otfrealizacion = @fecha_y_hora_de_entrega_efectiv,
			@otfcierre = @fecha_y_hora_de_entrega_efectiv,
			@otottcod = @ottcod,
			@otdessolicitud = @objectid, 
			@otdesrealizacion = @tipoincidencia,
			@otobs = @obs,
			@otiptcod=1, --SELECT * FROM imputaciones
			@otcotcod = @cotcod,
			@otsubcotcod = NULL, 
			@otalmcod = 1, --SELECT * FROM almacenes
			@otPrvCod = NULL,
			@otPobCod = NULL,
			@otdireccion = @direccion_1,
			@otCliCod = NULL,
			@otCtrCod = @ctrCod,
			@otCtrVersion = NULL,
			@otUsuSolicitud = @usrCreated, 
			@otUsuRealizacion = @usrRealizado,
			@otUsuCierre = @usrRealizado,
			@otEplCod = NULL,
			@otEplCttCod = NULL,
			@otDepCod = NULL, 
			@otMtcCod = NULL, 
			@otObsRealizacion = @numeroinspeccion,
			@otFechaReg = @FechaCarga,
			@otFPrevision = NULL,
			@otPrioridad = NULL,
			@otFecRechazo = NULL, 
			@otTipoOrigen = 'INSPMASIVO',
			@otPteRealizar = 0,
			@otCausaNoRealizacionCod = NULL,
			@otComentarioNoRealizacion = NULL,
			@otnumNuevo = @otnum OUTPUT;
		END	
		ELSE
		BEGIN
			--Si existía actualizamos la OT
			EXEC dbo.OrdenTrabajo_Update 
			@Original_otserscd=@sociedad,
			@Original_otsercod = @serie, 
			@Original_otnum = @otnum,
			@otfsolicitud = @created_date,
			@otfrealizacion = @fecha_y_hora_de_entrega_efectiv,
			@otfcierre = NULL, --@fecha_y_hora_de_entrega_efectiv,
			@otottcod = @ottcod,
			@otdessolicitud = @objectid, 
			@otdesrealizacion = @tipoincidencia,
			@otobs = @obs,
			@otiptcod=1,--SELECT * FROM imputaciones
			@otcotcod = @cotcod,
			@otsubcotcod = NULL, 
			@otalmcod = 1,--SELECT * FROM almacenes
			@otPrvCod = NULL,
			@otPobCod = NULL,
			@otdireccion = @direccion_1,
			@otCliCod = NULL,
			@otCtrCod = @ctrCod,
			@otCtrVersion = NULL,
			@otUsuSolicitud = @usrCreated, 
			@otUsuRealizacion = @usrRealizado,
			@otUsuCierre = @usrRealizado,
			@otEplCod = NULL,
			@otEplCttCod = NULL,
			@otDepCod = NULL, 
			@otMtcCod = NULL, 
			@otObsRealizacion = @numeroinspeccion,
			--@otFechaReg = @otiFechaCarga,
			@otFPrevision = NULL,
			@otPrioridad = NULL,
			@otFecRechazo = NULL, 
			@otTipoOrigen = 'INSPMASIVO',
			@otPteRealizar = 0,
			@otCausaNoRealizacionCod = NULL,
			@otComentarioNoRealizacion = NULL;
		END

		INSERT INTO otInspecciones_Melilla (
			objectid,
			globalid,
			fecha_y_hora_de_entrega_efectiv,
			numeroinspeccion,
			zona,
			tipologiacsv,
			contrato,
			domicilio,
			ruta1,
			ruta2,
			ruta3,
			ruta4,
			ruta5,
			ruta6,
			incidencias,
			tipoincidencia,
			servicio,
			direccion_1,
			viviendas,
			facilacceso,
			armariobuenestado,
			arquetaconpuerta,
			arquetafachada,
			arquetanivelsuelo,
			caracteristicas,
			ncontadores,
			calibrecontador,
			calibre13,
			calibre15,
			calibre20,
			calibre32,
			calibre40,
			calibre50,
			materialtuberias,
			llavepaso,
			juegollaves,
			valvularetencion,
			tuberiaentrada,
			roscacontadore,
			tamanoroscae,
			roscacontadors,
			tamanoroscas,
			direccion_bat,
			viviendasbat,
			llavescasa,
			llavescontadores,
			situacionbat,
			plantabaja,
			accesobat,
			usocomun,
			llavepasocerca,
			sepradogas,
			armarioid,
			armariounico,
			armario12,
			instestanca,
			desague,
			aljibe,
			idvivienda,
			tecnicas_bat_1,
			calibrebat,
			tecnicas_bat_2,
			tecnicas_bat_3,
			tecnicas_bat_4,
			tecnicas_bat_5,
			tecnicas_bat_6,
			tecnicas_bat_7,
			tecnicas_bat_8,
			tecnicas_bat_9,
			tecnicas_bat_10,
			tecnicas_bat_11,
			tecnicas_bat_12,
			tecnicas_bat_13,
			tecnicas_bat_14,
			tecnicas_bat_15,
			tecnicas_bat_16,
			tecnicas_bat_17,
			tecnicas_bat_18,
			tecnicas_bat_19,
			tecnicas_bat_20,
			roscacontadorebat,
			tamanoroscaebat,
			roscacontadorsbat,
			tamanoroscasbat,
			valvularetencionentrada,
			cerradura,
			estadobat,
			usuario,
			observaciones,
			apto,
			aptono5,
			aptono6,
			aptono2,
			aptono3,
			created_date,
			created_user,
			last_edited_date,
			last_edited_user,
			countattachments,
			attachid,
			url,
			attachid_last,
			url_final,
			domicilio_v2,
			calibre65,
			calibre80,
			calibre100,
			estadocontador,
			tecnicas_bat_7_1,
			tecnicas_bat_7_2,
			tecnicas_bat_7_3,
			juegollavesbat,
			realizado_user,
			x,
			y,
			otiserscd,
			otisercod,
			otinum,
			UsuarioCarga,
			FechaCarga,
			ctrcod
		)
		OUTPUT INSERTED.*
		VALUES (
			@objectid,
			@globalid,
			@fecha_y_hora_de_entrega_efectiv,
			@numeroinspeccion,
			@zona,
			@tipologiacsv,
			@contrato,
			@domicilio,
			@ruta1,
			@ruta2,
			@ruta3,
			@ruta4,
			@ruta5,
			@ruta6,
			@incidencias,
			@tipoincidencia,
			@servicio,
			@direccion_1,
			@viviendas,
			@facilacceso,
			@armariobuenestado,
			@arquetaconpuerta,
			@arquetafachada,
			@arquetanivelsuelo,
			@caracteristicas,
			@ncontadores,
			@calibrecontador,
			@calibre13,
			@calibre15,
			@calibre20,
			@calibre32,
			@calibre40,
			@calibre50,
			@materialtuberias,
			@llavepaso,
			@juegollaves,
			@valvularetencion,
			@tuberiaentrada,
			@roscacontadore,
			@tamanoroscae,
			@roscacontadors,
			@tamanoroscas,
			@direccion_bat,
			@viviendasbat,
			@llavescasa,
			@llavescontadores,
			@situacionbat,
			@plantabaja,
			@accesobat,
			@usocomun,
			@llavepasocerca,
			@sepradogas,
			@armarioid,
			@armariounico,
			@armario12,
			@instestanca,
			@desague,
			@aljibe,
			@idvivienda,
			@tecnicas_bat_1,
			@calibrebat,
			@tecnicas_bat_2,
			@tecnicas_bat_3,
			@tecnicas_bat_4,
			@tecnicas_bat_5,
			@tecnicas_bat_6,
			@tecnicas_bat_7,
			@tecnicas_bat_8,
			@tecnicas_bat_9,
			@tecnicas_bat_10,
			@tecnicas_bat_11,
			@tecnicas_bat_12,
			@tecnicas_bat_13,
			@tecnicas_bat_14,
			@tecnicas_bat_15,
			@tecnicas_bat_16,
			@tecnicas_bat_17,
			@tecnicas_bat_18,
			@tecnicas_bat_19,
			@tecnicas_bat_20,
			@roscacontadorebat,
			@tamanoroscaebat,
			@roscacontadorsbat,
			@tamanoroscasbat,
			@valvularetencionentrada,
			@cerradura,
			@estadobat,
			@usuario,
			@observaciones,
			@apto,
			@aptono5,
			@aptono6,
			@aptono2,
			@aptono3,
			@created_date,
			@created_user,
			@last_edited_date,
			@last_edited_user,
			@countattachments,
			@attachid,
			@url,
			@attachid_last,
			@url_final,
			@domicilio_v2,
			@calibre65,
			@calibre80,
			@calibre100,
			@estadocontador,
			@tecnicas_bat_7_1,
			@tecnicas_bat_7_2,
			@tecnicas_bat_7_3,
			@juegollavesbat,
			@realizado_user,
			@x,
			@y,
			@sociedad,
			@serie,
			@otnum,
			@UsuarioCarga,
			@FechaCarga,
			@ctrcod);

			--*********************************************
			--DATOSVALOR: APTO
			--Si todas las variables marcada como criticas son afirmativas “SI” entonces es APTO. 
			--Si falla cualquiera de ellas sería NO APTO.
			--*********************************************			
			DECLARE @OTAPTO AS VARCHAR(10) = '';
			EXEC  OtInspecciones_Melilla_EsApto @objectid, @OTAPTO OUTPUT;
			
			INSERT INTO dbo.otDatosValor (otdvOtSerScd, otdvOtSerCod, otdvOtNum, otdvOdtCodigo, otdvValor, otdvManual)
			VALUES (@sociedad , @serie , @otnum, @otDatosAPTO, @OTAPTO, 0);

			--Reinsertamos las inspecciones por contrato
			INSERT INTO dbo.otInspeccionesContratos_Melilla
			SELECT * FROM @HIJAS;
		COMMIT TRAN;
	
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 
		ROLLBACK TRAN;

		THROW; -- Re-throw the exception
	END CATCH
GO