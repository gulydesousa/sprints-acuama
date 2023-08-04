--DROP TYPE [dbo].[tCobrosPK_info]
CREATE TYPE [dbo].[tCobrosPK_info] AS TABLE(
	[cobScd]	[SMALLINT] NOT NULL,
	[cobPpag]	[SMALLINT] NOT NULL,
	[cobNum]	[INT] NOT NULL,
	[cblLin]	[SMALLINT] NOT NULL,
	[cldFacLin] [SMALLINT] NOT NULL,
	[cobfecreg] [DATETIME] NOT NULL,
	[cldImporte] MONEY NULL,
	[ppebca]	BIT NULL,

	--Datos de la factura
	[facCod]	 [INT] NOT NULL,
	[facPerCod]  [VARCHAR](6) NOT NULL,
	[facCtrCod]  [INT] NOT NULL,
	[facVersion] [INT] NOT NULL
	
	
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


