/*
--**************
--[000]Parametros
DECLARE @sociedad	AS SMALLINT;
DECLARE @usuario	AS VARCHAR(10);
DECLARE @fecha		AS DATETIME;
DECLARE @ppago		AS SMALLINT;
DECLARE @medpc		AS SMALLINT;
--**************
--[000]Factura
DECLARE @facContrato	AS INT;
DECLARE @totalFactura	AS MONEY;
*/

CREATE PROCEDURE dbo.Cobros_EntregasCuentas
  @sociedad		AS SMALLINT
, @fecha		AS DATETIME
, @periodo		AS VARCHAR(6)
, @usuario		AS VARCHAR(10)
, @ppago		AS SMALLINT
, @medpc		AS SMALLINT
--**** Factura ****
, @facContrato	AS INT
, @totalFactura	AS MONEY
, @periodoEntregaCuentas AS VARCHAR(6) = '999999'
AS

--**************
--[000]VARIABLES
DECLARE @importe	AS MONEY;
DECLARE @cblImporte AS MONEY;
DECLARE @importeNegativo AS MONEY;
DECLARE @importePositivo AS MONEY;
DECLARE @cobNumero AS INT;
DECLARE @linea AS INT;
--**************
DECLARE @RESULT AS INT = 0;


--[1001]Obtenemos el importe con el cual debemos insertar el nuevo cobro
SELECT @importe = SUM(ROUND(CL.cblImporte, 2))
FROM dbo.cobros AS C
INNER JOIN dbo.coblin AS CL 
ON  CL.cblScd	= C.cobScd 
AND CL.cblPpag	= C.cobPpag 
AND CL.cblNum	= C.cobNum
WHERE CL.cblPer = '999999' 
	AND C.cobCtr = @facContrato 
	AND C.cobScd = @sociedad;
	
IF (@importe>0)
BEGIN 
	--[2001]Cabecera del cobro
	EXEC Cobros_Insert @sociedad, @pPago, @usuario, @fecha, @facContrato, NULL, NULL, 0, @medpc, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @cobNumero OUTPUT;
	
	--[2010]Importe de cobros
	SET @cblImporte = IIF(@importe <= @totalFactura,  @importe, @totalFactura);
			
	--[2011]Insertamos la línea con el importe de entregas a cuenta en negativo
	SET @importeNegativo = ISNULL(@cblImporte, 0) * -1;	

	EXEC @RESULT = CobLin_Insert @sociedad, @ppago, @cobNumero, 1, '999999', NULL, @importeNegativo, @linea OUTPUT;
	IF @RESULT <> 0
		THROW 51000, 'Ha ocurrido un error insertando la linea de importe negativo', 0;	
		
	--[2012]Insertamos la línea con el importe positivo al periodo que se ha cerrado
	SET @importePositivo = ISNULL(@cblImporte, 0);	

	EXEC @RESULT = CobLin_Insert @sociedad, @ppago, @cobNumero, 1, @periodo, 1, @importePositivo, @linea OUTPUT;		
	IF @RESULT <> 0
		THROW 51000, 'Ha ocurrido un error insertando la linea de importe positivo', 0;	
		
END
GO