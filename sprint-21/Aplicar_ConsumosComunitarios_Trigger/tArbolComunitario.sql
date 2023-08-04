
--DROP TYPE [dbo].[tArbolComunitario]
CREATE TYPE [dbo].[tArbolComunitario] AS TABLE(
	[ctrCod] [int] NULL,
	[ctrComunitario] [int] NULL,
	[calculoComunitario] [varchar](25) NULL,
	[nivel] [int] NULL,
	[raiz] [int] NULL
)
GO


