--EXEC OrdenTrabajoTrab_Select

ALTER PROCEDURE [dbo].[OrdenTrabajoTrab_Select] 
	@otTrabSerScd SMALLINT = NULL,
	@otTrabSerCod SMALLINT = NULL,
	@otTrabNum INTEGER = NULL,
	@otTrabUsrCod VARCHAR(10) = NULL,
	@otFechaSolicitudD DATETIME = NULL,
	@otFechaSolicitudH DATETIME = NULL,
	@otFechaRealizacionD DATETIME = NULL,
	@otFechaRealizacionH DATETIME = NULL,
	@otTipo VARCHAR(4) = NULL
AS 
	SET NOCOUNT ON; 
	
SELECT otTrabSerScd, otTrabSerCod, otTrabNum, otTrabUsrCod
		--cierre masivo x origen
		, OT.otCtrCod
		, OT.otottcod
		, OT.otEplCttCod
		, OT.otEplCod
		, OT.otfsolicitud
		, OT.otFecRechazo
		, OT.otfrealizacion
		, OT.otottcod
		, OT.otTipoOrigen
		, C.cttnom
		, E.eplnom
		, T.ottdes
		, O.ottoDescripcion
		, O.ottoOrigen
	   FROM dbo.ordenTrabajoTrab AS OTT
	   INNER JOIN dbo.ordenTrabajo AS OT 
	   ON otserscd = otTrabSerScd AND otsercod = otTrabSerCod AND otnum = otTrabNum
	   LEFT JOIN dbo.contratistas AS C
	   ON C.cttcod = OT.otEplCttCod
	   LEFT JOIN dbo.empleados AS E
	   ON  E.eplcttcod = OT.otEplCttCod
	   AND E.eplcod = OT.otEplCod
	   LEFT JOIN dbo.ottipos AS T
	   ON OT.otottcod= T.ottcod
	   --cierre masivo x origen
	   LEFT JOIN dbo.otTiposOrigen AS O
	   ON OT.otottcod = O.ottoCodigo 
	   AND OT.otTipoOrigen = O.ottoOrigen 
	   
	   WHERE (@otFechaSolicitudD IS NULL OR otfsolicitud >= @otFechaSolicitudD) AND
			 (@otFechaSolicitudH IS NULL OR otfsolicitud <= @otFechaSolicitudH) AND
			 (@otFechaRealizacionD IS NULL OR otfrealizacion >= @otFechaRealizacionD) AND
			 (@otFechaRealizacionH IS NULL OR otfrealizacion <= @otFechaRealizacionH) AND
			 (@otTipo IS NULL OR otottcod = @otTipo) AND
		      otfcierre IS NULL	
ORDER BY otTrabSerScd, otTrabSerCod, otTrabNum
GO


