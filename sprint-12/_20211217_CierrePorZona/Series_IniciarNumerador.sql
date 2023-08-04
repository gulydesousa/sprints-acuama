--Al haber un cambio de año se reincia el contador de las facturas de esa serie
CREATE PROCEDURE Series_IniciarNumerador
   @sercod AS SMALLINT
 , @serscd AS SMALLINT
 AS
	DECLARE @AHORA DATETIME = dbo.GetAcuamaDate();
	DECLARE @facFecha DATETIME;
	DECLARE @RESULT INT = 0;
	BEGIN TRY
		--[000]Exito solo si la serie/sociedad existe
		IF NOT EXISTS(SELECT 1 FROM dbo.series AS S WHERE S.sercod = @sercod AND S.serscd = @serscd)
			THROW 51000, 'La serie/sociedad no está configurada en acuama', 0;  
	
		--[001]Fecha de la última factura
		SELECT TOP 1 @facFecha = F.facFecha
		FROM dbo.facturas AS F
		WHERE F.facSerCod = @sercod
		AND F.facSerScdCod= @serscd
		AND F.facfecha IS NOT NULL
		ORDER BY F.facfecha DESC;

		--[002]Si no hay facturas para el año en curso, inicializamos el contador de la factura por serie
		UPDATE S SET S.sernumfra = 0
		FROM dbo.series AS S
		WHERE S.sercod = @sercod
		  AND S.serscd = @serscd
		  AND (@facFecha IS NULL OR YEAR(@facFecha) < YEAR(@AHORA));
	END TRY

	BEGIN CATCH
		SET @RESULT = 1;
	END CATCH

	RETURN @RESULT;
GO



