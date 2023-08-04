--Tabla para detallar las caracteristicas de cada evolutivo
CREATE TABLE Trabajo.FAC_APERTURA
( fcaVersion VARCHAR(10) NOT NULL PRIMARY KEY
, fcaDescripcion VARCHAR(250) NOT NULL)

/*

INSERT INTO Trabajo.FAC_APERTURA VALUES
('1.0.0', 'Versión inicial'), 
('2.0.0', 'Se crea una trasacción por factura en los procesos de apertura, ampliación, cierre, remesas. Si falla una factura se hace rollback de esa y continua con la siguiente.'), 
('2.0.1', 'Se resuelve el BUG en la concurrencia de cobros en las remesas Usa la nueva tabla cobrosNum para guardar el último id de cobro en uso.'), 
('2.1.0', 'Nuevo buscador de facturas. Usa la tabla facTotales actualizada por medio de triggers. La remesa aplaza los triggers en facTotalesTrab hasta la finalización de la tarea.'), 
('2.1.1', 'La remesa no aplaza los triggers.'), 
('2.1.2', 'Aplicar consumos comunitarios aplaza los triggers de facTotales hasta la finalización de la tarea')

*/