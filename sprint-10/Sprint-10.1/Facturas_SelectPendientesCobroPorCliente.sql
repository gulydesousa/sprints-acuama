--DECLARE @clienteCodigo INT = NULL

ALTER PROCEDURE [dbo].[Facturas_SelectPendientesCobroPorCliente] 
@clienteCodigo INT = NULL

AS
	SET NOCOUNT ON;
	
	SELECT TOP 4 
	 facCod
	,facPerCod
	,facCtrCod
	,facVersion
	,facCtrVersion
	,facSerScdCod
	,facSerCod
	,facNumero
	,facFecha
	,facClicod
	,facSerieRectif
	,facNumeroRectif
	,facFechaRectif
	,facLecAnt
	,facLecAntFec
	,facLecLector
	,facLecLectorFec
	,facLecInlCod
	,facLecInspector
	,facLecInspectorFec
	,facInsInlCod
	,facLecAct
	,facLecActFec
	,facConsumoReal
	,facConsumoFactura
	,facLote
	,facLectorEplCod
	,facLectorCttCod
	,facInspectorEplCod
	,facInspectorCttCod
	,facNumeroRemesa
	,facFechaRemesa
	,facZonCod
	,facInspeccion
	,facFecReg
	,facOTNum
	,facOTSerCod
	,facCnsFinal
	,facCnsComunitario
	,facFecContabilizacion
	,facFecContabilizacionAnu
	,facUsrContabilizacion
	,facUsrReg
	,facUsrContabilizacionAnu
	,facRazRectcod
	,facRazRectDescType
	,facMeRect
	,facMeRectType
	,facEnvSERES
	,facEnvSAP
	,facTipoEmit
FROM facturas
	 INNER JOIN fFacturas_TotalFacturado(NULL, 0, NULL) ON ftfFacCod = facCod AND ftfFacPerCod = facPerCod AND ftfFacVersion = facVersion  AND ftfFacCtrCod = facCtrCod
	 LEFT JOIN fFacturas_TotalCobrado(NULL) ON ftcCtr = facCtrCod AND ftcFacCod = facCod AND ftcPer =facPerCod
WHERE facFechaRectif IS NULL
	  AND facSerScdCod IS NOT NULL
	  AND facSerCod IS NOT NULL
	  AND facNumero IS NOT NULL
	  AND (@clienteCodigo IS NOT NULL AND facClicod = @clienteCodigo)
	  --Pendiente de cobro
	  AND ISNULL((ftfImporte), 0) > ROUND(ISNULL((ftcImporte), 0), 2) 
	  
GO


