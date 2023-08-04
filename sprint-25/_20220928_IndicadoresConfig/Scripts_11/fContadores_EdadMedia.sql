/*
DECLARE @fechaRegistro DATE = '20221001'
SELECT Indicadores.Contadores_EdadMedia(@fechaRegistro)

*/

CREATE FUNCTION Indicadores.fContadores_EdadMedia(@fechaRegistro DATE)
RETURNS INT AS
BEGIN  

	DECLARE @RESULT INT;
	
	IF(@fechaRegistro IS NULL) SET @fechaRegistro=dbo.GetAcuamaDate();

	SET @fechaRegistro =DATEADD(DAY, 1, @fechaRegistro);

	SELECT @RESULT = AVG(DATEDIFF(YEAR, C.fechaFabricacion, @fechaRegistro))
	FROM dbo.vContadoresFecFabricacion AS C
	WHERE C.conFecReg < @fechaRegistro;

	RETURN @RESULT
	
END	

GO