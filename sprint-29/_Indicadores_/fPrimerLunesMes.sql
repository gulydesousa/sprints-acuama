ALTER FUNCTION Indicadores.fPrimerLunesMes (@fecha DATE)
RETURNS DATE
BEGIN
	DECLARE @aFecha DATE;

	SET @aFecha = EOMONTH(@fecha);
	SET @aFecha = DATEADD(DAY, -DAY(@aFecha), @aFecha);
	SET @aFecha = DATEADD(DAY, 8-DATEPART(WEEKDAY, @aFecha), @aFecha);

	RETURN @aFecha;
END