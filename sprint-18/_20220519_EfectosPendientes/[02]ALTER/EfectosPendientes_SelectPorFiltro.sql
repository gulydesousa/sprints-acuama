ALTER PROCEDURE [dbo].[EfectosPendientes_SelectPorFiltro] 
@filtro varchar(500) = NULL,
@remesada BIT = NULL,
@rechazado BIT = NULL,
@fechaARemesarHasta DATETIME = NULL,
@importeSuperarPendiente BIT = NULL, --Indica si obtiene los efectos pendientes agrupados por factura (sin remesar y sin ser rechazados) que tengan un importe superior al pendiente de la factura
@seleccionado BIT = NULL,
@usuarioActual VARCHAR(10) = NULL

AS 
	SET NOCOUNT ON; 
	

IF @filtro is NULL SET @filtro = '' 
DECLARE @where_or_and as varchar(6) --Ponemos la palabra "WHERE" o "AND" según sea necesario
IF CHARINDEX('WHERE',@filtro) = 0 SET @where_or_and = ' WHERE ' ELSE SET @where_or_and = ' AND '

DECLARE @sql AS VARCHAR(MAX)	

SET @sql = ('SELECT efePdteCod,
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
			LEFT JOIN fFacturas_TotalCobrado(NULL) ON ftcCtr = efePdteCtrCod AND ftcScd = efePdteScd AND ftcFacCod = efePdteFacCod aND ftcPer = efePdtePerCod '
			+ @filtro + @where_or_and +
			'('+ ISNULL(CAST(@remesada AS VARCHAR),'NULL') +' IS NULL OR ('+ ISNULL(CAST(@remesada AS VARCHAR),'NULL') +' = 1 AND efePdteFecRemesada IS NOT NULL) OR ('+ ISNULL(CAST(@remesada AS VARCHAR),'NULL') +' = 0 AND efePdteFecRemesada IS NULL)) 
			AND ('+ ISNULL(CAST(@rechazado AS VARCHAR),'NULL') +' IS NULL OR ('+ ISNULL(CAST(@rechazado AS VARCHAR),'NULL') +' = 1 AND efePdteFecRechazado IS NOT NULL) OR ('+ ISNULL(CAST(@rechazado AS VARCHAR),'NULL') +' = 0 AND efePdteFecRechazado IS NULL))
			AND ('+ ISNULL(CAST(@importeSuperarPendiente AS VARCHAR),'NULL') +' IS NULL OR
				('+ ISNULL(CAST(@importeSuperarPendiente AS VARCHAR),'NULL') +' = 0 AND
				ISNULL((SELECT SUM(efePdteImporte) FROM efectosPendientes e2 WHERE e2.efePdteFecRechazado IS NULL AND e2.efePdteFecRemesada IS NULL AND e2.efePdteCtrCod = e1.efePdteCtrCod AND e2.efePdteFacCod = e1.efePdteFacCod AND e2.efePdtePerCod = e1.efePdtePerCod  AND ('+ ISNULL( + '''' + CAST(@fechaARemesarHasta AS VARCHAR) + '''','NULL') +' IS NULL OR e2.efePdteFecRemDesde <= '+ ISNULL( + '''' + CAST(@fechaARemesarHasta AS VARCHAR) + '''','NULL') +') GROUP BY efePdtefacCod, efePdtePerCod, efePdteCtrCod), 0) <= (ISNULL(ftfImporte, 0) - ISNULL(ftcImporte, 0))
				)		
				OR 
				('+ ISNULL(CAST(@importeSuperarPendiente AS VARCHAR),'NULL') +' = 1 AND
				ISNULL((SELECT SUM(efePdteImporte) FROM efectosPendientes e2 WHERE e2.efePdteFecRechazado IS NULL AND e2.efePdteFecRemesada IS NULL AND e2.efePdteCtrCod = e1.efePdteCtrCod AND e2.efePdteFacCod = e1.efePdteFacCod AND e2.efePdtePerCod = e1.efePdtePerCod AND ('+ ISNULL(  + '''' + CAST(@fechaARemesarHasta AS VARCHAR) + '''','NULL') +' IS NULL OR e2.efePdteFecRemDesde <= '+ ISNULL( + '''' + CAST(@fechaARemesarHasta AS VARCHAR) + '''','NULL') +') GROUP BY efePdtefacCod, efePdtePerCod, efePdteCtrCod), 0) > (ISNULL(ftfImporte, 0) - ISNULL(ftcImporte, 0))
				)
			)
			AND ('+ ISNULL(CAST(@seleccionado AS VARCHAR),'NULL') +' IS NULL OR
				('+ ISNULL(CAST(@seleccionado AS VARCHAR),'NULL') +' = 1 AND EXISTS(SELECT remUsrCod 
							FROM remesasTrab 
							WHERE ('+ ISNULL(+ '''' + CAST(@usuarioActual AS VARCHAR) + '''','NULL') +' IS NULL OR remUsrCod = '+ ISNULL(+ '''' + CAST(@usuarioActual AS VARCHAR) + '''','NULL') +') AND 
								  remCtrCod = e1.efePdteCtrCod AND 
								  remPerCod = e1.efePdtePerCod AND
								  remFacCod = e1.efePdteFacCod AND
								  remEfePdteCod = e1.efePdteCod AND
								  remSerScdCod = e1.efePdteScd)
				) OR
				('+ ISNULL(CAST(@seleccionado AS VARCHAR),'NULL') +' = 0 AND NOT EXISTS(SELECT remUsrCod 
							FROM remesasTrab 
							WHERE ('+ ISNULL(+ '''' + CAST(@usuarioActual AS VARCHAR) + '''','NULL') +' IS NULL OR remUsrCod = '+ ISNULL( + '''' + CAST(@usuarioActual AS VARCHAR) + '''','NULL') +') AND 
								  remCtrCod = e1.efePdteCtrCod AND 
								  remPerCod = e1.efePdtePerCod AND
								  remFacCod = e1.efePdteFacCod AND
								  remEfePdteCod = e1.efePdteCod AND
								  remSerScdCod = e1.efePdteScd)
				)
			)
			
			ORDER BY efePdtePerCod, efePdteCtrCod, efePdteFacCod, efePdteFecRemDesde, efePdteFecReg'
			)

EXEC(@sql)






GO


