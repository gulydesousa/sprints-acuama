/*
	DECLARE  @contrato INT = 23570
	DECLARE  @periodo VARCHAR(6) = '202008'
	DECLARE  @codigo SMALLINT = 1
	DECLARE  @fecRegistroMaxima DATETIME = '20221105'
	DECLARE  @periodosSaldo BIT = NULL
	DECLARE  @medioPago SMALLINT = NULL
	DECLARE  @puntoPago SMALLINT = NULL
	DECLARE  @facturaVersion SMALLINT = NULL
	DECLARE  @lineaFactura INT = NULL
	DECLARE  @lineaCobro SMALLINT = NULL
	DECLARE  @impCobr MONEY 
	DECLARE  @precision TINYINT = 4


declare @p4 money
exec Cobros_ImporteCobrado @codigo=@codigo,@contrato=@contrato,@fecRegistroMaxima=@fecRegistroMaxima,@impCobr=@p4 output,@periodo=@periodo,@precision=@precision,  @lineaFactura= @lineaFactura
select @p4
*/
ALTER PROCEDURE [dbo].[Cobros_ImporteCobrado] 
( 
	  @contrato INT
	, @periodo VARCHAR(6) = NULL
	, @codigo SMALLINT = NULL --código de la factura
	, @fecRegistroMaxima DATETIME = NULL
	, @periodosSaldo BIT = NULL
	, @medioPago SMALLINT = NULL
	, @puntoPago SMALLINT = NULL
	, @facturaVersion SMALLINT = NULL
	, @lineaFactura INT = NULL
	, @lineaCobro SMALLINT = NULL
	, @impCobr MONEY OUTPUT
	, @precision TINYINT = 2
)
AS

    SET NOCOUNT OFF;

	DECLARE @GETACUAMADATE DATETIME;
	DECLARE @HOY DATE;
	DECLARE @periodoInicioSaldo VARCHAR(6); 
	DECLARE @cldTotal MONEY;
	DECLARE @cblTotal MONEY;
		
	SELECT @periodoInicioSaldo = P.pgsvalor 
	FROM dbo.parametros AS P 
	WHERE P.pgsclave='PERIODO_INICIO_SALDO';

	SELECT @GETACUAMADATE= dbo.GetAcuamaDate();
	SELECT @HOY = @GETACUAMADATE; 

	WITH COBS AS(
	SELECT C.cobScd
		 , C.cobPpag
		 , C.cobNum
		 , CL.cblLin
		 --Cobros: Totalizamos la cabecera.
		 , cblTotal = ROUND(ISNULL(MAX(CL.cblImporte),0), 2) 
		 --Cobros: Totalizamos el desglose de linea por cobro y redondeamos.
		 , cldTotal = ROUND(ISNULL(SUM(CLD.cldImporte),0), @precision)
	FROM dbo.cobros AS C 
	INNER JOIN dbo.coblin AS CL 
	ON  C.cobScd = CL.cblScd 
	AND C.cobPpag = CL.cblPpag 
	AND C.cobNum =CL.cblNum
	INNER JOIN dbo.cobLinDes AS CLD 
	ON CL.cblScd = CLD.cldCblScd 
	AND CL.cblPpag = CLD.cldCblPpag 
	AND CL.cblNum = CLD.cldCblNum 
	AND CL.cblLin = CLD.cldCblLin
	WHERE C.cobCtr = @contrato 
	 AND (@codigo IS NULL OR CL.cblFacCod = @codigo)
	 AND (@periodo IS NULL OR CL.cblPer = @periodo)
	 AND (@medioPago IS NULL OR C.cobMpc = @medioPago)
	 AND (@puntoPago IS NULL OR C.cobPpag = @puntoPago)
	 AND (C.cobFecReg <= ISNULL(@fecRegistroMaxima, @GETACUAMADATE))
	 AND ((@periodosSaldo IS NULL) OR 
		  (@periodosSaldo = 0) OR 
		  (@periodosSaldo = 1 AND (@periodoInicioSaldo IS NULL OR (CL.cblPer >= @periodoInicioSaldo OR CL.cblPer LIKE '000%')))
		  )
	 AND (@facturaVersion IS NULL OR CL.cblFacVersion = @facturaVersion)
	 AND (@lineaFactura IS NULL OR CLD.cldFacLin = @lineaFactura)
	 AND (@lineaCobro IS NULL OR CLD.cldCblLin = @lineaCobro)
	 GROUP BY C.cobScd, C.cobPpag, C.cobNum, CL.cblLin)

	SELECT @cblTotal = SUM(cblTotal), @cldTotal = SUM(cldTotal)  
	FROM COBS AS C;

	SET @impCobr = IIF(@lineaFactura IS NOT NULL, @cldTotal, @cblTotal);

	 SELECT @impCobr;
GO


