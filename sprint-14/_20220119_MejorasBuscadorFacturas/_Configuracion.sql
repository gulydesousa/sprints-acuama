--SELECT * FROM parametros
INSERT INTO dbo.parametros 
OUTPUT INSERTED.*
VALUES('FAC_APERTURA', 
'Versión de la apertura de facturación: 
1.0: Inicial 
2.0: Begin Tran por factura   
2.0.1: Bug concurrencia cobros-remesas  
2.1: Mejorar Buscador de facturas 
2.1.1: No aplaza triggers Remesas'
, 2, '2.1.1', 0, 1, 0);

                  
