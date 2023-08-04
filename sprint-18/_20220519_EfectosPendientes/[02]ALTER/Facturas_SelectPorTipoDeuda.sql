/*
DECLARE @contrato INT = 20781;
DECLARE @tipoDeuda SMALLINT = -1;
EXEC  [dbo].[Facturas_SelectPorTipoDeuda] @contrato, @tipoDeuda;
*/

ALTER PROCEDURE [dbo].[Facturas_SelectPorTipoDeuda] 
	@contrato INT = NULL
  , @tipoDeuda SMALLINT
AS
	SET NOCOUNT ON;

	DECLARE @PERIODO_INICIO AS VARCHAR(6)='';
	DECLARE @GETACUAMADATE AS DATETIME;
	DECLARE @HOY AS DATE;

	SELECT @PERIODO_INICIO=pgsValor 
	FROM dbo.parametros AS P 
	WHERE P.pgsClave = 'PERIODO_INICIO';

	SELECT @GETACUAMADATE= dbo.GetAcuamaDate();
	SELECT @HOY = @GETACUAMADATE; 

	WITH FACS AS (
	SELECT F.*
		 --RN=1: Para quedarnos con la última versión
		 , ROW_NUMBER() OVER (PARTITION BY F.facCod, F.facPerCod, F.facCtrCod ORDER BY F.facVersion DESC) AS RN
	FROM dbo.facturas AS F
	WHERE (@contrato IS NULL OR F.facCtrCod = @contrato) 
	  AND (F.facpercod >= @PERIODO_INICIO OR LEFT(F.facpercod,4)='0000') 
	  AND F.facSerScdCod IS NOT NULL 
	  AND F.facSerCod IS NOT NULL 
	  AND F.facNumero IS NOT NULL	

	), FACT AS(
	SELECT F.facCod
		 , F.facPerCod
		 , F.facCtrCod
		 , F.facVersion
		 , ROUND(SUM(ISNULL(FL.fclTotal, 0)), 2) AS facTotal
	FROM dbo.faclin AS FL
	INNER JOIN FACS AS F
	ON 	F.RN=1
	AND FL.fclFacPerCod = F.facPerCod  
	AND FL.fclFacCtrCod = F.facCtrCod 
	AND FL.fclFacVersion= F.facVersion
	AND FL.fclFacCod = F.facCod
	AND F.facFecReg <= @GETACUAMADATE 
	--Las líneas de factura que estén liquidadas NO se incluyen, ni las que tienen fecha de liquidación menor o igual que la de registro
	AND (FL.fclFecLiq IS NULL OR FL.fclFecLiq > @GETACUAMADATE)
	GROUP BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion
	
	), COBS AS(
	--Total por cobro:
	SELECT F.facCod
		 , F.facPerCod
		 , F.facCtrCod
		 , F.facVersion
		 , C.cobNum
		 , C.cobPpag
		 , C.cobScd
		 , CL.cblLin
		 , ROUND(SUM(CLD.cldImporte), 2) AS cblTotal
	FROM dbo.cobros AS C
	INNER JOIN dbo.cobLin AS CL
	ON  CL.cblPpag = C.cobPpag 
	AND CL.cblNum = C.cobNum 
	AND CL.cblScd = C.cobScd
	AND C.cobFecReg <= @GETACUAMADATE
	AND C.cobFec <= @GETACUAMADATE
	INNER JOIN dbo.cobLinDes AS CLD 
	ON  CLD.cldCblPpag = CL.cblPpag
	AND CLD.cldCblNum = CL.cblNum 
	AND CLD.cldCblScd = CL.cblScd 
	AND CLD.cldCblLin = CL.cblLin
	INNER JOIN FACS AS F
	ON 	F.RN=1
	AND F.facCod= CL.cblFacCod
	AND F.facPerCod = CL.cblPer
	AND F.facCtrCod = C.cobCtr
	AND F.facVersion = CL.cblFacVersion
	GROUP BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, C.cobNum, C.cobPpag, C.cobScd, CL.cblLin
	
	), COBT AS(
	--Total Cobrado
	SELECT C.facCod
		 , C.facPerCod
		 , C.facCtrCod
		 , C.facVersion
		 , SUM(C.cblTotal) AS cobTotal
	FROM COBS AS C
	GROUP BY C.facCod, C.facPerCod, C.facCtrCod, C.facVersion)

	SELECT F.*
		 , ISNULL(FT.facTotal, 0) AS facturado
		 , ISNULL(CT.cobTotal, 0) AS cobrado
		 , ISNULL(FT.facTotal, 0) - ISNULL(CT.cobTotal, 0) AS deuda
	FROM FACS AS F 
	LEFT JOIN FACT AS FT
	ON F.facCod = FT.facCod
	AND F.facPerCod = FT.facPerCod
	AND F.facCtrCod = FT.facCtrCod
	AND F.facVersion = FT.facVersion
	LEFT JOIN COBT AS CT
	ON F.facCod = CT.facCod
	AND F.facPerCod = CT.facPerCod
	AND F.facCtrCod = CT.facCtrCod
	AND F.facVersion = CT.facVersion
	WHERE(@tipoDeuda<0 AND ROUND(ISNULL(CT.cobTotal, 0), 2)  > ROUND(ISNULL(FT.facTotal, 0), 2)) --Sobrecobrada
	  OR (@tipoDeuda=0 AND ROUND(ISNULL(CT.cobTotal, 0), 2)  = ROUND(ISNULL(FT.facTotal, 0), 2)) --Cobrada 
	  OR (@tipoDeuda>0 AND ROUND(ISNULL(CT.cobTotal, 0), 2)  < ROUND(ISNULL(FT.facTotal, 0), 2)) --Pendiente de cobro
	ORDER BY F.facpercod, F.facctrcod;


GO


