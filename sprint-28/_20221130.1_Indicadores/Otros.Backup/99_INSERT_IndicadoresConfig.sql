INSERT [Indicadores].[IndicadoresConfig] ([indAcr], [indDescripcion], [indAnotaciones], [indPeriodicidad], [indUnidad], [indAcuama], [indFuncion], [indFuncionInfo], [indUsrCod], [indActivo]) VALUES 

 (N'I081'
, N'AGUA REGISTRADA'
, N'Este indicador en la suma del dato registrado en ACUAMA + agua del municipio (MARCHAMALO) (se obtiene de PCWIN)'
, N'S'
, N'm3'
, N'Suma de m3 del servcio de Agua que apareceran en factura y prefactura de las lecturas que se encuentran en el rango de fechas de lectura de la semana anterior a la ejecución de la consulta. ** FACTURA Y PREFACTURA CONSUMO **'
, N'SELECT * FROM Indicadores.fConsumoFacturaxSemana (@fDesde, @fHasta, NULL, NULL, NULL)'
, N'Totalización del consumo de todas las facturas/prefacturas (no-rectificadas)'
, N'gmdesousa'
, 1), 

 (N'I085'
, N'AGUA REGISTRADA QUE NO SE FACTURA'
, N'Xej: Ayuntamiento de Guadalajara no se factura, tampoco a usos municipales (jardines)
NOTA: solo se facturaría al Ayto si su consumo superara el 10% del agua que se compra a Mancomunidad. Se facturaría el exceso del 10%
En ACUAMA debe aparecer como AGUAS PARA USOS MUNICIPALES'
, N'S'
, N'm3'
, N'Suma de m3 del servcio de Agua de uso Municipal que apareceran en factura y prefactura de las lecturas que se encuentran en el rango de fechas de lectura de la semana anterior a la ejecución de la consulta. ** TARIFA 0 **'
, N'SELECT * FROM Indicadores.fConsumoFacturaxSemana (@fDesde, @fHasta, @AGUA, 0, NULL)'
, N'Totalización del consumo de todas las facturas/prefacturas (no-rectificadas) donde el consumo del agua tiene precio 0.'
, N'gmdesousa'
, 1)
