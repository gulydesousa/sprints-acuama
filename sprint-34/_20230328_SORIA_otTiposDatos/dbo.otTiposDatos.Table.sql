USE ACUAMA_SORIA
GO
--CREATE TABLE [dbo].[otTiposDatos](
--	[otdOdtCodigo] [smallint] NOT NULL,
--	[otdOttCod] [varchar](4) NOT NULL,
--	[ottdOrden] [int] NULL,
-- CONSTRAINT [PK_otTiposDatos] PRIMARY KEY CLUSTERED 
--(
--	[otdOdtCodigo] ASC,
--	[otdOttCod] ASC
--)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
--) ON [PRIMARY]
--GO
INSERT [dbo].[otTiposDatos] ([otdOdtCodigo], [otdOttCod], [ottdOrden]) VALUES (500, N'1', NULL)
INSERT [dbo].[otTiposDatos] ([otdOdtCodigo], [otdOttCod], [ottdOrden]) VALUES (600, N'1', NULL)
INSERT [dbo].[otTiposDatos] ([otdOdtCodigo], [otdOttCod], [ottdOrden]) VALUES (601, N'1', NULL)
INSERT [dbo].[otTiposDatos] ([otdOdtCodigo], [otdOttCod], [ottdOrden]) VALUES (602, N'1', NULL)
INSERT [dbo].[otTiposDatos] ([otdOdtCodigo], [otdOttCod], [ottdOrden]) VALUES (603, N'1', NULL)
INSERT [dbo].[otTiposDatos] ([otdOdtCodigo], [otdOttCod], [ottdOrden]) VALUES (604, N'1', NULL)
INSERT [dbo].[otTiposDatos] ([otdOdtCodigo], [otdOttCod], [ottdOrden]) VALUES (605, N'1', NULL)
INSERT [dbo].[otTiposDatos] ([otdOdtCodigo], [otdOttCod], [ottdOrden]) VALUES (606, N'1', NULL)
INSERT [dbo].[otTiposDatos] ([otdOdtCodigo], [otdOttCod], [ottdOrden]) VALUES (607, N'1', NULL)
INSERT [dbo].[otTiposDatos] ([otdOdtCodigo], [otdOttCod], [ottdOrden]) VALUES (608, N'1', NULL)
INSERT [dbo].[otTiposDatos] ([otdOdtCodigo], [otdOttCod], [ottdOrden]) VALUES (609, N'1', NULL)
GO
--ALTER TABLE [dbo].[otTiposDatos]  WITH CHECK ADD  CONSTRAINT [FK_otTiposDatos_otDatos] FOREIGN KEY([otdOdtCodigo])
--REFERENCES [dbo].[otDatos] ([odtCodigo])
--GO
--ALTER TABLE [dbo].[otTiposDatos] CHECK CONSTRAINT [FK_otTiposDatos_otDatos]
--GO
--ALTER TABLE [dbo].[otTiposDatos]  WITH CHECK ADD  CONSTRAINT [FK_otTiposDatos_ottipos] FOREIGN KEY([otdOttCod])
--REFERENCES [dbo].[ottipos] ([ottcod])
--GO
--ALTER TABLE [dbo].[otTiposDatos] CHECK CONSTRAINT [FK_otTiposDatos_ottipos]
--GO

SELECT * FROM otTiposDatos