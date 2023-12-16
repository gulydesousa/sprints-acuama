--DROP TABLE otInspeccionesContratos_Melilla
--DROP TABLE otInspecciones_Melilla
CREATE TABLE otInspecciones_Melilla (
    objectid INT,
    globalid UNIQUEIDENTIFIER,
    fecha_y_hora_de_entrega_efectiv DATETIME,
    numeroinspeccion VARCHAR(25),
    zona VARCHAR(10),
    tipologiacsv VARCHAR(25),
    contrato VARCHAR(25) NOT NULL,
    domicilio VARCHAR(150),
    ruta1 VARCHAR(10),
    ruta2 VARCHAR(10),
    ruta3 VARCHAR(10),
    ruta4 VARCHAR(10),
    ruta5 VARCHAR(10),
    ruta6 VARCHAR(10),
    incidencias VARCHAR(2),
    tipoincidencia VARCHAR(100),
    servicio VARCHAR(15),
    direccion_1  VARCHAR(150),
    viviendas SMALLINT,
    facilacceso VARCHAR(2),
    armariobuenestado VARCHAR(2),
    arquetaconpuerta VARCHAR(2),
    arquetafachada VARCHAR(2),
    arquetanivelsuelo VARCHAR(2),
    caracteristicas VARCHAR(250),
    ncontadores INT,
    calibrecontador SMALLINT,
    calibre13 SMALLINT,
    calibre15 INT,
    calibre20 SMALLINT,
    calibre32 INT,
    calibre40 SMALLINT,
    calibre50 SMALLINT,
    materialtuberias  VARCHAR(25),
    llavepaso  VARCHAR(2),
    juegollaves  VARCHAR(2),
    valvularetencion  VARCHAR(2),
    tuberiaentrada  VARCHAR(2),
    roscacontadore  VARCHAR(2),
    tamanoroscae  SMALLINT,
    roscacontadors  VARCHAR(2),
    tamanoroscas SMALLINT,
    direccion_bat  VARCHAR(250),
    viviendasbat SMALLINT,
    llavescasa VARCHAR(2),
    llavescontadores VARCHAR(2),
    situacionbat VARCHAR(25),
    plantabaja  VARCHAR(2),
    accesobat  VARCHAR(2),
    usocomun  VARCHAR(2),
    llavepasocerca  VARCHAR(2),
    sepradogas  VARCHAR(2),
    armarioid  VARCHAR(2),
    armariounico  VARCHAR(2),
    armario12  VARCHAR(2),
    instestanca  VARCHAR(2),
    desague  VARCHAR(2),
    aljibe VARCHAR(2),
    idvivienda  VARCHAR(2),
    tecnicas_bat_1 SMALLINT,
    calibrebat VARCHAR(25),
    tecnicas_bat_2 SMALLINT,
    tecnicas_bat_3 SMALLINT,
    tecnicas_bat_4 SMALLINT,
    tecnicas_bat_5 SMALLINT,
    tecnicas_bat_6 SMALLINT,
    tecnicas_bat_7 SMALLINT,
    tecnicas_bat_8 VARCHAR(25),
    tecnicas_bat_9 VARCHAR(2),
    tecnicas_bat_10 VARCHAR(2),
    tecnicas_bat_11 VARCHAR(2),
    tecnicas_bat_12 VARCHAR(2),
    tecnicas_bat_13 VARCHAR(2),
    tecnicas_bat_14 VARCHAR(2),
    tecnicas_bat_15 VARCHAR(2),
    tecnicas_bat_16 VARCHAR(2),
    tecnicas_bat_17 VARCHAR(2),
    tecnicas_bat_18 VARCHAR(2),
    tecnicas_bat_19 VARCHAR(2),
    tecnicas_bat_20 VARCHAR(2),
    roscacontadorebat VARCHAR(2),
    tamanoroscaebat SMALLINT,
    roscacontadorsbat  VARCHAR(2),
    tamanoroscasbat SMALLINT,
    valvularetencionentrada VARCHAR(2),
    cerradura VARCHAR(2),
    estadobat VARCHAR(25),
    usuario  VARCHAR(25),
    observaciones  VARCHAR(250),
    apto VARCHAR(2),
    aptono5 VARCHAR(10),
    aptono6 VARCHAR(10),
    aptono2 VARCHAR(10),
    aptono3 VARCHAR(10),
    created_date DATETIME,
    created_user VARCHAR(25),
    last_edited_date DATETIME,
    last_edited_user VARCHAR(25),
    countattachments SMALLINT,
    attachid INT,
    url VARCHAR(250),
    attachid_last INT,
    url_final  VARCHAR(250),
    domicilio_v2 VARCHAR(250),
    calibre65 SMALLINT,
    calibre80 SMALLINT,
    calibre100 SMALLINT,
    estadocontador VARCHAR(2),
    tecnicas_bat_7_1 VARCHAR(10),
    tecnicas_bat_7_2 VARCHAR(10),
    tecnicas_bat_7_3 VARCHAR(10),
    juegollavesbat VARCHAR(2),
    realizado_user  VARCHAR(25),
    x FLOAT,
    y FLOAT,

	otiserscd SMALLINT NULL,
	otisercod SMALLINT NULL,
	otinum INT NULL,
	ctrcod INT NULL,
	UsuarioCarga VARCHAR(10) NOT NULL,
	FechaCarga DATETIME NOT NULL,

	CONSTRAINT FK_otInspecciones_ot FOREIGN KEY (otiserscd, otisercod, otinum) 
	REFERENCES ordenTrabajo(otserscd, otsercod, otnum),

	CONSTRAINT FK_otInspecciones_usuarios FOREIGN KEY (UsuarioCarga) 
	REFERENCES usuarios(usrcod),

	CONSTRAINT PK_otInspecciones_Melilla PRIMARY KEY CLUSTERED (objectid));