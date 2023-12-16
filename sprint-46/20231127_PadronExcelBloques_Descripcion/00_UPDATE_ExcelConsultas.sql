UPDATE X SET ExcAyuda='Padrón detallado por bloques—unidades y precios—. <i>INCLUYE prefacturas y EXCLUYE rectificadas.</i><br>Para validar el <span style=''color:yellow''><b>Informe de facturación</b></span> que se descarga desde "Facturacion/Informes/<span style=''color:yellow''>Resumen Por Conceptos</span>": <ul><li><span style=''color:yellow''>Cuotas</span>: corresponde al numero de facturas con el servicio en este informe.</li><li><span style=''color:yellow''>Unid.:</span> se calcula totalizando la columna "Cuotas" de este informe.</li></ul>'
FROM ExcelConsultas AS X WHERE ExcDescCorta LIKE '%Padrón Excel por Bloques%'



