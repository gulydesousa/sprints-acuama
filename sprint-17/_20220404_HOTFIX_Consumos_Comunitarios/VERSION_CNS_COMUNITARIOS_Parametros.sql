
SELECT * 
--UPDATE P SET pgsdesc='Para condicionar la ejecución de Tasks_Facturas_AplicarConsumosComunitarios: 1.0.0, 2.1.0, 2.1.1, 3.0.0, 3.1.0, 3.1.1 para detalles de cada versión consulta en [Trabajo].[VERSION_CNS_COMUNITARIOS]'
FROM parametros AS P WHERE pgsclave='VERSION_CNS_COMUNITARIOS'