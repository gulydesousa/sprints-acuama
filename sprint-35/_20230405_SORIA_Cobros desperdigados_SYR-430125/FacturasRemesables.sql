/*
****** CONFIGURACION ******
--DELETE ExcelPerfil WHERE ExPCod='000/005' 
--DELETE ExcelConsultas WHERE ExcCod='000/005'
--SELECT * FROM ExcelConsultas WHERE ExcCod='000/005'

INSERT INTO dbo.ExcelConsultas
VALUES ('000/005',	'Facturas Remesables', 'Facturas Remesables', 12, '[InformesExcel].[Facturas_Remesables]', '000', 'Facturas domiciliadas: Información remesa', NULL, NULL, NULL, NULL);

INSERT INTO ExcelPerfil
VALUES('000/005', 'root', 5, NULL)

INSERT INTO ExcelPerfil
VALUES('000/005', 'jefAdmon', 5, NULL)

*/


/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_error_out INT;
DECLARE @p_errMsg_out   NVARCHAR(MAX);

SET @p_params= '<NodoXML><LI><periodoD>202204</periodoD><periodoH>202212</periodoH></LI></NodoXML>'


EXEC [InformesExcel].[Facturas_Remesables] @p_params, @p_error_out OUTPUT, @p_errMsg_out OUTPUT;
*/

ALTER PROCEDURE [InformesExcel].[Facturas_Remesables]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS
	SET NOCOUNT ON;  
	
	BEGIN TRY

	--DataTable[1]:  Parametros
	DECLARE @xml AS XML = @p_params;
	
	DECLARE @params TABLE (periodoD VARCHAR(6) NULL, fInforme DATETIME, periodoH VARCHAR(6) NULL);

	INSERT INTO @params
	SELECT periodoD = M.Item.value('periodoD[1]', 'VARCHAR(6)')
		 , fInforme = GETDATE()	
		 , periodoH = M.Item.value('periodoD[1]', 'VARCHAR(6)')
	FROM @xml.nodes('NodoXML/LI')AS M(Item);

	SELECT * FROM @params;
	
	--********************
	--DataTable[2]:  Grupos
	SELECT Grupo = 'Facturas remesables';
	--********************
	
	DECLARE @FACS AS tFacturasPK;
	
	WITH EP AS(
	--Efectos pendientes
	SELECT EP.efePdteCtrCod
	, EP.efePdtePerCod
	, EP.efePdteFacCod
	, CN= COUNT(*)
	FROM dbo.efectosPendientes AS EP
	INNER JOIN @params AS P
	ON EP.efePdtePerCod BETWEEN P.periodoD AND P.periodoH 
	GROUP BY  EP.efePdteCtrCod, EP.efePdtePerCod, EP.efePdteFacCod)
	

	SELECT F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion
	, F.facZonCod
	, F.facFecha
	, F.facFecReg
	, F.facFechaRemesa
	, [IBAN Factura] = IIF(CF.ctrIban IS NOT NULL, CONCAT('*', RIGHT(CF.ctrIban, 4), ' | ', LEFT(CF.ctrBIC, 4), '*')  , '')
	, [IBAN Ultima]  = IIF(CU.ctrIban IS NOT NULL, CONCAT('*', RIGHT(CU.ctrIban, 4), ' | ', LEFT(CU.ctrBIC, 4), '*')  , '')
	, efectosPendientes = EP.CN
	INTO #FAC
	FROM facturas AS F 
	INNER JOIN @params AS P
	ON F.facPerCod  BETWEEN P.periodoD AND P.periodoH 
	INNER JOIN vContratosUltimaVersion AS U
	ON U.ctrCod = F.facCtrCod
	INNER JOIN contratos AS CF 
	ON  CF.ctrcod = F.facCtrCod
	AND CF.ctrversion =  F.facCtrVersion
	INNER JOIN contratos AS CU 
	ON  CU.ctrcod = U.ctrCod
	AND CU.ctrversion =  U.ctrVersion
	LEFT JOIN apremios AS A
	ON A.aprFacCtrCod = F.facCod
	AND A.aprFacPerCod = F.facPerCod
	AND A.aprFacVersion = F.facVersion
	LEFT JOIN EP 
	ON EP.efePdteCtrCod = F.facCtrCod
	AND EP.efePdteFacCod = F.facCod
	AND EP.efePdtePerCod = F.facPerCod
	WHERE 
	--Sólo facturas NO anuladas (y por tanto últimas versiones)
	facFechaRectif IS NULL
	--El cliente debe tener domiciliado el pago
	AND ((CF.ctrBIC IS NOT NULL AND CF.ctrIBAN IS NOT NULL) OR (CU.ctrBIC IS NOT NULL AND CU.ctrIBAN IS NOT NULL))
	--Facturas
	AND F.facFecha IS NOT NULL
	--Solo se pueden remesar contratos que NO tengan activa la factura electrónica
	AND F.facEnvSERES IS NULL
	--Solo seleccionamos las facturas que no estén apremiadas
	AND A.aprFacCod IS NULL;


	INSERT INTO @FACS
	SELECT facCod, facPerCod, facCtrCod, facVersion FROM #FAC;

	EXEC [dbo].[FacTotales_Update] @FACS;
	
	SELECT F.*, T.fctDeuda 
	FROM #FAC AS F
	INNER JOIN dbo.facTotales AS T
	ON T.fctCod = F.facCod
	AND T.fctPerCod = F.facPerCod
	AND T.fctCtrCod = F.facCtrCod
	AND T.fctVersion = F.facVersion
	ORDER BY T.fctDeuda DESC, facCtrCod, facPerCod;

	END TRY
	BEGIN CATCH
		SELECT  @p_errId_out = ERROR_NUMBER()
			 ,  @p_errMsg_out= ERROR_MESSAGE();
	END CATCH

	DROP TABLE IF EXISTS #FAC;

GO


