--DROP TABLE otInspeccionesContratos_Melilla
CREATE TABLE otInspeccionesContratos_Melilla (
    [CONTRATO GENERAL] VARCHAR(25) NOT NULL,
    [CONTRATO ABONADO] VARCHAR(25) NOT NULL,
    [ZONA] VARCHAR(10),
	[Dir. Suministro] VARCHAR(250),
	[EMPLAZAMIENTO] VARCHAR(25),
	[INSPECCION] INT,
	UsuarioCarga VARCHAR(10) NOT NULL,
	FechaCarga DATETIME NOT NULL,

	CONSTRAINT FK_otInspeccionesHijos_otInspecciones FOREIGN KEY ([INSPECCION]) 
	REFERENCES otInspecciones_Melilla(objectid),

	CONSTRAINT PK_otInspeccionesHijos_Melilla PRIMARY KEY CLUSTERED ([INSPECCION], [CONTRATO ABONADO]));