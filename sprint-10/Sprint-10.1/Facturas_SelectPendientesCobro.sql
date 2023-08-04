/**** OBTIENE LAS FACTURAS PENDIENTES DE COBRAR ****/
-- Si se le pasa una versión obtendrá la factura cuya versión sea esa (pasándole también contrato y periodo),
-- si no se la pasa versión, obtiene la versión según la fecha de registro, que a su vez, si ésta no se le pasa,
-- toma la fecha de hoy
--EXEC Facturas_SelectPendientesCobro

ALTER PROCEDURE [dbo].[Facturas_SelectPendientesCobro] 
@periodo varchar(6) = NULL,
@zona varchar(4) = NULL,
@contrato int = NULL,
@versionFactura smallint = NULL,
@fechaRegistroMaxima DATETIME = NULL,
@fechaCobroMaxima DATETIME = NULL,
@contratoD INT = NULL,
@contratoH INT = NULL,
@periodoD VARCHAR(6) = NULL,
@periodoH VARCHAR(6) = NULL,
@importeD MONEY = NULL,
@importeH MONEY = NULL,
@xmlIncLecUltFac TEXT = NULL,
@xmlIncLecAlgunaFac TEXT = NULL,
@xmlIncLecInspec TEXT = NULL,
@numPeriodosDeuda INT = NULL,
@baja BIT = NULL, --Si vale 1 la selección será de las facturas pendientes de cobro de los contratos que están dados de baja, si es 0 los que no están de baja y si es NULL todos.
@esServicioMedido BIT = NULL, -- si el parámetro @esServicioMedido es igual a 1 devuelve toas las facturas que tienen servicio de tipo medido 'M', si es 0 las devuelve las facturas que son distintas al tipo medido y si es NULL devuelve todas
@fechaD DATETIME = NULL,
@fechaH DATETIME = NULL,
@servicioCodigo SMALLINT = NULL,
@zonaD VARCHAR(4) = NULL,
@zonaH VARCHAR(4) = NULL,
@tarifaD SMALLINT = NULL,
@tarifaH SMALLINT = NULL,
@usoCodigo INT = NULL,
@obtenerSoloClavePrimaria BIT = NULL, --Si es 1, sólo obtiene la PK de facturas y los importes
@clienteCodigo INT = NULL,
@apremiado BIT = NULL

AS
	SET NOCOUNT ON;

-- XML donde se indicas las incidencias de lectura para que solo salgan las facturas que tengan en la última factura las 
-- incidencias indicadas.
IF @xmlIncLecUltFac IS NOT NULL BEGIN
	--Creamos una tabla en memoria donde se van a insertar todos los valores
	DECLARE @incidenciasLecturaUltimaFactura AS TABLE(incidenciaCodigo VARCHAR(2)) 
	--Leemos los parámetros del XML
	DECLARE @idoc INT
	EXEC sp_xml_preparedocument @idoc OUTPUT, @xmlIncLecUltFac 
	--Insertamos en tabla temporal
	INSERT INTO @incidenciasLecturaUltimaFactura(incidenciaCodigo)	
	SELECT value
		FROM OPENXML (@idoc, '/incidenciasCodigo_List/incidenciaCodigo', 2) WITH (value VARCHAR(2))	
	--Liberamos memoria
	EXEC  sp_xml_removedocument @idoc
END

-- XML donde se indicas las incidencias de lectura para que solo salgan los contratos que tengan en alguna factura las 
-- incidencias indicadas.
IF @xmlIncLecAlgunaFac IS NOT NULL BEGIN
	--Creamos una tabla en memoria donde se van a insertar todos los valores
	DECLARE @incidenciasLecturaAlgunaFactura AS TABLE(incidenciaCodigo VARCHAR(2)) 
	--Leemos los parámetros del XML
	EXEC sp_xml_preparedocument @idoc OUTPUT, @xmlIncLecAlgunaFac 
	--Insertamos en tabla temporal
	INSERT INTO @incidenciasLecturaAlgunaFactura(incidenciaCodigo)	
	SELECT value
		FROM OPENXML (@idoc, '/incidenciasCodigo_List/incidenciaCodigo', 2) WITH (value VARCHAR(2))	
	--Liberamos memoria
	EXEC  sp_xml_removedocument @idoc
END


-- XML donde se indicas las incidencias de lectura para que solo salgan los contratos que tengan en alguna factura las 
-- incidencias indicadas.
IF @xmlIncLecInspec IS NOT NULL BEGIN
	--Creamos una tabla en memoria donde se van a insertar todos los valores
	DECLARE @incidenciasInspeccion AS TABLE(incidenciaCodigo VARCHAR(2)) 
	--Leemos los parámetros del XML
	EXEC sp_xml_preparedocument @idoc OUTPUT, @xmlIncLecInspec 
	--Insertamos en tabla temporal
	INSERT INTO @incidenciasInspeccion(incidenciaCodigo)	
	SELECT value
		FROM OPENXML (@idoc, '/incidenciasCodigo_List/incidenciaCodigo', 2) WITH (value VARCHAR(2))	
	--Liberamos memoria
	EXEC  sp_xml_removedocument @idoc
END


DECLARE @facturasPendientesDeCobro AS
		TABLE (
	    facCod smallint
	   ,facPerCod varchar(6)
	   ,facCtrCod int
	   ,facVersion smallint
	   ,facCtrVersion smallint
	   ,facSerScdCod smallint
	   ,facSerCod smallint
	   ,facNumero VARCHAR(20)
	   ,facFecha datetime
	   ,facClicod int
	   ,facSerieRectif smallint
	   ,facNumeroRectif VARCHAR(20)
	   ,facFechaRectif datetime
	   ,facLecAnt int
	   ,facLecAntFec datetime
	   ,facLecLector int
	   ,facLecLectorFec datetime
	   ,facLecInlCod varchar(2)
	   ,facLecInspector int
	   ,facLecInspectorFec datetime
	   ,facInsInlCod varchar(2)
	   ,facLecAct int
	   ,facLecActFec datetime
	   ,facConsumoReal int
	   ,facConsumoFactura int
	   ,facLote int
	   ,facLectorEplCod smallint
	   ,facLectorCttCod smallint
	   ,facInspectorEplCod smallint
	   ,facInspectorCttCod smallint
	   ,facNumeroRemesa int
	   ,facFechaRemesa datetime
	   ,facZonCod varchar(4)
	   ,facInspeccion int
	   ,facFecReg datetime
	   ,facOTNum int
	   ,facOTSerCod smallint
	   ,facCnsFinal int
	   ,facCnsComunitario int
	   ,facFecContabilizacion datetime
	   ,facFecContabilizacionAnu datetime
	   ,facUsrContabilizacion varchar(10)
	   ,facUsrReg varchar(10)
	   ,facUsrContabilizacionAnu varchar(10)
	   ,facRazRectcod VARCHAR(2)
	   ,facRazRectDescType VARCHAR(100)
	   ,facMeRect VARCHAR(2)
	   ,facMeRectType VARCHAR(100)
	   ,facEnvSERES VARCHAR(1)
	   ,facEnvSAP BIT
	   ,facTipoEmit VARCHAR(2)
	   ,cobrado money
	   ,facturado money
		)
	
INSERT INTO @facturasPendientesDeCobro(
		facCod, 
		facPerCod, 
		facCtrCod, 
		facVersion, 
		facCtrVersion,
		facSerScdCod, 
		facSerCod,	
		facNumero, 
		facFecha, 
		facClicod, 
		facSerieRectif,
		facNumeroRectif,
		facFechaRectif,
		facLecAnt, 
		facLecAntFec, 
		facLecLector, 
		facLecLectorFec,
		facLecInlCod, 
		facLecInspector, 
		facLecInspectorFec, 
		facInsInlCod, 
		facLecAct, 
		facLecActFec, 
		facConsumoReal, 
		facConsumoFactura, 
		facLote, 
		facLectorEplCod, 
		facLectorCttCod, 
		facInspectorEplCod, 
		facInspectorCttCod, 
		facNumeroRemesa, 
		facFechaRemesa, 
		facZonCod, 
		facInspeccion, 
		facFecReg, 
	    facOTNum,
	    facOTSerCod,
	    facCnsFinal,
	    facCnsComunitario,
	    facFecContabilizacion,
	    facFecContabilizacionAnu,
	    facUsrContabilizacion,
	    facUsrReg,
	    facUsrContabilizacionAnu,
	    facRazRectcod,
	    facRazRectDescType,
	    facMeRect,
	    facMeRectType,
	    facEnvSERES,
	    facEnvSAP,
		facTipoEmit,
		cobrado, 
		facturado)

SELECT  facCod
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
	   --Suma del importe cobrado
	   ,(SELECT ISNULL(SUM(ROUND(cblImporte, 2)), 0)
			 FROM cobros
			 inner join coblin ON cobScd=cblScd AND cobPpag=cblPpag AND cobNum=cblNum
			 WHERE
			 cobCtr=f.facCtrCod AND cblPer=f.facPerCod AND cblFacCod=f.facCod AND
			 CONVERT(VARCHAR,cobFecReg,120) <= CONVERT(VARCHAR,ISNULL(@fechaRegistroMaxima,GETDATE()),120) AND
			 CONVERT(VARCHAR,cobFec,120) <= CONVERT(VARCHAR,ISNULL(@fechaCobroMaxima,GETDATE()),120)) AS cobrado
	   --Suma del importe facturado
	   ,(SELECT ISNULL(ROUND(SUM(fclTotal), 2), 0)
			 FROM facturas fTotal
			 INNER JOIN faclin ON fclFacPerCod=fTotal.facPerCod  
								  AND fclFacCtrCod=fTotal.facCtrCod 
								  AND fclFacVersion=fTotal.facVersion
								  AND fclFacCod =fTotal.facCod
			 WHERE (fTotal.facCtrCod=f.facCtrCod) AND 
				   (fTotal.facPerCod=f.facPerCod) AND 
				   (fTotal.facVersion=f.facVersion) AND 
				   (fTotal.facCod=f.facCod) AND 
				   (fTotal.facFecReg <= ISNULL(@fechaRegistroMaxima, GETDATE())) AND
				   ((fclFecLiq IS NULL) OR (fclFecLiq > ISNULL(@fechaRegistroMaxima, GETDATE())))--las líneas de factura que estén liquidadas NO se incluyen, ni las que tienen fecha de liquidación menor o igual que la de registro
				) AS facturado

FROM facturas f
INNER JOIN contratos c ON facCtrCod=ctrCod AND ctrVersion=(SELECT MAX(ctrVersion) FROM contratos cSub WHERE cSub.ctrcod = f.facCtrCod)
WHERE 
	  (facPerCod = @periodo OR @periodo IS NULL) AND 
	  (facZonCod = @zona OR @zona IS NULL) AND 
	  (facCtrCod = @contrato OR @contrato IS NULL) AND 
	  (facVersion = @versionFactura OR @versionFactura IS NULL) AND 
	  (facCtrCod >= @contratoD OR @contratoD IS NULL) AND
	  (facCtrCod <= @contratoH OR @contratoH IS NULL) AND
	  (facperCod >= @periodoD or @periodoD IS NULL) AND
	  (facperCod <= @periodoH or @periodoH IS NULL) AND
	  (@zonaD IS NULL OR ctrzoncod >= @zonaD) AND
	  (@zonaH IS NULL OR ctrzoncod <= @zonaH) AND
	  (@usoCodigo IS NULL OR ctrUsoCod = @usoCodigo) AND
	  ((facpercod >= ISNULL((SELECT pgsValor FROM parametros WHERE pgsClave = 'PERIODO_INICIO'),'')) OR LEFT(facpercod,4)='0000') AND
	  (@xmlIncLecUltFac IS NULL OR 
	   EXISTS(SELECT f2.facLecInlCod FROM facturas f2 INNER JOIN @incidenciasLecturaUltimaFactura ON f2.facLecInlCod = incidenciaCodigo
			  WHERE f2.facFecReg = (SELECT MAX(f3.facFecReg) FROM facturas f3 WHERE f3.facCtrCod = f2.facCtrCod AND f3.facPerCod NOT LIKE '0%' AND f3.facPerCod NOT LIKE '9%')
			    AND f2.facCtrCod = f.facCtrCod
			    AND f2.facPerCod NOT LIKE '0%' AND f2.facPerCod NOT LIKE '9%')
       ) AND
       (@xmlIncLecAlgunaFac IS NULL OR 
		EXISTS(SELECT facLecInlCod FROM facturas f2	INNER JOIN @incidenciasLecturaAlgunaFactura ON f2.facLecInlCod = incidenciaCodigo
			   WHERE  (f2.facPerCod >= @periodoD OR @periodoD IS NULL)
				  AND (f2.facPerCod <= @periodoH OR @periodoH IS NULL)	
			      AND  f2.facCtrCod = C.ctrcod
			   )
	   ) AND
	   
	    
	          (@xmlIncLecInspec IS NULL OR 
		EXISTS(SELECT facLecInlCod FROM facturas f2	INNER JOIN @incidenciasInspeccion ON f2.facinsinlCod = incidenciaCodigo
			   WHERE  (f2.facPerCod >= @periodoD OR @periodoD IS NULL)
				  AND (f2.facPerCod <= @periodoH OR @periodoH IS NULL)	
			      AND  f2.facCtrCod = C.ctrcod
			   )
	   ) AND
	   
	   
	  (facVersion=(SELECT MAX(facVersion) FROM facturas fSub where fSub.facPerCod = f.facPerCod AND fSub.facCtrCod = f.facCtrCod AND fSub.facCod = f.facCod)) AND
	  (ctrBaja=@baja OR @baja IS NULL) AND
	  (facFecha >= @fechaD OR @fechaD IS NULL) AND
	  (facFecha <= @fechaH OR @fechaH IS NULL) AND
	  ((@servicioCodigo IS NULL AND @tarifaD IS NULL AND @tarifaH IS NULL) OR EXISTS(SELECT fclFacCod 
										 FROM faclin fl
										 WHERE f.facCod = fl.fclFacCod AND f.facPerCod = fl.fclFacPerCod AND f.facCtrCod = fl.fclFacCtrCod AND f.facVersion = fl.fclFacVersion
										   AND (@servicioCodigo IS NULL OR @servicioCodigo = fl.fclTrfSvCod)
										   AND (@tarifaD IS NULL OR @tarifaD <= fl.fclTrfCod)
										   AND (@tarifaH IS NULL OR @tarifaH >= fl.fclTrfCod) 
										   AND ((fl.fclFecLiq IS NULL) OR (fl.fclFecLiq > ISNULL(@fechaRegistroMaxima, GETDATE())))
										)
	  ) AND
	  -- IMPORTE_COBRADO < IMPORTE_FACTURADO condición para que sean pendientes de cobro
	   (SELECT ISNULL(SUM(ROUND(cblImporte, 2)), 0)
				FROM cobros INNER JOIN coblin ON cobScd=cblScd AND cobPpag=cblPpag AND cobNum=cblNum
				WHERE cobCtr=f.facCtrCod AND 
					  cblPer=f.facPerCod AND 
					  cblFacCod=f.facCod
		)
		<
		(SELECT ISNULL(ROUND(sum(fclTotal), 2), 0)
				FROM facturas fTotal
			    INNER JOIN faclin ON fclFacPerCod=fTotal.facPerCod 
									 AND fclFacCtrCod=fTotal.facCtrCod 
									 AND fclFacVersion=fTotal.facVersion
									 AND fclFacCod=Ftotal.facCod
				WHERE (fTotal.facCtrCod=f.facCtrCod) AND 
					  (fTotal.facPerCod=f.facPerCod) AND 
					  (fTotal.facVersion=f.facVersion) AND
					  (fTotal.facCod=f.facCod) AND
					  (fTotal.facFecReg <= ISNULL(@fechaRegistroMaxima, GETDATE())) AND 
					  ((fclFecLiq IS NULL) OR (fclFecLiq > ISNULL(@fechaRegistroMaxima, GETDATE())))--las líneas de factura que estén liquidadas NO se incluyen, ni las que tienen fecha de liquidación menor o igual que la de registro
		) AND
		(@esServicioMedido IS NULL OR EXISTS (SELECT fclNumLinea 
													FROM facLin 	
													INNER JOIN servicios ON fclTrfSvCod = svcCod AND 
																			fclFacPerCod = facPerCod AND 
																			fclFacCtrCod = facCtrCod AND 
																			fclFacVersion = facVersion AND
																			fclFacCod = facCod 
													WHERE (@esServicioMedido = 1 AND svcTipo = 'M') OR 
														  (@esServicioMedido = 0 AND svcTipo <> 'M')
											 )
		) AND
	   facSerScdCod IS NOT NULL AND 
	   facSerCod IS NOT NULL AND
	   facNumero IS NOT NULL  AND
	   (@clienteCodigo IS NULL OR facClicod = @clienteCodigo) AND
	   (@apremiado IS NULL OR @apremiado = 0 OR 
	    EXISTS(SELECT aprnumero 
					  FROM apremios 
					  WHERE aprFacCod = facCod AND 
							aprFacPerCod = facPerCod AND 
							aprFacCtrCod = facCtrCod AND 
							aprFacVersion = facVersion)
		)				   	   
       ORDER BY facCtrCod, facPerCod, facZonCod, facFecha

DELETE FROM @facturasPendientesDeCobro 
	   WHERE facCtrcod NOT IN 
		(
			SELECT facCtrCod FROM @facturasPendientesDeCobro 
			GROUP BY facCtrCod
			HAVING COUNT(facpercod) >= ISNULL(@numPeriodosDeuda,1) AND 
			((SUM(facturado)-SUM(cobrado) >= @importeD)OR @importeD IS NULL) AND
			((SUM(facturado)-SUM(cobrado) <= @importeH) OR @importeH IS NULL) 
		)

IF ISNULL(@obtenerSoloClavePrimaria, 0) = 1
	SELECT facCod, facCtrCod, facPerCod, facVersion, facturado, cobrado FROM @facturasPendientesDeCobro 
	ORDER BY facpercod, facctrcod
ELSE
	SELECT * FROM @facturasPendientesDeCobro 
	ORDER BY facpercod, facctrcod
GO