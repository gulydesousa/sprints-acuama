
CREATE VIEW Indicadores.vIndicadoresPlantilla
AS
SELECT [TAG:] = indAcr 
, [Description:] = indDescripcion
, [Unit:] = indUnidad
, [Interval (ms):] = '0 (raw data)'
, [Statistic type:] = 'N/A'
, [Time Zone:] = P.pgsvalor
FROm Indicadores.IndicadoresConfig AS I
LEFT JOIN dbo.parametros AS P
ON P.pgsclave = 'TIMEZONE';

GO