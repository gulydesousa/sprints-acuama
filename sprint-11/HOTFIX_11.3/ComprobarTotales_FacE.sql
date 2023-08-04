/*
****** CONFIGURACION ******

INSERT INTO dbo.ExcelConsultas
VALUES ('000/101',	'Comprobar Totales FacE', 'Comprobar Totales por Tipo Impositivo (FacE)', 12, '[InformesExcel].[ComprobarTotales_FacE]', '001', 'Para comprobar facturas enviadas a facE donde el total por líneas es diferente al total por tipo impositivo.');

INSERT INTO ExcelPerfil
VALUES('000/101', 'root', 4, NULL)

INSERT INTO ExcelPerfil
VALUES('000/101', 'jefeExp', 4, NULL)

INSERT INTO ExcelPerfil
VALUES('000/101', 'jefAdmon', 4, NULL)

*/

/*
--Corrige problemas por desglose de tarifas 
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_error_out INT;
DECLARE @p_errMsg_out   NVARCHAR(MAX);

SET @p_params= '<NodoXML><LI><periodoD>202101</periodoD><periodoH>202103</periodoH></LI></NodoXML>'

EXEC [InformesExcel].[ComprobarTotales_FacE] @p_params, @p_error_out OUTPUT, @p_errMsg_out OUTPUT;
*/


CREATE PROCEDURE [InformesExcel].[ComprobarTotales_FacE]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS

SET NOCOUNT ON;  
BEGIN TRY

	--********************
	--INICIO: 2 DataTables
	-- 1: Paramentros del encabezado
	-- 2: Gurpos
	-- 3: Datos
	--********************
	
	--DataTable[1]:  Parametros
	DECLARE @xml AS XML = @p_params;
	
	DECLARE @params TABLE (periodoD VARCHAR(6) NULL, periodoH VARCHAR(6) NULL, fInforme DATETIME);

	INSERT INTO @params
	SELECT periodoD = M.Item.value('periodoD[1]', 'VARCHAR(6)')
		 , periodoH = M.Item.value('periodoH[1]', 'VARCHAR(6)')
		 , fInforme = GETDATE()	
	FROM @xml.nodes('NodoXML/LI')AS M(Item);

	--********************
	--VALIDAR PARAMETROS
	--********************
	SELECT * 
	, [totalFacturado]  = 'Total por lineas'
	, [totalFacturado_] = 'Total por tipo impositivo'
	FROM @params;
	

	WITH FACS AS(
	--[01]Factura con los filtros
	SELECT F.faccod
		 , F.facPercod
		 , F.facCtrCod
		 , F.facVersion
		 , CAST(F.facFecha AS DATE) AS facFecha
		 , F.facSerCod
		 , F.facNumero
		 , F.facFecReg
		 , F.facFechaRectif
		 , F.facNumeroRectif
		 , F.facSerieRectif
		 , facEnvSERES = ISNULL(F.facEnvSERES, '')
		 , ctrFace = ISNULL(C.ctrFace, 0)
		 , PP.perAvisoPago
		 , P.pgsvalor  AS fecLineas2Decimales
		 , PV.pgsvalor AS diasPagoVoluntario
		 , IIF(P.pgsvalor IS NOT NULL AND F.facFecReg>=P.pgsvalor, 2, 4) AS [precision]
	FROM dbo.facturas AS F
	INNER JOIN dbo.periodos AS PP
	ON PP.percod = F.facPerCod
	INNER JOIN @params AS _P
	ON PP.perCod >=  _P.periodoD
	AND PP.perCod <= _P.periodoH
	AND F.facFechaRectif IS NULL
	LEFT JOIN dbo.contratos AS C
	ON  C.ctrCod = F.facCtrCod
	AND C.ctrVersion = F.facCtrVersion
	LEFT JOIN dbo.parametros AS P
	ON P.pgsclave = 'LINEAS_2DECIMALES'
	LEFT JOIN dbo.parametros AS PV
	ON PV.pgsclave = 'DIAS_PAGO_VOLUNTARIO'
	WHERE C.ctrFace=1	

	), FTI AS(
	--[03]Total lineas por Tipo Impositivo
	SELECT F.faccod
		 , F.facPercod
		 , F.facCtrCod
		 , F.facVersion
		 , FL.fclImpuesto
		 , SUM(FL.fclBase) AS base
		 , _totaliva = CAST(SUM(ROUND(FL.fclBase*FL.fclImpuesto*0.01, 4)) AS MONEY) 
		 , totaliva  = ROUND(CAST(SUM(ROUND(FL.fclBase*FL.fclImpuesto*0.01, 4)) AS MONEY) , IIF(ctrFace=1, 2, 4))
	FROM FACS AS F
	INNER JOIN dbo.faclin AS FL
	ON  F.facCod = FL.fclFacCod 
	AND F.facPerCod = FL.fclFacPerCod 
	AND F.facCtrCod = FL.fclFacCtrCod 
	AND F.facVersion= FL.fclFacVersion
	WHERE (FL.fclFecLiq IS NULL AND FL.fclUsrLiq IS NULL)
	GROUP BY F.faccod
			, F.facPercod
			, F.facCtrCod
			, F.facVersion
			, FL.fclImpuesto
			, F.ctrFace

	), FACT AS(	   	  	
	SELECT F.facCod
		 , F.facCtrCod
		 , F.facPerCod
		 , F.facVersion
		 , F.facFecReg
		 , F.facNumero
		 , FL.base
		 , FL.fclImpuesto
		 , FL.totaliva
		 , totalFacturado  = ROUND(SUM(FL.base + FL.totaliva) OVER (PARTITION BY F.facCod, F.facCtrCod, F.facPerCod, F.facVersion), 2)
		 , _totalFacturado = ROUND(SUM(FL.base + FL._totaliva) OVER (PARTITION BY F.facCod, F.facCtrCod, F.facPerCod, F.facVersion), 2)
		 , FacE = CASE facEnvSERES WHEN '' THEN 'N/A' 
								   WHEN 'P' THEN 'Pendiente' 
								   WHEN 'E' THEN 'Enviada' END
	FROM FACS AS F
	INNER JOIN FTI AS FL
	ON  FL.facCod = F.facCod
	AND FL.facPerCod = F.facPerCod
	AND FL.facCtrCod = F.facCtrCod
	AND FL.facVersion = F.facVersion

	), COBS AS (
	SELECT C.cobCtr
		 , CL.cblPer
		 , CL.cblFacCod
		 , Cobrado = SUM(CL.cblImporte)
	FROM dbo.cobros AS C
	INNER JOIN dbo.coblin AS CL
	ON  CL.cblScd = C.cobScd
	AND CL.cblPpag = C.cobPpag
	AND CL.cblNum = C.cobNum
	INNER JOIN FACS AS F
	ON  C.cobCtr  = F.facCtrcod
	AND CL.cblPer = F.facPerCod
	AND CL.cblFacCod = F.facCod
	GROUP BY C.cobCtr, CL.cblPer, CL.cblFacCod)

	SELECT F.*
		 , Deuda   = CAST(IIF(C.Cobrado IS NOT NULL AND C.Cobrado>=totalFacturado, 0, 1) AS BIT)
		 , Cobrado = ISNULL(C.Cobrado, 0) 
	FROM FACT AS F
	LEFT JOIN COBS AS C
	ON  C.cobCtr = F.facCtrCod
	AND C.cblPer = F.facPerCod
	AND C.cblFacCod = F.facCod
	WHERE totalFacturado <> _totalFacturado
	ORDER BY facCod, facPerCod, facCtrCod, facVersion, fclImpuesto;

END TRY
	
BEGIN CATCH
	SELECT  @p_errId_out = ERROR_NUMBER()
		 ,  @p_errMsg_out= ERROR_MESSAGE();
END CATCH
	
GO
