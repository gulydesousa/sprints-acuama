ALTER PROCEDURE [dbo].[OrdenTrabajo_SelectPorFactura] 
	@facCtrCod INT,
	@facPerCod VARCHAR(6),
	@facCod SMALLINT
AS
BEGIN

	SET NOCOUNT ON; 

	-- Buscamos primero el facNumero para comprobar si queremos seleccionar las OTs de una rectificativa (facNumero en negativo)
	DECLARE @facNumero VARCHAR(20)

	SELECT @facNumero = facNumero
	  FROM facturas
	 WHERE facCtrCod = @facCtrCod AND facPerCod = @facPerCod and facCod = @facCod
	   AND facVersion = (SELECT MAX(facVersion) FROM facturas WHERE facCtrCod = @facCtrCod AND facPerCod = @facPerCod and facCod = @facCod)

	IF CONVERT(BIGINT, @facNumero) < 0 
	  BEGIN
		SELECT DISTINCT otserscd, otsercod, otnum, otfsolicitud, otfrealizacion, otfcierre, otottcod, otdessolicitud, otdesrealizacion, otobs, otiptcod, 
			   otcotcod, otsubcotcod, otalmcod, otPrvCod, otPobCod, otdireccion, otCliCod, otCtrCod, otCtrVersion, otUsuSolicitud, otUsuRealizacion, otUsuCierre, 
			   otEplCod, otEplCttCod, otDepCod, otMtcCod, otObsRealizacion, otFechaReg, otFPrevision, otFecUltMod, otUsrUltMod
			   , otPrioridad
			   , otFecRechazo
			   , otUsuRechazo
			   , otTipoOrigen
		 FROM ordenTrabajo AS o 
			INNER JOIN diferidosHist d ON o.otnum = d.difHOriNum and o.otsercod = d.difHOriSerCod and o.otserscd = d.difHOriSerScdCod and o.otCtrCod = d.difHCtrCod
		 WHERE difHCtrCod = @facCtrCod
		   AND (difHPeriodoAplicacion = @facPerCod)
		   AND (difHFacCod = 1 OR difHFacVersion = 1)

		-- Dejo esto para descomentarlo si en algún momento queremos que también se abran las OTs de los diferidos que estén sin aplicar aún

		--UNION
		--SELECT DISTINCT otserscd, otsercod, otnum, otfsolicitud, otfrealizacion, otfcierre, otottcod, otdessolicitud, otdesrealizacion, otobs, otiptcod, 
		--	   otcotcod, otsubcotcod, otalmcod, otPrvCod, otPobCod, otdireccion, otCliCod, otCtrCod, otCtrVersion, otUsuSolicitud, otUsuRealizacion, otUsuCierre, 
		--	   otEplCod, otEplCttCod, otDepCod, otMtcCod, otObsRealizacion, otFechaReg, otFPrevision, otFecUltMod, otUsrUltMod
		--, otPrioridad
		--, otFecRechazo
		--, otUsuRechazo
		--  FROM ordenTrabajo o 
		--	INNER JOIN diferidos d ON o.otnum = d.diforinum and o.otsercod = d.difOriSerCod and o.otserscd = d.difOriSerScdCod and o.otCtrCod = d.difCtrCod
		-- WHERE difctrcod = @facCtrCod AND difPeriodoAplicacion IS NULL AND difFacCod IS NULL 

		ORDER BY otnum
	  END
	ELSE
	  BEGIN	
		SELECT DISTINCT otserscd, otsercod, otnum, otfsolicitud, otfrealizacion, otfcierre, otottcod, otdessolicitud, otdesrealizacion, otobs, otiptcod, 
			   otcotcod, otsubcotcod, otalmcod, otPrvCod, otPobCod, otdireccion, otCliCod, otCtrCod, otCtrVersion, otUsuSolicitud, otUsuRealizacion, otUsuCierre, 
			   otEplCod, otEplCttCod, otDepCod, otMtcCod, otObsRealizacion, otFechaReg, otFPrevision, otFecUltMod, otUsrUltMod
			   , otPrioridad
			   , otFecRechazo
			   , otUsuRechazo
			   , otTipoOrigen
		  FROM ordenTrabajo AS o 
			INNER JOIN diferidos d ON o.otnum = d.diforinum and o.otsercod = d.difOriSerCod and o.otserscd = d.difOriSerScdCod and o.otCtrCod = d.difCtrCod
		 WHERE difctrcod = @facCtrCod 
		   AND difPeriodoAplicacion = @facPerCod 
		   AND difFacCod = @facCod 
		ORDER BY otnum
	  END	   	   
END
GO


