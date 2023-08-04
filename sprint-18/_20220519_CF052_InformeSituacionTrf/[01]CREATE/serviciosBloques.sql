--DROP TABLE dbo.serviciosBloques

CREATE TABLE dbo.serviciosBloques
( sblqCod SMALLINT NOT NULL
, sblqSvcCod SMALLINT NOT NULL
, sblqDesc VARCHAR(50) NOT NULL
, CONSTRAINT [PK_serviciosBloques] PRIMARY KEY CLUSTERED 
	(
		sblqCod ASC,
		sblqSvcCod ASC
	)
, CONSTRAINT UC_sblqSvcCod UNIQUE (sblqSvcCod)
);


ALTER TABLE [dbo].[serviciosBloques]  WITH CHECK 
ADD  CONSTRAINT [FK_serviciosBloques_servicios] 
FOREIGN KEY([sblqSvcCod])
REFERENCES [dbo].[servicios] ([svcCod]);
GO


