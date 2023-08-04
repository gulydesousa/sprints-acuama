--DROP TYPE [dbo].[tFacLin_Situacion]
CREATE TYPE [dbo].[tFacLin_situacion] AS TABLE(
	[FAC_ID]			INT NOT NULL,
	[facCod]			SMALLINT NOT NULL,
	[facPerCod]			VARCHAR(6) NOT NULL,
	[facCtrCod]			INT NOT NULL,
	[facVersion]		SMALLINT NOT NULL,
	[fclNumLinea]		INT NOT NULL,

	[periodoMensual]	VARCHAR(6),
	[periodoRegistrado] VARCHAR(6),
	[periodo]			VARCHAR(6),

	[cuatrimestre]		SMALLINT,
	[BloqueId]			SMALLINT,

	[fclTrfSvCod]		SMALLINT NOT NULL,
	[fclTrfCod]			SMALLINT NOT NULL,

	[servTarifa]		VARCHAR(10),
	[esServicio]		TINYINT,
	[desServTarifa]		VARCHAR(50),

	[facZonCod]			VARCHAR(4),
	[przTipo]			VARCHAR(50),

	[facFechaRectif]	DATETIME,
	[facFecha]			DATETIME,
	[facFechaV1]		DATETIME,

	[fclBase]			MONEY,
	[fclImpImpuesto]	MONEY,
	[fcltotal]			MONEY,

	[cargoFijo]			DECIMAL(12, 4),
	[consumo]			DECIMAL(12, 4),

	--Campo auxiliar para clasificar las facturas
	[Original]			TINYINT, 
	[Anulada]			TINYINT, 
	[Creada]			TINYINT, 
	[Cobrada]			TINYINT,
	[NoLiquidada]		TINYINT,

	PRIMARY KEY CLUSTERED 
(
	[facCod] ASC,
	[facPerCod] ASC,
	[facCtrCod] ASC,
	[facVersion] ASC,
	[fclNumLinea] ASC
)WITH (IGNORE_DUP_KEY = OFF)
)
GO
