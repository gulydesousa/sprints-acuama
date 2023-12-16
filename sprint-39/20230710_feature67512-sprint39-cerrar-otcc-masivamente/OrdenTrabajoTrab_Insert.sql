ALTER PROCEDURE [dbo].[OrdenTrabajoTrab_Insert]
(
	@otTrabSerScd SMALLINT = NULL,
	@otTrabSerCod SMALLINT = NULL,
	@otTrabNum INTEGER = NULL,
	@otTrabUsrCod VARCHAR(10) = NULL,
	@otFechaSolicitudD DATETIME = NULL,
	@otFechaSolicitudH DATETIME = NULL,
	@otFechaRealizacionD DATETIME = NULL,
	@otFechaRealizacionH DATETIME = NULL,
	@otTipo VARCHAR(4) = NULL,
	@otClasif VARCHAR(10) = NULL,
	@otTipoOrigen VARCHAR(250) = NULL,	--cierre masivo x origen
	@regAfectados int OUT				--registros insertados
)
AS
	SET NOCOUNT OFF;
 	


	INSERT INTO ordenTrabajoTrab(otTrabSerScd, otTrabSerCod, otTrabNum, otTrabUsrCod)
	SELECT otserscd, otsercod, otnum, @otTrabUsrCod
		FROM dbo.ordenTrabajo AS OT
		--cierre masivo x origen
		LEFT JOIN [dbo].[Split](@otTipoOrigen, ',') AS O
		ON OT.otTipoOrigen = O.value 
		WHERE (@otFechaSolicitudD IS NULL OR otfsolicitud >= @otFechaSolicitudD) AND
			  (@otFechaSolicitudH IS NULL OR otfsolicitud <= @otFechaSolicitudH) AND
			  (@otFechaRealizacionD IS NULL OR otfrealizacion >= @otFechaRealizacionD) AND
			  (@otFechaRealizacionH IS NULL OR otfrealizacion <= @otFechaRealizacionH) AND
			  (@otTipo IS NULL OR otottcod = @otTipo) AND
			  (@otClasif IS NULL OR otcotcod = @otClasif) AND
			   otfcierre IS NULL AND --La OT NO debe estar cerrada
			  --Comprobar que no intente insertar órdenes de trabajo para un usuario y un tipo de proceso que ya esten en la tabla de trabajo
			   NOT EXISTS(SELECT otTrabSerScd, otTrabSerCod, otTrabNum
				                 FROM ordenTrabajoTrab
				                 WHERE otTrabSerScd = otserscd AND
									   otTrabSerCod = otsercod AND
									   otTrabNum = otnum AND
									   otTrabUsrCod = @otTrabUsrCod
			   )
			   --cierre masivo x origen
			   AND (@otTipoOrigen IS NULL OR @otTipoOrigen= '' OR O.value IS NOT NULL);

	SET @regAfectados = @@ROWCOUNT;

GO


