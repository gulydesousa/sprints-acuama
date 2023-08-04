--DROP TABLE dbo.tarifasClasificacion

CREATE TABLE dbo.tarifasClasificacion
(
  trfcCod SMALLINT NOT NULL
, trfcSrvcod SMALLINT NOT NULL
, trfcTrfcod SMALLINT NOT NULL
, trfcTrfdes VARCHAR(50) NOT NULL
, CONSTRAINT [PK_tarifasClasificacion] PRIMARY KEY CLUSTERED 
	(
		trfcCod ASC,
		trfcSrvcod ASC,
		trfcTrfcod ASC
	)
, CONSTRAINT UC_trfcTarifaServicio UNIQUE (trfcSrvcod, trfcTrfcod)
)



ALTER TABLE [dbo].[tarifasClasificacion]  WITH CHECK 
ADD  CONSTRAINT [FK_tarifasClasificacions_Tarifas]
FOREIGN KEY([trfcSrvcod], [trfcTrfcod])
REFERENCES [dbo].[tarifas] ([trfsrvcod], [trfcod]);
GO