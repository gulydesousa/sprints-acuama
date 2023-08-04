ALTER PROCEDURE [dbo].[EfectosPendientes_Select] 
	@efePdteCod INT = NULL,
	@efePdteCtrCod INT = NULL,
	@efePdtePerCod VARCHAR(6) = NULL,
	@efePdteFacCod SMALLINT = NULL,
	@efePdteImporte MONEY = NULL,
	@efePdteCCC VARCHAR(20) = NULL,
	@efePdteTitCCC VARCHAR(40) = NULL,
	@efePdteDocIdenCCC VARCHAR(12) = NULL,
	@efePdteFecRemDesde DATETIME = NULL,
	@efePdteUsrCod VARCHAR(10) = NULL,
	@efePdteFecReg DATETIME = NULL,
	@efePdteFecRemesada DATETIME = NULL,
	@efePdteUsrRemesada VARCHAR(10) = NULL,
	@efePdteFecSelRemesa DATETIME = NULL,
	@efePdteUsrSelRemesa VARCHAR(10) = NULL,
	@remesada BIT = NULL,
	@rechazado BIT = NULL,
	@efePdteFecRechazado DATETIME = NULL,
	@efePdteUsrRechazado VARCHAR(10) = NULL,
	@efePdteScd SMALLINT = NULL,
	@fechaARemesarHasta DATETIME = NULL,
	@seleccionado BIT = NULL,
	@usuarioActual VARCHAR(10) = NULL,
	@importeSuperarPendiente BIT = NULL, --Indica si obtiene los efectos pendientes agrupados por factura (sin remesar y sin ser rechazados) que tengan un importe superior al pendiente de la factura
	@efePdteManRef VARCHAR(35) = NULL
	--Efectos No-Domiciliados
	, @efePdteDomiciliado BIT = NULL
	--, @efePdteFecVencimiento DATETIME = NULL
	--, @efePdteRegMarcado BIT = NULL

AS 
	SET NOCOUNT OFF; 

SELECT 
	efePdteCod,
	efePdteCtrCod,
	efePdtePerCod,
	efePdteFacCod,
	efePdteImporte,
	efePdteCCC,
	efePdteTitCCC,
	efePdteDocIdenCCC,
	efePdteFecRemDesde,
	efePdteUsrCod,
	efePdteFecReg,
	efePdteFecRemesada,
	efePdteUsrRemesada,
	efePdteFecSelRemesa,
	efePdteUsrSelRemesa,
	efePdteFecRechazado,
	efePdteUsrRechazado,
	efePdteScd,
	efePdteIban,
	efePdteBic,
	efePdteDirCta,
	efePdtePobCta,
	efePdtePrvCta,
	efePdteCPosCta,
	efePdteNacCta,
	efePdteManRef
	--Efectos No-Domiciliados
	, efePdteDomiciliado
	--, efePdteFecVencimiento
	--, efePdteRegMarcado

	, C.cleCblScd
	, C.cleCblPpag
	, C.cleCblNum
	, C.cleCblLin

FROM dbo.efectosPendientes AS E1
LEFT JOIN dbo.cobLinEfectosPendientes AS C 
	ON  C.clefePdteCod	  = E1.efePdteCod
	AND C.clefePdteCtrCod = E1.efePdteCtrCod
	AND C.clefePdtePerCod = E1.efePdtePerCod
	AND C.clefePdteFacCod = E1.efePdteFacCod
	AND C.clefePdteScd	  = E1.efePdteScd

LEFT JOIN fFacturas_TotalFacturado(NULL, 0, NULL) ON ftfFacSerScdCod = efePdteScd AND 
												ftfFacCod=efePdteFacCod AND 
												ftfFacPerCod=efePdtePerCod AND 
												ftfFacCtrCod=efePdteCtrCod AND 
												ftfFacVersion=(SELECT MAX(facVersion) FROM facturas WHERE efePdteCtrCod = facCtrCod AND efePdteFacCod = facCod AND efePdtePerCod = facPerCod)

LEFT JOIN fFacturas_TotalCobrado(NULL) ON ftcCtr = efePdteCtrCod AND ftcScd = efePdteScd AND ftcFacCod = efePdteFacCod AND ftcPer = efePdtePerCod
	

WHERE 
	(@efePdteCod IS NULL OR efePdteCod = @efePdteCod)
AND (@efePdteCtrCod IS NULL OR efePdteCtrCod = @efePdteCtrCod)
AND (@efePdtePerCod IS NULL OR efePdtePerCod = @efePdtePerCod)
AND (@efePdteFacCod IS NULL OR efePdteFacCod = @efePdteFacCod)
AND (@efePdteImporte IS NULL OR efePdteImporte = @efePdteImporte)
AND (@efePdteCCC IS NULL OR efePdteCCC = @efePdteCCC)
AND (@efePdteTitCCC IS NULL OR efePdteTitCCC = @efePdteTitCCC)
AND (@efePdteDocIdenCCC IS NULL OR efePdteDocIdenCCC = @efePdteDocIdenCCC)
AND (@efePdteFecRemDesde IS NULL OR efePdteFecRemDesde = @efePdteFecRemDesde)
AND (@efePdteUsrCod IS NULL OR efePdteUsrCod = @efePdteUsrCod)
AND (@efePdteFecReg IS NULL OR efePdteFecReg = @efePdteFecReg)
AND (@efePdteFecRemesada IS NULL OR efePdteFecRemesada = @efePdteFecRemesada)
AND (@efePdteUsrRemesada IS NULL OR efePdteUsrRemesada = @efePdteUsrRemesada)
AND (@efePdteFecSelRemesa IS NULL OR efePdteFecSelRemesa = @efePdteFecSelRemesa)
AND (@efePdteUsrSelRemesa IS NULL OR efePdteUsrSelRemesa = @efePdteUsrSelRemesa)
AND (@remesada IS NULL OR (@remesada = 1 AND efePdteFecRemesada IS NOT NULL) OR (@remesada = 0 AND efePdteFecRemesada IS NULL)) 
AND (@rechazado IS NULL OR (@rechazado = 1 AND efePdteFecRechazado IS NOT NULL) OR (@rechazado = 0 AND efePdteFecRechazado IS NULL)) 
AND (@efePdteFecSelRemesa IS NULL OR efePdteFecSelRemesa = @efePdteFecSelRemesa)
AND (@efePdteUsrRechazado IS NULL OR efePdteUsrRechazado = @efePdteUsrRechazado)
AND (@efePdteScd IS NULL OR efePdteScd = @efePdteScd)
AND (@efePdteManRef IS NULL OR efePdteManRef = @efePdteManRef) 
AND (@importeSuperarPendiente IS NULL OR
		(@importeSuperarPendiente = 0 AND
		ISNULL((SELECT SUM(efePdteImporte) FROM efectosPendientes e2 WHERE e2.efePdteFecRechazado IS NULL AND e2.efePdteFecRemesada IS NULL AND e2.efePdteCtrCod = e1.efePdteCtrCod AND e2.efePdteFacCod = e1.efePdteFacCod AND e2.efePdtePerCod = e1.efePdtePerCod  AND (@fechaARemesarHasta IS NULL OR e2.efePdteFecRemDesde <= @fechaARemesarHasta) GROUP BY efePdtefacCod, efePdtePerCod, efePdteCtrCod), 0) <= (ISNULL(ftfImporte, 0) - ISNULL(ftcImporte, 0))
		)		
		OR 
	    (@importeSuperarPendiente = 1 AND
		ISNULL((SELECT SUM(efePdteImporte) FROM efectosPendientes e2 WHERE e2.efePdteFecRechazado IS NULL AND e2.efePdteFecRemesada IS NULL AND e2.efePdteCtrCod = e1.efePdteCtrCod AND e2.efePdteFacCod = e1.efePdteFacCod AND e2.efePdtePerCod = e1.efePdtePerCod AND (@fechaARemesarHasta IS NULL OR e2.efePdteFecRemDesde <= @fechaARemesarHasta) GROUP BY efePdtefacCod, efePdtePerCod, efePdteCtrCod), 0) > (ISNULL(ftfImporte, 0) - ISNULL(ftcImporte, 0))
		)
	)
AND (@fechaARemesarHasta IS NULL OR efePdteFecRemDesde <= @fechaARemesarHasta)

AND (@seleccionado IS NULL OR
		(@seleccionado = 1 AND EXISTS(SELECT remUsrCod 
					FROM remesasTrab 
					WHERE (@usuarioActual IS NULL OR remUsrCod = @usuarioActual) AND 
						  remCtrCod = e1.efePdteCtrCod AND 
						  remPerCod = e1.efePdtePerCod AND
						  remFacCod = e1.efePdteFacCod AND
						  remEfePdteCod = e1.efePdteCod AND
						  remSerScdCod = e1.efePdteScd)
		) OR
		(@seleccionado = 0 AND NOT EXISTS(SELECT remUsrCod 
					FROM remesasTrab 
					WHERE (@usuarioActual IS NULL OR remUsrCod = @usuarioActual) AND 
						  remCtrCod = e1.efePdteCtrCod AND 
						  remPerCod = e1.efePdtePerCod AND
						  remFacCod = e1.efePdteFacCod AND
						  remEfePdteCod = e1.efePdteCod AND
						  remSerScdCod = e1.efePdteScd)
		)
	)
AND (@efePdteDomiciliado IS NULL OR efePdteDomiciliado=@efePdteDomiciliado)
ORDER BY efePdtePerCod, efePdteCtrCod, efePdteFacCod, efePdteFecReg

GO


