/*
DECLARE @facCtrcod INT = NULL ;
DECLARE @facPerCod VARCHAR(6) = '202201';		
DECLARE @facCodigo SMALLINT--=1;
DECLARE @facVersion SMALLINT--=1;f
DECLARE @ultimoCobro BIT--= 1
DECLARE @soloOnlineUsuarios BIT-- = 1

EXEC ReportingServices.CF010_EmisionFacTotales_CodigoBarras   @facCtrcod, @facPerCod, @facCodigo, @facVersion, @ultimoCobro, @soloOnlineUsuarios
*/

ALTER PROCEDURE [ReportingServices].[CF010_EmisionFacTotales_CodigoBarras] 
(   @facCtrcod INT,
	@facPerCod VARCHAR(6),		
	@facCodigo SMALLINT,
	@facVersion SMALLINT, 
	@ultimoCobro BIT= 1,
	@soloOnlineUsuarios BIT = 0
)

AS

 SET @ultimoCobro = ISNULL(@ultimoCobro, 1);
 SET @soloOnlineUsuarios= ISNULL(@soloOnlineUsuarios, 0);

--***********************
--Reconocerá la fecha de pago voluntario cuando haya un texto en estos formatos: 
--dd/MM/yyyy
--dd-MM-yyyy
DECLARE @MASK VARCHAR(100) = '%[0-9][0-9][-/][0-9][0-9][-/][0-9][0-9][0-9][0-9]%';

--***********************
--Calculamos en fechaVto la fecha como sale en el codigo de barras
DECLARE @HOY DATE = (SELECT dbo.GETACUAMADATE());

DECLARE @BARCODE_FECHAVTO INT =  1; 
DECLARE @DIAS_VTO_C57_POR_DEFECTO INT =  0; 
DECLARE @DIAS_PAGO_VOLUNTARIO INT =  0; 
DECLARE @SCD_REMESA INT = 0;

SELECT @BARCODE_FECHAVTO = p.pgsvalor FROM dbo.parametros AS P WHERE P.pgsclave='BARCODE_FECHAVTO'; --1:SegunFactura, 2:SiempreFuturo, 3:SinFecha
SELECT @DIAS_VTO_C57_POR_DEFECTO = p.pgsvalor FROM dbo.parametros AS P WHERE P.pgsclave='DIAS_VTO_C57_POR_DEFECTO';
SELECT @DIAS_PAGO_VOLUNTARIO = p.pgsvalor FROM dbo.parametros AS P WHERE P.pgsclave='DIAS_PAGO_VOLUNTARIO';
SELECT @SCD_REMESA = p.pgsvalor FROM dbo.parametros AS P WHERE P.pgsclave='SOCIEDAD_REMESA';

--SELECT [@BARCODE_FECHAVTO]=@DIAS_VTO_C57_POR_DEFECTO, [@DIAS_VTO_C57_POR_DEFECTO]=@DIAS_VTO_C57_POR_DEFECTO, [@DIAS_PAGO_VOLUNTARIO]=@DIAS_PAGO_VOLUNTARIO, [@SCD_REMESA]=@SCD_REMESA
--***********************

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
SELECT F.facCod
, F.facPerCod
, F.facCtrCod
, F.facVersion
, F.facFecha
, F.facNumero
, facScd = IIF(@SCD_REMESA > 0, @SCD_REMESA, F.facSerScdCod)
, C.ctrIban
, C.ctrTitDocIden
, esUserOnline = IIF(U.usrLogin IS NULL, 0, 1)
, perAvisoPago = LTRIM(RTRIM(PP.perAvisoPago))
, PP.perFecFinPagoVol
, esPrefactura = IIF(F.facFecha IS NULL, 1, 0)   
, esRectificada = IIF(F.facFechaRectif IS NOT NULL, 1, 0)  
, esDomiciliada = IIF(C.ctrIBAN IS NOT NULL AND LEN(C.ctrIBAN) BETWEEN 24 AND 34, 1, 0)
, Explotacion = CASE PE.pgsValor 
				WHEN '001' THEN 'Almaden'
				WHEN '003' THEN 'Svb' 
				ELSE P.pgsValor END 
, CodExplotacion = PE.pgsValor
--Explotaciones donde se muestra el codigo de barras
, esExploCodigoBarras = IIF(PE.pgsValor IN ('001','002','003', '004', '006','007','010','011','015'), 1, 0)
--Validar domiciliacion: 006:SORIA, 010:AVG, 015:RIBADESELLA
, checkDomiciliacion = IIF(PE.pgsValor IN ('006', '010','015'), 1, 0)
INTO #FAC
FROM  dbo.facturas AS F
INNER JOIN dbo.Contratos AS C
ON  C.ctrCod = F.facCtrCod
AND C.ctrVersion = F.facCtrVersion
INNER JOIN dbo.periodos AS PP
ON PP.percod = F.facPerCod
LEFT JOIN dbo.parametros AS P
ON P.pgsclave = 'EXPLOTACION'
LEFT JOIN dbo.parametros AS PE
ON PE.pgsclave = 'EXPLOTACION_CODIGO'
LEFT JOIN dbo.online_usuarios AS U
ON U.usrLogin = C.ctrTitDocIden

WHERE (@facCodigo IS NULL OR F.facCod = @facCodigo)
  AND (@facPerCod IS NULL OR F.facPerCod  = @facPerCod)
  AND (@facCtrCod IS NULL OR F.facCtrCod  = @facCtrCod)
  AND (@facVersion IS NULL OR F.facVersion = @facVersion);

--[02]Cobros
SELECT F.facCod
, F.facPerCod
, F.facCtrCod
, F.facVersion
, C.cobScd
, C.cobPpag
, C.cobNum
, C.cobFec
, C.cobFecReg
, C.cobDevCod
, CL.cblLin
, ROW_NUMBER() OVER (PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion ORDER BY C.cobFec DESC, C.cobFecReg DESC, C.cobNum DESC) AS RN
INTO #COB
FROM dbo.cobros AS C
INNER JOIN dbo.coblin AS CL 
ON  CL.cblScd = C.cobScd 
AND CL.cblPpag= C.cobPpag 
AND CL.cblNum = C.CobNum
INNER JOIN #FAC AS F
ON  C.cobCtr = F.facCtrCod
AND CL.cblPer = F.facPerCod
AND CL.cblFacCod = F.facCod
AND CL.cblFacVersion =  F.facVersion;

WITH SCD AS(
SELECT TOP 1  scdCod, scdFecIniC57, P.pgsclave 
FROM dbo.sociedades AS S
INNER JOIN dbo.parametros AS P
ON P.pgsclave='SOCIEDAD_POR_DEFECTO'
AND S.scdcod = P.pgsvalor

), APR AS(
SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, A.aprNumero
--aprRN=1: Para quedarnos con un apremio por factura
, aprRN= ROW_NUMBER() OVER(PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion ORDER BY A.aprNumero DESC)
FROM #FAC AS F
INNER JOIN dbo.apremios AS A
ON A.aprFacCtrCod = F.facCtrCod
AND A.aprFacPerCod = F.facPerCod
AND A.aprFacCod = F.facCod
AND A.aprFacVersion = F.facVersion
)

SELECT F.facCod
, F.facPerCod
, F.facCtrCod
, F.facVersion
, F.facNumero
, F.CodExplotacion
, F.Explotacion
, scdFecIniC57 = CAST(S.scdFecIniC57 AS DATE)
, inicioC57 = IIF(S.scdFecIniC57 IS NULL OR F.facFecha IS NULL OR S.scdFecIniC57 > F.facFecha, 0, 1)
, F.ctrIban
, F.ctrTitDocIden

, C.cobScd
, C.cobPpag
, C.cobNum
, C.cobFec
, C.cobFecReg
, C.cobDevCod 

, fechaLimitePagoVoluntario = CAST( 
							  CASE  --Buscamos una fecha dd/MM/yyyy en periodos.perAvisoPago
							  WHEN PATINDEX(@MASK, F.perAvisoPago) > 0	
							  THEN CONVERT(DATE, SUBSTRING(F.perAvisoPago, PATINDEX(@MASK, F.perAvisoPago), 10))
							  --Si está configurado por parametros los días de pago voluntario, los sumamos a la fecha de la factura
							  WHEN @DIAS_PAGO_VOLUNTARIO > 0 
							  THEN DATEADD(DAY, @DIAS_PAGO_VOLUNTARIO, ISNULL(F.facFecha, @HOY))
							  --No hay fecha limite para el pago voluntario
							  ELSE NULL END	
							  AS DATE)
, AcuamaGetDate = @HOY

, F.esExploCodigoBarras
, F.esUserOnline
, F.esRectificada
, F.esPrefactura
, F.checkDomiciliacion
, F.esDomiciliada
, esDevolucion = IIF(C.cobNum IS NOT NULL AND C.cobDevCod IS NOT NULL , 1, 0)
--****************************
--Fecha de vencimiento que se pinta en el codigo de barras
, fecVto = CASE @BARCODE_FECHAVTO 
		   --1:SegunFactura
		   WHEN 1 THEN
		   CASE WHEN F.perFecFinPagoVol IS NOT NULL THEN F.perFecFinPagoVol
				WHEN F.facFecha IS NOT NULL THEN DATEADD(DAY, @DIAS_PAGO_VOLUNTARIO, F.facFecha)
				WHEN F.facFecha IS NULL		THEN DATEADD(DAY, @DIAS_PAGO_VOLUNTARIO, @HOY)
				ELSE ISNULL(F.facFecha, @HOY) 
				END 
		   --2:SiempreFuturo
		   WHEN 2 THEN 
		   CASE WHEN F.perFecFinPagoVol IS NOT NULL AND F.perFecFinPagoVol > @HOY THEN  F.perFecFinPagoVol 
				WHEN SS.scdDiasVtoC57 IS NOT NULL AND SS.scdDiasVtoC57 > 0 THEN  DATEADD(DAY, SS.scdDiasVtoC57 , @HOY)
				WHEN @DIAS_VTO_C57_POR_DEFECTO > 0 THEN  DATEADD(DAY, @DIAS_VTO_C57_POR_DEFECTO, @HOY)
				ELSE NULL
				END
		   --3: Sin Fecha
		   ELSE NULL END

, urlParams = FORMATMESSAGE('?periodo=%s&contrato=%i&facturaCodigo=%i&explotacion=%s', F.facPerCod, F.facCtrCod, F.facCod, F.Explotacion)
, A.aprNumero
FROM #FAC AS F
LEFT JOIN SCD AS S
ON S.pgsclave='SOCIEDAD_POR_DEFECTO'
LEFT JOIN dbo.sociedades AS SS
ON SS.scdcod = F.facScd
LEFT JOIN #COB AS C
ON F.facCod = C.facCod
AND F.facPerCod = C.facPerCod
AND F.facCtrCod = C.facCtrCod
AND F.facVersion = C.facVersion
LEFT JOIN APR AS A
ON  A.facCod = F.facCod
AND A.facCtrCod = F.facCtrCod
AND A.facPerCod = F.facPerCod
AND A.facVersion = F.facVersion
AND A.aprRN=1
WHERE ((@ultimoCobro = 0) OR (@ultimoCobro = 1 AND C.RN IS NULL OR C.RN=1))
AND (@soloOnlineUsuarios = 0 OR (@soloOnlineUsuarios = 1 AND F.esUserOnline = 1))
ORDER BY F.esUserOnline DESC
       , F.esRectificada ASC
	   , F.esPrefactura ASC
	   , F.esDomiciliada ASC
	   , esDevolucion DESC
	   , F.facCtrCod ASC;

IF OBJECT_ID('tempdb..#FAC') IS NOT NULL DROP TABLE #FAC
IF OBJECT_ID('tempdb..#COB') IS NOT NULL DROP TABLE #COB
GO


