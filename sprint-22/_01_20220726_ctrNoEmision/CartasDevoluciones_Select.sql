ALTER PROCEDURE [dbo].[CartasDevoluciones_Select] 
	@listaDevoluciones NTEXT = NULL,
	@orden VARCHAR(50) = NULL, --De momento no se utilizara
	@xmlRepresentantesArray	TEXT = NULL
 ,  @excluirNoEmitir BIT= 1	--@excluirNoEmitir=1: Para sacar solo las cartas a los contratos con ctrNoEmision=0
AS 
	SET NOCOUNT ON;

	DECLARE @idoc INT
	EXEC sp_xml_preparedocument @idoc OUTPUT, @listaDevoluciones


	IF @xmlRepresentantesArray IS NOT NULL 
	
		BEGIN
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
	CodigoContrato as ctrCod,
	CodigoPeriodo as facPerCod,
	perDes,
	ctrTitNom,ctrTitDir,ctrTitPob,ctrTitPrv,ctrTitDocIden,ctrTitCPos,ctrTitNac,
	ctrPagNom,ctrPagDir,ctrPagPob,ctrPagPrv,ctrPagDocIden,ctrPagCPos,ctrPagNac,
    ctrEnvCPos,ctrEnvNom,ctrEnvDir,ctrEnvPob,ctrEnvPrv,ctrEnvNac,
	DireccionSuministro as inmDireccion, inmcpost,
	inmPrvCod, inmPobCod, inmMncCod, pobdes, pobcpos, prvdes, 
	mncdes, mncCpos, cllCpos,
	conNumSerie,conDiametro,
	ctrRuta1,ctrRuta2,ctrRuta3,ctrRuta4,ctrRuta5,ctrRuta6,
	(CASE WHEN LEN(ctrIBAN) >= 24 AND LEN(ctrIBAN) <= 34 THEN LEFT(ctrIBAN,4) + SUBSTRING(ctrIBAN,5,4) + SUBSTRING(ctrIBAN,9,4) + REPLICATE('*',2) + REPLICATE('*',6) + RIGHT(ctrIBAN,4) ELSE  '---' END) AS iban,
	getDate() as fecha,
	Importe AS importeCobrado,
	'0' AS importeFacturado,
	NULL as excNumExp,
	NULL AS excFechaCorte,
	'1' as periodosConDeudaPorContrato -- Siempre va a ver 1 porque por cada (contrato,periodo) una carta
FROM  
	OPENXML (@idoc, '/cDevolucionesBO_List/cDevolucionesBO',2) WITH
	(
		CodigoContrato int,
		CodigoPeriodo varchar(6),
		Fecha nvarchar(50),
		NombreCliente varchar(40),
		DireccionSuministro varchar(60),
		Importe decimal(16,2)
	)
	LEFT JOIN contratos c ON CodigoContrato=C.ctrcod AND (ctrVersion = (SELECT MAX(ctrVersion) FROM contratos c1 WHERE c1.ctrcod = CodigoContrato))
	LEFT JOIN inmuebles ON C.ctrinmcod=inmcod
	LEFT JOIN provincias on inmPrvCod = prvCod
	LEFT JOIN poblaciones on inmPobCod = pobCod and inmPrvCod = pobPrv
	LEFT JOIN municipios on inmMncCod = mncCod and inmPobCod = mncPobCod and inmPrvCod = mncPobPrv
	LEFT JOIN calles on inmcllcod = cllcod and inmmnccod = cllmnccod and inmPobCod = cllPobCod and inmPrvCod = cllPrvCod
	LEFT JOIN fContratos_ContadoresInstalados(NULL) v ON c.ctrcod = v.ctcCtr
	LEFT JOIN periodos ON CodigoPeriodo = percod
WHERE
	--ISNULL(ctrNoEmision, 0) = 0 	
	-- Representante
	--AND
	--**************************************************************
	(@excluirNoEmitir IS NULL OR @excluirNoEmitir=0 OR C.ctrNoEmision IS NULL OR C.ctrNoEmision = 0) AND
	--**************************************************************

    (@xmlRepresentantesArray is null OR (ctrRepresent not in (select representante from @representantesExcluidos)) OR ctrRepresent is null)
ORDER BY
CASE @orden 
	WHEN 'suministro' THEN (SELECT top 1 inmdireccion FROM inmuebles INNER JOIN contratos cSum ON ctrCod=cSum.ctrcod AND ctrinmcod=inmcod) 
	WHEN 'contrato' THEN CAST(REPLICATE('0',10-LEN(CAST(ctrCod AS VARCHAR))) + CAST(ctrCod AS VARCHAR) AS VARCHAR)
	ELSE          
		 REPLICATE('0',10-LEN(ISNULL(ctrRuta1,''))) + ISNULL(ctrRuta1,'') 
		+REPLICATE('0',10-LEN(ISNULL(ctrRuta2,''))) + ISNULL(ctrRuta2,'')
		+REPLICATE('0',10-LEN(ISNULL(ctrRuta3,''))) + ISNULL(ctrRuta3,'')
		+REPLICATE('0',10-LEN(ISNULL(ctrRuta4,''))) + ISNULL(ctrRuta4,'')
		+REPLICATE('0',10-LEN(ISNULL(ctrRuta5,''))) + ISNULL(ctrRuta5,'')
		+REPLICATE('0',10-LEN(ISNULL(ctrRuta6,''))) + ISNULL(ctrRuta6,'')
	END
	
--Liberamos memoria
EXEC  sp_xml_removedocument @idoc
GO


