
/*
****** CONFIGURACION ******
INSERT INTO dbo.ExcelConsultas
VALUES ('000/800',	'Cobros Validar Importes', 'Cobros: Validar Importes', 1, '[InformesExcel].[CobrosImporteLineasxDesglose]', '001', 'Para identificar los cobros en los que hay diferencias entre la cabecera y las lineas o el desglose');

INSERT INTO ExcelPerfil
VALUES('000/800', 'root', 5, NULL)

INSERT INTO ExcelPerfil
VALUES('000/800', 'jefeExp', 5, NULL)

INSERT INTO ExcelPerfil
VALUES('000/800', 'jefAdmon', 5, NULL)

--DELETE FROM ExcelPerfil WHERE ExPCod= '000/800'


DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI><FecDesde>20210101</FecDesde><FecHasta>20210731</FecHasta></LI></NodoXML>'

EXEC [InformesExcel].[CobrosImporteLineasxDesglose] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;

*/

ALTER PROCEDURE [InformesExcel].[CobrosImporteLineasxDesglose]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS

	--**********
	--PARAMETROS: 
	--[1]FecDesde: fecha dede
	--[2]FecHasta: fecha hasta
	--**********

	SET NOCOUNT ON;   
	BEGIN TRY
	
	--********************
	--INICIO: 2 DataTables
	-- 1: Parametros del encabezado (FecDesde, FecHasta)
	-- 2: Datos
	--********************

	--DataTable[1]:  Parametros
	DECLARE @xml AS XML = @p_params;
	DECLARE @params TABLE (FecDesde DATE NULL, fInforme DATETIME, FecHasta DATE NULL);

	INSERT INTO @params
	SELECT  FecDesde = CASE WHEN M.Item.value('FecDesde[1]', 'DATE') = '19000101' THEN NULL 
						   ELSE M.Item.value('FecDesde[1]', 'DATE') END
		  , fInforme     = GETDATE()
		  , FecHasta = CASE WHEN M.Item.value('FecHasta[1]', 'DATE') = '19000101' THEN NULL 
						   ELSE M.Item.value('FecHasta[1]', 'DATE') END
	FROM @xml.nodes('NodoXML/LI')AS M(Item);
	
	UPDATE @params SET FecHasta = DATEADD(DAY, 1, FecHasta)
	OUTPUT DELETED.*;
	
	--********************
	--VALIDAR PARAMETROS
	--Fechas obligatorias

	IF EXISTS(SELECT 1 FROM @params WHERE FecDesde IS NULL OR FecHasta IS NULL)
		THROW 50001 , 'La fecha ''desde'' y ''hasta'' son requeridos.', 1;
	IF EXISTS(SELECT 1 FROM @params WHERE FecDesde>FecHasta)
		THROW 50002 , 'La fecha ''hasta'' debe ser posterior a la fecha ''desde''.', 1;
	
	
	--********************
	--DataTable[3]:  Datos Importes desglose de cobros por lineas
	WITH COBS AS(
	SELECT C.cobScd
	, C.cobPpag
	, C.cobNum
	, CL.cblLin 
	, MAX(C.cobImporte) AS cobImporte
	, MAX(CL.cblImporte) AS cblImporte
	, SUM(CLD.cldImporte) AS cldImporte
	FROM dbo.cobros AS C
	INNER JOIN dbo.cobLin AS CL
	ON CL.cblPpag = C.cobPpag 
	AND CL.cblNum = C.cobNum 
	AND CL.cblScd = C.cobScd
	INNER JOIN dbo.cobLinDes AS CLD 
	ON  CLD.cldCblPpag = CL.cblPpag
	AND CLD.cldCblNum = CL.cblNum 
	AND CLD.cldCblScd = CL.cblScd 
	AND CLD.cldCblLin = CL.cblLin
	INNER JOIN @params AS P 
	ON  (P.FecDesde IS NULL OR cobFec >= P.FecDesde) 
	AND (P.FecHasta IS NULL OR cobFec <= P.FecHasta)
	GROUP BY C.cobScd, C.cobPpag, C.cobNum, CL.cblLin
	
	), TOTALES AS(
	
	SELECT * 
	--La sumatoria de los coblin debe ser igual al cobro cobImporte=ROUND(_cobImporte, 2)
	, SUM(cblImporte)  OVER (PARTITION BY C.cobScd, C.cobPpag, C.cobNum) AS  [_cobImporte]
	, COUNT(cblLin)  OVER (PARTITION BY C.cobScd, C.cobPpag, C.cobNum) AS numLinCobros
	--La sumatoria de los coblindes debe ser igual al coblin ROUND(cblImporte, 2) = ROUND(_cldImporte, 2)
	, SUM(cldImporte)  OVER (PARTITION BY C.cobScd, C.cobPpag, C.cobNum, cblLin) AS  [_cldImporte]
	FROM COBS AS C
	)

	
	SELECT Sociedad = cobScd
	, [Pto.Pago] = cobPpag
	, [Num.Cobro] = cobNum	
	, [Num.Líneas Cobro]= numLinCobros
	, [Línea Cobro] = cblLin
	, [Imp.Cobro] = cobImporte	
	, [SUM(Líneas Cobro)] = ROUND(_cobImporte, 2)
	, [DIF Cobros-Líneas] = cobImporte-ROUND(_cobImporte, 2)
	, [Imp.Líneas Cobro] = ROUND(cblImporte, 2)
	, [SUM(Desglose Líneas Cobro)] = ROUND(_cldImporte, 2)
	, [DIF.Líneas-Desglose] = ROUND(cblImporte, 2) - ROUND(_cldImporte, 2)
	FROM TOTALES AS C
	WHERE NOT(cobImporte=ROUND(_cobImporte, 2) AND ROUND(cblImporte, 2)=ROUND(_cldImporte, 2))
	ORDER BY C.cobScd
	, C.cobPpag
	, C.cobNum
	, C.cblLin 
	END TRY

	BEGIN CATCH
		SELECT  @p_errId_out = ERROR_NUMBER()
			 ,  @p_errMsg_out= ERROR_MESSAGE();
	END CATCH



GO

