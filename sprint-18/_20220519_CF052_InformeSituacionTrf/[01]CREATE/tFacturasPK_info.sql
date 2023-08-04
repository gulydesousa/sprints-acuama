--DROP TYPE [dbo].[tFacturasPK_info]
CREATE TYPE [dbo].[tFacturasPK_info] AS TABLE(
	[facCod]	 [INT] NOT NULL,
	[facPerCod]  [VARCHAR](6) NOT NULL,
	[facCtrCod]  [INT] NOT NULL,
	[facVersion] [INT] NOT NULL,
	[facFecha]	 [DATETIME] NULL,
	[facFechaRectif] [DATETIME] NULL,
	--Campo auxiliar para clasificar las facturas
	[Original]	BIT NULL, 
	[Anulada]	BIT NULL, 
	[Creada]	BIT NULL, 
	[Cobrada]	BIT NULL, 

	PRIMARY KEY CLUSTERED 
(
	[facCod] ASC,
	[facPerCod] ASC,
	[facCtrCod] ASC,
	[facVersion] ASC
)WITH (IGNORE_DUP_KEY = OFF)
)
GO


