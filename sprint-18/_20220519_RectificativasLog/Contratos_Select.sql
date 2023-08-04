ALTER PROCEDURE [dbo].[Contratos_Select]
@ctrCod INT = NULL,
@ctrVersion SMALLINT = NULL,
@ctrComunitario INT = NULL,
@ctrTitCod INT = NULL,
@ctrZonCod VARCHAR(4) =NULL,
@ultimaVersion BIT = 0,
@soloActivos BIT = NULL, --Si es 1 devuelve los activos, si es 0 o NULL devuelve todos los registros
@tarifaDesde SMALLINT = NULL,
@tarifaHasta SMALLINT = NULL,
@servicio SMALLINT = NULL,
@ctrCodDesde INT = NULL,
@ctrCodHasta INT = NULL,
@servicioActivo BIT = NULL,
@soloComunitarios BIT = NULL, --Si es 1 devuelve sólo los contratos comunitarios, si es 0 o NULL los devuelve todos
@orden VARCHAR(100) = NULL,
@contadorID INT = NULL,
@titularNombre VARCHAR(100) = NULL,
@direccionSuministro VARCHAR(40) = NULL,
@titularDocIden VARCHAR(20) = NULL,
@soloDocIdenIncorrectos BIT = NULL,
@soloVip BIT = NULL, --Si vale 1 se seleccionan solo los contratos V.I.P., si vale 0 o null se seleccionaran todos los contratos
@ctrZonaDesde VARCHAR(4) = NULL,
@ctrZonaHasta VARCHAR(4) = NULL,
@ctrManRef VARCHAR(35) = NULL,
@ctrNuevo INT = NULL,
@soloFacturasE BIT = NULL --Si vale 1 se seleccionan solo los contratos Facturae Activa, si vale 0 o null se seleccionaran todos los contratos
AS
	SET NOCOUNT ON;

	
SELECT [ctrCod]
	  ,[ctrVersion]
	  ,[ctrFec]
	  ,[ctrFecIni]
	  ,[ctrFecReg]
	  ,[ctrUsrCod]
	  ,[ctrFecAnu]
	  ,[ctrUsrCodAnu]
	  ,[ctrTitCod]
	  ,[ctrPagNom]
	  ,[ctrPagDir]
	  ,[ctrPagPob]
	  ,[ctrPagPrv]
	  ,[ctrPagCPos]
	  ,[ctrTitNom] 
	  ,[ctrTitDir] 
	  ,[ctrTitPob] 
	  ,[ctrTitPrv]
	  ,[ctrTitCPos] 
	  ,[ctrTitTipDoc]
	  ,[ctrTitDocIden]
	  ,[ctrTitNac] 
	  ,ctrTitNacionalidad
	  ,[ctrEnvNom]
	  ,[ctrEnvDir]
	  ,[ctrEnvPob]
	  ,[ctrEnvPrv]
	  ,[ctrEnvCPos]
	  ,[ctrTlf1]
	  ,[ctrTlfRef1]
	  ,[ctrTlf2]
	  ,[ctrTlfRef2]
	  ,[ctrTlf3]
	  ,[ctrTlfRef3]
	  ,[ctrFax]
	  ,[ctrFaxRef]
	  ,[ctrEmail]
	  ,[ctrPagTipDoc]
	  ,[ctrPagDocIden]
	  ,[ctrPagNac]
	  ,ctrPagNacionalidad
	  ,[ctrCCC]
	  ,[ctrInmCod]
	  ,[ctrEmplaza]
	  ,[ctrBatFila]
	  ,[ctrBatColum]
	  ,[ctrAvisoLector]
	  ,[ctrZonCod]
	  ,[ctrBaja]
	  ,ctrRuta1
	  ,ctrRuta2
	  ,ctrRuta3
	  ,ctrRuta4
	  ,ctrRuta5
	  ,ctrRuta6
	  ,ctrObs
	  ,ctrLecturaUlt
	  ,ctrLecturaUltFec
	  ,ctrUsoCod
	  ,ctrEnvNac
	  ,ctrFecSolAlta
	  ,ctrFecSolBaja
	  ,ctrNumChapa
	  ,ctrNuevo
	  ,ctrComunitario
	  ,ctrEmpadronados
	  ,ctrCalculoComunitario
	  ,ctrRepresent
	  ,ctrValorc1
	  ,ctrValorc2
	  ,ctrValorc3
	  ,ctrValorc4
	  ,ctrTvipCodigo
	  ,ctrAcoCod
	  ,ctrSctCod
	  ,ctrIban
	  ,ctrBic
	  ,ctrManRef
	  ,ctrFace
	  ,ctrFaceMinimo
	  ,ctrFaceOficCon
	  ,ctrFaceOrgGest
	  ,ctrFaceUnitrmi
	  ,ctrFaceOrgProponente
	  ,ctrFacePortal
	  ,ctrFaceMail
	  ,ctrFaceTipoEnvio
	  ,ctrFaceAdmPublica
	  ,ctrFaceTipo
	  ,ctrNoEmision
	  ,ctrTitDocidenValidado
	  ,ctrPagDocIdenValidado
  FROM [dbo].[contratos] AS C
   LEFT JOIN inmuebles ON (@direccionSuministro IS NOT NULL OR @orden = 'direccionSuministro') AND ctrinmcod = inmcod
  WHERE 
		(ctrCod = @ctrCod OR @ctrCod IS NULL) AND
		(ctrVersion = @ctrVersion OR @ctrVersion IS NULL) AND
		(ctrTitCod = @ctrTitCod OR @ctrTitCod IS NULL) AND 
		(@ultimaVersion=0 OR @ultimaVersion IS NULL OR (ctrVersion=(SELECT MAX(ctrVersion) FROM contratos cSub where c.ctrCod = cSub.ctrcod))) AND
		(ctrZonCod = @ctrZonCod OR @ctrZonCod IS NULL) AND
		(ctrComunitario = @ctrComunitario OR @ctrComunitario IS NULL) AND
		((ctrBaja = 0) AND (ctrFecAnu IS NULL) OR @soloActivos IS NULL OR @soloActivos=0) AND
		(@ctrCodDesde IS NULL OR ctrcod >= @ctrCodDesde) AND
		(@ctrCodHasta IS NULL OR ctrcod <= @ctrCodHasta) AND
		--Tarifa y servicio
		((@tarifaDesde IS NULL AND @tarifaHasta IS NULL AND @servicio IS NULL) OR ( 
			EXISTS(SELECT ctsctrcod
				   FROM contratoServicio
				   WHERE ctsctrcod = ctrcod AND
						 (@tarifaDesde IS NULL OR ctstar >= @tarifaDesde) AND
						 (@tarifaHasta IS NULL OR ctstar <= @tarifaHasta) AND
						 (@servicio IS NULL OR ctssrv = @servicio) AND
						 (@servicioActivo IS NULL OR (@servicioActivo = 1 AND ctsfecbaj IS NULL) OR (@servicioActivo = 0 AND ctsfecbaj IS NOT NULL))
				  )
		)) AND
		(@soloComunitarios IS NULL OR @soloComunitarios = 0 OR (@soloComunitarios = 1 AND  EXISTS(SELECT ctrcod FROM contratos c2 WHERE c2.ctrComunitario=c.ctrcod))) AND
		(@contadorID IS NULL OR 
			(
				EXISTS(SELECT ctcCtr FROM ctrcon 
									 WHERE ctcCtr = ctrcod AND
										   ctcCon = @contadorID
					  )
			)
		) AND
		(@titularNombre IS NULL OR ctrTitNom LIKE '%' + @titularNombre + '%') AND
		(@direccionSuministro IS NULL OR inmdireccion LIKE '%' + @direccionSuministro + '%') AND
		(@titularDocIden IS NULL OR ctrTitDocIden LIKE '%' + @titularDocIden + '%') AND
		(@soloDocIdenIncorrectos IS NULL OR @soloDocIdenIncorrectos = 0 OR ctrTitDocIden IS NOT NULL AND 0 = CASE WHEN ctrTitTipDoc = (SELECT didcod FROM dociden WHERE diddes = 'DNI') THEN dbo.ValidarNIF(ctrTitDocIden)END 
																	  OR 0 = CASE WHEN ctrTitTipDoc = (SELECT didcod FROM dociden WHERE diddes = 'CIF') THEN dbo.ValidarCIF(ctrTitDocIden) END
																	  OR 0 = CASE WHEN ctrTitTipDoc = (SELECT didcod FROM dociden WHERE diddes = 'NIE') THEN dbo.ValidarNIE(ctrTitDocIden) END
		)
		AND (@soloVip IS NULL OR @soloVip = 0 OR (@soloVip = 1 AND ctrTvipCodigo IS NOT NULL))
		AND (@ctrZonaDesde IS NULL OR ctrzoncod >= @ctrZonaDesde) 
		AND (@ctrZonaHasta IS NULL OR ctrzoncod <= @ctrZonaHasta) 
		AND (@ctrNuevo IS NULL OR ctrNuevo = @ctrNuevo)
		AND (@ctrManRef IS NULL OR ctrManRef = @ctrManRef)
		
		AND (@soloFacturasE IS NULL OR @soloFacturasE= 0 OR ( @soloFacturasE = 1 AND ctrFace IS NOT NULL) )
		
		ORDER BY CASE @orden WHEN 'direccionSuministro' THEN 
					inmdireccion
				END,	
				CASE @orden WHEN 'nombreTitular' THEN
					ctrTitNom
				END,
					ctrcod, ctrversion
	OPTION(RECOMPILE);

GO


