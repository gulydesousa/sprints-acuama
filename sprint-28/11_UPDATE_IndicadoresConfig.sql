--*******************************
-- indPeriodicidad:
-- S: Semanal  => Los datos vienen agrupados por numero de semana
-- F: Función => El resultado de la función se saca siempre, no depende de la fecha de solicitud.
-- M: Mensual => El resultado de la función se saca solo si la fecha limite de la consulta por semanas incluye el último día del mes.
-- A: Anual   => El resultado de la función se saca solo si la fecha limite de la consulta por semanas incluye el último día del mes, las fechas de consulta son a 12 meses.

--****** P A R A M E T R O S *******
-- @aFecha: Fecha de solicitud del informe

--****** ******************* *******

--*******************************
--[1] fUltimoConsumoContrato
--********************************

DELETE Indicadores.IndicadoresConfig WHERE indAcr='I081';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
( 'I081'
, 'AGUA REGISTRADA'
, 'Este indicador en la suma del dato registrado en ACUAMA + agua del municipio (MARCHAMALO) (se obtiene de PCWIN)'
, 'F'
, 'Suma de m3 del servcio de Agua que apareceran en factura y prefactura de las lecturas que se encuentran en el rango de fechas de lectura de la semana anterior a la ejecución de la consulta. ** FACTURA Y PREFACTURA CONSUMO **'
, 'SELECT [aFecha]= @aFecha, [Value]= SUM(facConsumoFactura) FROM Indicadores.fUltimoConsumoContrato(@aFecha, @AGUA)'
, 'El ultimo consumo de cada contrato a la fecha de petición del informe. 
 Seleccionamos los contratos activos a la fecha de consulta.
 De estos contratos, seleccionamos las factura ó prefactura con servicio de AGUA no rectificadas y fecha de registro hasta la fecha de consulta.
 Seleccionamos para cada contrato la factura mas reciente (con mayor fecha de registro) 
 y Totalizamos esos consumos.'
, 'gmdesousa'
, 'm3'
, 1)

DELETE Indicadores.IndicadoresConfig WHERE indAcr='I085';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
( 'I085'
, 'AGUA REGISTRADA QUE NO SE FACTURA'
, 'Xej: Ayuntamiento de Guadalajara no se factura, tampoco a usos municipales (jardines)
NOTA: solo se facturaría al Ayto si su consumo superara el 10% del agua que se compra a Mancomunidad. Se facturaría el exceso del 10%
En ACUAMA debe aparecer como AGUAS PARA USOS MUNICIPALES'
, 'F'
, 'Suma de m3 del servcio de Agua de uso Municipal que apareceran en factura y prefactura de las lecturas que se encuentran en el rango de fechas de lectura de la semana anterior a la ejecución de la consulta. ** TARIFA 0 **'
, 'SELECT [aFecha]= @aFecha, [Value]= SUM(facConsumoFactura) FROM Indicadores.fUltimoConsumoContrato(@aFecha, @AGUA) WHERE esFacturada IS NOT NULL AND esFacturada=0'
, 'El ultimo consumo de cada contrato a la fecha de petición del informe.
 Seleccionamos los contratos activos a la fecha de consulta.
 De estos contratos, seleccionamos las factura ó prefactura con servicio de AGUA no rectificadas y fecha de registro hasta la fecha de consulta.
 Seleccionamos para cada contrato la factura mas reciente (con mayor fecha de registro) 
 Nos quedamos con las lineas en las que todas sus bloques tienen precio 0
 y Totalizamos esos consumos.'
, 'gmdesousa'
, 'm3'
, 1)

DELETE Indicadores.IndicadoresConfig WHERE indAcr='I087';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
( 'I087'
, 'AGUA FACTURADA'
, 'Dato directo de ACUAMA
En principio debería ser una FORMULA: I081-I085, pero no siempre se puede facturar toda el agua registrada'
, 'F'
, 'Agua en factura y prefactura de servicio de Agua con tarifa mayor que 0.'
, 'SELECT [aFecha]= @aFecha, [Value]= SUM(facConsumoFactura) FROM Indicadores.fUltimoConsumoContrato(@aFecha, @AGUA) WHERE esFacturada IS NOT NULL AND esFacturada=1'
, 'El ultimo consumo de cada contrato a la fecha de petición del informe.
 Seleccionamos los contratos activos a la fecha de consulta.
 De estos contratos, seleccionamos las factura ó prefactura con servicio de AGUA no rectificadas y fecha de registro hasta la fecha de consulta.
 Seleccionamos para cada contrato la factura mas reciente (con mayor fecha de registro) 
 Nos quedamos con las lineas en las que alguno de sus bloques tienen precio distinto de 0
 y Totalizamos esos consumos.'
, 'gmdesousa'
, 'm3'
, 1)

DELETE Indicadores.IndicadoresConfig WHERE indAcr='I088';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
( 'I088'
, 'AGUA REGISTRADA PARA SANEAMIENTO'
, 'CONCEPTO: Agua para ALCANTARILLADO
NOTA: Es toda el agua REGISTRADA (I081) menos la registrada de contadores para riego de jardines municipales. En ACUAMA debe aparecer como agua regisrada zona de JARDINES
Faltaría añadir el agua de marchamalo (PCWIN)
FORMULA: I081 - AGUA JARDINES + MARCHAMALO'
, 'F'
, 'Agua facturada, para el servicio de alcantarillado.'
, 'SELECT [aFecha]= @aFecha, [Value]= SUM(facConsumoFactura) FROM Indicadores.fUltimoConsumoContrato(@aFecha, @ALCANTARILLADO)'
, 'El ultimo consumo de cada contrato a la fecha de petición del informe.
 Seleccionamos los contratos activos a la fecha de consulta.
 De estos contratos, seleccionamos las factura ó prefactura con servicio de ALCANTARILLADO no rectificadas y fecha de registro hasta la fecha de consulta.
 Seleccionamos para cada contrato la factura mas reciente (con mayor fecha de registro) 
 y Totalizamos esos consumos.'
, 'gmdesousa'
, 'm3'
, 1);


--*******************************
--[2] fContratos
--********************************
DELETE Indicadores.IndicadoresConfig WHERE indAcr='I116';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
('I116'
, 'NÚMERO TOTAL DE CLIENTES'
, 'IMPORTANTE: PEL es una ventana temporal con la posibilidad de elegir el dia de inicio. A ACUAMA solicitar dato absoluto de NUMERO TOTAL DE CLIENTES regisrados Con la ventana temporal elegida en IDBOX se calculará el acumulado en dicho intervalo'
, 'M'
, '¿Número de servicios por contrato, clientes, o contratos?. Contratos Activos'	
, 'SELECT [VALOR] = COUNT(*) FROM Indicadores.fContratos (@fDesde, @fHasta, NULL, NULL) WHERE ctssrv IS NOT NULL'
, 'Busca la ultima versión del contrato activa en el rango de consulta (mensual) que tiene el servicio de agua vigente en ese mismo rango de fechas.'
, 'gmdesousa'
, 'Ctrs.'
, 1);


--*******************************
--[3] fReclamaciones
--********************************
DELETE Indicadores.IndicadoresConfig WHERE indAcr='I117';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
('I117' , 
'NÚMERO TOTAL DE QUEJAS / RECLAMACIONES', 
'NOTA: Aquí se anotan las importantes, cuando un abonado te pide el libro de reclamaciones
CONSULTAR: Preguntar si en ACUAMA se pueden distringuir la reclamaciones o quejas por su criticidad o tipologia: importantes o consultas',
'M',
'Grupo reclamación código 11 en Guadalagua. Incidencias Registradas en el mes pasado a la fecha actual. ¿todas las del código 11 o solo las que tienen cumplimentado el campo Nº hoja de reclamaciones? **Grupo RS reclamaciones seguimiento**', 
'SELECT [VALOR] = COUNT(*) FROM Indicadores.fReclamaciones (@fDesde, @fHasta, @RECLAMACION)',
'Numero de reclamaciones por fecha de reclamación del grupo de reclamacion RS'
, 'gmdesousa'
, 'Reclams.'
, 1)


--*******************************
--[4] fContratos_ContadoresInstalados
--********************************
DELETE Indicadores.IndicadoresConfig WHERE indAcr='I120';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
( 'I120'
, 'Nº TOTAL CONTADORES INSTALADOS EN BAJA'
, 'Red de baja es la red de ABONADOS'
, 'M'
, 'Total de contadores asociados a contratos con último estado Instalado a fecha menor del día 1 del mes en curso'
, 'SELECT [VALOR] = COUNT(conNumSerie) FROM dbo.fContratos_ContadoresInstalados(@fHasta) WHERE ctcCon IS NOT NULL'
, 'Se totalizan los contadores instalados a la fecha según el cálculo en (CD014_ListadoContadoresInstalados): Acuama/Técnica/Informes/Contadores Instalados.'
, 'gmdesousa'
, 'Conts.'
, 1)

--*******************************
--[5] fCtrAltasBajas
--********************************
DELETE Indicadores.IndicadoresConfig WHERE indAcr='I121';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
( 'I121'
, 'NÚMERO DE NUEVAS ALTAS CONTADORES '
, 'Dato directo de ACUAMA'
, 'M'
, 'Contadores instalados en el mes anterior al actual ** y enrutados ver informe de altas **'
, 'SELECT [VALOR]= COUNT(*) FROM  dbo.fCtrAltasBajas (@fDesde, @fHasta, ''A'', 1)'
, 'Se totalizan las ALTAS a la fecha según el cálculo en (CC034_CtrAltasBajas):  Acuama/Catastro/Informes/Altas y Bajas
Incluimos la opción para sacar las ALTAS por cambio de titular.
Se contablilizan como ALTAS, los contratos donde la ""fecha de contrato"" está en el rango de fechas que no esté dado de baja en ese mismo rango de fechas. 
NO se excluyen las ALTAS por Cambio de Titular. 
Se entiende por Alta por Cambio de Titular los contratos que aparecen como Contrato Nuevo en otro contrato dado de baja.'
, 'gmdesousa'
, 'Conts.'
, 1)


DELETE Indicadores.IndicadoresConfig WHERE indAcr='I122';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
( 'I122'
, 'NÚMERO DE NUEVAS BAJAS CONTADORES '
, 'Dato directo de ACUAMA'
, 'M'
, 'Contadores retirados en el mes anterior al actual. ** catastreo informes /informe de baja**'
, 'SELECT [VALOR]= COUNT(*) FROM  dbo.fCtrAltasBajas (@fDesde, @fHasta, ''B'', 1)'
, 'Bajas de contratos (Sin cambio de titular): CC034_CtrAltasBajas.'
, 'gmdesousa'
, 'Conts.'
,  1)

--*******************************
--[2] fContratos
--********************************
DELETE Indicadores.IndicadoresConfig WHERE indAcr='I123';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
('I123'
, 'NÚMERO CLIENTES DOMICILIADOS'
, 'Quiénes de ellos tienen domiciliado el pago'
, 'M'
, '¿Contratos Domiciliados o clientes? (Un cliente puede tener varios contratos)'
, 'SELECT [VALOR] = COUNT(DISTINCT ctrCod) FROM Indicadores.fContratos (@fDesde, @fHasta, NULL, 1)'
, 'Contratos dónde la ultima versión en el rango de fechas tiene IBAN asociado.'
, 'gmdesousa'
, 'Ctrs.'
, 1)

--*******************************
--[6] fContadorCambioxMes
--********************************
DELETE Indicadores.IndicadoresConfig WHERE indAcr='I126';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
('I126'
, 'NÚMERO TOTAL DE CONTADORES REPUESTOS (12 meses)'
, 'Creo que afecta cuando se introduzcan las Ots de cambio de contadores en Acu@ma, y por tanto, este dato debería sacarse de un año entero, mensualmente y así se iría "corrigiendo", por posibles retrasos en la cumplimentación de las Ots.'
, 'A'
, 'Confirmar estos tipos de OT: 0031 Cambio contador CARGOUSER  0032 Cambio contador con cargo  0034 CAMBIO CONTADOR SIN CARGO  0036 Cambio diámetro contador  120 Cambio Contador Laborator  3 Cambio de Contador  cdia Cambio diametro y contador  revisar informe cambio de contador  ** tecnica informes cambios de contador **'
, 'SELECT [FechaMes]=[Date], [Value] FROM Indicadores.fContadorCambioxMes (@aDesde, @aHasta)'
, 'Copiamos la select del informe (CD008_ListadoCambiosContadores.rdl): Acuama/Tecnica/Informes/Cambio de contadores.
   Sacamos los cambios de contador para un año y totalizamos agrupado por mes.'
, 'gmdesousa'
, 'Conts.'
, 1)


--*******************************
--[6] fContadores_EdadMedia
--********************************
DELETE Indicadores.IndicadoresConfig WHERE indAcr='I130';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
( 'I130'
, 'EDAD MEDIA DEL PARQUE DE CONTADORES'
, 'dato directo'
, 'M'
, 'Tenemos 1384 contadores con fecha de fabricación a null. ¿usamos la de instalación para estos o para todos? ** ok **'
, 'SELECT [VALOR] = Indicadores.fContadores_EdadMedia (@fHasta)'
, 'Calcula la edad de todos los contadores registrados a la fecha y retorna el promedio.
 Edad media en el registro de contadores se calcula  a partir de la fecha de fabricación, pero si este dato no existe vemos en este orden cual sí esta informado para calcular la edad.
 1. fecha fabricación 
 2. fecha primera instalación 
 3. registro de la primera instalacion 
 4. fecha de registro del contador'
, 'gmdesousa'
, 'Años'
, 1)

--*******************************
--[7] fFacturasxInspeccion
--********************************
DELETE Indicadores.IndicadoresConfig WHERE indAcr='I131';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
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
, 'Facturas con fecha de lectura del inspector en el rango de consulta y que tiene un tipo de inspección asociado. '
, 'gmdesousa'
, 'Facs.'
, 1)

--*******************************
--[8] fIncidenciasLecturaxSemana
--********************************
DELETE Indicadores.IndicadoresConfig WHERE indAcr='I132';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
('I132' , 
'NÚMERO TOTAL DE LECTURAS REALIZADAS', 
'Dato directo en ACUAMA los lectores cargan en TPL la ruta y todos las semanas se descaran en ACUAMA',
'M',
'Nº de facturas y prefacturas de las lecturas que se encuentran en el rango de fechas de lectura de la semana anterior a la ejecución de la consulta y con la incidencia de lectura 1 LECTURA NORMAL',
'SELECT [VALOR] = SUM(VALOR) FROM Indicadores.fIncidenciasLecturaxSemana (@fDesde, @fHasta, @LECTURANORMAL)',
'Se usa la fecha de lectura actual  para acotar las facturas y prefacturas no rectificadas con incidencia de lectura solicitadas (ver imagen).'
, 'gmdesousa'
, 'Facs.'
, 1)


--*******************************
--[9] fRectificativasxSemana
--********************************
DELETE Indicadores.IndicadoresConfig WHERE indAcr='I133';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
('I133' , 
'NÚMERO DE LECTURAS ERRÓNEAS', 
'No se sabe si ACUAMA discrimina este tipo de lectura regisrada',
'M',
'Nº de facturas y prefacturas de las lecturas que se encuentran en el rango de fechas de lectura de la semana anterior a la ejecución de la consulta y con la incidencia de lectura distinta de 1 LECTURA NORMAL ** Rectificativas con distinto consumo de agua **',
'SELECT [VALOR] = SUM([VALOR]) FROM Indicadores.fRectificativasxSemana (@fDesde, @fHasta, 1)',
'Se usa la FECHA DE LECTURA ACTUAL para acotar las facturas RECTIFICATIVAS no rectificadas dentro del periodo de consulta. 
Se cuentan solo las facturas donde el consumo de estas rectificativas es diferente al de la rectificada asociada.'
, 'gmdesousa'
, 'Facs.'
, 1)


--*******************************
--[10] fUsuariosServicioxSemana
--********************************
DELETE Indicadores.IndicadoresConfig WHERE indAcr='I145';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
('I145', 
'USUARIOS AGUA RED EN BAJA', 
'Usuarios a los que se les ha leido en el mes en curso. Podria coincidir con I132 ?? ',
'M',
'Mismo dato del I132. Contros por servcio. informe de resumen por conceptos',
'SELECT [VALOR] = SUM([VALOR]) FROM Indicadores.fUsuariosServicioxSemana(@fDesde, @fHasta, ''1'')',
'Hacemos el cálculo como lo hace el informe 
 Facturación/Informes/Relación Conceptos (Consolidado por zonas)
 CF012_InfFacConSinZona
 Seleccionamos las FACTURAS NO RECTIFICADAS por fecha de la factura.
 Resultado:
 FACTURAS que tienen el servicio(*) (1)Agua +
 UNIDADES DE LAS FACTURAS que tienen el servicio(*) (23)T.Fijo Agua Cdad.(**)
 (*)no liquidado en el rango de fechas
 (**)excepto el periodo 000001'
, 'gmdesousa'
, 'Usr.'
, 1)

DELETE Indicadores.IndicadoresConfig WHERE indAcr='I148';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
('I148', 
'USUARIOS ALCANTARILLADO',
'Cuántos usuarios de los que se han leido en el mes, son de alcantarillado
solicitar a ACUAMA los usuarios por USO ALCANTARILLADO',
'M', 
'Consulta por lineas de factura del servicio de alncantarillado. Servicios por contrato',	
'SELECT [VALOR] = SUM([VALOR]) FROM Indicadores.fUsuariosServicioxSemana(@fDesde, @fHasta, ''3'')',
'Hacemos el cálculo como lo hace el informe 
 Facturación/Informes/Relación Conceptos (Consolidado por zonas)
 CF012_InfFacConSinZona
 Seleccionamos las FACTURAS NO RECTIFICADAS por fecha de la factura.
 Resultado:
 FACTURAS que tienen el servicio(*) (3)Alcantarillado +  
 UNIDADES  que tienen el servicio(*) (24)T.Fijo Alcant. Cdad. (**)
 (*)no liquidado en el rango de fechas
 (**)excepto el periodo 000001'
, 'gmdesousa'
, 'Usr.'
, 1)

--*******************************
--[11] fFacturasRangoCnsxSemana
--********************************
DELETE Indicadores.IndicadoresConfig WHERE indAcr='I150';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
( 'I150'
, 'NÚMERO DE CLIENTES CON CONSUMO 0 M3'
, 'Aprovechar las descargas de los TPLs y registrar cada vez que se toman las lecturas de campo
pedir a ACUAMA que en cada exportacion, nos de el valor absoluto del dato solicitado'
, 'S'
, 'Servicios por contrato con valor 0.'
, 'SELECT * FROM Indicadores.fFacturasRangoCnsxSemana (@fDesde, @fHasta, 0, 0)'
, 'Se usa la fecha de lectura  para acotar las facturas y prefacturas no rectificadas  cuyo consumo es igual a 0'
, 'gmdesousa'
, 'Facs.'
, 1)

DELETE Indicadores.IndicadoresConfig WHERE indAcr='I152';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
( 'I152'
, 'NÚMERO DE CLIENTES CON (0 < CONSUMO M3 < 2)'
, 'select'
, 'S'
, 'Servicios por contrato en el rango.'
, 'SELECT * FROM Indicadores.fFacturasRangoCnsxSemana (@fDesde, @fHasta, 1, 1)'
, 'Se usa la fecha de lectura  para acotar las facturas y prefacturas no rectificadas  cuyo consumo es igual a 1. El consumo es un número entero.'
, 'gmdesousa'
, 'Facs.'
, 1)

--*******************************
--[12] fAguaFacturadaxSemana
--********************************
DELETE Indicadores.IndicadoresConfig WHERE indAcr='I154';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
('I154' , 
'AGUA FACTURADA A CLIENTES DOMÉSTICOS', 
'AGUA discriminado por USO tipos de USO: domestico, industrial (no domestico) y municipal dato absoluto de ACUAMA',
'M',
'contratos activos',
'SELECT [VALOR] = SUM(VALOR) FROM Indicadores.fAguaFacturadaxSemana (@fDesde, @fHasta, ''@DOMESTICO'') ',
'Consumo total en las facturas de uso domestico'
, 'gmdesousa'
, 'm3'
, 1)

--*******************************
--[13] fContratosAgua
--********************************
DELETE Indicadores.IndicadoresConfig WHERE indAcr='I155';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
('I155'
, 'NÚMERO DE CLIENTES DOMÉSTICOS'
, 'Dato directo de ACUAMA. USO: domestico'
, 'M'
, 'Contratos activos'
, 'SELECT [VALOR] = COUNT(*) FROM [Indicadores].[fContratosAgua](@fDesde, @fHasta, ''@DOMESTICO'')'
, 'Contratos dónde la ultima versión activa en el rango de fechas con el servicio de agua activo en el mismo rango de fechas y USO DOMESTICO.'
, 'gmdesousa'
, 'Ctrs.'
, 1)

--*******************************
--[12] fAguaFacturadaxSemana
--********************************
DELETE Indicadores.IndicadoresConfig WHERE indAcr='I157';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
('I157' , 
'AGUA FACTURADA A CLIENTES NO DOMÉSTICOS', 
'AGUA discriminado por USO: solo industrial dato absoluto de ACUAMA',
'M',
'¿Contratos o servicios por contrato? ** m3 **',
'SELECT [VALOR] = SUM(VALOR) FROM Indicadores.fAguaFacturadaxSemana (@fDesde, @fHasta, @NODOMESTICO)  ',
'Se usa la fecha de lectura  para acotar las facturas y prefacturas no rectificadas en el rango de fechas en consulta y que además tienen  el servicio de agua facturado.
Se totalizan solo los consumos de las facturas de Uso Industrial, Movil y ContraIncendios.'
, 'gmdesousa'
, 'm3'
, 1)

--*******************************
--[13] fContratosAgua
--********************************
DELETE Indicadores.IndicadoresConfig WHERE indAcr='I158';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
( 'I158'
, 'NÚMERO DE CLIENTES NO DOMÉSTICOS'
, 'Dato directo de ACUAMA, USO: solo industrial'
, 'M'
, '¿Contratos o servicios por contrato?	** CONTRATOS ACTIVOS **'
, 'SELECT [VALOR] = COUNT(*) FROM [Indicadores].[fContratosAgua](@fDesde, @fHasta, @NODOMESTICO)'
, 'Contratos dónde la ultima versión activa en el rango de fechas con el servicio de agua activo en el mismo rango de fechas y Uso Industrial, Movil y ContraIncendios.'
, 'gmdesousa'
, 'Ctrs.'
, 1)

--*******************************
--[12] fAguaFacturadaxSemana
--********************************
DELETE Indicadores.IndicadoresConfig WHERE indAcr='I160';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
('I160' , 
'AGUA FACTURADA A AYTO. Y ORGANISMOS PÚBLICOS', 
'AGUA discriminado por USO: municipal dato absoluto de ACUAMA',
'M',
'uso municipal',
'SELECT [VALOR] = SUM(VALOR) FROM Indicadores.fAguaFacturadaxSemana (@fDesde, @fHasta, ''@MUNICIPAL'') ',
'Se usa la fecha de lectura  para acotar las facturas y prefacturas no rectificadas en el rango de fechas en consulta y que además tienen  el servicio de agua facturado.
 Se totalizan solo los consumos de las facturas de Uso Municipal.'
, 'gmdesousa'
, 'm3'
, 1)

--*******************************
--[13] fContratosAgua
--********************************
DELETE Indicadores.IndicadoresConfig WHERE indAcr='I161';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
('I161' , 
'NÚMERO DE CLIENTES AYTO Y ORGANISMOS PÚBLICOS', 
'dato directo de ACUAMA, USO: municipal',
'M',
'¿Contratos o servicios por contrato? **contratos activos / Uso municipal **',
'SELECT [VALOR] = COUNT(*) FROM [Indicadores].[fContratosAgua](@fDesde, @fHasta, @MUNICIPAL)',
'Contratos dónde la ultima versión activa en el rango de fechas con el servicio de agua activo en el mismo rango de fechas y USO MUNICIPAL.'
, 'gmdesousa'
, 'Ctrs.'
, 1)

--*******************************
--[14] Facturas_ConDeuda
--********************************
DELETE Indicadores.IndicadoresConfig WHERE indAcr='I358';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
( 'I358'
, 'PENDIENTE DE COBRO (>120 DIAS): USUARIOS (NO ENTIDAD CONTRATANTE)'
, 'USUARIOS (NO ENTIDAD CONTRATANTE) son abonados'
, 'M'
, '¿Contratos o servicios por contrato? contratos'
, 'EXECUTE Indicadores.Facturas_ConDeuda @fHasta, 0.01, 120, @NOMUNICIPAL, NULL, 3, @INDICADOR OUTPUT'
, 'TOTAL DEUDA en facturas de contratos con uso NO-MUNICIPAL cuya fecha de vencimiento supera los 120 días.
  Seleccionamos la última version de las facturas:
  - De todos los periodos
  - Creadas hasta la fecha  de consulta 
  - No rectificadas a la fecha de consulta
  - Con uso NO-MUNICIPAL (1, 2, 4, 5, 6)
  Totalizamos la facturas sumando las lineas no liquidadas a la fecha de consulta.
  Calculamos el total de los cobros de estas facturas: Para cada cobro sumamos el desglose de las lineas de cobros. 
  Seleccionamos las facturas con deuda cuya fecha de vencimiento supera los 120 días'
, 'gmdesousa'
, '€'
, 1)

DELETE Indicadores.IndicadoresConfig WHERE indAcr='I359';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
( 'I359'
, 'PENDIENTE DE COBRO (>120 DIAS): ENTIDAD CONTRATANTE'
, 'USUARIOS (ENTIENDAD CONTRATANTE) podría ser un constructor que pida nuevas acometidas, (xej)'
, 'M'
, '¿Contratos o servicios por contrato? contratos'
, 'EXECUTE Indicadores.Facturas_ConDeuda @fHasta, 0.01, 120, @MUNICIPAL, NULL, 3, @INDICADOR OUTPUT' 
, 'TOTAL DEUDA en facturas de contratos con uso NO-MUNICIPAL cuya fecha de vencimiento supera los 120 días.
Seleccionamos la última version de las facturas:
- De todos los periodos
- Creadas hasta la fecha  de consulta 
- No rectificadas a la fecha de consulta
- Con uso MUNICIPAL (3)
Totalizamos la facturas sumando las lineas no liquidadas a la fecha de consulta.
Calculamos el total de los cobros de estas facturas: Para cada cobro sumamos el desglose de las lineas de cobros. 
Seleccionamos las facturas con deuda cuya fecha de vencimiento supera los 120 días'
, 'gmdesousa'
, '€'
, 1)


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
, 'SELECT [VALOR]= COUNT(*) FROM [Indicadores].[fExpedientesCorte](@fDesde, @fHasta, ''1,100'')'
, 'Numero de expedientes de corte por tipo de expediente de corte(1, 100)
 Se usa la fecha OT para acotar la seleccion de expedientes.
 Usamos la consulta del formulario
 Cobros/Expendientes Corte/Expedientes de corte
 Por tipo de expediente de corte 
 1-EXP CORTE POR SUSPENSIÓN DE SUMINISTRO 
 100- EXP.CORTE SUSP.SUMINISTRO INDUSTRIALES'
, 'flgarciad'
, 'Exps.'
, 1)

--*******************************
--[16] fFacturasErroneas
--********************************
DELETE Indicadores.IndicadoresConfig WHERE indAcr='N001';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
('N001'
, 'FACTURAS ERRONEAS'
, 'Facturas rectificativas de cualquier serie.'
, 'M'
, 'Facturas rectificativas de cualquier serie.'
, 'SELECT [VALOR] = COUNT(*) FROM [Indicadores].[fFacturasErroneas](@fDesde, @fHasta)'
, 'Se usa la fecha de factura para acotar las facturas rectificativas de cualquier serie.'
, 'flgarciad'
, 'Facs.'
, 1)


--*******************************
--[17] fUsuariosActivosOV
--********************************
DELETE Indicadores.IndicadoresConfig WHERE indAcr='N002';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
('N002'
, 'NUMERO USUARIOS OFICINA VIRTUAL'
, 'Usuarios de la oficina virtual con contrato activo'
, 'M'
, 'Usuarios de la oficina virtual con contrato activo.'
, 'SELECT [VALOR] = COUNT(*) FROM [Indicadores].[fUsuariosActivosOV](@fDesde, @fHasta)'
, 'Se recuperan los  DNI de titular y pagador de contratos activos en el rango de fechas en consulta, luego  contamos los DNI que aparecen registrados como usuarios de la OV.'
, 'flgarciad'
, 'Usrs.'
, 1)



--*******************************
--[18] fMediaRespuestasReclamaciones
--********************************
DELETE Indicadores.IndicadoresConfig WHERE indAcr='N003';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
('N003'
, 'TIEMPO MEDIO RESPUESTA RECLAMACIONES'
, ''
, 'M'
, 'Dias que permanecen abiertas gestiones del grupo RS Reclamaciones,dividido entre el numero de gestiones para todas las gestiones ceradas hace un año respecto al mes anterior del actual.'
, 'SELECT [VALOR] = COUNT(*) FROM [Indicadores].[fMediaRespuestasReclamaciones](@aDesde, @aHasta,  @RECLAMACION)'
, 'Media días'
, 'gmdesousa'
, 'Días'
, 1)

--*******************************
--[19] fDevolucionesBancarias
--********************************
DELETE Indicadores.IndicadoresConfig WHERE indAcr='N004';
INSERT INTO Indicadores.IndicadoresConfig (indAcr, indDescripcion, indAnotaciones, indPeriodicidad, indAcuama, indFuncion, indFuncionInfo, indUsrCod, indUnidad, indActivo) VALUES
('N004'
, 'DEVOLUCIONES BANCARIAS'
, 'Devoluciones bancarias a fecha de cobro en el rango de fechas'
, 'M'
, 'Devoluciones bancarias a fecha de cobro en el rango de fechas'
, 'SELECT [VALOR] = COUNT(*) FROM [Indicadores].[fDevolucionesBancarias](@fDesde, @fHasta)'
, 'Numero de devoluciones'
, 'flgarciad'
, 'Devs.'
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
, 'SELECT [VALOR] = COUNT(*) FROM [Indicadores].[fPosiblesCortes](@fDesde, @fHasta)'
, 'Usamos la consulta del formulario
Cobros/Expendientes Corte/Expedientes de corte
Se usa la de registro del expediente  para acotar la seleccion de expedientes.
Por tipo de expediente de corte 
1 - EXP CORTE POR SUSPENSIÓN DE SUMINISTRO 
100 -  EXP.CORTE SUSP.SUMINISTRO INDUSTRIALES
Sin fecha de cierre (excFechaCierreExp)'
, 'flgarciad'
, 'Exps.'
, 1)


--SELECT * FROM Indicadores.IndicadoresConfig
--UPDATE Indicadores.IndicadoresConfig SET indActivo=0;