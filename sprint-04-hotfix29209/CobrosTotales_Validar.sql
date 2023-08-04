/*
****** CONFIGURACION ******
--DELETE FROM ExcelPerfil WHERE ExPCod= '000/800'
--DELETE FROM ExcelConsultas WHERE ExcCod='000/800'
--DROP PROCEDURE [InformesExcel].[CobrosImporteLineasxDesglose]

DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI><FecDesde>20201201</FecDesde><FecHasta>20210809</FecHasta></LI></NodoXML>'

EXEC  [InformesExcel].[CobrosTotales_Validar] @p_params, @p_errId_out, @p_errMsg_out

*/

CREATE PROCEDURE [InformesExcel].[CobrosTotales_Validar]
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
	
	UPDATE @params SET FecHasta = DATEADD(DAY, 1, FecHasta);
	
	
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
	, [Num.L�neas Cobro]= numLinCobros
	, [L�nea Cobro] = cblLin
	, [Origen] = cobOrigen
	, [Fecha Reg. Cobro] = cobFecReg
	, [Usuario] = cobUsr
	, [Contrato] = cobCtr
	, [Periodo] = cblPer
	, [Imp.Cobro] = cobImporte	
	, [SUM(L�neas Cobro)] = ROUND(cblTotal, 2)
	, [DIF Cobros-L�neas] = ISNULL(cobImporte, 0) - ISNULL(ROUND(cblTotal, 2), 0)
	, [Imp.L�neas Cobro] = ROUND(cblImporte, 2)
	, [SUM(Desglose L�neas Cobro)] = ROUND(cldTotal, 2)
	, [DIF.L�neas-Desglose] = ISNULL(ROUND(cblImporte, 2), 0) - ISNULL(ROUND(cldTotal, 2), 0)
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


