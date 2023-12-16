/*
DECLARE @esApto AS VARCHAR(10);
EXEC  OtInspecciones_Melilla_EsApto 1, @esApto OUTPUT;
SELECT [es_Apto] = @esApto
*/
ALTER PROCEDURE dbo.otInspecciones_Melilla_EsApto(@objectid INT,  @esApto VARCHAR(10) OUTPUT)
AS
	DECLARE @servicio AS VARCHAR(25);
	
	DECLARE @otiaColumnas NVARCHAR(MAX);
	DECLARE @columns NVARCHAR(MAX);
	DECLARE @sql NVARCHAR(MAX);
	SET @esApto = '';

	--Tabla donde guardamos las columnas de otInspeccionesApto
	DECLARE @DATOS_EVAL AS TABLE(Clave VARCHAR(128), Valor VARCHAR(250) DEFAULT '');

	--Servicio asociado a la inspección
	SELECT @servicio=servicio FROM dbo.otInspecciones_Melilla WHERE objectid=@objectid;

	IF (@servicio IS NOT NULL)
	BEGIN

		-- Obtener las columnas plantilla inspeccion
		SELECT @otiaColumnas = STRING_AGG('ISNULL(CAST(' + otiaColumna + ' AS VARCHAR), '''') AS ' + otiaColumna, ', ') 
		FROM otInspeccionesApto_Melilla 
		WHERE otiaServicio=@servicio;

		SELECT @columns = STRING_AGG(otiaColumna, ', ') 
		FROM dbo.otInspeccionesApto_Melilla 
		WHERE otiaServicio=@servicio;

		-- Construir la cadena de consulta SQL
		SET @sql = CONCAT('SELECT Clave, Valor FROM (SELECT ', @otiaColumnas, ' FROM dbo.otInspecciones_Melilla AS I WHERE objectid=', @objectid, ') AS SourceTable UNPIVOT (Valor FOR Clave IN (', @columns, ')) AS UnpivotTable');
	
		INSERT INTO @DATOS_EVAL (Clave, Valor)
		EXEC sp_executesql @sql;

		--Si alguno de las criticas no se cumple, es no-apto
		IF EXISTS (
		SELECT 1 
		FROM @DATOS_EVAL AS D
		INNER JOIN otInspeccionesApto_Melilla AS A
		ON A.otiaServicio = @servicio
		AND A.otiaColumna = D.Clave
		AND A.otiaCritico = 'SI'
		AND (Valor IS NULL OR Valor IN('NO', 'MALO', '')))
			SET @esApto = 'NO';
		ELSE
			SET @esApto = 'SI';

		
		IF(@esApto='SI')
		BEGIN
			--Es apto, veamos si las no criticas se cumplen todas para marcarlo APTO 100%
			IF NOT EXISTS(
			SELECT 1 
			FROM @DATOS_EVAL AS D
			INNER JOIN otInspeccionesApto_Melilla AS A
			ON A.otiaServicio = @servicio
			AND A.otiaColumna = D.Clave
			AND A.otiaCritico = 'NO'
			AND (Valor IS NULL OR Valor IN('NO', 'MALO', '')))
				SET @esApto = 'APTO 100%';
		END		
	END
GO