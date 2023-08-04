SELECT * 
--UPDATE P SET pgsValor='3.1.1'
FROM parametros AS P WHERE pgsclave = 'VERSION_CNS_COMUNITARIOS'

INSERT INTO Trabajo.VERSION_CNS_COMUNITARIOS
VALUES ('1.0.0', 'Versión Inicial')

, ('2.0.0', 'Sin uso')
, ('2.1.0', 'Aplazando triggers en factotales por toda la zona')
, ('2.1.1', 'Aplazando triggers en factotales para las facturas en @tablaAuxiliar')

, ('3.0.0', 'DESCONTAR: Correcciones en @facConsumoFactura (Cns.), @facCnsFinal(Consumo final)')
, ('3.1.0', 'DESCONTAR: Correcciones aplazando triggers en factotales por toda la zona')
, ('3.1.1', 'DESCONTAR: Correcciones aplazando triggers en factotales para las facturas en @tablaAuxiliar')

--SELECT * FROM  [Trabajo].[VERSION_CNS_COMUNITARIOS]
