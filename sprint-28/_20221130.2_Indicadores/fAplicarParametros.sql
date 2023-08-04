
ALTER FUNCTION [Indicadores].[fAplicarParametros]
( @aFecha DATE
, @wDesde DATE
, @wHasta DATE
, @mDesde DATE
, @mHasta DATE
, @AGUA INT
, @ALCANTARILLADO INT
, @DOMESTICO INT
, @NODOMESTICO VARCHAR(25)
, @MUNICIPAL INT
, @NOMUNICIPAL VARCHAR(25)
, @INDUSTRIAL INT
, @LECTURANORMAL VARCHAR(250)
, @RECLAMACION VARCHAR(4)
, @INSPECCIONES VARCHAR(250))

RETURNS @RESULT TABLE(indAcr VARCHAR(5)
					, indPeriodicidad CHAR(1)
					, indFuncion VARCHAR(MAX)
					, indFuncionInfo VARCHAR(MAX)
					, indUnidad VARCHAR(15))
AS
BEGIN

DECLARE @aFecha_ VARCHAR(10);
DECLARE @wDesde_ VARCHAR(10);
DECLARE @wHasta_ VARCHAR(10);
DECLARE @wDesdeAnt VARCHAR(10);
DECLARE @wHastaAnt VARCHAR(10);

DECLARE @mDesde_ VARCHAR(10);
DECLARE @mHasta_ VARCHAR(10);
DECLARE @mDesdeAnt VARCHAR(10);
DECLARE @mHastaAnt VARCHAR(10);

DECLARE @aDesde VARCHAR(10);
DECLARE @aHasta VARCHAR(10);


DECLARE @LECTURANORMAL_ VARCHAR(255); 
DECLARE @NODOMESTICO_ VARCHAR(50);
DECLARE @NOMUNICIPAL_ VARCHAR(50);

SELECT @aFecha_			=  '''' + CONVERT(VARCHAR(10), DATEADD(DAY, 1, @aFecha), 112) + ''''
	 , @wDesde_			=  '''' + CONVERT(VARCHAR(10), @wDesde, 112) + ''''
	 , @wHasta_			=  '''' + CONVERT(VARCHAR(10), @wHasta, 112) + ''''
	 , @wDesdeAnt		=  '''' + CONVERT(VARCHAR(10), DATEADD(WEEK, -1, @wDesde), 112) + ''''
	 , @wHastaAnt		=  '''' + CONVERT(VARCHAR(10), DATEADD(WEEK, -1, @wHasta), 112) + ''''
	 
	 , @mDesde_			=  '''' + CONVERT(VARCHAR(10), @mDesde, 112) + ''''
	 , @mHasta_			=  '''' + CONVERT(VARCHAR(10), @mHasta, 112) + ''''
	 , @mDesdeAnt		=  '''' + CONVERT(VARCHAR(10), DATEADD(MONTH, -1, @mDesde), 112) + ''''
	 , @mHastaAnt		=  '''' + CONVERT(VARCHAR(10), DATEADD(MONTH, -1, @mHasta), 112) + ''''

	 , @aDesde			=  '''' + CONVERT(VARCHAR(10), DATEADD(MONTH, -11, @mDesde), 112) + ''''
	 , @aHasta			=  '''' + CONVERT(VARCHAR(10), @mHasta, 112) + ''''

	 , @LECTURANORMAL_	= ''''+ @LECTURANORMAL + ''''
	 , @RECLAMACION		= ''''+ @RECLAMACION + ''''
	 , @NODOMESTICO_		= ''''+ @NODOMESTICO + ''''
	 , @NOMUNICIPAL_		= ''''+ @NOMUNICIPAL + ''''



INSERT INTO @RESULT
SELECT indAcr
, indPeriodicidad
, REPLACE(
  REPLACE(
  REPLACE(
  REPLACE(
  REPLACE(
  REPLACE(
  REPLACE(
  REPLACE(
  REPLACE(
  REPLACE(
  REPLACE(
  REPLACE(
  REPLACE(
  REPLACE(
  REPLACE(
  REPLACE(
  REPLACE(
  REPLACE(indFuncion, '@aFecha', @aFecha_)
					, '@fDesdeAnt', IIF(C.indPeriodicidad = 'S', @wDesdeAnt, @mDesdeAnt))
					, '@fHastaAnt', IIF(C.indPeriodicidad = 'S', @wHastaAnt, @mHastaAnt))
					, '@fDesde', IIF(C.indPeriodicidad = 'S', @wDesde_, @mDesde_))
					, '@fHasta', IIF(C.indPeriodicidad = 'S', @wHasta_, @mHasta_))
					, '@AGUA', @AGUA)
					, '@ALCANTARILLADO', @ALCANTARILLADO)
					, '@DOMESTICO', @DOMESTICO)
					, '@NODOMESTICO', @NODOMESTICO_)
					, '@MUNICIPAL', @MUNICIPAL)
					, '@NOMUNICIPAL', @NOMUNICIPAL_)
					, '@INDUSTRIAL', @INDUSTRIAL)
					, '@LECTURANORMAL', @LECTURANORMAL_)
					, '@RECLAMACION', @RECLAMACION)
					, '@INDICADOR', CONCAT('@', indAcr))
					, '@INSPECCIONES', @INSPECCIONES)
					, '@aDesde', @aDesde)
					, '@aHasta', @aHasta)
, indFuncionInfo
, indUnidad
FROM Indicadores.IndicadoresConfig AS C
WHERE C.indActivo=1;


RETURN;



END
GO


