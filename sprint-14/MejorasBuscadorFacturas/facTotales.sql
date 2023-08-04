CREATE TABLE dbo.facTotales
( fctCod INT NOT NULL
, fctCtrCod INT NOT NULL
, fctPerCod VARCHAR(6) NOT NULL
, fctVersion INT NOT NULL
, fctActiva BIT NOT NULL

, fctBase MONEY NOT NULL DEFAULT (0)		--2 decimales
, fctImpuestos MONEY NOT NULL DEFAULT (0)	--4 decimales
, fctTotal MONEY NOT NULL DEFAULT (0)		--base+impuestos (4 decimales)

, fctFacturado MONEY NOT NULL DEFAULT (0)		
, fctCobrado MONEY NOT NULL DEFAULT (0)
, fctEntregasCta  MONEY NOT NULL DEFAULT (0)

, fctDeuda AS fctFacturado - fctCobrado

, fctTipoImp1 DECIMAL(4,2) DEFAULT(0)
, fctBaseTipoImp1 MONEY DEFAULT (0)	
, fctImpuestoTipoImp1 AS CAST(ROUND(ISNULL(fctTipoImp1, 0) * ISNULL(fctBaseTipoImp1, 0) * 0.01, 2) AS MONEY)

, fctTipoImp2 DECIMAL(4,2) DEFAULT(0)
, fctBaseTipoImp2 MONEY DEFAULT (0)	
, fctImpuestoTipoImp2 AS CAST(ROUND(ISNULL(fctTipoImp2, 0) * ISNULL(fctBaseTipoImp2, 0) * 0.01, 2) AS MONEY)

, fctTipoImp3 DECIMAL(4,2) DEFAULT(0)
, fctBaseTipoImp3 MONEY DEFAULT (0)	
, fctImpuestoTipoImp3 AS CAST(ROUND(ISNULL(fctTipoImp3, 0) * ISNULL(fctBaseTipoImp3, 0) * 0.01, 2) AS MONEY)

, fctTipoImp4 DECIMAL(4,2) DEFAULT(0)
, fctBaseTipoImp4 MONEY DEFAULT (0)	
, fctImpuestoTipoImp4 AS CAST(ROUND(ISNULL(fctTipoImp4, 0) * ISNULL(fctBaseTipoImp4, 0) * 0.01, 2) AS MONEY)

, fctTipoImp5 DECIMAL(4,2) DEFAULT(0)
, fctBaseTipoImp5 MONEY DEFAULT (0)	
, fctImpuestoTipoImp5 AS CAST(ROUND(ISNULL(fctTipoImp5, 0) * ISNULL(fctBaseTipoImp5, 0) * 0.01, 2) AS MONEY)

, fctTipoImp6 DECIMAL(4,2) DEFAULT(0)
, fctBaseTipoImp6 MONEY DEFAULT (0)	
, fctImpuestoTipoImp6 AS CAST(ROUND(ISNULL(fctTipoImp6, 0) * ISNULL(fctBaseTipoImp6, 0) * 0.01, 2) AS MONEY)


, fctTotalTipoImp AS  ISNULL(fctBaseTipoImp1, 0) + CAST(ROUND(ISNULL(fctTipoImp1, 0) * ISNULL(fctBaseTipoImp1, 0) * 0.01, 2) AS MONEY)
					+ ISNULL(fctBaseTipoImp2, 0) + CAST(ROUND(ISNULL(fctTipoImp2, 0) * ISNULL(fctBaseTipoImp2, 0) * 0.01, 2) AS MONEY)
					+ ISNULL(fctBaseTipoImp3, 0) + CAST(ROUND(ISNULL(fctTipoImp3, 0) * ISNULL(fctBaseTipoImp3, 0) * 0.01, 2) AS MONEY)
					+ ISNULL(fctBaseTipoImp4, 0) + CAST(ROUND(ISNULL(fctTipoImp4, 0) * ISNULL(fctBaseTipoImp4, 0) * 0.01, 2) AS MONEY)
					+ ISNULL(fctBaseTipoImp5, 0) + CAST(ROUND(ISNULL(fctTipoImp5, 0) * ISNULL(fctBaseTipoImp5, 0) * 0.01, 2) AS MONEY)
					+ ISNULL(fctBaseTipoImp6, 0) + CAST(ROUND(ISNULL(fctTipoImp6, 0) * ISNULL(fctBaseTipoImp6, 0) * 0.01, 2) AS MONEY)

--*************************************************
, fctActualizacion DATETIME DEFAULT GETDATE()
--Digitos de precision en la base
, fctPrecisionBase AS LEN(CONVERT(INT, PARSE(REPLACE(REVERSE(CONVERT(VARCHAR(50), ABS(fctBase), 2)), '.', ',') AS FLOAT USING 'es-ES')))  



, CONSTRAINT  PK_facTotales PRIMARY KEY(fctCod, fctCtrCod, fctPerCod, fctVersion)
, INDEX IX_fctTotal NONCLUSTERED(fctTotal)
);

GO






