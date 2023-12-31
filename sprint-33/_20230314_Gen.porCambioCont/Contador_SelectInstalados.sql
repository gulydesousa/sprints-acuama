
ALTER PROCEDURE [dbo].[Contador_SelectInstalados] 
	@incidenciaCambioContador BIT = NULL, --True = Obtiene tambi�n los que tengan la marca "cambio de contador" en la incidencia de lectura. False � NULL obtiene todos
	@codigo INT = NULL,
	@inciLecLectorD VARCHAR(2) = NULL,
	@inciLecLectorH VARCHAR(2) = NULL,
	@inciLecInspD VARCHAR(2) = NULL,
	@inciLecInspH VARCHAR(2) = NULL,
	@contratoD INT = NULL,
	@contratoH INT = NULL,
	@contadorD VARCHAR(14) = NULL, --N�mero de serie
	@contadorH VARCHAR(14) = NULL,
	@fechaCompraD DATETIME = NULL,
	@fechaCompraH DATETIME = NULL,
	@fechaInstalacionD DATETIME = NULL,
	@fechaInstalacionH DATETIME = NULL,
	@SinOTAbiertas BIT = NULL
	--Mejoras Generaci�n masiva de ordenes de trabajo Acuama
  , @zonaD VARCHAR(4) = NULL
  , @zonaH VARCHAR(4) = NULL
  , @ruta1 VARCHAR(10) = NULL
  , @ruta2 VARCHAR(10) = NULL
  , @ruta3 VARCHAR(10) = NULL
  , @ruta4 VARCHAR(10) = NULL
  , @ruta5 VARCHAR(10) = NULL
  , @ruta6 VARCHAR(10) = NULL

AS 
SET NOCOUNT ON; 
	
SELECT     --Datos contador
		   c1.conNumSerie 
		  ,conMcnCod
		  ,conClcCod
		  ,conFecReg
		  ,conComFec
		  ,conComPro
		  ,conHomFec
		  ,conHomRef
		  ,conHomPro
		  ,c1.conDiametro
		  ,[conMdlCod]
          ,[conEqpTipoCod] 
          ,[conTtzCod] 
          ,[conConTipoCod] 
          ,[conAlmCod] 
          ,[conNumRuedas] 
          ,[conCaudal]
          ,[conAnyoFab] 
          ,[conFecPrimIns] 
          ,[conFecFinGar] 
          ,[conFecRev] 
          ,[conFecPreRen] 
          ,[conPropCod]
          ,[conEstadoCod]
		  ,conID
		  --Datos de instalaci�n
		  ,ctcCtr
		  ,ctcFec --Fecha de instalaci�n
          ,ctcLec --Lectura de instalaci�n
		  ,ctrTitCod --Cliente
FROM contador
INNER JOIN fContratos_ContadoresInstalados(NULL) c1 ON ctcCon = conID /*Saca los registros que tengan una operaci�n I y no tengan luego una R*/
INNER JOIN dbo.contratos AS C ON 
			ctrCod = ctcCtr AND
			ctrVersion = (SELECT MAX(ctrVersion) FROM contratos cSub WHERE cSub.ctrCod = c.ctrCod)
LEFT JOIN dbo.facturas AS F ON 
						 facCtrCod = ctcCtr AND
					     facFechaRectif IS NULL AND --�ltima versi�n de la factura
					     facZonCod = ctrzoncod AND
						 facPerCod = (SELECT zonPerCod FROM zonas where zoncod = facZonCod) --�ltimo periodo facturado
WHERE (
		  (@codigo IS NULL OR conId = @codigo) AND
		  (@inciLecLectorD IS NULL OR @inciLecLectorD <= facLecInlCod) AND
		  (@inciLecLectorH IS NULL OR @inciLecLectorH >= facLecInlCod) AND
		  (@inciLecInspD IS NULL OR @inciLecInspD <= facInsInlCod) AND
		  (@inciLecInspH IS NULL OR @inciLecInspH >= facInsInlCod) AND
		  (@contratoD IS NULL OR @contratoD <= ctcCtr) AND
		  (@contratoH IS NULL OR @contratoH >= ctcCtr) AND
		  (@fechaCompraD IS NULL OR @fechaCompraD <= conComFec) AND
		  (@fechaCompraH IS NULL OR @fechaCompraH >= conComFec) AND
		  (@fechaInstalacionD IS NULL OR @fechaInstalacionD <= ctcFec) AND
		  (@fechaInstalacionH IS NULL OR @fechaInstalacionH >= ctcFec) AND
		  (@contadorD IS NULL OR @contadorD <= c1.conNumSerie) AND
		  (@contadorH IS NULL OR @contadorH >= c1.conNumSerie) AND
		  --*************************
		  --Mejoras Generaci�n masiva de ordenes de trabajo Acuama
		  (@zonaD IS NULL OR F.facZonCod>=@zonaD ) AND
		  (@zonaH IS NULL OR F.facZonCod<=@zonaH ) AND
		  (@ruta1 IS NULL OR C.ctrRuta1 = @ruta1 ) AND
		  (@ruta2 IS NULL OR C.ctrRuta2 = @ruta2 ) AND
		  (@ruta3 IS NULL OR C.ctrRuta3 = @ruta3 ) AND
		  (@ruta4 IS NULL OR C.ctrRuta4 = @ruta4 ) AND
		  (@ruta5 IS NULL OR C.ctrRuta5 = @ruta5 ) AND
		  (@ruta6 IS NULL OR C.ctrRuta6 = @ruta6 ) AND

		  --*************************		
		  (@SinOTAbiertas IS NULL OR @SinOTAbiertas = 0 OR (@SinOTAbiertas = 1 AND NOT EXISTS(SELECT otCtrCod 
																							  FROM dbo.ordenTrabajo AS OT
																							  WHERE OT.otCtrCod = ctrcod 
																							    AND OT.otottcod = (SELECT pgsvalor FROM parametros WHERE pgsclave = 'OT_TIPO_CC') 
																								AND OT.otfcierre IS NULL 
																								AND OT.otFecRechazo IS NULL)))
       ) 
      OR
      (
		(@incidenciaCambioContador = 1 AND EXISTS(SELECT inlcod FROM inciLec WHERE inlCod = facLecInlCod AND inlConCam = 1)) OR
	    (@incidenciaCambioContador = 1 AND EXISTS(SELECT inlcod FROM inciLec WHERE inlCod = facInsInlCod AND inlConCam = 1))
      )
ORDER BY conId

GO


