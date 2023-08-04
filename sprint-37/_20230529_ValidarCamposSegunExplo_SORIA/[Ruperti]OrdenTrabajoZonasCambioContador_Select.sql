
ALTER PROCEDURE [dbo].[OrdenTrabajoZonasCambioContador_Select] 

    @usuario VARCHAR(10) = NULL,

    @zona VARCHAR(4) = NULL,

    @rechazadas BIT = NULL,

    @startIndex INT = 0,

    @pageSize INT = 100000000

    AS SET NOCOUNT ON;

BEGIN

    DECLARE @tipoOtCC VARCHAR(4), @asignacionOtCC INT = 1

    SELECT @tipoOtCC = pgsValor FROM parametros WHERE pgsClave = 'OT_TIPO_CC'

    SELECT @asignacionOtCC = ISNULL(pgsValor, 1) FROM parametros WHERE pgsClave = 'OTCC_ASIGNACION_OT'

    SELECT otserscd, otsercod, otnum, otfsolicitud, otdessolicitud, otFecRechazo, otPrioridad, otCtrCod

        , CASE WHEN otdireccion IS NULL THEN inmDireccion ELSE otdireccion END AS otdireccion 

    FROM ordenTrabajo

    INNER JOIN contratos ON otCtrCod = ctrcod AND otCtrVersion = ctrversion

    LEFT JOIN inmuebles ON ctrinmcod = inmcod

    LEFT JOIN contadorCambio ON conCamOtNum = otnum

    WHERE otottcod = @tipoOtCC

        AND otfcierre IS NULL 

        AND otfrealizacion IS NULL

        AND conCamOtNum IS NULL

        AND (@zona IS NULL OR ctrzoncod = @zona)

        AND (@rechazadas IS NULL OR (@rechazadas = 0 AND otFecRechazo IS NULL) OR (@rechazadas = 1 AND otFecRechazo IS NOT NULL))    

        AND (@asignacionOtCC = 1 OR @usuario IS NULL

            OR (@asignacionOtCC = 2 AND @usuario IS NOT NULL AND (otEplCod = (SELECT usreplcod FROM usuarios WHERE usrcod = @usuario) 

                AND otEplCttCod = (SELECT usreplcttcod FROM usuarios WHERE usrcod = @usuario)))

            OR (@asignacionOtCC = 3 AND @usuario IS NOT NULL AND otEplCttCod = (SELECT usreplcttcod FROM usuarios WHERE usrcod = @usuario))

        )

    ORDER BY IIF(otPrioridad IS NULL, 1, 0), otPrioridad, ctrzoncod, inmcalle, inmfinca, inmDireccion, otfsolicitud ASC

    OFFSET @startIndex ROWS  

    FETCH NEXT @pageSize ROWS ONLY

END





