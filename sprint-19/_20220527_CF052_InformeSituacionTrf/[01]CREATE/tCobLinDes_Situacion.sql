--DROP TYPE [dbo].[tCobLinDes_Situacion]
CREATE TYPE [dbo].[tCobLinDes_Situacion] AS TABLE(

	[cobScd]		SMALLINT NOT NULL,
	[cobPpag]		SMALLINT NOT NULL,
	[cobNum]		INT NOT NULL,
	[cblLin]		SMALLINT NOT NULL,
	[cldFacLin]		SMALLINT NOT NULL,
	[cobfecreg]		DATETIME NOT NULL,
	
	[facCod]		INT NOT NULL,
	[facCtrCod]		INT NOT NULL,
	[facPerCod]		VARCHAR(6) NOT NULL,
	[facVersion]	INT NOT NULL,
	
	[cldTrfSrvCod]	SMALLINT NOT NULL,
	[cldTrfCod]		SMALLINT NOT NULL,

	[cldImporte]	MONEY,
	
	[esCobro]		TINYINT,
	[esDevolucion]	TINYINT,
	[esBanco]		TINYINT,
	[esOficina]		TINYINT,
	--***********************************
	[cargoFijo]		MONEY, 
	[consumo]		MONEY,  
	[base]			MONEY,
	[impuesto]		MONEY,
	[cobContar]		TINYINT,
	--***********************************
	--Factura usada para calcular cargoFijo, consumo, base, impuesto
	[fclFacVersion]	SMALLINT,
	[fclFacLin]		INT,
	[fclTotal]		MONEY,
	[fclFicticia]		BIT
	
	PRIMARY KEY CLUSTERED 
	(
	[cobScd] ASC,
	[cobPpag] ASC,
	[cobNum] ASC,
	[cblLin] ASC,
	[cldFacLin] ASC
	)WITH (IGNORE_DUP_KEY = OFF)
)
GO
