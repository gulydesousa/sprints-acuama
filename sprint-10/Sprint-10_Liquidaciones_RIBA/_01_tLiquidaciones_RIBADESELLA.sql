--DROP TYPE tLiquidaciones_RIBADESELLA

CREATE TYPE [dbo].[tLiquidaciones_RIBADESELLA] AS TABLE(
	[EJ] [char](2) NULL,
	[ENTEMI] [char](3) NULL,
	[AYTO] [char](3) NULL,
	[TRIBUTO] [char](3) NULL,
	[ANUALIDAD] [char](2) NULL,
	[NUMLIQ] [char](12) NULL,
	[NOMCER] [char](12) NULL,
	[PRINCI] [char](9) NULL,
	[INIVOL] [char](6) NULL,
	[FINVOL] [char](6) NULL,
	[CONTRI] [char](40) NULL,
	[DNI] [char](9) NULL,
	[SIGLAS] [char](2) NULL,
	[LUGAR] [char](38) NULL,
	[POBLACION] [char](15) NULL,
	[MUNICIPIO] [char](3) NULL,
	[PROVINCIA] [char](2) NULL,
	[CPP] [char](5) NULL,
	[CONCEPTO] [char](20) NULL,
	[CLAVE1] [char](1) NULL,
	[CONYUGE] [char](40) NULL,
	[NIFCON] [char](9) NULL,
	[FECHACER] [char](6) NULL,
	[DETALLE] [char](64) NULL,
	[OTRA1] [char](64) NULL,
	[OTRA2] [char](78) NULL,
	[LOTE] [char](4) NULL,
	[MODONOT] [char](1) NULL,
	[FECHALIQ] [char](6) NULL,
	[PERIODO] [char](2) NULL,
	[FECHAFIR] [char](6) NULL,
	[REPRE] [char](40) NULL,
	[DIREREPRE] [char](55) NULL,
	[MUNIREPRE] [char](3) NULL,
	[PROVIREPRE] [char](2) NULL,
	[CPPREPRE] [char](5) NULL,
	[IMPENT] [char](9) NULL,
	[FINGRE] [char](6) NULL,
	[ORGOFI] [char](2) NULL,
	[IVA] [char](9) NULL,
	------------------------------------
	[FECHA_APREMIO] [char](6) NULL,
	[CODAGUA180] [char](2) NULL,
	[IMPAGUA180] [char](8) NULL,
	[IVAAGUA180] [char](8) NULL,

	[CODBASURA180] [char](2) NULL,
	[IMPBASURA180] [char](8) NULL,
	
	[CODALC180] [char](2) NULL,
	[IMPALC180] [char](8) NULL,
	
	[CODMIN180] [char](2) NULL,
	[IMPMIN180] [char](8) NULL,

	[CODTCONT180] [char](2) NULL,
	[IMPTCONT180] [char](8) NULL,
	[IVATCONT180] [char](8) NULL,

	[CODCANON180] [char](2) NULL,
	[IMPCANON180] [char](8) NULL,
	
	[CODOTRO1180] [char](2) NULL,
	[IMPOTRO1180] [char](8) NULL,
	
	[CODOTRO2180] [char](2) NULL,
	[IMPOTRO2180] [char](8) NULL,
	
	[PRESCRIPCION] [char](3) NULL,
	-----------------------------
	[TOTAL_BASE] MONEY NULL,
	[TOTAL_IVA] MONEY NULL,
	[PK] [int] NOT NULL,
	PRIMARY KEY CLUSTERED 
(
	[PK] ASC
)WITH (IGNORE_DUP_KEY = OFF)
)
GO


