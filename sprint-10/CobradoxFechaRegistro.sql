/*
INSERT INTO dbo.ExcelConsultas
VALUES ('000/710',	'Cobros por Fecha Registro', 'Listado de cobros por fecha de registro', 1, '[InformesExcel].[CobradoxFechaRegistro]', '001', 'Listado detallado de los cobros por factura según la fecha de registro');

INSERT INTO ExcelPerfil
VALUES('000/710', 'root', 5, NULL)

INSERT INTO ExcelPerfil
VALUES('000/710', 'jefeExp', 5, NULL)

INSERT INTO ExcelPerfil
VALUES('000/710', 'jefAdmon', 5, NULL)

INSERT INTO ExcelPerfil
VALUES('000/710', 'comerc', 5, NULL)
*/


/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_error_out INT;
DECLARE @p_errMsg_out VARCHAR;

SET @p_params= '<NodoXML><LI><FecDesde>20211001</FecDesde><FecHasta>20211031</FecHasta></LI></NodoXML>';


EXEC [InformesExcel].[CobradoxFechaRegistro] @p_params, @p_error_out, @p_errMsg_out;
*/


CREATE PROCEDURE [InformesExcel].[CobradoxFechaRegistro]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT

AS
SET NOCOUNT ON;   
BEGIN TRY	
	
	--********************
	--INICIO: 2 DataTables
	-- 1: Paramentros del encabezado
	-- 2: Grupos
	-- 3: Detalle por facturas
	-- 4: Detalle por periodos 
	--********************

	--********************
	--DataTable[1]:  Parametros
	DECLARE @xml AS XML = @p_params;
	DECLARE @params TABLE (FecDesde DATE NULL, fInforme DATETIME, FecHasta DATE NULL);

	INSERT INTO @params
	OUTPUT INSERTED.*
	SELECT  CASE WHEN M.Item.value('FecDesde[1]', 'DATE') = '19000101' THEN '19010101'
			ELSE M.Item.value('FecDesde[1]', 'DATE') END
			, GETDATE() AS fInforme
			, CASE WHEN M.Item.value('FecHasta[1]', 'DATE') = '19000101' THEN GETDATE() 
					ELSE M.Item.value('FecHasta[1]', 'DATE') END
	FROM @xml.nodes('NodoXML/LI')AS M(Item);

	--Para garantizar que el rango de fechas cubre el día completo
	UPDATE @params SET FecHasta = DATEADD(DAY, 1, FecHasta);
		
	WITH C AS(
	SELECT  C.cobNum
	, C.cobScd
	, C.cobPpag
	, C.cobFecReg
	, C.cobctr
	, CL.cblPer
	, CL.cblFacCod
	, CL.cblFacVersion
	, E.ppebca
	, E.ppedes
	, C.cobOrigen
	, CL.cblImporte
	, [Sum.cldImporte] = SUM(cldImporte) OVER (PARTITION BY  C.cobScd, C.cobPpag, C.cobNum, CL.cblLin)
	, RN= ROW_NUMBER() OVER (PARTITION BY  C.cobScd, C.cobPpag, C.cobNum, CL.cblLin ORDER BY CLD.cldFacLin)
	FROM dbo.cobros AS C
	INNER JOIN @params AS PP
	ON  C.cobfecreg>=PP.FecDesde 
	AND C.cobfecreg<PP.FecHasta
	LEFT JOIN dbo.coblin AS CL
	ON CL.cblScd = C.cobScd
	AND CL.cblPpag = C.cobPpag
	AND CL.cblNum = C.cobNum
	LEFT JOIN dbo.cobLinDes AS CLD
	ON CLD.cldCblScd = CL.cblScd
	AND CLD.cldCblPpag = CL.cblPpag
	AND CLD.cldCblNum = CL.cblNum
	AND CLD.cldCblLin = CL.cblLin
	INNER JOIN ppagos AS P
	ON P.ppagcod = C.cobppag
	INNER JOIN ppentidades AS E 
	ON E.ppecod = P.ppagppcppeCod)

	SELECT * 
	, [Sum.cldImporte2] = ROUND([Sum.cldImporte], 2)
	, ENTIDAD = IIF(ppebca=1, 'BCO', 'OFI')
	, TIPO	  =	IIF(cblImporte>0, 'COB', 'DEV')
	INTO #RESULT
	FROM C
	WHERE RN=1;


	SELECT [Cobro Num.]  = cobNum 
		 , [Sociedad]	 = cobScd
		 , [Pto.Pago]	 = cobPpag
		 , [Cobro F.Reg.]= cobFecReg
		 , [Cobro Origen]= cobOrigen
		 , [Contrato]	 = cobCtr
		 , [Periodo]	 = cblPer
		 , [Fac.Cod]	 = cblFacCod
		 , [Fac.Version] = cblFacVersion
		 , ENTIDAD
		 , [Entidad Cod.]= ppebca
		 , [Entidad Nom.]= UPPER(ppedes)
		 , TIPO
		 , [Importe CobLin]		= [cblImporte]
		 , [Importe CobLinDes]	= [Sum.cldImporte2]
		 , [Importe Dif.]		= [cblImporte]- [Sum.cldImporte2] 
		 , [COB_BCO]= IIF(ENTIDAD = 'BCO' AND TIPO='COB',  [Sum.cldImporte2], NULL)
		 , [COB_OFI]= IIF(ENTIDAD = 'OFI' AND TIPO='COB',  [Sum.cldImporte2], NULL)
		 , [DEV_BCO]= IIF(ENTIDAD = 'BCO' AND TIPO='DEV',  [Sum.cldImporte2], NULL)
		 , [DEV_OFI]= IIF(ENTIDAD = 'OFI' AND TIPO='DEV',  [Sum.cldImporte2], NULL)	 
	FROM #RESULT

	UNION ALL
	SELECT [Cobro Num.]  = NULL
		 , [Sociedad]	 = NULL
		 , [Pto.Pago]	 = NULL
		 , [Cobro Origen]= NULL
		 , [Cobro F.Reg.]= NULL
		 , [Contrato]	 = NULL
		 , [Periodo]	 = NULL
		 , [Fac.Cod]	 = NULL
		 , [Fac.Version] = NULL
		 , ENTIDAD	= NULL
		 , [Entidad Cod.]= NULL
		 , [Entidad Nom.]= NULL
		 , TIPO		= NULL
		 , [Importe CobLin]	   = NULL
		 , [Importe CobLinDes] = NULL
		 , [Importe Dif.]		= NULL
		 , [COB_BCO]= SUM([Sum.cldImporte2] * IIF(ENTIDAD = 'BCO' AND TIPO='COB', 1, 0))
		 , [COB_OFI]= SUM([Sum.cldImporte2] * IIF(ENTIDAD = 'OFI' AND TIPO='COB', 1, 0))
		 , [DEV_BCO]= SUM([Sum.cldImporte2] * IIF(ENTIDAD = 'BCO' AND TIPO='DEV', 1, 0))
		 , [DEV_OFI]= SUM([Sum.cldImporte2] * IIF(ENTIDAD = 'OFI' AND TIPO='DEV', 1, 0))
	FROM #RESULT;
END TRY

BEGIN CATCH
END CATCH



IF OBJECT_ID('tempdb.dbo.#RESULT', 'U') IS NOT NULL 
DROP TABLE #RESULT;

GO