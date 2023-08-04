ALTER PROCEDURE [dbo].[OrdenTrabajo_Select]
	@otserscd smallint = NULL,
	@otsercod smallint = NULL,
	@otnum int = NULL,
	@otCtrCod int = NULL,
	@otCtrVersion smallint = NULL,
	@otFechaRegDesde datetime = NULL,
	@otFechaRegHasta datetime = NULL,
	@otottcod varchar(4) = NULL,
	@anyoSolicitud INT = NULL,
	@otdessolicitud varchar(80) = NULL 
	, @otRechazada BIT = NULL
	, @otCerrada BIT = NULL
AS
	SET NOCOUNT ON;

SELECT [otserscd]
      ,[otsercod]
      ,[otnum]
      ,[otfsolicitud]
      ,[otfrealizacion]
      ,[otfcierre]
      ,[otottcod]
      ,[otdessolicitud]
      ,[otdesrealizacion]
      ,[otobs]
      ,[otiptcod]
      ,[otcotcod]
      ,[otsubcotcod]
      ,[otalmcod]
	  ,[otPrvCod]
	  ,[otPobCod]
      ,[otdireccion]
      ,[otCliCod]
      ,[otCtrCod]
      ,[otCtrVersion]
      ,[otUsuSolicitud]
      ,[otUsuRealizacion]
      ,[otUsuCierre]
      ,[otEplCod]
      ,[otEplCttCod]
      ,[otDepCod]
      ,[otMtcCod]
	  ,[otObsRealizacion]
	  ,[otFPrevision]
	  ,[otFechaReg]
	  ,[otUsrUltMod]
	  ,[otFecUltMod]
	  , [otPrioridad]
	  , [otFecRechazo]
	  , [otUsuRechazo]
	  , [otTipoOrigen]
FROM  dbo.ordenTrabajo AS OT

WHERE  (otserscd=@otserscd OR @otserscd IS NULL) AND
	   (otsercod=@otsercod OR @otsercod IS NULL) AND
	   (otnum=@otnum OR @otnum IS NULL) AND
	   (otCtrCod=@otCtrCod OR @otCtrCod IS NULL) AND
	   (otCtrVersion=@otCtrVersion OR @otCtrVersion IS NULL) AND
	   (otFechaReg >= @otFechaRegDesde OR @otFechaRegDesde IS NULL) AND
	   (otFechaReg <= @otFechaRegHasta OR @otFechaRegHasta IS NULL) AND
	   (otottcod = @otottcod OR @otottcod IS NULL) AND
	   (YEAR(otfsolicitud) = @anyoSolicitud OR @anyoSolicitud IS NULL) AND 
	   (otdessolicitud = @otdessolicitud OR @otdessolicitud IS NULL)

	   AND (@otRechazada IS NULL OR (@otRechazada = 0 AND OT.otFecRechazo IS NULL) OR (@otRechazada = 1 AND OT.otFecRechazo IS NOT NULL))
	   AND (@otCerrada IS NULL OR (@otCerrada = 0 AND OT.otfcierre IS NULL) OR (@otCerrada = 1 AND OT.otfcierre IS NOT NULL));


GO


