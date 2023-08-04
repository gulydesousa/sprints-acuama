CREATE TYPE [dbo].[tContratosPK] AS TABLE(
	[CtrCod] [INT] NOT NULL,
	[CtrVersion] [INT] NOT NULL,
	PRIMARY KEY CLUSTERED 
(
	[CtrCod] ASC,
	[CtrVersion] ASC
)WITH (IGNORE_DUP_KEY = OFF)
)
GO

