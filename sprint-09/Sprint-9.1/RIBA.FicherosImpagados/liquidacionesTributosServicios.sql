CREATE TABLE liquidacionesTributosServicios(
  tribCodigo				CHAR(3)		NOT NULL
, tribSvcCod				SMALLINT	NOT NULL
, tribSvcDescuento			SMALLINT
, CONSTRAINT PK_LiquidacionTributosServicios	PRIMARY KEY (tribCodigo, tribSvcCod)
, CONSTRAINT FK_LiquidacionTributosTributo		FOREIGN KEY (tribCodigo)		REFERENCES LiquidacionesTributos(tribCodigo)
, CONSTRAINT FK_LiquidacionTributosServicios	FOREIGN KEY (tribSvcCod)		REFERENCES servicios(svcCod)
, CONSTRAINT FK_LiquidacionTributosSvcDescuenta FOREIGN KEY (tribSvcDescuento)	REFERENCES servicios(svcCod)
);

