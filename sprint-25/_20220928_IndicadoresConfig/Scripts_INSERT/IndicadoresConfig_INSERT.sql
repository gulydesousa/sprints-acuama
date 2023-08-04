--*************************************
--DELETE FROM Indicadores.IndicadoresConfig WHERE indUsrCod='gmdesousa' AND indAcr IN('I116', 'I123', 'I150', 'I152', 'I155', 'I158', 'I145', 'I148', 'I132', 'I117')

INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad)
VALUES
('I116'
, 'NÚMERO TOTAL DE CLIENTES'
, 'IMPORTANTE: PEL es una ventana temporal con la posibilidad de elegir el dia de inicio. A ACUAMA solicitar dato absoluto de NUMERO TOTAL DE CLIENTES regisrados Con la ventana temporal elegida en IDBOX se calculará el acumulado en dicho intervalo'
, 'M'
, '¿Número de servicios por contrato, clientes, o contratos?. Contratos Activos'	
, 'SELECT [VALOR] = COUNT(*) FROM Indicadores.fContratos (@fDesde, @fHasta, NULL, NULL)'
, 'Contratos activos.'
, 'gmdesousa'
, 'Ctrs.'
),


('I123'
, 'NÚMERO CLIENTES DOMICILIADOS'
, 'Quiénes de ellos tienen domiciliado el pago'
, 'M'
, '¿Contratos Domiciliados o clientes? (Un cliente puede tener varios contratos)'
, 'SELECT [VALOR] = COUNT(DISTINCT ctrCod) FROM Indicadores.fContratos (@fDesde, @fHasta, NULL, 1)'
, 'Contratos con domiciliación bancaria.'
, 'gmdesousa'
, 'Ctrs.'
),


( 'I150'
, 'NÚMERO DE CLIENTES CON CONSUMO 0 M3'
, 'Aprovechar las descargas de los TPLs y registrar cada vez que se toman las lecturas de campo
pedir a ACUAMA que en cada exportacion, nos de el valor absoluto del dato solicitado'
, 'S'
, 'Servicios por contrato con valor 0.'
, 'SELECT * FROM Indicadores.fFacturaxSemana (@fDesde, @fHasta, 0, 0, NULL, NULL)'
, 'Facturas/pre-facturas (no-rectificadas) con consumo 0.'
, 'gmdesousa'
, 'Facs.'
),


( 'I152'
, 'NÚMERO DE CLIENTES CON (0 < CONSUMO M3 < 2)'
, 'select'
, 'S'
, 'Servicios por contrato en el rango.'
, 'SELECT * FROM Indicadores.fFacturaxSemana (@fDesde, @fHasta, 1, 1, NULL, NULL)'
, 'Facturas/pre-facturas (no-rectificadas) con consumo 1. El consumo es un número entero.'
, 'gmdesousa'
, 'Facs.'
),


('I155'
, 'NÚMERO DE CLIENTES DOMÉSTICOS'
, 'Dato directo de ACUAMA. USO: domestico'
, 'M'
, 'Contratos activos'
, 'SELECT [VALOR] = COUNT(*) FROM Indicadores.fContratos (@fDesde, @fHasta, @DOMESTICO, NULL)'
, 'Contratos activos con el uso domestico.'
, 'gmdesousa'
, 'Ctrs.'
),


( 'I158'
, 'NÚMERO DE CLIENTES NO DOMÉSTICOS'
, 'Dato directo de ACUAMA, USO: solo industrial'
, 'M'
, '¿Contratos o servicios por contrato?	** CONTRATOS ACTIVOS **'
, 'SELECT [VALOR] = COUNT(*) FROM Indicadores.fContratos (@fDesde, @fHasta, @INDUSTRIAL, NULL)'
, 'Contratos activos con el uso industrial.'
, 'gmdesousa'
, 'Ctrs.'
),

('I145', 
'USUARIOS AGUA RED EN BAJA', 
'Usuarios a los que se les ha leido en el mes en curso. Podria coincidir con I132 ?? ',
'M',
'Mismo dato del I132. Contros por servcio. informe de resumen por conceptos',
'SELECT [VALOR] = SUM(VALOR) FROM Indicadores.fFacturaxSemana (@fDesde, @fHasta, NULL, NULL, NULL, NULL)',
'Total de facturas con fecha de lectura en el mes de consulta'
, 'gmdesousa'
, 'Facs.'
),


('I148', 
'USUARIOS ALCANTARILLADO',
'Cuántos usuarios de los que se han leido en el mes, son de alcantarillado
solicitar a ACUAMA los usuarios por USO ALCANTARILLADO',
'M', 
'Consulta por lineas de factura del servicio de alncantarillado. Servicios por contrato',	
'SELECT [VALOR] = SUM(VALOR) FROM Indicadores.fFacturaxSemana (@fDesde, @fHasta, NULL, NULL, @ALCANTARILLADO, NULL)',
'Total de facturas  con fecha de lectura en el mes de consulta con el servicio de alcantarillado'
, 'gmdesousa'
, 'Facs.'
),

('I132' , 
'NÚMERO TOTAL DE LECTURAS REALIZADAS', 
'Dato directo en ACUAMA los lectores cargan en TPL la ruta y todos las semanas se descaran en ACUAMA',
'M',
'Nº de facturas y prefacturas de las lecturas que se encuentran en el rango de fechas de lectura de la semana anterior a la ejecución de la consulta y con la incidencia de lectura 1 LECTURA NORMAL',
'SELECT [VALOR] = SUM(VALOR) FROM Indicadores.fFacturaxSemana (@fDesde, @fHasta, NULL, NULL, NULL, @LECTURANORMAL)',
'Total de facturas con fecha de lectura en el mes de consulta sin incidencia de lectura (LECTURA NORMAL)'
, 'gmdesousa'
, 'Facs.'
),

('I117' , 
'NÚMERO TOTAL DE QUEJAS / RECLAMACIONES', 
'NOTA: Aquí se anotan las importantes, cuando un abonado te pide el libro de reclamaciones
CONSULTAR: Preguntar si en ACUAMA se pueden distringuir la reclamaciones o quejas por su criticidad o tipologia: importantes o consultas',
'M',
'Grupo reclamación código 11 en Guadalagua. Incidencias Registradas en el mes pasado a la fecha actual. ¿todas las del código 11 o solo las que tienen cumplimentado el campo Nº hoja de reclamaciones? **Grupo RS reclamaciones seguimiento**', 
'SELECT [VALOR] = COUNT(*) FROM Indicadores.fReclamaciones (@fDesde, @fHasta, @RECLAMACION)',
'Numero de reclamaciones por fecha de reclamación'
, 'gmdesousa'
, 'Reclams.'
)


--*************************************
--DELETE FROM Indicadores.IndicadoresConfig WHERE indUsrCod='gmdesousa' AND indAcr IN('I133')

INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad)
VALUES
('I133' , 
'NÚMERO DE LECTURAS ERRÓNEAS', 
'No se sabe si ACUAMA discrimina este tipo de lectura regisrada',
'M',
'Nº de facturas y prefacturas de las lecturas que se encuentran en el rango de fechas de lectura de la semana anterior a la ejecución de la consulta y con la incidencia de lectura distinta de 1 LECTURA NORMAL ** Rectificativas con distinto consumo de agua **',
'SELECT [VALOR] = SUM([VALOR]) FROM Indicadores.fRectificativasxSemana (@fDesde, @fHasta, 1)',
'Facs. rectificativas donde el consumo es diferente al de la rectificada.'
, 'gmdesousa'
, 'Facs.'
)

--*************************************
--DELETE FROM Indicadores.IndicadoresConfig WHERE indUsrCod='gmdesousa' AND indAcr IN('I154', 'I157', 'I160')


INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad)
VALUES
('I154' , 
'AGUA FACTURADA A CLIENTES DOMÉSTICOS', 
'AGUA discriminado por USO tipos de USO: domestico, industrial (no domestico) y municipal dato absoluto de ACUAMA',
'M',
'contratos activos',
'SELECT [VALOR] = SUM(VALOR) FROM Indicadores.fConsumoFacturaxSemana (@fDesde, @fHasta, NULL, NULL, ''@DOMESTICO'') ',
'Consumo total en las facturas de uso domestico'
, 'gmdesousa'
, 'm3'
), 

('I157' , 
'AGUA FACTURADA A CLIENTES NO DOMÉSTICOS', 
'AGUA discriminado por USO: solo industrial dato absoluto de ACUAMA',
'M',
'¿Contratos o servicios por contrato? ** m3 **',
'SELECT [VALOR] = SUM(VALOR) FROM Indicadores.fConsumoFacturaxSemana (@fDesde, @fHasta, NULL, NULL, ''@INDUSTRIAL'') ',
'Consumo total en las facturas de uso industrial'
, 'gmdesousa'
, 'm3'
),

('I160' , 
'AGUA FACTURADA A AYTO. Y ORGANISMOS PÚBLICOS', 
'AGUA discriminado por USO: municipal dato absoluto de ACUAMA',
'M',
'uso municipal',
'SELECT [VALOR] = SUM(VALOR) FROM Indicadores.fConsumoFacturaxSemana (@fDesde, @fHasta, NULL, NULL, ''@MUNICIPAL'') ',
'Consumo total en las facturas de uso municipal'
, 'gmdesousa'
, 'm3'
);


--*************************************
--DELETE FROM Indicadores.IndicadoresConfig WHERE indUsrCod='gmdesousa' AND indAcr IN('I161')

INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad)
VALUES
('I161' , 
'NÚMERO DE CLIENTES AYTO Y ORGANISMOS PÚBLICOS', 
'dato directo de ACUAMA, USO: municipal',
'M',
'¿Contratos o servicios por contrato? **contratos activos / Uso municipal **',
'SELECT [VALOR] = COUNT(*) FROM Indicadores.fContratos (@fDesde, @fHasta, @MUNICIPAL, NULL)',
'Contratos activos con el uso municipal.'
, 'gmdesousa'
, 'Ctrs.'
)



--*************************************
--DELETE FROM Indicadores.IndicadoresConfig WHERE indUsrCod='gmdesousa' AND indAcr IN('I081', 'I085', 'I087', 'I088')


INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad)
VALUES
( 'I081'
, 'AGUA REGISTRADA'
, 'Este indicador en la suma del dato registrado en ACUAMA + agua del municipio (MARCHAMALO) (se obtiene de PCWIN)'
, 'S'
, 'Suma de m3 del servcio de Agua que apareceran en factura y prefactura de las lecturas que se encuentran en el rango de fechas de lectura de la semana anterior a la ejecución de la consulta. ** FACTURA Y PREFACTURA CONSUMO **'
, 'SELECT * FROM Indicadores.fConsumoFacturaxSemana (@fDesde, @fHasta, NULL, NULL, NULL)'
, 'Consumo de todas las facturas/pre-facturas (no-rectificadas)'
, 'gmdesousa'
, 'm3'
),

( 'I085'
, 'AGUA REGISTRADA QUE NO SE FACTURA'
, 'Xej: Ayuntamiento de Guadalajara no se factura, tampoco a usos municipales (jardines)
NOTA: solo se facturaría al Ayto si su consumo superara el 10% del agua que se compra a Mancomunidad. Se facturaría el exceso del 10%
En ACUAMA debe aparecer como AGUAS PARA USOS MUNICIPALES'
, 'S'
, 'Suma de m3 del servcio de Agua de uso Municipal que apareceran en factura y prefactura de las lecturas que se encuentran en el rango de fechas de lectura de la semana anterior a la ejecución de la consulta. ** TARIFA 0 **'
, 'SELECT * FROM Indicadores.fConsumoFacturaxSemana (@fDesde, @fHasta, @AGUA, 0, NULL)'
, 'Consumo de todas las facturas/pre-facturas (no-rectificadas). El consumo de agua tiene precio = 0'
, 'gmdesousa'
, 'm3'
),

( 'I087'
, 'AGUA FACTURADA'
, 'Dato directo de ACUAMA
En principio debería ser una FORMULA: I081-I085, pero no siempre se puede facturar toda el agua registrada'
, 'S'
, 'Agua en factura y prefactura de servicio de Agua con tarifa mayor que 0.'
, 'SELECT * FROM Indicadores.fConsumoFacturaxSemana (@fDesde, @fHasta, @AGUA, 1, NULL)'
, 'Consumo de todas las facturas/pre-facturas (no-rectificadas). El consumo de agua tiene precio <> 0'
, 'gmdesousa'
, 'm3'
),


( 'I088'
, 'AGUA REGISTRADA PARA SANEAMIENTO'
, 'CONCEPTO: Agua para ALCANTARILLADO
NOTA: Es toda el agua REGISTRADA (I081) menos la registrada de contadores para riego de jardines municipales. En ACUAMA debe aparecer como agua regisrada zona de JARDINES
Faltaría añadir el agua de marchamalo (PCWIN)
FORMULA: I081 - AGUA JARDINES + MARCHAMALO'
, 'S'
, 'Agua facturada, para el servicio de alcantarillado.'
, 'SELECT * FROM Indicadores.fConsumoFacturaxSemana (@fDesde, @fHasta, @ALCANTARILLADO, 1, NULL)'
, 'Consumo de todas las facturas/pre-facturas (no-rectificadas). Para facturas con el servicio de ALCANTARILLADO'
, 'gmdesousa'
, 'm3'
);




--*************************************
--DELETE FROM Indicadores.IndicadoresConfig WHERE indUsrCod='gmdesousa' AND indAcr IN('I120', 'I121', 'I122', 'I130')


INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad)
VALUES
( 'I120'
, 'Nº TOTAL CONTADORES INSTALADOS EN BAJA'
, 'Red de baja es la red de ABONADOS'
, 'M'
, 'Total de contadores asociados a contratos con último estado Instalado a fecha menor del día 1 del mes en curso'
, 'SELECT [VALOR] = COUNT(conId) FROM Indicadores.fContadoresInstalados(@fHasta)'
, 'Contadores instalados a la fecha.'
, 'gmdesousa'
, 'Conts.'
),


( 'I121'
, 'NÚMERO DE NUEVAS ALTAS CONTADORES '
, 'Dato directo de ACUAMA'
, 'M'
, 'Contadores instalados en el mes anterior al actual ** y enrutados ver informe de altas **'
, 'SELECT [VALOR]= COUNT(*) FROM dbo.fContadoresxOperacion (''I'', @fDesde, @fHasta)'
, 'Número de contadores por fecha de instalación.'
, 'gmdesousa'
, 'Conts.'
),

( 'I122'
, 'NÚMERO DE NUEVAS BAJAS CONTADORES '
, 'Dato directo de ACUAMA'
, 'M'
, 'Contadores retirados en el mes anterior al actual. ** catastreo informes /informe de baja**'
, 'SELECT [VALOR]= COUNT(*) FROM dbo.fContadoresxOperacion (''R'', @fDesde, @fHasta)'
, 'Número de contadores por fecha de retirada.'
, 'gmdesousa'
, 'Conts.'
),


( 'I130'
, 'EDAD MEDIA DEL PARQUE DE CONTADORES'
, 'dato directo'
, 'M'
, 'Tenemos 1384 contadores con fecha de fabricación a null. ¿usamos la de instalación para estos o para todos? ** ok **'
, 'SELECT [VALOR] = Indicadores.fContadores_EdadMedia (@fHasta)'
, 'Edad media en el registro de contadores por: fecha fabricación || fecha primera instalación || registro de la primera instalacion || fecha de registro del contador '
, 'gmdesousa'
, 'Años'
)






--*************************************
--DELETE FROM Indicadores.IndicadoresConfig WHERE indUsrCod='gmdesousa' AND indAcr IN('I358', 'I359')


INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad)
VALUES
( 'I358'
, 'PENDIENTE DE COBRO (>120 DIAS): USUARIOS (NO ENTIDAD CONTRATANTE)'
, 'USUARIOS (NO ENTIDAD CONTRATANTE) son abonados'
, 'M'
, '¿Contratos o servicios por contrato? contratos'
, 'EXECUTE Indicadores.Facturas_ConDeuda @fHasta, 0.01, 120, ''@INDUSTRIAL'', 2, @INDICADOR OUTPUT'
, 'Contratos de uso industrial con facturas pendientes de cobro cuya fecha de vencimiento supera los 120 días'
, 'gmdesousa'
, 'Ctrs.'
),

( 'I359'
, 'PENDIENTE DE COBRO (>120 DIAS): ENTIDAD CONTRATANTE'
, 'USUARIOS (ENTIENDAD CONTRATANTE) podría ser un constructor que pida nuevas acometidas, (xej)'
, 'M'
, '¿Contratos o servicios por contrato? contratos'
, 'EXECUTE Indicadores.Facturas_ConDeuda @fHasta, 0.01, 120, ''@DOMESTICO'', 2, @INDICADOR OUTPUT' 
, 'Contratos de uso domestico con facturas pendientes de cobro cuya fecha de vencimiento supera los 120 días'
, 'gmdesousa'
, 'Ctrs.'
)


--*************************************
--DELETE FROM Indicadores.IndicadoresConfig WHERE indUsrCod='gmdesousa' AND indAcr IN('I126', 'I131', 'P025')


INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad)
VALUES
( 'I126'
, 'NÚMERO TOTAL DE CONTADORES REPUESTOS'
, 'la OFICINA COMERCIAL genera las Ots de cambio de contador solicitar el dato por tipo de OT: cambio de contador por renovacion solicitar cualquier otra OT registrada en ACUAMA respecto a combio de contador existe algun campo en ACUAMA que discrimine el motivo?'
, 'M'
, 'Confirmar estos tipos de OT:                          
0031	Cambio contador CARGOUSER
0032	Cambio contador con cargo
0034	CAMBIO CONTADOR SIN CARGO
0036	Cambio diámetro contador
120	Cambio Contador Laborator
3	Cambio de Contador
cdia	Cambio diametro y contador
revisar informe cambio de contador
** tecnica informes cambios de contador **'
, 'SELECT [VALOR] = COUNT(*) FROM Indicadores.fContadorCambio (@fDesde, @fHasta)'
, 'Copiamos la select del informe CD008_ListadoCambiosContadores.rdl'
, 'gmdesousa'
, 'Conts.'
),

( 'I131'
, 'NÚMERO TOTAL DE INSPECCIONES DE LECTURA'
, 'INSPECCIONES: numero de veces que se realizan inspecciones en contador de abonado para verificar posibles anomalias en la lectura'
, 'M'
, 'Revisar si son todas estas OT:                                            
0028 	Inspección red abastecimi
0044 	Inspección inst. contador
0046 	Inspección cambio diámetr
0066 	Inspecc visual red saneam
0068 	Inspecc cámara red saneam
0112 	Inspección redes
31 	Inspecc. Cambio Diámetro
AVII 	INSPECCIÓN AVERIAINTERIOR
icm 	inspección con cámara
ION 	INSPECCIÓN OBRA NUEVA                           
** son inspecciones de lectura **'
, 'SELECT [VALOR] = COUNT(*) FROM Indicadores.fFacturasxInspeccion (@fDesde, @fHasta, ''@INSPECCIONES'')'
, 'Facturas con inspección registrada usando la fecha de lectura de la inspección para acotar las facturas'
, 'gmdesousa'
, 'Facs.'
)

--*************************************
--DELETE FROM Indicadores.IndicadoresConfig WHERE indUsrCod='flgarciad' AND indAcr IN('I386', 'N001', 'N002',  'N004', 'N005', 'N006')


INSERT [Indicadores].[IndicadoresConfig] ([indAcr], [indDescripcion], [indAnotaciones], [indPeriodicidad], [indAcuama], [indFuncion], [indFuncionInfo], [indUsrCod], [indUnidad]) VALUES (N'I386', N'SUSPENSIONES DE SERVICIO POR IMPAGO', N'Expedientes de corte con fecha de cierre y de corte.', N'M', N'Expedientes de corte con fecha de cierre y de corte.'
, N'SELECT	[VALOR]= COUNT(*) FROM [Indicadores].[fExpedientesCorte](@fDesde, @fHasta)'
, N'Número de Cortes', N'flgarciad', N'Exps.')

INSERT [Indicadores].[IndicadoresConfig] ([indAcr], [indDescripcion], [indAnotaciones], [indPeriodicidad], [indAcuama], [indFuncion], [indFuncionInfo], [indUsrCod], [indUnidad]) VALUES (N'N001', N'FACTURAS ERRONEAS', N'Facturas rectificativas de cualquier serie.', N'M', N'Facturas rectificativas de cualquier serie.'
, N'SELECT [VALOR] = COUNT(*) FROM [Indicadores].[fFacturasErroneas](@fDesde, @fHasta)'
, N'Número de facturas', N'flgarciad', N'Facs.')

INSERT [Indicadores].[IndicadoresConfig] ([indAcr], [indDescripcion], [indAnotaciones], [indPeriodicidad], [indAcuama], [indFuncion], [indFuncionInfo], [indUsrCod], [indUnidad]) VALUES (N'N002', N'NUMERO USUARIOS OFICINA VIRTUAL', N'Usuarios de la oficina virtual con contrato activo', N'M', N'Usuarios de la oficina virtual con contrato activo.'
, N'SELECT [VALOR] = COUNT(*) FROM [Indicadores].[fUsuariosActivosOV](@fDesde, @fHasta)'
, N'Número de usuarios', N'flgarciad', N'Usrs.')

INSERT [Indicadores].[IndicadoresConfig] ([indAcr], [indDescripcion], [indAnotaciones], [indPeriodicidad], [indAcuama], [indFuncion], [indFuncionInfo], [indUsrCod], [indUnidad]) VALUES (N'N004', N'DEVOLUCIONES BANCARIAS', N'Devoluciones bancarias a fecha de cobro en el rango de fechas', N'M', N'Devoluciones bancarias a fecha de cobro en el rango de fechas'
, N'SELECT [VALOR] = COUNT(*) FROM [Indicadores].[fDevolucionesBancarias](@fDesde, @fHasta)'
, N'Numero de devoluciones', N'flgarciad', N'Devs.')

INSERT [Indicadores].[IndicadoresConfig] ([indAcr], [indDescripcion], [indAnotaciones], [indPeriodicidad], [indAcuama], [indFuncion], [indFuncionInfo], [indUsrCod], [indUnidad]) VALUES (N'N006', N'Nº DE CONTRATOS POSIBLES CORTES', N'Contratos que aparecen en expediente de corte sin fecha  de ejecución y no cerrados', N'M', N'Contratos que aparecen en expediente de corte sin fecha  de ejecución y no cerrados'
, N'SELECT [VALOR] = COUNT(*) FROM [Indicadores].[fPosiblesCortes](@fDesde, @fHasta)'
, N'Numero de expedientes', N'flgarciad', N'Exps.')




--****************************************************
--DELETE FROM Indicadores.IndicadoresConfig WHERE indAcr IN('N003')

INSERT [Indicadores].[IndicadoresConfig] ([indAcr], [indDescripcion], [indAnotaciones], [indPeriodicidad], [indAcuama], [indFuncion], [indFuncionInfo], [indUsrCod], [indUnidad]) VALUES (
N'N003'
, N'TIEMPO MEDIO RESPUESTA RECLAMACIONES'
, N''
, N'M'
, N'Dias que permanecen abiertas gestiones del grupo RS Reclamaciones,dividido entre el numero de gestiones para todas las gestiones ceradas hace un año respecto al mes anterior del actual.'
, N'DECLARE @IND_SUM NUMERIC(14,4), @IND_AVG NUMERIC(14,4), @IND_PREV NUMERIC(14,4);  
	SELECT @IND_SUM = ISNULL(SUM(dRespuesta), 0), @IND_AVG = ISNULL(AVG(dRespuesta), 0) FROM [Indicadores].[fRespuestasReclamaciones](@fDesde, @fHasta, @RECLAMACION) WHERE rclFecCierre IS NOT NULL;
	SELECT @IND_PREV = ISNULL(SUM(dRespuesta), 0) FROM [Indicadores].[fRespuestasReclamaciones](@fDesdeAnt, @fHastaAnt, @RECLAMACION) WHERE rclFecCierre IS NOT NULL;	
	SET  @INDICADOR = IIF(@IND_PREV=0, @IND_AVG, CAST(@IND_SUM/@IND_PREV AS  NUMERIC(14,4)));'
, N'Media días'
, N'gmdesousa'
, N'Días')



