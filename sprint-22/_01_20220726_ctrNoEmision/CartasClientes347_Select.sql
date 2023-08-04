/*
DECLARE @totalFacturaD INT =1000;
DECLARE @fechaFacturaD DATETIME = '20220101';
DECLARE @fechaFacturaH DATETIME = '20220119';

EXEC dbo.CartasClientes347_Select @totalFacturaD, @fechaFacturaD, @fechaFacturaH;
*/

ALTER PROCEDURE [dbo].[CartasClientes347_Select]
	@totalFacturaD INT = NULL,
	@fechaFacturaD DATETIME = NULL,
	@fechaFacturaH DATETIME = NULL,
	@xmlRepresentantesArray	TEXT = NULL
		
  ,  @excluirNoEmitir BIT= 1	--@excluirNoEmitir=1: Para sacar solo las cartas a los contratos con ctrNoEmision=0
AS 


	--**********************************************
	--2021-03-02: Hemos cambiado este informe para recuperar los totales conforme lo hace el informe "347 VENTAS"
	--**********************************************
	--Sincronizar los cambios en: 
	--347 VENTAS--------------------[ReportingServices].Facturas_Ventas347
	--347 VENTAS + Generar Carta----[dbo].CartasClientes347_Select
	--GENERAR MODELO 347------------[dbo}.Facturas_Select_347	
	--********************************************** 
	SET NOCOUNT ON;
	
	
	BEGIN TRY

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

		DECLARE @ahora DATETIME = dbo.GetAcuamaDate(); 
		DECLARE @fechaD DATETIME = @fechaFacturaD;
		DECLARE @fechaH DATETIME = @fechaFacturaH;
	
		DECLARE @explotacion VARCHAR(200)= ''; 
		DECLARE @listadoServicioExcluidos VARCHAR(50) = NULL;
		DECLARE @fechaH_ant DATE = IIF(@fechaH IS NULL, NULL, DATEADD(YEAR, -1, @fechaH))
	
		SELECT @explotacion= P.pgsValor 
		FROM parametros AS P
		WHERE P.pgsclave LIKE 'EXPLOTACION';

		--BIAR: Aunque se filtran 12 meses, recupera las facturas de 13 meses
		IF(@fechaH IS NOT NULL AND @explotacion = 'BIAR')
			SET @fechaH = DATEADD(MONTH, +1, @fechaH);

		SET @listadoServicioExcluidos = CASE @explotacion 
										WHEN 'Soria' THEN '3, 99, 100, 103, 104, 105, 106, 107'
										ELSE NULL END; 					

		--******************************************																			
		--[00]#FACS: Filtramos las facturas por fechas
		SELECT F.facCod
		, F.facPerCod
		, F.facCtrCod
		, F.facVersion
		, F.facCtrVersion
		, F.facFecha
		, C.ctrIban	
		, C.ctrTitCod
		, C.ctrTitDocIden, C.ctrTitNom, C.ctrTitDir, C.ctrTitNac, C.ctrTitPob, C.ctrTitPrv, C.ctrTitCPos
		, C.ctrPagDocIden, C.ctrPagNom, C.ctrPagDir, C.ctrPagNac, C.ctrPagPob, C.ctrPagPrv, C.ctrPagCPos
		
		, explotacion = @explotacion
		, ident		  =	CASE   WHEN C.ctrPagDocIden IS NULL					THEN 'titular'			--!hay pagador								   => titular
							   WHEN C.ctrPagDocIden =  ''					THEN 'titular'			--!hay pagador								   => titular
							   WHEN @explotacion <> 'AVG'					THEN 'pagador'			-- hay pagador && !AVG						   => pagador	
							   WHEN F.facPerCod NOT IN ('000013', '000015') THEN 'pagador'			-- hay pagador && AVG  && !periodos especiales => pagador 
							   ELSE 'titular' END 													-- hay pagador && AVG  &&  periodos especiales => titular
		
		, docIdent	 =	CASE   WHEN C.ctrPagDocIden IS NULL					THEN ctrTitDocIden		--!hay pagador								   => titular
							   WHEN C.ctrPagDocIden =  ''					THEN ctrTitDocIden		--!hay pagador								   => titular
							   WHEN @explotacion <> 'AVG'					THEN ctrPagDocIden		-- hay pagador && !AVG						   => pagador	
							   WHEN F.facPerCod NOT IN ('000013', '000015') THEN ctrPagDocIden		-- hay pagador && AVG  && !periodos especiales => pagador 
							   ELSE ctrTitDocIden END 	
		
		INTO #FACS
		FROM dbo.facturas AS F
		INNER JOIN dbo.contratos AS C
		ON  C.ctrCod = F.facCtrcod
		AND C.ctrVersion = F.facCtrVersion
		AND C.ctrTitDocIden IS NOT NULL 
		AND C.ctrTitDocIden<>''
		--AND (C.ctrNoEmision IS NULL OR C.ctrNoEmision=0)
		--**************************************************************
		AND (@excluirNoEmitir IS NULL OR @excluirNoEmitir=0 OR C.ctrNoEmision IS NULL OR C.ctrNoEmision = 0)
		--**************************************************************
		AND (F.facNumero IS NOT NULL) -- Que no sean preFactura
		AND (@fechaD IS NULL OR F.facFecha >= @fechaD)
		AND (@fechaH IS NULL OR F.facFecha <= @fechaH)
		-- Representante
		AND (@xmlRepresentantesArray is null OR (ctrRepresent not in (select representante from @representantesExcluidos)) OR ctrRepresent is null)
		AND (F.facFechaRectif IS NULL OR (@fechaH IS NOT NULL AND F.facFechaRectif > @fechaH)); 

		--******************************************	
		--[01]#FACT: Totales por tipo impositivo y servicios
		SELECT F.facCod
		, F.facPerCod
		, F.facCtrCod
		, F.facVersion
		, ftfImporte = SUM(FN.ftfImporte)
		INTO #FACT
		FROM #FACS AS F
		INNER JOIN dbo.fFacturas_TotalFacturado(@fechaH, 1, @listadoServicioExcluidos) AS FN
		ON F.facCod=FN.ftfFacCod
		AND F.facPerCod = FN.ftfFacPerCod
		AND F.facVersion = FN.ftfFacVersion
		AND F.facCtrcod = FN.ftfFacCtrCod
		WHERE FN.ftfImpuesto > 0
		GROUP BY F.facCod
				, F.facPerCod
				, F.facCtrCod
				, F.facVersion;
																				
		--[02]#RECTIF: De las facturas seleccionadas, buscamos las facturas rectificadas el año anterior
		SELECT F0.facCod
		, F0.facPerCod
		, F0.facCtrCod
		, F0.facVersion
		, F0.facFecha
		, F0.facCtrVersion
		, docIdent = MAX(F.docIdent)
		, ident = MAX(F.ident)
		, importeRectificativa			= SUM(FL.fclTotal)
		, fechaRectificativa			= F0.facFechaRectif 
		--RN=1 para quedarnos solo con la ultima rectificativa
		, ROW_NUMBER() OVER (PARTITION BY F0.facCod, F0.facPerCod, F0.facCtrCod ORDER BY F0.facVersion DESC) AS RN
		INTO #RECTIF
		FROM #FACS AS F
		INNER JOIN dbo.facturas AS F0
		ON  F0.facCod = F.facCod
		AND F0.facPerCod = F.facPerCod
		AND F0.facCtrCod = F.facCtrCod
		INNER JOIN dbo.faclin AS FL
		ON  FL.fclFacCtrCod = F0.facCtrCod 
		AND FL.fclFacCod = F0.facCod 
		AND FL.fclFacPerCod = F0.facPerCod 
		AND FL.fclFacVersion = F0.facVersion
		AND F0.facNumero IS NOT NULL
		AND FL.fclImpImpuesto > 0
		AND (@fechaH_ant IS NULL OR F0.facFecha <= @fechaH_ant)
		AND (@fechaH IS NULL OR (F0.facFechaRectif > @fechaH_ant AND F0.facFechaRectif <= @fechaH))
		LEFT JOIN dbo.split(@listadoServicioExcluidos, ',') AS XS
		ON FL.fclTrfSvCod= XS.value
		WHERE (XS.value IS NULL)
		GROUP BY F0.facCod
		, F0.facPerCod
		, F0.facCtrCod
		, F0.facVersion
		, F0.facCtrVersion
		, F0.facSerScdCod
		, F0.facSerCod
		, F0.facFecha
		, F0.facFechaRectif;
		
		--******************************************		
		--[11]#RESULT: Totalizamos las facturas
		SELECT F.facCod
		, F.facPerCod
		, F.facCtrCod
		, F.facVersion
		, F.facCtrVersion
		, F.facFecha
		, facTotal = ISNULL(FT.ftfImporte, 0)
		, F.docIdent
		, F.ident
		, tipo = 'factura'
		INTO #RESULT
		FROM #FACS AS F
		LEFT JOIN #FACT AS FT
		ON F.facCod = FT.facCod 
		AND F.facPerCod = FT.facPerCod
		AND F.facCtrCod = FT.facCtrCod
		AND F.facVersion = FT.facVersion;

		--[12]#RESULT: Nos quedamos con las rectificadas por el docIdent y titular
		INSERT INTO #RESULT
		SELECT F0.facCod
		, F0.facPerCod
		, F0.facCtrCod
		, F0.facVersion
		, F0.facCtrVersion
		, F0.facFecha
		, facTotal = ISNULL(F0.importeRectificativa, 0) * -1
		, F0.docIdent
		, F0.ident
		, tipo = 'rectif'
		FROM #RECTIF AS F0;

		--******************************************		
		--[21]#TOTAL: Totalizamos por docIdent y nos quedamos con la factura mas reciente para mostrar los datos del contrato
		WITH TOTAL AS ( 
		SELECT R.facCod
			 , R.facPerCod
			 , R.facCtrCod
			 , R.facVersion
			 , R.facCtrVersion
			 , R.facFecha
			 , R.docIdent
			 , R.ident
			 , R.tipo
			 , totalCliente = SUM(ISNULL(R.facTotal, 0)) OVER (PARTITION BY R.docIdent)
			 --Para quedarnos con los datos de identidad en la factura mas reciente
			 , RN_facFecha = ROW_NUMBER() OVER(PARTITION BY R.docIdent ORDER BY R.facFecha DESC, R.facPerCod DESC, R.facCtrCod DESC, R.facCod DESC, R.facVersion DESC)
		FROM #RESULT AS R)

		SELECT T.docIdent
		, T.ident
		, T.totalCliente
		, identDoc = T.docIdent
		, identNombre		= IIF(F.ident = 'titular', F.ctrTitNom, F.ctrPagNom)
		, identDireccion	= IIF(F.ident = 'titular', F.ctrTitDir, F.ctrPagDir)
		, identNac = IIF(F.ident = 'titular', F.ctrTitNac, F.ctrPagNac)
		, identPob = IIF(F.ident = 'titular', F.ctrTitPob, F.ctrPagPob)
		, identPrv = IIF(F.ident = 'titular', F.ctrTitPrv, F.ctrPagPrv)
		, identCPos= IIF(F.ident = 'titular', F.ctrTitCPos, F.ctrPagCPos)	
		, titCod = F.ctrTitCod
		, F.ctrIban
		INTO #TOTAL
		FROM TOTAL AS T
		INNER JOIN #FACS AS F
		ON T.RN_facFecha=1
		AND F.facCod = T.facCod
		AND F.facPerCod = T.facPerCod
		AND F.facCtrCod = T.facCtrCod
		AND F.facVersion = T.facVersion;
		
		--SELECT * FROM #TOTAL WHERE docIdent='03103900G';
		--THROW 51000, 'The record does not exist.', 1;  

		--******************************************	
		--**************  S A L I D A  *************	
		--******************************************
		
		SELECT ctrCod = T.titCod 
		--Solo para la emisión cuando viene de devoluciones
		, facPerCod = NULL, perDes = NULL
		--*************************************************
		, ctrTitNom = T.identNombre
		, ctrTitDir = T.identDireccion
		, ctrTitPob = T.identPob
		, ctrTitPrv = T.identPrv
		, ctrTitDocIden = T.docIdent
		, ctrTitCPos = T.identCPos
		, ctrTitNac = T.identNac 
		--*************************************************
		, ctrPagNom = NULL, ctrPagDir = NULL, ctrPagPob = NULL,  ctrPagPrv = NULL, ctrPagDocIden = NULL, ctrPagCPos = NULL, ctrPagNac = NULL
		, ctrEnvCPos = NULL	, ctrEnvNom = NULL, ctrEnvDir = NULL, ctrEnvPob = NULL, ctrEnvPrv = NULL, ctrEnvNac = NULL
		--*************************************************
		, inmdireccion = T.identDireccion
		--*************************************************
		, inmPrvCod = NULL, inmPobCod = NULL, inmMncCod = NULL
		, pobdes = NULL, pobcpos = NULL
		, prvdes = NULL
		, mncdes = NULL, mnccpos = NULL
		, cllcpos = NULL
		, conNumSerie = NULL, conDiametro = NULL
		, ctrRuta1 = NULL, ctrRuta2 = NULL, ctrRuta3 = NULL, ctrRuta4 = NULL, ctrRuta5 = NULL, ctrRuta6 = NULL
		, cllcpos = NULL, cllcpos = NULL
		--*************************************************
		, iban = (CASE WHEN LEN(T.ctrIBAN) BETWEEN 24 AND 34 
		   THEN LEFT(T.ctrIBAN,4) + SUBSTRING(T.ctrIBAN,5,4) + SUBSTRING(T.ctrIBAN,9,4) + REPLICATE('*',2) + REPLICATE('*',6) + RIGHT(T.ctrIBAN,4) 
		   ELSE  '---' END)
		, fecha = @ahora
		--*************************************************
		, importeCobrado = NULL
		--*************************************************
		, importeFacturado = totalCliente
		--*************************************************
		, excNumExp = NULL, excFechaCorte = NULL
		, periodosConDeudaPorContrato = NULL
		--*************************************************
		, docIdent
		, ident
		FROM #TOTAL AS T
		WHERE T.totalCliente > @totalFacturaD
		ORDER BY T.docIdent;	
		

		
	END TRY
	BEGIN CATCH
	
	END CATCH

	IF OBJECT_ID('tempdb.dbo.#FACS', 'U') IS NOT NULL 
	DROP TABLE #FACS;

	IF OBJECT_ID('tempdb.dbo.#FACT', 'U') IS NOT NULL 
	DROP TABLE #FACT;

	IF OBJECT_ID('tempdb.dbo.#RECTIF', 'U') IS NOT NULL 
	DROP TABLE #RECTIF;

	IF OBJECT_ID('tempdb.dbo.#RESULT', 'U') IS NOT NULL 
	DROP TABLE #RESULT;

	IF OBJECT_ID('tempdb.dbo.#TOTAL', 'U') IS NOT NULL 
	DROP TABLE #TOTAL;

GO


