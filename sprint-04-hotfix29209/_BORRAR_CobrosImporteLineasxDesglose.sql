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

SET @p_params= '<NodoXML><LI><FecDesde>20201201</FecDesde><FecHasta>20210809</FecHasta></LI></NodoXML>'

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
	WITH DESGLOSE AS(
	SELECT C.cobScd
	, C.cobPpag
	, C.cobNum
	, C.cobctr
	, C.cobImporte
	, C.cobFecReg
	, C.cobOrigen
	, C.cobUsr
	, CL.cblLin 
	, CL.cblPer
	, CL.cblImporte
	, CLD.cldImporte
	--RN=1: Cabecera de la linea del cobro
	, RN = ROW_NUMBER() OVER (PARTITION BY C.cobScd, C.cobPpag,  C.cobNum, CL.cblLin ORDER BY CLD.cldFacLin ASC)
	, cldTotal = SUM(CLD.cldImporte) OVER (PARTITION BY C.cobScd, C.cobPpag,  C.cobNum, CL.cblLin) 
	FROM dbo.cobros AS C
	LEFT JOIN dbo.cobLin AS CL
	ON CL.cblPpag = C.cobPpag 
	AND CL.cblNum = C.cobNum 
	AND CL.cblScd = C.cobScd
	LEFT JOIN dbo.cobLinDes AS CLD 
	ON  CLD.cldCblPpag = CL.cblPpag
	AND CLD.cldCblNum = CL.cblNum 
	AND CLD.cldCblScd = CL.cblScd 
	AND CLD.cldCblLin = CL.cblLin
	INNER JOIN @params AS P 
	ON  (P.FecDesde IS NULL OR cobFec >= P.FecDesde) 
	AND (P.FecHasta IS NULL OR cobFec <= P.FecHasta)
	
	), COBS AS(
	SELECT D.cobScd
	, D.cobPpag
	, D.cobNum
	, D.cblLin 
	
	, D.cobctr
	, D.cblPer
	, D.cobFecReg
	, D.cobOrigen
	, D.cobUsr
	, numLinCobros = COUNT(D.cblLin) OVER (PARTITION BY  D.cobScd, D.cobPpag, D.cobNum) 
	, D.cobImporte
	, cblTotal = SUM(D.cblImporte) OVER (PARTITION BY  D.cobScd, D.cobPpag, D.cobNum) 
	, D.cblImporte
	, cldTotal = SUM(D.cldTotal) OVER (PARTITION BY  D.cobScd, D.cobPpag, D.cobNum, D.cblLin) 
	--, CL.cblImporte, CLD.cldImporte, C.cobImporte
	FROM DESGLOSE AS D
	WHERE D.RN=1)
	

	SELECT Sociedad = cobScd
	, [Pto.Pago] = cobPpag
	, [Num.Cobro] = cobNum	
	, [Num.Líneas Cobro]= numLinCobros
	, [Línea Cobro] = cblLin
	, [Origen] = cobOrigen
	, [Fecha Reg. Cobro] = cobFecReg
	, [Usuario] = cobUsr
	, [Contrato] = cobCtr
	, [Periodo] = cblPer
	, [Imp.Cobro] = cobImporte	
	, [SUM(Líneas Cobro)] = ROUND(cblTotal, 2)
	, [DIF Cobros-Líneas] = ISNULL(cobImporte, 0) - ISNULL(ROUND(cblTotal, 2), 0)
	, [Imp.Líneas Cobro] = ROUND(cblImporte, 2)
	, [SUM(Desglose Líneas Cobro)] = ROUND(cldTotal, 2)
	, [DIF.Líneas-Desglose] = ISNULL(ROUND(cblImporte, 2), 0) - ISNULL(ROUND(cldTotal, 2), 0)
	FROM COBS AS C
	WHERE NOT(ISNULL(cobImporte, 0) = ISNULL(ROUND(cblTotal, 2), 0) AND ISNULL(ROUND(cblImporte, 2), 0) = ISNULL(ROUND(cldTotal, 2), 0))
	
	ORDER BY cobCtr
	, cblPer
	, C.cobScd
	, C.cobPpag
	, C.cobNum
	, C.cblLin 

	END TRY

	BEGIN CATCH
		SELECT  @p_errId_out = ERROR_NUMBER()
			 ,  @p_errMsg_out= ERROR_MESSAGE();
	END CATCH




GO


