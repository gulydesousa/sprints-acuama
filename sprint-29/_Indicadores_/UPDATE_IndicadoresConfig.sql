
--*******************************
--[15] fExpedientesCorte
--********************************
DELETE Indicadores.IndicadoresConfig WHERE indAcr='I386';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
('I386'
, 'SUSPENSIONES DE SERVICIO POR IMPAGO'
, 'Expedientes de corte con fecha de cierre y de corte.'
, 'M'
, 'Expedientes de corte con fecha de cierre y de corte.'
, 'SELECT [VALOR]= COUNT(*) FROM [Indicadores].[fExpedientesCorte](@fDesde, @fHasta, ''100,200'')'
, 'Numero de expedientes de corte por tipo de expediente de corte(1, 100)
 Se usa la fecha OT para acotar la seleccion de expedientes.
 Usamos la consulta del formulario
 Cobros/Expendientes Corte/Expedientes de corte
 Por tipo de expediente de corte 
 100	SUSPENSION DE SUMINISTRO - INDUSTRIALES
 200	SUSPENSION DE SUMINISTRO - DOMESTICO'
, 'flgarciad'
, 'Exps.'
, 1)




--*******************************
--[20] fPosiblesCortes
--********************************
DELETE Indicadores.IndicadoresConfig WHERE indAcr='N006';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
(N'N006'
, 'Nº DE CONTRATOS POSIBLES CORTES'
, 'Contratos que aparecen en expediente de corte sin fecha  de ejecución y no cerrados'
, 'M'
, 'Contratos que aparecen en expediente de corte sin fecha  de ejecución y no cerrados'
, 'SELECT [VALOR] = COUNT(*) FROM [Indicadores].[fPosiblesCortes](@fDesde, @fHasta, ''100, 200'')'
, 'Usamos la consulta del formulario
Cobros/Expendientes Corte/Expedientes de corte
Se usa la de registro del expediente  para acotar la seleccion de expedientes.
Por tipo de expediente de corte 
100	SUSPENSION DE SUMINISTRO - INDUSTRIALES
200	SUSPENSION DE SUMINISTRO - DOMESTICO
Sin fecha de cierre (excFechaCierreExp)'
, 'flgarciad'
, 'Exps.'
, 1)


SELECT * FROM Indicadores.IndicadoresConfig WHERE indAcr IN ('I386', 'N006');

--UPDATE I SET indActivo=1 FROM Indicadores.IndicadoresConfig AS I  WHERE I.indPeriodicidad='M' AND  I.indAcr NOT IN ('I386', 'N006');
--SELECT * FROM [dbo].[expedientesCorteTipos]
