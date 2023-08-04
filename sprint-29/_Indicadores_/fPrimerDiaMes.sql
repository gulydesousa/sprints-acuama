/*
SELECT Indicadores.fPrimerDiaMes ('20221214', 1)
SELECT Indicadores.fPrimerDiaMes ('20221214', 2)
SELECT Indicadores.fPrimerDiaMes ('20221214', 3)
SELECT Indicadores.fPrimerDiaMes ('20221214', 4)
SELECT Indicadores.fPrimerDiaMes ('20221214', 5)
SELECT Indicadores.fPrimerDiaMes ('20221214', 6)
SELECT Indicadores.fPrimerDiaMes ('20221214', 7)

*/
ALTER FUNCTION Indicadores.fPrimerDiaMes (@fecha DATE, @dia INT)
RETURNS DATE
BEGIN
	DECLARE @aFecha DATE;
	
	SET @dia = @dia-1;

	SET @aFecha = EOMONTH(@fecha);
	SET @aFecha = DATEADD(DAY, -DAY(@aFecha), @aFecha);
	
	DECLARE @weekday INT = DATEPART(WEEKDAY, @aFecha);

	IF (@dia >= @weekday)
		SET @aFecha = DATEADD(DAY, 0+@dia-@weekday+1, @aFecha);
	ELSE
		SET @aFecha = DATEADD(DAY, 7+@dia-@weekday+1, @aFecha);
	
	RETURN @aFecha;
END