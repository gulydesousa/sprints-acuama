--DROP TYPE [dbo].[tEfectosPendientesPK] 
CREATE TYPE [dbo].[tEfectosPendientesPK] AS TABLE(
	[efePdteCod]		 [INT] NOT NULL,
	[efePdteCtrCod]		 [INT] NOT NULL,
	[efePdtePerCod]		 [VARCHAR](6) NOT NULL,
	[efePdteFacCod]		 [SMALLINT] NOT NULL,
	[efePdteScd]		 [SMALLINT] NOT NULL,
	[efePdteImporte]	 [MONEY] NOT NULL,
	[efePdteDomiciliado] [BIT] NOT NULL,
	[efePdteFecRemDesde] DATETIME NOT NULL,
	[efePdteFecRemesada] DATETIME NULL,
	[efePdteIban]		 VARCHAR(34) NULL, 
	[efePdteTitCCC]		 VARCHAR(40) NULL,
	[efePdteDocIdenCCC]	 VARCHAR(12) NULL,
	PRIMARY KEY CLUSTERED 
(
	[efePdteCod] ASC,
	[efePdteCtrCod] ASC,
	[efePdtePerCod] ASC,
	[efePdteFacCod] ASC,
	[efePdteScd] ASC
)WITH (IGNORE_DUP_KEY = OFF)
)
GO

