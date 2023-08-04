--DROP TYPE [dbo].[tComunitariosPK] 
CREATE TYPE [dbo].[tComunitariosPK] AS TABLE(
	[facCod] [int] NOT NULL,
	[facPerCod] [varchar](6) NOT NULL,
	[facCtrCod] [int] NOT NULL,
	[facVersion] [int] NOT NULL,
	[ctrVersion] INT NOT NULL,
	[ctrComunitario] INT NULL,
	[ctrCalculoComunitario] SMALLINT NULL,
	PRIMARY KEY CLUSTERED 
(
	[facCod] ASC,
	[facPerCod] ASC,
	[facCtrCod] ASC,
	[facVersion] ASC
)WITH (IGNORE_DUP_KEY = OFF)
)
GO