ALTER PROCEDURE [dbo].[Facturas_ImporteFacturado] 
( 
	  @codigo SMALLINT = NULL
	, @contrato INT = NULL
	, @periodo VARCHAR(6) = NULL
	, @version SMALLINT = NULL
	, @fechaRegistroMaxima DATETIME = NULL
	, @prefacturas BIT = NULL -- True: Solo prefacturas; False: Ninguna prefactura; NULL: Todas
	, @periodosSaldo BIT = NULL
	, @impFact MONEY OUTPUT --Importe total
	, @precision TINYINT = 2
)
AS

   SET NOCOUNT OFF;

	DECLARE @fRegistroMaxima DATE;
	DECLARE @GETACUAMADATE DATETIME;
	DECLARE @HOY DATE;

	DECLARE @periodoInicioSaldo VARCHAR(6); 

	SELECT @GETACUAMADATE= dbo.GetAcuamaDate();
	SELECT @HOY = @GETACUAMADATE; 

	SET @fechaRegistroMaxima = ISNULL(@fechaRegistroMaxima, @GETACUAMADATE);
	SET @fRegistroMaxima = DATEADD(DAY, 1, @fechaRegistroMaxima);

	SELECT @periodoInicioSaldo = P.pgsvalor 
	FROM dbo.parametros AS P 
	WHERE P.pgsclave='PERIODO_INICIO_SALDO';
	
	DECLARE @FACS AS dbo.tFacturasPK;

	WITH FACS AS(
	SELECT F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion
	--RN=1: Version mas reciente
	, ROW_NUMBER() OVER (PARTITION BY F.facCod, F.facPerCod, F.facCtrCod ORDER BY F.facVersion DESC) AS RN
	FROM dbo.facturas AS F
	WHERE (@codigo IS NULL OR F.facCod = @codigo)
	  AND (@contrato IS NULL OR F.facCtrCod = @contrato)
	  AND (@periodo IS NULL OR F.facPerCod = @periodo)
	  AND ((@version IS NULL AND F.facFecReg < @fRegistroMaxima) OR 
		   (F.facVersion=@version))
	  AND ((@prefacturas IS NULL) OR 
	       (@prefacturas = 1 AND F.facNumero IS NULL) OR 
		   (@prefacturas = 0 AND F.facNumero IS NOT NULL))	
	  AND ((@periodosSaldo = 0) OR 
	       (@periodosSaldo IS NULL) OR
		   (@periodosSaldo = 1 AND (@periodoInicioSaldo IS NULL OR (F.FacPerCod >= @periodoInicioSaldo OR F.facPerCod LIKE '000%'))))
	)
	
	INSERT INTO @FACS(facCod, facPerCod, facCtrCod, facVersion)
	SELECT facCod, facPerCod, facCtrCod, facVersion
	FROM FACS
	WHERE RN=1
	OPTION(RECOMPILE);


	WITH FACT AS(
	SELECT F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion
	, SUM(ISNULL(FL.fclTotal, 0)) AS facTotal
	FROM @FACS AS F
	LEFT JOIN dbo.faclin AS FL 
	ON  F.facCod = FL.fclFacCod
	AND F.facPerCod = FL.fclFacPerCod
	AND F.facCtrCod = FL.fclFacCtrCod 
	AND F.facVersion = FL.fclFacVersion 
	--No se debe sumar al importe facturado las líneas de factura que esten liquidadas
	AND (FL.fclFecLiq IS NULL OR FL.fclFecLiq > @fechaRegistroMaxima)
	GROUP BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion)

	SELECT @impFact = SUM(ROUND(facTotal, @precision))
	FROM FACT
	OPTION(RECOMPILE);

	--SELECT @impFact;
	


GO


