USE [ACUAMA_AVG]
GO
/****** Object:  Table [Trabajo].[tarval_20230215_1240]    Script Date: 15/02/2023 13:22:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Trabajo].[tarval_20230215_1240](
	[trvsrvcod] [smallint] NOT NULL,
	[trvtrfcod] [smallint] NOT NULL,
	[trvfecha] [datetime] NOT NULL,
	[trvfechafin] [datetime] NULL,
	[trvcuota] [decimal](10, 4) NULL,
	[trvprecio1] [decimal](10, 6) NULL,
	[trvprecio2] [decimal](10, 6) NULL,
	[trvprecio3] [decimal](10, 6) NULL,
	[trvprecio4] [decimal](10, 6) NULL,
	[trvprecio5] [decimal](10, 6) NULL,
	[trvprecio6] [decimal](10, 6) NULL,
	[trvprecio7] [decimal](10, 6) NULL,
	[trvprecio8] [decimal](10, 6) NULL,
	[trvprecio9] [decimal](10, 6) NULL,
	[trvlegalavb] [varchar](50) NULL,
	[trvlegal] [varchar](200) NULL,
	[trvumdcod] [varchar](4) NULL
) ON [PRIMARY]
GO
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (19, 101, CAST(N'2011-05-01T00:00:00.000' AS DateTime), CAST(N'2022-12-31T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(1.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (19, 101, CAST(N'2023-01-01T00:00:00.000' AS DateTime), NULL, CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'RD 7/2022', N'RD 7/2022', N'uds')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 101, CAST(N'2011-05-01T00:00:00.000' AS DateTime), CAST(N'2012-04-30T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.030000 AS Decimal(10, 6)), CAST(0.060000 AS Decimal(10, 6)), CAST(0.180000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 101, CAST(N'2012-05-01T00:00:00.000' AS DateTime), CAST(N'2013-04-30T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.045000 AS Decimal(10, 6)), CAST(0.090000 AS Decimal(10, 6)), CAST(0.270000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 101, CAST(N'2013-05-01T00:00:00.000' AS DateTime), CAST(N'2014-04-30T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.060000 AS Decimal(10, 6)), CAST(0.120000 AS Decimal(10, 6)), CAST(0.360000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 101, CAST(N'2014-05-01T00:00:00.000' AS DateTime), CAST(N'2015-04-30T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.080000 AS Decimal(10, 6)), CAST(0.160000 AS Decimal(10, 6)), CAST(0.480000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 101, CAST(N'2015-05-01T00:00:00.000' AS DateTime), CAST(N'2022-12-31T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.100000 AS Decimal(10, 6)), CAST(0.200000 AS Decimal(10, 6)), CAST(0.600000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 101, CAST(N'2023-01-01T00:00:00.000' AS DateTime), NULL, CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'RD 7/2022', N'RD 7/2022', N'uds')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 201, CAST(N'2011-05-01T00:00:00.000' AS DateTime), CAST(N'2012-04-30T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.075000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 201, CAST(N'2012-05-01T00:00:00.000' AS DateTime), CAST(N'2013-04-30T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.112500 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 201, CAST(N'2013-05-01T00:00:00.000' AS DateTime), CAST(N'2014-04-30T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.150000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 201, CAST(N'2014-05-01T00:00:00.000' AS DateTime), CAST(N'2015-04-30T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.200000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 201, CAST(N'2015-05-01T00:00:00.000' AS DateTime), CAST(N'2022-12-31T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.250000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 201, CAST(N'2023-01-01T00:00:00.000' AS DateTime), NULL, CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'RD 7/2022', N'RD 7/2022', N'uds')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 301, CAST(N'2011-05-01T00:00:00.000' AS DateTime), CAST(N'2012-04-30T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.075000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 301, CAST(N'2012-05-01T00:00:00.000' AS DateTime), CAST(N'2013-04-30T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.112500 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 301, CAST(N'2013-05-01T00:00:00.000' AS DateTime), CAST(N'2014-04-30T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.150000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 301, CAST(N'2014-05-01T00:00:00.000' AS DateTime), CAST(N'2015-04-30T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.200000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 301, CAST(N'2015-05-01T00:00:00.000' AS DateTime), CAST(N'2022-12-31T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.250000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 301, CAST(N'2023-01-01T00:00:00.000' AS DateTime), NULL, CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'RD 7/2022', N'RD 7/2022', N'uds')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 401, CAST(N'2011-05-01T00:00:00.000' AS DateTime), CAST(N'2012-04-30T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.030000 AS Decimal(10, 6)), CAST(0.060000 AS Decimal(10, 6)), CAST(0.180000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 401, CAST(N'2012-05-01T00:00:00.000' AS DateTime), CAST(N'2013-04-30T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.045000 AS Decimal(10, 6)), CAST(0.090000 AS Decimal(10, 6)), CAST(0.270000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 401, CAST(N'2013-05-01T00:00:00.000' AS DateTime), CAST(N'2014-04-30T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.060000 AS Decimal(10, 6)), CAST(0.120000 AS Decimal(10, 6)), CAST(0.360000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 401, CAST(N'2014-05-01T00:00:00.000' AS DateTime), CAST(N'2015-04-30T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.080000 AS Decimal(10, 6)), CAST(0.160000 AS Decimal(10, 6)), CAST(0.480000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 401, CAST(N'2015-05-01T00:00:00.000' AS DateTime), CAST(N'2022-12-31T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.100000 AS Decimal(10, 6)), CAST(0.200000 AS Decimal(10, 6)), CAST(0.600000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 401, CAST(N'2023-01-01T00:00:00.000' AS DateTime), NULL, CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'RD 7/2022', N'RD 7/2022', N'uds')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 501, CAST(N'2011-05-01T00:00:00.000' AS DateTime), CAST(N'2012-04-30T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.030000 AS Decimal(10, 6)), CAST(0.060000 AS Decimal(10, 6)), CAST(0.180000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 501, CAST(N'2012-05-01T00:00:00.000' AS DateTime), CAST(N'2013-04-30T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.045000 AS Decimal(10, 6)), CAST(0.090000 AS Decimal(10, 6)), CAST(0.270000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 501, CAST(N'2013-05-01T00:00:00.000' AS DateTime), CAST(N'2014-04-30T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.060000 AS Decimal(10, 6)), CAST(0.120000 AS Decimal(10, 6)), CAST(0.360000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 501, CAST(N'2014-05-01T00:00:00.000' AS DateTime), CAST(N'2015-04-30T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.080000 AS Decimal(10, 6)), CAST(0.160000 AS Decimal(10, 6)), CAST(0.480000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 501, CAST(N'2015-05-01T00:00:00.000' AS DateTime), CAST(N'2022-12-31T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.100000 AS Decimal(10, 6)), CAST(0.200000 AS Decimal(10, 6)), CAST(0.600000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 501, CAST(N'2023-01-01T00:00:00.000' AS DateTime), NULL, CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'RD 7/2022', N'RD 7/2022', N'uds')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 601, CAST(N'2011-05-01T00:00:00.000' AS DateTime), CAST(N'2012-04-30T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.030000 AS Decimal(10, 6)), CAST(0.060000 AS Decimal(10, 6)), CAST(0.180000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 601, CAST(N'2012-05-01T00:00:00.000' AS DateTime), CAST(N'2013-04-30T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.045000 AS Decimal(10, 6)), CAST(0.090000 AS Decimal(10, 6)), CAST(0.270000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 601, CAST(N'2013-05-01T00:00:00.000' AS DateTime), CAST(N'2014-04-30T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.060000 AS Decimal(10, 6)), CAST(0.120000 AS Decimal(10, 6)), CAST(0.360000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 601, CAST(N'2014-05-01T00:00:00.000' AS DateTime), CAST(N'2015-04-30T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.080000 AS Decimal(10, 6)), CAST(0.160000 AS Decimal(10, 6)), CAST(0.480000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 601, CAST(N'2015-05-01T00:00:00.000' AS DateTime), CAST(N'2022-12-31T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.100000 AS Decimal(10, 6)), CAST(0.200000 AS Decimal(10, 6)), CAST(0.600000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 601, CAST(N'2023-01-01T00:00:00.000' AS DateTime), NULL, CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'RD 7/2022', N'RD 7/2022', N'uds')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 701, CAST(N'2011-05-01T00:00:00.000' AS DateTime), CAST(N'2012-04-30T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.030000 AS Decimal(10, 6)), CAST(0.060000 AS Decimal(10, 6)), CAST(0.180000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 701, CAST(N'2012-05-01T00:00:00.000' AS DateTime), CAST(N'2013-04-30T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.045000 AS Decimal(10, 6)), CAST(0.090000 AS Decimal(10, 6)), CAST(0.270000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 701, CAST(N'2013-05-01T00:00:00.000' AS DateTime), CAST(N'2014-04-30T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.060000 AS Decimal(10, 6)), CAST(0.120000 AS Decimal(10, 6)), CAST(0.360000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 701, CAST(N'2014-05-01T00:00:00.000' AS DateTime), CAST(N'2015-04-30T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.080000 AS Decimal(10, 6)), CAST(0.160000 AS Decimal(10, 6)), CAST(0.480000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 701, CAST(N'2015-05-01T00:00:00.000' AS DateTime), CAST(N'2022-12-31T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.100000 AS Decimal(10, 6)), CAST(0.200000 AS Decimal(10, 6)), CAST(0.600000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 701, CAST(N'2023-01-01T00:00:00.000' AS DateTime), NULL, CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'RD 7/2022', N'RD 7/2022', N'uds')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 801, CAST(N'2015-03-15T00:00:00.000' AS DateTime), CAST(N'2022-12-31T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.200000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 801, CAST(N'2023-01-01T00:00:00.000' AS DateTime), NULL, CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'RD 7/2022', N'RD 7/2022', N'uds')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 1001, CAST(N'2015-05-01T00:00:00.000' AS DateTime), CAST(N'2022-12-31T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.100000 AS Decimal(10, 6)), CAST(0.200000 AS Decimal(10, 6)), CAST(0.600000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 1001, CAST(N'2023-01-01T00:00:00.000' AS DateTime), NULL, CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'RD 7/2022', N'RD 7/2022', N'uds')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 8501, CAST(N'2015-05-01T00:00:00.000' AS DateTime), CAST(N'2022-12-31T00:00:00.000' AS DateTime), CAST(0.0000 AS Decimal(10, 4)), CAST(0.250000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.100000 AS Decimal(10, 6)), CAST(0.200000 AS Decimal(10, 6)), CAST(0.600000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'BOJA 155  09-08-2010 - CANON JUNTA DE ANDALUCIA', NULL, N'UDS')
INSERT [Trabajo].[tarval_20230215_1240] ([trvsrvcod], [trvtrfcod], [trvfecha], [trvfechafin], [trvcuota], [trvprecio1], [trvprecio2], [trvprecio3], [trvprecio4], [trvprecio5], [trvprecio6], [trvprecio7], [trvprecio8], [trvprecio9], [trvlegalavb], [trvlegal], [trvumdcod]) VALUES (20, 8501, CAST(N'2023-01-01T00:00:00.000' AS DateTime), NULL, CAST(0.0000 AS Decimal(10, 4)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), CAST(0.000000 AS Decimal(10, 6)), N'RD 7/2022', N'RD 7/2022', N'uds')
GO
