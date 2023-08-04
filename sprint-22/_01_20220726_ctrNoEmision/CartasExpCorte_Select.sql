ALTER PROCEDURE [dbo].[CartasExpCorte_Select] 
	@numPeriodosD INT = NULL,
	@contratoD INT = NULL,
	@contratoH INT = NULL,
	@tieneFCarta BIT = NULL,
	@tieneFCierre BIT = NULL,
	@tieneFCorte BIT = NULL,
	@numeroD INT = NULL,
	@numeroH INT = NULL,
	@motcierreD INT = NULL,
	@motcierreH INT = NULL,
	@otNumeroD INT = NULL,
	@otNumeroH INT = NULL,
	@otSerieD INT = NULL,
	@otSerieH INT = NULL,
	@otSociedadD INT = NULL,
	@otSociedadH INT = NULL,
	@fCierreD DATETIME = NULL,
	@fCierreH DATETIME = NULL,
	@fCorteD DATETIME = NULL,
	@fCorteH DATETIME = NULL,
	@fOrdenTrabajoD DATETIME = NULL,
	@fOrdenTrabajoH DATETIME = NULL,
	@fRegistroD DATETIME = NULL,
	@fRegistroH DATETIME = NULL,
	@fCartaD DATETIME = NULL,
	@fCartaH DATETIME = NULL,
	@impDeudaD MONEY = NULL,
	@impDeudaH MONEY = NULL,
	@orden VARCHAR(50) = NULL,
	@xmlRepresentantesArray	TEXT = NULL

  ,  @excluirNoEmitir BIT= 1	--@excluirNoEmitir=1: Para sacar solo las cartas a los contratos con ctrNoEmision=0
AS 
	SET NOCOUNT ON;
	
	IF @xmlRepresentantesArray IS NOT NULL 
	
		BEGIN
			DECLARE @idoc INT
			--Creamos una tabla en memoria donde se van a insertar todos los valores
			DECLARE @representantesExcluidos AS TABLE(representante varchar(80)) 
			--Leemos los parámetros del XML
			SET @idoc = NULL
			EXEC sp_xml_preparedocument @idoc OUTPUT, @xmlRepresentantesArray
			--Insertamos en tabla temporal
			INSERT INTO @representantesExcluidos(representante)
			SELECT value
			FROM   OPENXML (@idoc, '/representante_List/representante', 2) WITH (value varchar(80))
			--Liberamos memoria
			EXEC  sp_xml_removedocument @idoc
		END

	
	SELECT 
		ctrcod,
		excPeriodosDeuda as facPerCod, --Solo para la emisión cuando viene de devoluciones o los expedientes de corte (Saldrán todos los periodos de deuda de ese expediente entre ;)
		NULL as perDes, --Solo para la emisión cuando viene de devoluciones
		ctrTitNom,ctrTitDir,ctrTitPob,ctrTitPrv,ctrTitDocIden,ctrTitCPos,ctrTitNac,
		ctrPagNom,ctrPagDir,ctrPagPob,ctrPagPrv,ctrPagDocIden,ctrPagCPos,ctrPagNac,
		ctrEnvCPos,ctrEnvNom,ctrEnvDir,ctrEnvPob,ctrEnvPrv,ctrEnvNac,
		inmdireccion, inmcpost,
		inmPrvCod, inmPobCod, inmMncCod, pobdes, pobcpos, prvdes,
		mncdes, mncCpos, cllCpos,
		conNumSerie,conDiametro,
		ctrRuta1,ctrRuta2,ctrRuta3,ctrRuta4,ctrRuta5,ctrRuta6,
		(CASE WHEN LEN(ctrIBAN) >= 24 AND LEN(ctrIBAN) <= 34 THEN LEFT(ctrIBAN,4) + SUBSTRING(ctrIBAN,5,4) + SUBSTRING(ctrIBAN,9,4) + REPLICATE('*',2) + REPLICATE('*',6) + RIGHT(ctrIBAN,4) ELSE  '---' END) AS iban,
		ISNULL(excFechaCarta,getDate()) as fecha,
		'0' AS importeCobrado,
		excImporteDeuda AS importeFacturado,
		excNumExp,
		excFechaCorte,
		excNumFac as periodosConDeudaPorContrato
		, ctrNoEmision
	FROM  
		CONTRATOS c
		LEFT JOIN INMUEBLES ON ctrinmcod=inmcod
		LEFT JOIN provincias on inmPrvCod = prvCod
		LEFT JOIN poblaciones on inmPobCod = pobCod and inmPrvCod = pobPrv
		LEFT JOIN municipios on inmMncCod = mncCod and inmPobCod = mncPobCod and inmPrvCod = mncPobPrv
		LEFT JOIN calles on inmcllcod = cllcod and inmmnccod = cllmnccod and inmPobCod = cllPobCod and inmPrvCod = cllPrvCod
		RIGHT JOIN EXPEDIENTESCORTE ON excCtrCod = ctrCod
		LEFT JOIN fContratos_ContadoresInstalados(NULL) v ON c.ctrcod = v.ctcCtr
	WHERE
		(ctrCod>= @contratoD OR @contratoD IS NULL)
		AND (ctrCod<= @contratoH OR @contratoH IS NULL)
		AND (excNumExp >= @numeroD or @numeroD IS NULL)
		AND (excNumExp <= @numeroH or @numeroH IS NULL)
		AND (excMotivoCierre >= @motCierreD or @motCierreD IS NULL)
		AND (excMotivoCierre <= @motCierreH or @motCierreH IS NULL)
		AND (excOtNum >= @otNumeroD or @otNumeroD IS NULL)
		AND (excOtNum <= @otNumeroH or @otNumeroH IS NULL)
		AND (excOtSerCod >= @otSerieD or @otSerieD IS NULL)
		AND (excOtSerCod <= @otSerieH or @otSerieH IS NULL)
		AND (excOtSerScd >= @otSociedadD or @otSociedadD IS NULL)
		AND (excOtSerScd <= @otSociedadH or @otSociedadH IS NULL)
		AND (excFechaCierreExp >= @fCierreD or @fCierreD IS NULL)
		AND (excFechaCierreExp <= @fCierreH or @fCierreH IS NULL)
		AND (excFechaCorte >= @fCorteD or @fCorteD IS NULL)
		AND (excFechaCorte <= @fCorteH or @fCorteH IS NULL)
		AND (excFechaGeneracionot >= @fOrdenTrabajoD or @fOrdenTrabajoD IS NULL)
		AND (excFechaGeneracionot <= @fOrdenTrabajoH or @fOrdenTrabajoH IS NULL)
		AND (excFechaReg >= @fRegistroD or @fRegistroD IS NULL)
		AND (excFechaReg <= @fRegistroH or @fRegistroH IS NULL)
		AND (excFechaCarta >= @fCartaD or @fCartaD IS NULL)
		AND (excFechaCarta <= @fCartaH or @fCartaH IS NULL)	
		AND	(@tieneFCarta IS NULL OR (@tieneFCarta = 1 AND excFechaCarta IS NOT NULL) OR (@tieneFCarta = 0 AND excFechaCarta IS NULL))
		AND (@tieneFCorte IS NULL OR (@tieneFCorte = 1 AND excFechaCorte IS NOT NULL) OR (@tieneFCorte = 0 AND excFechaCorte IS NULL))
		AND (@tieneFCierre IS NULL OR (@tieneFCierre = 1 AND excFechaCierreExp IS NOT NULL) OR (@tieneFCierre = 0 AND excFechaCierreExp IS NULL))
		AND (@impDeudaD IS NULL OR @impDeudaD <= excImporteDeuda)
		AND (@impDeudaH IS NULL OR @impDeudaH >= excImporteDeuda)
		AND (ctrVersion = (SELECT MAX(ctrVersion) FROM contratos c WHERE c.ctrcod = excCtrCod))
		AND (@numPeriodosD IS NULL OR excNumFac >= @numPeriodosD)
		--AND ISNULL(ctrNoEmision, 0) = 0 		
		--**************************************************************
		AND (@excluirNoEmitir IS NULL OR @excluirNoEmitir=0 OR C.ctrNoEmision IS NULL OR C.ctrNoEmision = 0)
		--**************************************************************
		-- Representante
		AND (@xmlRepresentantesArray is null OR (ctrRepresent not in (select representante from @representantesExcluidos)) OR ctrRepresent is null)
ORDER BY 
	CASE @orden 
	WHEN 'suministro' THEN 	(SELECT top 1 inmdireccion FROM inmuebles INNER JOIN contratos cSum ON ctrCod=cSum.ctrcod AND ctrinmcod=inmcod) 
	WHEN 'contrato' THEN CAST(REPLICATE('0',10-LEN(CAST(ctrCod AS VARCHAR))) + CAST(ctrCod AS VARCHAR) AS VARCHAR)
	ELSE          
		 REPLICATE('0',10-LEN(ISNULL(ctrRuta1,''))) + ISNULL(ctrRuta1,'') 
		+REPLICATE('0',10-LEN(ISNULL(ctrRuta2,''))) + ISNULL(ctrRuta2,'')
		+REPLICATE('0',10-LEN(ISNULL(ctrRuta3,''))) + ISNULL(ctrRuta3,'')
		+REPLICATE('0',10-LEN(ISNULL(ctrRuta4,''))) + ISNULL(ctrRuta4,'')
		+REPLICATE('0',10-LEN(ISNULL(ctrRuta5,''))) + ISNULL(ctrRuta5,'')
		+REPLICATE('0',10-LEN(ISNULL(ctrRuta6,''))) + ISNULL(ctrRuta6,'')
	END
GO


