/*
--DECLARE @objectid AS INT = 3715;
EXEC [ReportingServices].[TO039_InspeccionPlantilla_Melilla] @objectid
*/
CREATE PROCEDURE [ReportingServices].[TO039_InspeccionPlantilla_Melilla] @objectid AS INT
AS
	DECLARE @servicio AS VARCHAR(25);

	DECLARE @DATOS AS TABLE(Columna  VARCHAR(128), Valor VARCHAR(250) DEFAULT '');
	DECLARE @DATOS_EVAL AS TABLE(Orden SMALLINT, Descripcion VARCHAR(250), Columna VARCHAR(128), Valor VARCHAR(250) DEFAULT '', esOK VARCHAR(2), esCritico VARCHAR(2));

	SELECT @servicio=servicio FROM otInspecciones_Melilla WHERE objectid=@objectid;

	INSERT INTO @DATOS(Columna, Valor)
	EXEC otInspecciones_Melilla_ObtenerDatos @objectid=@objectid ;

					
	--Si es apto, vamos a ver si es apto al 100%
	INSERT INTO @DATOS_EVAL(Orden, Descripcion, Columna, Valor, esCritico, esOK)
	SELECT otiaOrden, otiaDescripcion, otiaColumna, Valor, otiaCritico
			, esOK = CASE 
				WHEN D.Valor IS NULL THEN 'NO' --Si el valor no esta informado NO es valido				
				WHEN D.Valor IN ('SI', 'NO') THEN D.Valor								
				WHEN D.Valor IN ('MALO') THEN 'NO'												
				WHEN LEN(D.Valor) > 0 THEN 'SI' --Otro tipo lo consideramos válido si tiene valor asiganado
				ELSE 'NO' END 
	FROM dbo.otInspeccionesApto_Melilla AS V
	LEFT JOIN @DATOS AS D 
	ON  V.otiaColumna = D.Columna 
	WHERE V.otiaServicio = @servicio;

	SELECT * FROM @DATOS_EVAL ORDER BY Orden;

GO