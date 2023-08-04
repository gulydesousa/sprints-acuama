--DROP TYPE [dbo].[tFaclinCobrado] 

CREATE TYPE [dbo].[tFaclinCobrado] AS TABLE(
	  fclFacCod		SMALLINT NOT NULL
	, fclFacPerCod  VARCHAR(6) NOT NULL
	, fclFacCtrCod	INT NOT NULL
	, fclFacVersion SMALLINT NOT NULL
	, fclNumLinea	INT NOT NULL
	, cldTotal	MONEY NULL
	, numCobros INT

	, PRIMARY KEY CLUSTERED 
	(
		fclFacCod ASC,
		fclFacPerCod ASC,
		fclFacCtrCod ASC,
		fclFacVersion ASC,
		fclNumLinea ASC
	)WITH (IGNORE_DUP_KEY = OFF)
)
