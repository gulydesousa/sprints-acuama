SELECT * 
--UPDATE I SET indFuncion='SELECT [VALOR] = COUNT(conNumSerie) FROM dbo.fContratos_ContadoresInstalados(@fHasta) WHERE ctcCon IS NOT NULL', indFuncionInfo=CONCAT('Contadores instalados a la fecha: CD014_ListadoContadoresInstalados.', CHAR(13), CHAR(10), 'Antes: Indicadores.fContadoresInstalados(@fHasta)')
FROM Indicadores.IndicadoresConfig AS I WHERE indAcr= 'I120'


SELECT * 
--UPDATE I SET indFuncion='SELECT [VALOR]= COUNT(*) FROM  dbo.fCtrAltasBajas (@fDesde, @fHasta, ''A'', 0)', indFuncionInfo=CONCAT('Alta de contratos: CC034_CtrAltasBajas.', CHAR(13), CHAR(10), 'Antes: N�mero de contadores por fecha de instalaci�n => dbo.fContadoresxOperacion (''I'', @fDesde, @fHasta)')
FROM Indicadores.IndicadoresConfig AS I WHERE indAcr= 'I121'


SELECT * 
--UPDATE I SET indFuncion='SELECT [VALOR]= COUNT(*) FROM  dbo.fCtrAltasBajas (@fDesde, @fHasta, ''B'', 0)', indFuncionInfo=CONCAT('Bajas de contratos (Sin cambio de titular): CC034_CtrAltasBajas.', CHAR(13), CHAR(10), 'Antes: N�mero de contadores por fecha de retirada => dbo.fContadoresxOperacion (''R'', @fDesde, @fHasta)')
FROM Indicadores.IndicadoresConfig AS I WHERE indAcr= 'I122'


--==============================
SELECT * 
--UPDATE I SET indFuncion='EXECUTE Indicadores.Facturas_ConDeuda @fHasta, 0.01, 120, ''@INDUSTRIAL'', 1, 2, @INDICADOR OUTPUT', indFuncionInfo='Contratos de uso industrial con facturas de consumo pendientes de cobro cuya fecha de vencimiento supera los 120 d�as'
FROM Indicadores.IndicadoresConfig AS I WHERE indAcr= 'I358'

SELECT * 
--UPDATE I SET indFuncion='EXECUTE Indicadores.Facturas_ConDeuda @fHasta, 0.01, 120, ''@DOMESTICO'', NULL, 2, @INDICADOR OUTPUT'
FROM Indicadores.IndicadoresConfig AS I WHERE indAcr= 'I359'


SELECT * 
--UPDATE I SET indFuncion='SELECT [VALOR] = COUNT(*) FROM Indicadores.fReclamaciones (@fDesde, @fHasta, @RECLAMACION)'
FROM Indicadores.IndicadoresConfig AS I WHERE indAcr= 'I117'

INSERT INTO Indicadores.IndicadoresConfig VALUES
('I126_', 'N�MERO TOTAL DE CONTADORES REPUESTOS (12 meses)'
, 'Creo que afecta cuando se introduzcan las Ots de cambio de contadores en Acu@ma, y por tanto, este dato deber�a sacarse de un a�o entero, mensualmente y as� se ir�a "corrigiendo", por posibles retrasos en la cumplimentaci�n de las Ots.'
, 'M'
, 'Conts.'
, 'Confirmar estos tipos de OT: 0031 Cambio contador CARGOUSER  0032 Cambio contador con cargo  0034 CAMBIO CONTADOR SIN CARGO  0036 Cambio di�metro contador  120 Cambio Contador Laborator  3 Cambio de Contador  cdia Cambio diametro y contador  revisar informe cambio de contador  ** tecnica informes cambios de contador **'
, 'SELECT [VALOR] = COUNT(*) FROM Indicadores.fContadorCambio (@aDesde, @aHasta)'
, 'Copiamos la select del informe CD008_ListadoCambiosContadores.rdl'
, 'gmdesousa'
, '1')

SELECT * 
--UPDATE I SET indDescripcion='N�MERO TOTAL DE CONTADORES REPUESTOS (12 meses)'
FROM Indicadores.IndicadoresConfig AS I WHERE indAcr= 'I126_'


SELECT * 
--UPDATE I SET indFuncion='SELECT [VALOR] = COUNT(*) FROM Indicadores.fServiciosCuotasxSemana (@fDesde, @fHasta, ''1,23'')'
FROM Indicadores.IndicadoresConfig AS I WHERE indAcr= 'I145';

SELECT * 
--UPDATE I SET indFuncion='SELECT [VALOR] = COUNT(*) FROM Indicadores.fServiciosCuotasxSemana (@fDesde, @fHasta, ''3,24'')'
FROM Indicadores.IndicadoresConfig AS I WHERE indAcr= 'I148'


SELECT * 
--UPDATE I SET indFuncion='SELECT [VALOR] = SUM(VALOR) FROM Indicadores.fIncidenciasLecturaxSemana (@fDesde, @fHasta, @LECTURANORMAL)'
FROM Indicadores.IndicadoresConfig AS I WHERE indAcr= 'I132'


SELECT * 
--UPDATE I SET indFuncion='SELECT * FROM Indicadores.fFacturasRangoCnsxSemana (@fDesde, @fHasta, 0, 0)'
FROM Indicadores.IndicadoresConfig AS I WHERE indAcr= 'I150'

SELECT * 
--UPDATE I SET indFuncion='SELECT * FROM Indicadores.fFacturasRangoCnsxSemana (@fDesde, @fHasta, 1, 1)'
FROM Indicadores.IndicadoresConfig AS I WHERE indAcr= 'I152'

