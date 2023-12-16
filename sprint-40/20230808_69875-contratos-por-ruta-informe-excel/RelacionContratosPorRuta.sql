--DELETE FROM ExcelPerfil WHERE ExpCod='000/020'
--DELETE FROM ExcelConsultas WHERE ExcCod='000/020'
/*
INSERT INTO ExcelConsultas VALUES(
  '000/020'	
, 'Contratos por Ruta'	
, 'Catastro: Contratos por Ruta'
, '19'
, '[InformesExcel].[RelacionContratosPorRuta]'
, '000'
, 'CC011_RelacionContratosPorRuta: Corresponde a la selección disponible desde Catastro/Contratos por Ruta.<br>Incluye información de los emplazamientos.'
, NULL, NULL, NULL, NULL
)

INSERT INTO ExcelPerfil VALUES('000/020', 'root', 3, NULL)
INSERT INTO ExcelPerfil VALUES('000/020', 'direcc', 3, NULL)
*/

/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI></LI></NodoXML>'

EXEC [InformesExcel].[RelacionContratosPorRuta] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;

*/


CREATE PROCEDURE [InformesExcel].[RelacionContratosPorRuta]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS

SET NOCOUNT ON;   
BEGIN TRY

	--********************
	--INICIO: 2 DataTables
	-- 1: Parametros del encabezado (Anios)
	-- 2: Datos
	--********************
	DECLARE @xml AS XML = @p_params;
	DECLARE @params TABLE (zonaD VARCHAR(4) NULL, fInforme DATETIME, zonaH VARCHAR(4) NULL);

	INSERT INTO @params
	OUTPUT INSERTED.*
	SELECT zonaD = M.Item.value('zonaD[1]', 'VARCHAR(4)') 
		 , fInforme     = dbo.GetAcuamaDate()		  		
		 , zonaH = M.Item.value('zonaH[1]', 'VARCHAR(4)')
	FROM @xml.nodes('NodoXML/LI')AS M(Item);


	--********************
	--DataTable[2]:  Nombre de Grupos 
	DECLARE @zonaD AS VARCHAR(4) = '';
	DECLARE @zonaH AS VARCHAR(4) = '';
	DECLARE @Zonas AS TABLE(codZona VARCHAR(4),Grupo VARCHAR(50));
	
	SELECT @zonaD = ISNULL(zonaD, ''), @zonaH = ISNULL(zonaH, '')
	FROM @params;

	INSERT INTO @Zonas
	SELECT Z.zoncod, FORMATMESSAGE('%s-%s', Z.zoncod, Z.zondes) 
	FROM dbo.zonas AS Z
	WHERE (@zonaD = '' OR Z.zoncod>=@zonaD) 
	  AND (@zonaH = '' OR Z.zoncod<=@zonaH)

	SELECT Grupo FROM @Zonas ORDER BY codZona;

	
	--********************
	--DataTable[3]:  #RESULT
	SELECT [Ruta] = FORMATMESSAGE('%s.%s.%s.%s.%s.%s'
						  , ISNULL(ctrRuta1,'')
						  , ISNULL(ctrRuta2,'')
						  , ISNULL(ctrRuta3,'')
						  , ISNULL(ctrRuta4,'')
						  , ISNULL(ctrRuta5,'')
						  , ISNULL(ctrRuta6,''))
	, [Ruta_10D] = FORMATMESSAGE('%010i.%010i.%010i.%010i.%010i.%010i'
						  , CAST(ISNULL(ctrRuta1,'') AS INT)
						  , CAST(ISNULL(ctrRuta2,'') AS INT)
						  , CAST(ISNULL(ctrRuta3,'') AS INT)
						  , CAST(ISNULL(ctrRuta4,'') AS INT)
						  , CAST(ISNULL(ctrRuta5,'') AS INT)
						  , CAST(ISNULL(ctrRuta6,'') AS INT))
	, [Grupo] = FORMATMESSAGE('%s-%s', Z.zoncod, Z.zondes) 
	, [Contrato] = ctrcod
	, [Ctr.Versión] = ctrversion
	, [Contador] = V.conNumSerie
	, [Cod.Zona] = Z.zoncod
	, [Zona] = Z.zondes
	, [Dir. Suministro] = I.inmdireccion
	, [Titular] = ctrTitNom 
	, [Cod.Emplazamiento]= C.ctremplaza
	, [Emplazamiento] = E.emcdes
	, [Ctr.Comunitario] = C.ctrComunitario 
	INTO #RESULT
	FROM dbo.contratos AS C
	INNER JOIN dbo.inmuebles AS I
	ON I.inmcod = C.ctrinmcod
	INNER JOIN dbo.zonas AS Z
	ON Z.zoncod = C.ctrzoncod
	AND (@zonaD = '' OR Z.zoncod >= @zonaD)
	AND (@zonaH = '' OR Z.zoncod <=@zonaH)
	LEFT JOIN dbo.fContratos_ContadoresInstalados(NULL) AS V 
	ON C.ctrcod = V.ctcCtr
	LEFT JOIN dbo.emplaza AS E
	ON E.emccod = C.ctremplaza
	WHERE(C.ctrfecanu IS  NULL);


	--********************
	--DataTable[i]:  Datos por zona
	DECLARE @codZona VARCHAR(4);
	
	DECLARE CUR CURSOR FOR
	SELECT codZona FROM @Zonas ORDER BY codZona;
	OPEN CUR;
	FETCH NEXT FROM CUR INTO @codZona;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT Ruta
		, Contrato
		, [Ctr.Versión]
		, Contador
		, [Cod.Zona]
		, Zona
		, [Dir. Suministro]
		, Titular
		, [Cod.Emplazamiento]
		, Emplazamiento 
		, [Ctr.Comunitario]
		FROM #RESULT
		WHERE [Cod.Zona]=@codZona
		ORDER BY  Ruta_10D, [Dir. Suministro];

	FETCH NEXT FROM CUR INTO @codZona;
	END
	CLOSE CUR;
	DEALLOCATE CUR;

	END TRY

	BEGIN CATCH
		IF CURSOR_STATUS('GLOBAL','CUR') >= 0 
		BEGIN
			CLOSE CURSOR_NAME
			DEALLOCATE CURSOR_NAME 
		END

		SELECT  @p_errId_out = ERROR_NUMBER()
			 ,  @p_errMsg_out= ERROR_MESSAGE();
	END CATCH

	DROP TABLE  IF EXISTS #RESULT;

GO