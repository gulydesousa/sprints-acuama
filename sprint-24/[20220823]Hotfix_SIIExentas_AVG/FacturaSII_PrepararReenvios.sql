ALTER PROCEDURE [dbo].[FacturaSII_PrepararReenvios]
	@fcSiiLoteID NVARCHAR(128) = NULL,
	@cuantosReenvios INT OUTPUT,
	@errorNumber INT OUTPUT,
	@errorMessage VARCHAR(4000) OUTPUT
AS
BEGIN
 
	SET NOCOUNT ON;	
--====================================Inicio Simplificada===============================

Declare @cuantosReenviosSimplificados as INT =0
BEGIN TRY  
begin tran Simplificadas


-- Guardamos las l�neas que vamos a insertar despu�s
SELECT fclSiiFacCod, fclSiiFacPerCod, fclSiiFacCtrCod, fclSiiFacVersion, fclSiiNumLinea
     , fclSiiNumEnvio		= D.fclSiiNumEnvio+1
	 , fclSiiCausaExencion	= D.fclSiiCausaExencion
	 , fclSiiTipoNoExenta	= D.fclSiiTipoNoExenta
	 , fclSiiEntrega
	 , fclSiiTipoImpositivo
	 , fclSiiBaseImponible
	 , fclSiiCuotaRepercutida
	 , fclSiiImpPorArt7_14_Otros
	 , fclSiiImpTAIReglasLoc
INTO #facSIIDesgloseFactura
--select distinct d.fclSiiFacCod, d.fclSiiFacCtrCod, d.fclSiiFacPerCod, d.fclSiiFacVersion
  FROM dbo.facSIIDesgloseFactura AS D 
  inner join facsii f on d.fclSiiFacCod = f.fcSiiFacCod and d.fclSiiFacCtrCod = f.fcSiiFacCtrCod
   and d.fclSiiFacPerCod = f.fcSiiFacPerCod and d.fclSiiFacVersion = f.fcSiiFacVersion and d.fclSiiNumEnvio = f.fcSiiNumEnvio
where 
 fcsiifechaexpedicionFacturaEmisor >'20190630' and
fcSiiNumEnvio = (select max(fcSiiNumEnvio) 
		  			     from facSII f2 where f2.fcSiiNumSerieFacturaEmisor = f.fcSiiNumSerieFacturaEmisor)
  and ((fcSiiImporteTotal <> 0 and fcSiiImporteTotal < CONVERT( decimal(6,2),(select pgsvalor from parametros where pgsclave = 'SII_MAX_IMP_SIMPLIFICADA') ))or fcsiitipofactura = 'AN') 
  -- Esto se a�adir�a para reenviar las que no se han enviado ya correctamente (que ser�an las de estado 1)
    and (isnull(fcSiiestado,0)=3) 
   --- A�ADIR AQU� CRITERIOS DE FILTRADO PARA SELECCIONAR LAS QUE QUEREMOS REENVIAR
   --and fclSiiFacCtrCod = 622 and fclSiiFacPerCod='201904'-- and isnull(fcSiiestado, 0) in (1) 
  -- and (fclSiiFacPerCod='201904' )  and isnull(fcSiiestado, 0) in (1) and fcSiiFechaOperacion> '20191231'
   --and (fclSiiFacPerCod='201904' ) 
		--AND 	(	 (f.fcSiiLoteID IS NOT NULL AND f.fcSiiestado IN (3) ) or (f.fcSiiLoteID IS NOT NULL AND f.fcSiiestado is not null ))
				AND (f.fcSiicodErr IN (
				 	'1117', '1100','4111'
				
				--SELECT [facsiiSimpErrcod]  FROM [facSiiSimplificadaErr] where facsiiSimpProceso = 1
				) OR
					(f.fcSiicodErr = '1100' AND RIGHT(f.fcSiidescErr, 4) = ' NIF'))
						
  
order by 1, 2, 3, 4, 5 

-- Insertamos nuevos env�os para facturas err�neas por NIF que se pueden enviar como simplificadas por no superar el importe m�ximo definido
INSERT INTO facSII
	(fcSiiFacCod, fcSiiFacPerCod, fcSiiFacCtrCod, fcSiiFacVersion, fcSiiNumEnvio, SuministroLR, fcSiiCabIDVersion, fcSiiCabTitNombreRazon,
	 fcSiiCabTitNifRepresentante, fcSiiCabTitNif, fcSiiCabTipoComunicacion, fcSiiEjercicio, fcSiiPeriodo, fcSiiIDEmisorFacturaNIF, fcSiiNumSerieFacturaEmisor,
	 fcSiiFechaExpedicionFacturaEmisor, fcSiiIDEmisorFacturaOrg, fcSiiTipoFactura, TipoRectificativa, fcSiiFraRecNumSerieFacturaEmisor, 
	 fcSiiFraRecFechaExpedicionFacturaEmisor, BaseRectificada, CuotaRectificada, fcSiiFechaOperacion, fcSiiClavRegEspOTras, fcSiiImporteTotal, DescripcionOperacion,
	 fcSiiDetInmRefCat, fcSiiEmitidaPorTerceros, fcSiiContraparteNombreRazon, fcSiiContraparteNIFRepresentante, fcSiiContraparteNIF, fcSiiContraparteIDOtro,
	 fcSiiContraparteIDType, fcSiiContraparteID, fcSiiLoteID, fcSiiestado, fcSiicodErr, fcSiidescErr, fcSiicsv)
SELECT fcSiiFacCod, fcSiiFacPerCod, fcSiiFacCtrCod, fcSiiFacVersion, fcSiiNumEnvio+1, SuministroLR, fcSiiCabIDVersion, fcSiiCabTitNombreRazon, 
	 fcSiiCabTitNifRepresentante, fcSiiCabTitNif, 'A0', fcSiiEjercicio, fcSiiPeriodo, fcSiiIDEmisorFacturaNIF, fcSiiNumSerieFacturaEmisor, 
	 fcSiiFechaExpedicionFacturaEmisor, fcSiiIDEmisorFacturaOrg, 
	 --SIMPLIFICADA
	CASE WHEN f.fcSiiTipoFactura = 'F1' THEN 'F2'
	 WHEN (f.fcSiiTipoFactura = 'R1' OR f.fcSiiTipoFactura = 'R2' OR f.fcSiiTipoFactura = 'R3' OR f.fcSiiTipoFactura = 'R4') THEN 'R5'
	 ELSE f.fcSiiTipoFactura END as fcSiiTipoFactura,
	 TipoRectificativa, fcSiiFraRecNumSerieFacturaEmisor,
	 fcSiiFraRecFechaExpedicionFacturaEmisor, BaseRectificada, CuotaRectificada, fcSiiFechaOperacion, fcSiiClavRegEspOTras, fcSiiImporteTotal, DescripcionOperacion,
	 fcSiiDetInmRefCat, fcSiiEmitidaPorTerceros, 
	 
	 -- DATOS DE LA CONTRAPARTE --------------
	 -- Si es simplificada (tipo factura F2 o R5) los datos de la contraparte deben ir a null. En esta SELECT siempre ser� simplificada o anulaci�n
	 IIF(fcsiitipofactura <> 'AN', NULL, fcSiiContraparteNombreRazon) AS fcSiiContraparteNombreRazon, 
	 IIF(fcsiitipofactura <> 'AN', NULL, fcSiiContraparteNIFRepresentante) AS fcSiiContraparteNIFRepresentante, 
	 IIF(fcsiitipofactura <> 'AN', NULL, fcSiiContraparteNIF) AS fcSiiContraparteNIF, 
	 IIF(fcsiitipofactura <> 'AN', NULL, fcSiiContraparteIDOtro) AS fcSiiContraparteIDOtro,
	 IIF(fcsiitipofactura <> 'AN', NULL, fcSiiContraparteIDType) AS fcSiiContraparteIDType, 
	 IIF(fcsiitipofactura <> 'AN', NULL, fcSiiContraparteID) AS fcSiiContraparteID, 
	 -----------------------------------------
	 
	 null, null, null, null, fcSiicsv
from facSII f
WHERE  fcsiifechaexpedicionFacturaEmisor >'20190630' and
		fcSiiNumEnvio = (select max(fcSiiNumEnvio) 
		  			     from facSII f2 where f2.fcSiiNumSerieFacturaEmisor = f.fcSiiNumSerieFacturaEmisor)
  and ((fcSiiImporteTotal <> 0 and fcSiiImporteTotal < CONVERT( decimal(6,2),(select pgsvalor from parametros where pgsclave = 'SII_MAX_IMP_SIMPLIFICADA') ))or fcsiitipofactura = 'AN') 
  -- Esto se a�adir�a para reenviar las que no se han enviado ya correctamente (que ser�an las de estado 1)
  and (isnull(fcSiiestado,0)=3) 
   --- A�ADIR AQU� LOS MISMOS CRITERIOS DE FILTRADO DE ANTES, PARA SELECCIONAR LAS QUE QUEREMOS REENVIAR
		AND 	(	 (f.fcSiiLoteID IS NOT NULL AND f.fcSiiestado IN (2, 3) ) or (f.fcSiiLoteID IS NOT NULL AND f.fcSiiestado is not null ))
				AND (f.fcSiicodErr IN (
				--'4109', '4111', '1104', '1116', '1117', '1153', '1168', '1169', '2011'
				'1117', '1100','4111'
				
				--SELECT [facsiiSimpErrcod]  FROM [facSiiSimplificadaErr] where facsiiSimpProceso = 1
				) OR
					(f.fcSiicodErr = '1100' AND RIGHT(f.fcSiidescErr, 4) = ' NIF'))
				

				set	@cuantosReenviosSimplificados = @@ROWCOUNT 
					
INSERT INTO facSIIDesgloseFactura
  (fclSiiFacCod, fclSiiFacPerCod, fclSiiFacCtrCod, fclSiiFacVersion, fclSiiNumLinea, fclSiiNumEnvio, fclSiiCausaExencion, fclSiiTipoNoExenta,
   fclSiiEntrega, fclSiiTipoImpositivo, fclSiiBaseImponible, fclSiiCuotaRepercutida, fclSiiImpPorArt7_14_Otros, fclSiiImpTAIReglasLoc)
SELECT 
   fclSiiFacCod, fclSiiFacPerCod, fclSiiFacCtrCod, fclSiiFacVersion, fclSiiNumLinea, fclSiiNumEnvio, fclSiiCausaExencion, fclSiiTipoNoExenta,
   fclSiiEntrega, fclSiiTipoImpositivo, fclSiiBaseImponible, fclSiiCuotaRepercutida, fclSiiImpPorArt7_14_Otros, fclSiiImpTAIReglasLoc
FROM #facSIIDesgloseFactura
order by 1, 2, 3, 4, 5

DROP TABLE #facSIIDesgloseFactura

commit tran Simplificadas

END TRY
BEGIN CATCH
	
    DROP TABLE #facSIIDesgloseFactura	
	DECLARE @erlNumber INT = (SELECT ERROR_NUMBER());
	DECLARE @erlSeverity INT = (SELECT ERROR_SEVERITY());
	DECLARE @erlState INT = (SELECT ERROR_STATE());
	DECLARE @erlProcedure nvarchar(128) = (SELECT ERROR_PROCEDURE());
	DECLARE @erlLine int = (SELECT ERROR_LINE());
	DECLARE @erlMessage nvarchar(4000) = (SELECT ERROR_MESSAGE());
	DECLARE @erlParams varchar(500) = ''

    rollback tran Simplificadas

	DECLARE @expl VARCHAR(20) = NULL
	SET @expl = (SELECT pgsvalor FROM parametros WHERE pgsclave = 'EXPLOTACION')
	EXEC ErrorLog_Insert  @expl, '[dbo].[[FacturaSII_PrepararReenvios]]', @erlNumber, @erlSeverity, @erlState, @erlProcedure, @erlLine, @erlMessage, @erlParams	
	
END CATCH
--=================================== Fin Simplificada



	-- Preparamos para reenv�o las facturas cuyo �ltimo n�mero de env�o se ha procesado con error (aceptadas 
	-- con errores "2", incorrectas "3", o error t�cnico "4")
	-- Si nos especifican un lote, s�lo prepararemos las facturas de dicho lote

	-- Se tratan los casos de error t�cnico (4220), y el de NIF no censado (2011, 1117). C�digos de errores frecuentes:
    --		Errores que provocan el rechazo del env�o completo
    --			4109, // El NIF no est� identificado. NIF: XXXX
    --			4111, // El NIF tiene un formato err�neo.
	--		 **	4220, // SocketTimeoutException invoking https://www1.agenciatributaria.gob.es/wlpl/SSII-FACT/ws/fe/SiiFactFEV1SOAP: Read timed out
	--				  // SocketException invoking https://www1.agenciatributaria.gob.es/wlpl/SSII-FACT/ws/fe/SiiFactFEV1SOAP: Connection reset
    --		Errores que provocan el rechazo de la factura (o de la petici�n completa si el error se produce en la cabecera)
	--			1100, // Valor o tipo incorrecto del campo: XXXXX (s�lo para campo NIF)
	--			1104, // Valor del campo ID incorrecto
    --			1116, // El NIF no est� identificado. NIF:XXXXX
    --		 **	1117, // El NIF no est� identificado. NIF:XXXXX. NOMBRE_RAZON:YYYYY
    --			1153  // El NIF tiene un formato err�neo
	--			1168, // El valor del CodigoPais s�lo puede ser 'ES' cuando el IDType sea '07'
    --			1169, // El campo ID no contiene un NIF con formato correcto.
   
    --		Errores que producen la aceptaci�n y registro de la factura en el sistema (posteriormente deben ser corregidos)
    --		 **	2011 // El NIF de la contraparte no est� censado   
	
	DECLARE @versionSII VARCHAR(3) 
	SELECT @versionSII = pgsvalor from parametros where pgsclave = 'VERSION_SII'

	SELECT pgsvalor from parametros where pgsclave = 'VERSION_SII'
	
	DECLARE @claveID_NoCensado VARCHAR(2) = '07',
			@maxReenvios INT = 3 -- Le damos un valor por defecto, por si faltara el par�metro

	-- N�mero m�ximo de reenv�os al SII desde el �ltimo cambio en la factura
	SELECT @maxReenvios = convert(int, pgsvalor) FROM parametros WHERE pgsclave = 'MaxReenviosSII'

	-- N�mero de facturas que se van a preparar para reenv�o
	SELECT @cuantosReenvios = 0, @errorNumber = 0, @errorMessage = ''

	DECLARE @facturitas TABLE
		(fcSiiNumSerieFacturaEmisor VARCHAR(60),
		 fcSiiContraparteIDOtro		VARCHAR(2), 
		 fcSiiContraparteIDType		VARCHAR(2), 
		 fcSiiContraparteID			VARCHAR(20),
		 enviarIdOtro				BIT,
		 yaAceptadaConErrores		BIT,
		 numEnvios					INT)
		
	INSERT @facturitas (fcSiiNumSerieFacturaEmisor, enviarIdOtro, yaAceptadaConErrores)
	SELECT fcSiiNumSerieFacturaEmisor, 0, 0
	  FROM facSII f INNER JOIN facSIILote l ON f.fcSiiLoteID = l.fcSiiLtID
	 WHERE 
	 	f.fcSiiCabTipoComunicacion='A0' and --=====Alta de facturas

	   -- *** Primero seleccionamos los lotes que podr�an tener facturas para reenviar ***

	   -- Si el estado del env�o no es correcto, y el estado de la respuesta no es nulo (porque si es nulo ser�
	   -- que no se han procesado las respuestas a�n)
	   --(l.fcSiiLtEstado = 'T' OR
	   -- (l.fcSiiLtEstado IS NOT NULL AND l.fcSiiLtEstado <> 'S' AND l.fcSiiLtEnvEstado IS NOT NULL AND l.fcSiiLtEnvEstado <> 'S'))
	   (l.fcSiiLtEstado = 'T' OR
	    (l.fcSiiLtEstado IS NOT NULL AND l.fcSiiLtEstado <> 'S' AND ISNULL(l.fcSiiLtEnvEstado, 'E') <> 'S'))
	   -- *** Y despu�s escogemos las facturas que hay que reenviar de dichos lotes ***

	   -- El que nos interesa es el �ltimo n�mero de env�o, que es donde vemos el estado actual
	   AND f.fcSiiNumEnvio = (SELECT MAX(fcSiiNumEnvio) 
			  				    FROM facSII f2 WHERE f.fcSiiNumSerieFacturaEmisor = f2.fcSiiNumSerieFacturaEmisor)
	   -- S�lo facturas con ID lote asignado (las que no lo tienen ya entrar�n autom�ticamente en el proceso rutinario
	   -- de env�o de lotes), o cuyo lote es el que se pide espec�ficamente, si es que se est� pidiendo alguno
	   AND (@fcSiiLoteID IS NULL OR f.fcSiiLoteID = @fcSiiLoteID)
	   -- S�lo facturas que a�n no se han procesado (p. ej. porque haya habido un error t�cnico) o las que se han 	 
	   --=========================================================================================================
	   -- SOLO PROCESAREMOS FACTURAS INCORRECTOAS INCORRECTAS "3" LAS QUE SON "2" ACEPTADAS CON ERRORES Y 4 ERROR TECNICO NO VAN AQUI
	   --=============================================================================================================
       AND (f.fcSiiestado IS NULL OR f.fcSiiestado IN (2))	   
	   -- S�lo errores de NIF despu�s de haberse aceptado con errores, errores t�cnicos o env�os incorrectos "E" 
	   -- para los que no hemos tenido respuesta
       --=================================Parametrizo en tabla=======================================================	   
	   AND (f.fcSiicodErr IS NOT NULL OR f.fcSiicodErr NOT IN (	'1117', '1100','4111')) --SIMPLICADA METO NOT IN
	    -- AND (f.fcSiicodErr IS NOT NULL OR f.fcSiicodErr NOT IN (
		-- SELECT [facsiiSimpErrcod]  FROM [facSiiSimplificadaErr] where [FacsiiSimpNoProceso] = 1
		 --))
		 --=================================Fin parametrizo en tabla================================================

	   -- Que no se haya sobrepasado el m�ximo de env�os para la factura desde el �ltimo cambio
	   --AND dbo.FacturaNumEnvios(f.fcSiiNumSerieFacturaEmisor) < @maxReenvios	   
	   --AND (f.fcSiicodErr IS NULL OR (f.fcSiicodErr IN ('1117', '2011') AND dbo.FacturaNumEnvios(f.fcSiiNumSerieFacturaEmisor) < @maxReenvios))
	 
	  -- AND (f.fcSiicodErr IS NULL OR dbo.FacturaNumEnvios(f.fcSiiNumSerieFacturaEmisor) < @maxReenvios) SIMPLIFICADA QUITO
	 
	   -- Si es un reenv�o de un NIF no censado, s�lo reenviamos si comprobamos que el pagador/titular ya est� validado
	   -- Buscamos en contratos por c�digo de contrato, pero tambi�n por el mismo NIF-Nombre que hay en la factura, porque
	   -- si son distintos el env�o seguir�a dando error aunque el del contrato sea v�lido
	   -- Y que tenga l�neas
	   AND EXISTS (SELECT 1 FROM facSIIDesgloseFactura d 
	   WHERE d.fclSiiFacCod = f.fcSiiFacCod AND d.fclSiiFacPerCod = f.fcSiiFacPerCod 
       AND d.fclSiiFacCtrCod = f.fcSiiFacCtrCod AND d.fclSiiFacVersion = f.fcSiiFacVersion
	   AND d.fclSiiNumEnvio = f.fcSiiNumEnvio)

	-- Comprobamos las veces que se ha rechazado cada factura por errores de NIF, mirando los errores de todos los env�os de una factura
	-- Ya est�n filtradas las comprobaciones previas, porque tiramos de la variable tabla
	;WITH sq as (
			 SELECT f.fcSiiNumSerieFacturaEmisor, COUNT(1) cuantos 
			   FROM facSII f INNER JOIN @facturitas s ON f.fcSiiNumSerieFacturaEmisor = s.fcSiiNumSerieFacturaEmisor
			  WHERE 
				-- Env�os que se han procesado y han quedado aceptados con errores "2" o incorrectos "3"
				-- Aqu� s�lo nos interesan los errores de NIF
					 --f.fcSiiLoteID IS NOT NULL AND f.fcSiiestado IN (2, 3)
					 f.fcSiiLoteID IS NOT NULL AND f.fcSiiestado IN (2)
				AND (f.fcSiicodErr IN (
				--'4109', '4111', '1104', '1116', '1117', '1153', '1168', '1169',
				 '2011',
				'1104'
				--SELECT [facsiiSimpErrcod]  FROM [facSiiSimplificadaErr] where facsiiSimpProceso = 1
				) )
		   GROUP BY f.fcSiiNumSerieFacturaEmisor) 
			 			 
	UPDATE s
	   SET enviarIdOtro = 1,
		   yaAceptadaConErrores = 
				CASE WHEN EXISTS 
					(SELECT 1 FROM facSII f
			     			WHERE f.fcSiiestado = '2' AND f.fcSiicodErr = '2011'
							  AND f.fcSiiNumSerieFacturaEmisor = s.fcSiiNumSerieFacturaEmisor)
				THEN 1 ELSE 0 END
	  FROM @facturitas s INNER JOIN sq ON s.fcSiiNumSerieFacturaEmisor = sq.fcSiiNumSerieFacturaEmisor
	 WHERE sq.cuantos >= 2

	-- Para los casos en que se ha aceptado con errores probaremos a seguir reenviando para ver si la AEAT ya ha censado
	-- esos NIF no censados, pero ya sin el idOtro, para lo cual necesitamos saber cu�les fueron los �ltimos valores que
	-- ten�amos en los campos de contraparte antes de haberse dado por v�lidos envi�ndolos como tipo 07 "no censados"
	-- Esto es debido a que en caso de extranjeros habremos machacado estos valore'200-4-172002640's para colarlos como no censados
	UPDATE s
	   SET enviarIdOtro = 0, -- Porque al ya estar aceptada con errores ya no necesitamos enviar el idOtro modificado
		   fcSiiContraparteIDOtro = f.fcSiiContraparteIDOtro, 
		   fcSiiContraparteIDType = f.fcSiiContraparteIDType,
		   fcSiiContraparteID = f.fcSiiContraparteID
	  FROM @facturitas s INNER JOIN facSII f ON s.fcSiiNumSerieFacturaEmisor = f.fcSiiNumSerieFacturaEmisor
	 WHERE enviarIdOtro = 1 AND s.yaAceptadaConErrores = 1
	   AND f.fcSiiNumEnvio = (SELECT MIN(fcSiiNumEnvio)-1
			  				    FROM facSII f2 
							   WHERE f2.fcSiiestado = '2' AND f2.fcSiicodErr = '2011' 
								 AND f.fcSiiNumSerieFacturaEmisor = f2.fcSiiNumSerieFacturaEmisor) 

	BEGIN TRAN NuevoEnvio
	
	BEGIN TRY
	
	  -- Insertamos las cabeceras de las facturas de los nuevos env�os que estamos preparando	
	  INSERT INTO facSII 
			(fcSiiFacCod, fcSiiFacPerCod, fcSiiFacCtrCod, fcSiiFacVersion, fcSiiNumEnvio, SuministroLR,
			fcSiiCabIDVersion, fcSiiCabTitNombreRazon, fcSiiCabTitNifRepresentante, fcSiiCabTitNif, fcSiiCabTipoComunicacion,
			fcSiiEjercicio, fcSiiPeriodo, fcSiiIDEmisorFacturaNIF, fcSiiNumSerieFacturaEmisor, fcSiiFechaExpedicionFacturaEmisor,
			fcSiiIDEmisorFacturaOrg, fcSiiTipoFactura, TipoRectificativa, fcSiiFraRecNumSerieFacturaEmisor, 
			fcSiiFraRecFechaExpedicionFacturaEmisor, BaseRectificada, CuotaRectificada, fcSiiFechaOperacion,
			fcSiiClavRegEspOTras, fcSiiImporteTotal, DescripcionOperacion, fcSiiDetInmRefCat, fcSiiEmitidaPorTerceros, f.fcSiicsv,
			fcSiiContraparteNombreRazon, fcSiiContraparteNIFRepresentante, fcSiiContraparteNIF, fcSiiContraparteIDOtro,
			fcSiiContraparteIDType, fcSiiContraparteID, fcSiiLoteID, fcSiiestado, fcSiicodErr, fcSiidescErr)
	  SELECT f.fcSiiFacCod, f.fcSiiFacPerCod, f.fcSiiFacCtrCod,f.fcSiiFacVersion, f.fcSiiNumEnvio+1 AS fclSiiNumEnvio, f.SuministroLR,
			@versionSII, f.fcSiiCabTitNombreRazon, f.fcSiiCabTitNifRepresentante, f.fcSiiCabTitNif, 
			-- Cuando se est� reenviando como NIF no censado y ya ha sido aceptada con errores, debemos enviarla como modificaci�n, 
			-- puesto que realmente ya est� aceptada aunque sea con errores
			CASE WHEN s.yaAceptadaConErrores = 1 THEN 'A1' 
				 ELSE f.fcSiiCabTipoComunicacion END AS fcSiiCabTipoComunicacion,
			f.fcSiiEjercicio, f.fcSiiPeriodo, 
			f.fcSiiIDEmisorFacturaNIF, f.fcSiiNumSerieFacturaEmisor, f.fcSiiFechaExpedicionFacturaEmisor,
			f.fcSiiIDEmisorFacturaOrg, f.fcSiiTipoFactura, f.TipoRectificativa, f.fcSiiFraRecNumSerieFacturaEmisor, 
			f.fcSiiFraRecFechaExpedicionFacturaEmisor, f.BaseRectificada, f.CuotaRectificada, f.fcSiiFechaOperacion,
			f.fcSiiClavRegEspOTras, f.fcSiiImporteTotal, f.DescripcionOperacion, f.fcSiiDetInmRefCat, f.fcSiiEmitidaPorTerceros,
			f.fcSiicsv, 

			-- DATOS DE LA CONTRAPARTE --------------
			-- Si es simplificada (tipo factura F2 o R5), los datos de la contraparte vendr�n ya a null
			f.fcSiiContraparteNombreRazon, f.fcSiiContraparteNIFRepresentante, f.fcSiiContraparteNIF,
		    -- Si se ha rechazado ya al menos dos veces por errores de NIF rellenamos estos campos para enviarlos posteriormente
		    -- en el nodo IdOtro. "Al menos dos veces" porque si ya lo hemos reenviado por medio del nodo idOtro y nos ha dado alg�n
		    -- error, tenemos que seguir intentando reenviarlo
			-- Solamente para cuando no haya sido ya aceptada con errores, puesto que si ya lo ha sido la reenviamos de forma 
			-- habitual sin idOtro para comprobar si ya se ha censado
			NULL AS fcSiiContraparteIDOtro, 
			NULL AS fcSiiContraparteIDType, 
			NULL AS fcSiiContraparteID, 
			-----------------------------------------

			-- Dejamos a NULL estos campos para que la factura se recoja posteriormente en la creaci�n y env�o de un nuevo lote
			NULL AS fcSiiLoteID, --> f.fcSiiLoteID
			NULL AS fcSiiestado, --> f.fcSiiestado
			NULL AS fcSiicodErr, --> f.fcSiicodErr	
			NULL AS fcSiidescErr --> f.fcSiidescErr
		FROM facSII f
			  INNER JOIN @facturitas s 
				ON f.fcSiiNumSerieFacturaEmisor = s.fcSiiNumSerieFacturaEmisor 
	   -- El que nos interesa es el �ltimo n�mero de env�o, que es el actual
	   WHERE f.fcSiiNumEnvio = (SELECT MAX(fcSiiNumEnvio) 
			  				    FROM facSII f2 WHERE f.fcSiiNumSerieFacturaEmisor = f2.fcSiiNumSerieFacturaEmisor)
					  				
		-- N�mero de facturas que se van a preparar para reenv�o
		SET @cuantosReenvios = @@ROWCOUNT + @cuantosReenviosSimplificados

      -- Insertamos las l�neas de las facturas de los nuevos env�os que estamos preparando
	  INSERT INTO facSIIDesgloseFactura
			(fclSiiFacCod, fclSiiFacPerCod, fclSiiFacCtrCod, fclSiiFacVersion, fclSiiNumLinea, fclSiiNumEnvio,
			fclSiiCausaExencion, fclSiiTipoNoExenta, fclSiiEntrega, fclSiiTipoImpositivo,
			fclSiiBaseImponible, fclSiiCuotaRepercutida, fclSiiImpPorArt7_14_Otros, fclSiiImpTAIReglasLoc)
	  SELECT l.fclSiiFacCod, l.fclSiiFacPerCod, l.fclSiiFacCtrCod, l.fclSiiFacVersion, l.fclSiiNumLinea, 
			l.fclSiiNumEnvio+1 AS fclSiiNumEnvio, l.fclSiiCausaExencion, l.fclSiiTipoNoExenta, l.fclSiiEntrega, 
			l.fclSiiTipoImpositivo, l.fclSiiBaseImponible, l.fclSiiCuotaRepercutida, l.fclSiiImpPorArt7_14_Otros, 
			l.fclSiiImpTAIReglasLoc
  	    FROM facSIIDesgloseFactura l 
		  INNER JOIN facSII f 
			ON f.fcSiiFacCod = l.fclSiiFacCod AND f.fcSiiFacPerCod = l.fclSiiFacPerCod AND f.fcSiiFacCtrCod = l.fclSiiFacCtrCod 
				AND f.fcSiiFacVersion = l.fclSiiFacVersion AND f.fcSiiNumEnvio = l.fclSiiNumEnvio
		  INNER JOIN @facturitas s 
			ON f.fcSiiNumSerieFacturaEmisor = s.fcSiiNumSerieFacturaEmisor
	   -- El que nos interesa es el �ltimo n�mero de env�o-1, que es el actual (el anterior al que acabamos de insertar)
	   WHERE f.fcSiiNumEnvio = (SELECT MAX(fcSiiNumEnvio)-1
			  				    FROM facSII f2 WHERE f.fcSiiNumSerieFacturaEmisor = f2.fcSiiNumSerieFacturaEmisor)
																
	   --ROLLBACK TRANSACTION NuevoEnvio
	   COMMIT TRAN NuevoEnvio	
	END TRY
	
	BEGIN CATCH
	  SELECT @errorNumber = ERROR_NUMBER(), @errorMessage = ERROR_MESSAGE(), @cuantosReenvios = 0
	  ROLLBACK TRANSACTION NuevoEnvio
	END CATCH			

	-- select * from @facturitas
END

GO


