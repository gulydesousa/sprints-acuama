/*
DECLARE @esApto AS VARCHAR(10);
DECLARE @objectid INT = 1;
EXEC  otInspecciones_Melilla_EsApto @objectid , @esApto OUTPUT;
SELECT [es_Apto] = @esApto
*/
CREATE PROCEDURE dbo.otInspecciones_Melilla_EsApto(@objectid INT,  @esApto VARCHAR(10) OUTPUT)
AS
	--Para determinar si la inspección puede marcarse APTA.
	DECLARE @servicio AS TINYINT;
	
	DECLARE @otivColumnas NVARCHAR(MAX);
	DECLARE @columns NVARCHAR(MAX);
	DECLARE @sql NVARCHAR(MAX);
	SET @esApto = '';

	--Tabla donde guardamos las columnas de otInspeccionesApto
	DECLARE @DATOS_EVAL AS TABLE(Clave VARCHAR(128), Valor VARCHAR(250) DEFAULT '');

	--Servicio asociado a la inspección
	SELECT @servicio = S.otisCod
	FROM dbo.otInspecciones_Melilla AS I
	INNER JOIN dbo.otInspeccionesServicios AS S
	ON S.otisDescripcion = I.servicio
	WHERE objectid=@objectid;


	IF (@servicio IS NOT NULL)
	BEGIN
		-- Obtener todas las columnas plantilla inspeccion
		SELECT @otivColumnas = STRING_AGG('ISNULL(CAST(' + otivColumna + ' AS VARCHAR), '''') AS ' + otivColumna, ', ') 
		FROM otInspeccionesValidaciones 
		WHERE otivServicioCod=@servicio;



		SELECT @columns = STRING_AGG(otivColumna, ', ') 
		FROM dbo.otInspeccionesValidaciones 
		WHERE otivServicioCod=@servicio;
	
		-- Construir la cadena de consulta SQL
		SET @sql = CONCAT('SELECT Clave, Valor FROM (SELECT ', @otivColumnas, ' FROM dbo.otInspecciones_Melilla AS I WHERE objectid=', @objectid, ') AS SourceTable UNPIVOT (Valor FOR Clave IN (', @columns, ')) AS UnpivotTable');
	
		INSERT INTO @DATOS_EVAL (Clave, Valor)
		EXEC sp_executesql @sql;

		--Si alguno de las criticas no se cumple, es no-apto
		IF EXISTS (
		SELECT 1 
		FROM @DATOS_EVAL AS D
		INNER JOIN otInspeccionesValidaciones AS A
		ON A.otivServicioCod = @servicio
		AND A.otivColumna = D.Clave
		AND A.otivCritica = 1
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
			INNER JOIN otInspeccionesValidaciones AS A
			ON A.otivServicioCod = @servicio
			AND A.otivColumna = D.Clave
			AND A.otivCritica = 'NO'
			AND (Valor IS NULL OR Valor IN('NO', 'MALO', '')))
				SET @esApto = 'APTO 100%';
		END		
	END
GO