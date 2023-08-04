
/*
DECLARE @facCtrcod INT= 30928;
DECLARE @facPerCod VARCHAR(6) = '201002';		
DECLARE @facCodigo SMALLINT--=1;
DECLARE @facVersion SMALLINT--=1;


EXEC [ReportingServices].[CF010_EmisionFacTotales] @facCtrcod, @facPerCod, @facCodigo, @facVersion
*/

CREATE PROCEDURE [ReportingServices].[CF010_EmisionFacTotales] 
(   @facCtrcod INT ,
	@facPerCod VARCHAR(6),		
	@facCodigo SMALLINT,
	@facVersion SMALLINT
)

AS

DECLARE @HOY DATE = (SELECT dbo.GETACUAMADATE());
DECLARE @cobPpag INT;
DECLARE @cobMpc INT;
DECLARE @explotacion	VARCHAR(100);
DECLARE @explotacionCod VARCHAR(5);
DECLARE @diasPagoVoluntario INT = NULL;
DECLARE @facTotales VARCHAR(10);
DECLARE @EXPLO_BARCODE AS TABLE(COD VARCHAR(5))
DECLARE @EXPLO_DOMICILIACION AS TABLE(COD VARCHAR(5))


--***********************
--PARAMETROS
SELECT @cobPpag = P.pgsvalor FROM dbo.parametros AS P WHERE pgsclave = 'PUNTO_PAGO_ENTREGAS_A_CTA';
SELECT @cobMpc = P.pgsvalor FROM dbo.parametros AS P WHERE pgsclave = 'MEDIO_PAGO_ENTREGAS_A_CTA';
SELECT @diasPagoVoluntario = CAST(P.pgsvalor AS INT) FROM dbo.parametros AS P WHERE pgsclave = 'DIAS_PAGO_VOLUNTARIO' AND TRY_PARSE(P.pgsvalor AS INT) IS NOT NULL ;
SELECT @facTotales = ISNULL(P.pgsvalor, '') FROM dbo.parametros AS P WHERE pgsclave = 'FACTOTALES';

INSERT INTO @EXPLO_BARCODE
SELECT VALUE FROM dbo.Split('001,002,003,004,006,007,010,011,015' , ',');

--Validar domiciliacion: 006:SORIA, 010:AVG, 015:RIBADESELLA
INSERT INTO @EXPLO_DOMICILIACION
SELECT VALUE FROM dbo.Split('006,010,015' , ',');

SELECT @explotacion =  CASE PE.pgsValor 
						WHEN '001' THEN 'Almaden'
						WHEN '003' THEN 'Svb' 
						ELSE P.pgsValor END
	 , @explotacionCod = PE.pgsValor	
FROM dbo.parametros AS P 
INNER JOIN dbo.parametros AS PE
ON PE.pgsclave = 'EXPLOTACION_CODIGO'
AND P.pgsclave = 'EXPLOTACION';

--***********************
--Explotaciones con el codigo de barras
--001	ALMADEN
--002	ALAMILLO
--003	SVB
--004	GUADALAJARA
--006	Soria
--007	Valdaliga
--010	AVG
--011	Biar
--015	Ribadesella
--***********************
 
--[01]Factura
WITH FAC AS (
SELECT F.facCod
, F.facPerCod
, F.facCtrCod
, F.facVersion
, F.facFecha
, F.facNumero
, C.ctrIban
, C.ctrTitDocIden
, esPrefactura = IIF(F.facFecha IS NULL, 1, 0)   
, esRectificada = IIF(F.facFechaRectif IS NOT NULL, 1, 0)  
, esDomiciliada = IIF(C.ctrIBAN IS NOT NULL AND LEN(C.ctrIBAN) BETWEEN 24 AND 34, 1, 0)
, perAvisoPago = LTRIM(RTRIM(PP.perAvisoPago))
, esUserOnline = IIF(U.usrLogin IS NULL, 0, 1)
FROM  dbo.Facturas AS F
INNER JOIN dbo.Contratos AS C
ON  C.ctrCod = F.facCtrCod
AND C.ctrVersion = F.facCtrVersion
INNER JOIN dbo.periodos AS PP
ON PP.percod = F.facPerCod
LEFT JOIN dbo.online_usuarios AS U
ON U.usrLogin = C.ctrTitDocIden
WHERE (@facCodigo IS NULL OR F.facCod = @facCodigo)
  AND (@facPerCod IS NULL OR F.facPerCod  = @facPerCod)
  AND (@facCtrCod IS NULL OR F.facCtrCod  = @facCtrCod)
  AND (@facVersion IS NULL OR F.facVersion = @facVersion)

--[02]Cobros
), COBS AS(
SELECT F.facCod
, F.facPerCod
, F.facCtrCod
, F.facVersion
, C.cobScd
, C.cobPpag
, C.cobNum
, CL.cblLin
, C.cobDevCod
, ROW_NUMBER() OVER (PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion ORDER BY C.cobFec DESC, C.cobFecReg DESC, C.cobNum DESC) AS RN
FROM dbo.cobros AS C
INNER JOIN dbo.coblin AS CL 
ON  CL.cblScd = C.cobScd 
AND CL.cblPpag= C.cobPpag 
AND CL.cblNum = C.CobNum
INNER JOIN FAC AS F
ON  C.cobCtr = F.facCtrCod
AND CL.cblPer = F.facPerCod
AND CL.cblFacCod = F.facCod
AND CL.cblFacVersion =  F.facVersion

), SCD AS(
SELECT TOP 1 scdCod, scdFecIniC57, P.pgsclave 
FROM dbo.sociedades AS S
INNER JOIN dbo.parametros AS P
ON P.pgsclave='SOCIEDAD_POR_DEFECTO'
AND S.scdcod = P.pgsvalor
)

SELECT F.facCod
, F.facPerCod
, F.facCtrCod
, F.facVersion
, facFecha = CAST(F.facFecha AS DATE)
, F.facNumero
, CodExplotacion = @explotacionCod
, Explotacion	 = @explotacion
--Explotaciones donde se muestra el codigo de barras
, esExploCodigoBarras = IIF(B.COD IS NULL, 0, 1)
--Validar domiciliacion
, checkDomiciliacion = IIF(D.COD IS NULL, 0, 1)
, F.ctrIban
, F.ctrTitDocIden
, F.esPrefactura
, F.esRectificada
, F.esDomiciliada
, diasPagoVoluntario = @diasPagoVoluntario
, fechaLimitePagoVoluntario =	CAST(CASE 
								  --Si está configurado por parametros los días de pago voluntario, los sumamos a la fecha de la factura
								  WHEN @diasPagoVoluntario IS NOT NULL 
								  THEN DATEADD(DAY, @diasPagoVoluntario, ISNULL(F.facFecha, @HOY))
								  --No hay fecha limite para el pago voluntario
								  ELSE NULL 
								  END AS DATE)

, scdFecIniC57 = CAST(S.scdFecIniC57 AS DATE)
, inicioC57 = IIF(S.scdFecIniC57 IS NULL OR F.facFecha IS NULL OR S.scdFecIniC57 > F.facFecha, 0, 1)
, AcuamaGetDate = @HOY
, F.esUserOnline
, urlParams = FORMATMESSAGE('?periodo=%s&contrato=%i&facturaCodigo=%i&explotacion=%s', F.facPerCod, F.facCtrCod, F.facCod, @explotacion)
, fctTipoImp1, fctBaseTipoImp1, fctImpuestoTipoImp1
, fctTipoImp2, fctBaseTipoImp2, fctImpuestoTipoImp2
, fctTipoImp3, fctBaseTipoImp3, fctImpuestoTipoImp3
, fctTipoImp4, fctBaseTipoImp4, fctImpuestoTipoImp4
, fctTipoImp5, fctBaseTipoImp5, fctImpuestoTipoImp5
, fctTipoImp6, fctBaseTipoImp6, fctImpuestoTipoImp6
, fctTotal
, fctDeuda
, fctCobrado
, fctEntregasCta
, vFacTotales = @facTotales
, esDevolucion = IIF(cobDevCod IS NOT NULL, 1, 0)
, C.cobDevCod
, mostrarBarCode =  IIF (NOT B.COD IS NULL AND							--La explotacion es de las que sacan el codigo de barras
						 ROUND(fctTotal, 0) > ROUND(fctCobrado, 0) AND	--Está pendiente de cobro
						 esRectificada = 0	AND							--No es una rectificada 
						 esPrefactura = 0 AND							--No es una prefactura
																		--La fecha de la factura es posterior a scdFecIniC57
						 (F.facFecha IS NOT NULL AND S.scdFecIniC57 IS NOT NULL AND F.facFecha>=S.scdFecIniC57) AND
																		--Es no domiciliada OR Está domiciliada y devuelta
						 (esDomiciliada = 0 OR (esDomiciliada = 1 AND NOT C.cobDevCod IS NULL)) 
						, 1, 0)  

FROM FAC AS F
INNER JOIN dbo.facTotales AS T
ON	T.fctCod= F.facCod
AND T.fctCtrCod = F.facCtrCod
AND T.fctPerCod = F.facPerCod
AND T.fctVersion = F.facVersion
LEFT JOIN @EXPLO_BARCODE AS B
ON B.COD = @explotacionCod
LEFT JOIN @EXPLO_DOMICILIACION AS D
ON D.COD = @explotacionCod
LEFT JOIN SCD AS S
ON S.pgsclave='SOCIEDAD_POR_DEFECTO'
LEFT JOIN COBS AS C
ON  C.facCod = F.facCod
AND C.facPerCod = F.facPerCod
AND C.facCtrCod = F.facCtrCod
AND C.facVersion = F.facVersion
AND C.RN=1
GO


