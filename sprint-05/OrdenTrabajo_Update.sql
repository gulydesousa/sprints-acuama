ALTER PROCEDURE [dbo].[OrdenTrabajo_Update]
(
	@otfsolicitud datetime,
	@otfrealizacion datetime,
	@otfcierre datetime,
	@otottcod varchar(4),
	@otdessolicitud varchar(80),
	@otdesrealizacion varchar(80),
	@otobs varchar(500),
	@otiptcod varchar(14),
	@otcotcod varchar(6),
	@otsubcotcod varchar(6),
	@otalmcod varchar(4),
	@otPrvCod varchar(3) = null,
	@otPobCod varchar(3) = null,
	@otdireccion varchar(200),
	@otCliCod int = null,
	@otCtrCod int = null,
	@otCtrVersion smallint=null,
	@otUsuSolicitud varchar(10)=null,
	@otUsuRealizacion varchar(10)=null,
	@otUsuCierre varchar(10)=null,
	@otEplCod smallint =null,
	@otEplCttCod smallint =null,
	@otDepCod int =null,
	@otMtcCod int =null,
	@otObsRealizacion varchar(500)=NULL,
	@otFPrevision datetime=null,
	@otUsrUltMod varchar(10) = NULL,
	@otFecUltMod datetime = NULL,
	@otPrioridad smallint = null,
	@Original_otserscd smallint,
	@Original_otsercod smallint,
	@Original_otnum int
	, @otFecRechazo DATETIME = NULL
	, @otUsuRechazo VARCHAR(10) = NULL
)
AS
	SET NOCOUNT OFF;

	UPDATE [ordenTrabajo] 
	   SET [otfsolicitud] = @otfsolicitud, 
		   [otfrealizacion] = @otfrealizacion, 
		   [otfcierre] = @otfcierre, 
		   [otottcod] = @otottcod, 
		   [otdessolicitud] = @otdessolicitud, 
		   [otdesrealizacion] = @otdesrealizacion, 
		   [otobs] = @otobs, 
		   [otiptcod] = @otiptcod, 
		   [otcotcod] = @otcotcod, 
		   [otsubcotcod] = @otsubcotcod, 
		   [otalmcod] = @otalmcod,
		   [otPrvCod]= @otPrvCod,
		   [otPobCod]= @otPobCod,
		   [otdireccion]= @otdireccion,
		   [otCliCod] = @otCliCod,
		   [otCtrCod]=@otCtrCod,
		   [otCtrVersion]=@otCtrVersion,
		   [otUsuSolicitud] = @otUsuSolicitud,
		   [otUsuRealizacion] = @otUsuRealizacion,
		   [otUsuCierre] = @otUsuCierre,
		   [otEplCod] = @otEplCod,
		   [otEplCttCod] = @otEplCttCod,
		   [otDepCod] = @otDepCod,
		   [otMtcCod] = @otMtcCod,
		   [otObsRealizacion] = @otObsRealizacion, 
		   [otFPrevision]=@otFPrevision, 
		   [otUsrUltMod] = @otUsrUltMod, 
		   [otFecUltMod] = ISNULL(@otFecUltMod, GETDATE())
		   , [otPrioridad] = @otPrioridad
		   , [otFecRechazo] = @otFecRechazo
		   , [otUsuRechazo] = @otUsuRechazo

	WHERE (([otserscd] = @Original_otserscd) 
	  AND ([otsercod] = @Original_otsercod) 
	  AND ([otnum] = @Original_otnum) );

GO


