/*
DECLARE @return_value int, @errores varchar(max)
EXEC @return_value = RemesasTrab_Errores @remUsrCod = 'admin', @errores = @errores OUTPUT
SELECT @errores as N'@errores'
SELECT 'Return Value' = @return_value
*/
ALTER PROCEDURE [dbo].[RemesasTrab_Errores]
	@remUsrCod VARCHAR(10) = NULL

  , @programacionPdte BIT = NULL
  , @tskType SMALLINT = NULL
  , @tskNumber INT = NULL

  , @errores VARCHAR(MAX) OUTPUT
AS SET NOCOUNT ON;
SET @errores = '';

DECLARE @remFacNumero VARCHAR(20), @ctrCod INT, @ctrVersion SMALLINT, @manRef VARCHAR(35), @manBic VARCHAR(11), @manIban VARCHAR(34), @manFecUltUso DATETIME
	, @manEstadoActual SMALLINT, @manFecFirma DATETIME, @remVersionCtrCCC VARCHAR(2), @remPerCod VARCHAR(6), @remFacCod SMALLINT;

DECLARE rellena_errores CURSOR FOR

SELECT DISTINCT remFacNumero, ctrCod, ctrVersion, manRef, manBic, manIban, manFecUltUso, manEstadoActual, manFecFirma, remVersionCtrCCC, remPerCod, remFacCod
	FROM dbo.remesasTrab AS r1
	INNER JOIN facturas ON facNumero = remFacNumero and facCtrCod = remCtrCod and facPerCod = remPerCod AND facCod = remFacCod
	INNER JOIN contratos c1 ON facCtrCod = ctrCod and facctrversion = ctrversion
	INNER JOIN mandatos ON manRef = ctrManRef AND manCtrVersion = ctrversion
	WHERE (@remUsrCod IS NULL OR remUsrCod = @remUsrCod) 
	  AND (remVersionCtrCCC<>'EP')
	  AND (remCtrCod = ctrCod)

	  AND (@tskType IS NULL	  OR r1.[remTskType]	=@tskType)
	  AND (@tskNumber IS NULL OR r1.[remTskNumber]=@tskNumber)
	  AND ((@programacionPdte IS NULL) OR 
		   (@programacionPdte=1 AND (r1.[remTskType] IS NULL AND r1.[remTskNumber] IS NULL)) OR 
		   (@programacionPdte=0 AND (r1.[remTskType] IS NOT NULL AND r1.[remTskNumber] IS NOT NULL))) 

OPEN rellena_errores;
FETCH NEXT FROM rellena_errores INTO @remFacNumero, @ctrCod, @ctrVersion, @manRef, @manBic, @manIban, @manFecUltUso, @manEstadoActual, @manFecFirma, @remVersionCtrCCC, @remPerCod, @remFacCod;
WHILE @@FETCH_STATUS = 0 BEGIN
	IF (LEN(@manIBAN) < 16 OR LEN(@manIBAN) > 34)
		SET @errores = @errores + CONCAT('IBAN erroneo: mandato ', @manRef, ', contrato ', @ctrCod) + '.<br/>';
	IF (LEN(@manBic) <> 8 AND LEN(@manBic) <> 11)
		SET @errores = @errores + CONCAT('BIC erroneo: mandato ', @manRef, ', contrato ', @ctrCod) + '.<br/>';
	IF (((MONTH(GETDATE()) - MONTH(@manFecUltUso)) + (12 * (YEAR(GETDATE()) - YEAR(@manFecUltUso)))) > 36)
		SET @errores = @errores + CONCAT('Mandato ', @manRef, ' obsoleto, contrato ', @ctrCod) + '.<br/>';	
	IF (@manEstadoActual <> 0 AND @manEstadoActual <> 1)
		SET @errores = @errores + CONCAT('Mandato ', @manRef, ' estado erroneo, contrato ', @ctrCod) + '.<br/>';
	IF @manFecFirma IS NULL
		SET @errores = @errores + CONCAT('Mandato ', @manRef, ' sin firmar, contrato ', @ctrCod) + '.<br/>';
	IF NOT EXISTS(SELECT manRef FROM mandatos WHERE manCtrCod = @ctrCod)
		SET @errores = @errores + CONCAT('Contrato ', @ctrCod, ' Sin mandato') + '.<br/>';
	IF (@remVersionCtrCCC = 'UV' AND @ctrVersion <> (SELECT MAX(ctrVersion) FROM contratos c WHERE c.ctrCod = @ctrCod))
		SET @errores = @errores + CONCAT('Versión de contrato en factura ', @remFacNumero, ' no coincide con la del contrato') + '.<br/>';
	IF (@remVersionCtrCCC <> 'UV' AND @ctrVersion <> (SELECT facCtrVersion FROM facturas WHERE facCtrCod = @ctrCod AND facPerCod = @remPerCod AND facCod = @remFacCod AND facFechaRectif IS NULL))
		SET @errores = @errores + CONCAT('Versión de contrato en factura ', @remFacNumero, ' no coincide con la del contrato') + '.<br/>';
	FETCH NEXT FROM rellena_errores INTO @remFacNumero, @ctrCod, @ctrversion, @manRef, @manBic, @manIban, @manFecUltUso, @manEstadoActual, @manFecFirma, @remVersionCtrCCC, @remPerCod, @remFacCod;
END;
CLOSE rellena_errores;
DEALLOCATE rellena_errores;
GO


