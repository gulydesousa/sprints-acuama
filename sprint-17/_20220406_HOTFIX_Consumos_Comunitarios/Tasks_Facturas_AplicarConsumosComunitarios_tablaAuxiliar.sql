
CREATE TABLE [Trabajo].[Tasks_Facturas_AplicarConsumosComunitarios_tablaAuxiliar](
	[fecha] [datetime] NULL,
	[ctrRaizCod] [int] NULL,
	[periodo] [varchar](6) NULL,
	[zona] [varchar](4) NULL,
	[nivel] [int] NULL,
	[raiz] [int] NULL,
	[contrato] [int] NOT NULL,
	[ctrVersion] [smallint] NULL,
	[padre] [int] NULL,
	[nHijos] [int] NULL,
	[consumoFactura] [int] NULL,
	[consumoComunitario] [int] NULL,
	[consumoFinal] [int] NULL,
	[metodoCalculo] [smallint] NULL
) ON [PRIMARY]

GO

