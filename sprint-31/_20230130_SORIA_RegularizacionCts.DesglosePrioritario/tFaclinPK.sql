--DROP TYPE [dbo].[tFaclinPK] 

CREATE TYPE [dbo].[tFaclinPK] AS TABLE(
	  fclFacCod		SMALLINT NOT NULL
	, fclFacPerCod  VARCHAR(6) NOT NULL
	, fclFacCtrCod	INT NOT NULL
	, fclFacVersion SMALLINT NOT NULL
	, fclNumLinea	INT NOT NULL
	, fclTrfSvCod	SMALLINT NOT NULL
	, fclTrfCod		SMALLINT NOT NULL
	, fclFecLiq		DATETIME NULL
	, svcOrgCod		INT
	, fcltotal		MONEY
	, [@facTotal]	MONEY NULL

	, PRIMARY KEY CLUSTERED 
	(
		fclFacCod ASC,
		fclFacPerCod ASC,
		fclFacCtrCod ASC,
		fclFacVersion ASC,
		fclNumLinea ASC
	)WITH (IGNORE_DUP_KEY = OFF)
)
