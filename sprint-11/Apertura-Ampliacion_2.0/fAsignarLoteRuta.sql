CREATE  FUNCTION dbo.fAsignarLoteRuta (@Rutas AS dbo.tRutaLotes READONLY, @MinLecturasLote INT) 
RETURNS @result  TABLE(RUTA INT NULL, QTY INT NULL, LOTE INT NULL )
AS
BEGIN

DECLARE @ruta AS INT;
DECLARE @qty AS INT;
DECLARE @lote AS INT = 1;
DECLARE @sumTotal AS INT = 0;

DECLARE CUR CURSOR FOR
SELECT RUTA, QTY FROM @Rutas 
ORDER BY RUTA; --Importante recorrer en orden

OPEN CUR
FETCH NEXT FROM CUR INTO @ruta, @qty;

WHILE @@FETCH_STATUS = 0
BEGIN

	INSERT INTO @result VALUES(@ruta, @qty, @lote);

	SET @sumTotal = @sumTotal + @qty;

	IF (@sumTotal>= @MinLecturasLote)
	SELECT @lote=@lote+1, @sumTotal=0;

	FETCH NEXT FROM CUR INTO @ruta, @qty;
END

CLOSE CUR;
DEALLOCATE CUR;

RETURN;
 
END