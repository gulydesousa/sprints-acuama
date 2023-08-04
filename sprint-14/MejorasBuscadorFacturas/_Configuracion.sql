--SELECT * FROM parametros

INSERT INTO dbo.parametros 
OUTPUT INSERTED.*
VALUES('FAC_APERTURA', 
'Apertura de facturación: 
1.0.0: Inicial 
2.0.0: Begin Tran por factura   
2.0.1: Bug concurrencia cobros-remesas  
2.1.0: Mejorar Buscador de facturas 
2.1.1: No aplaza triggers Remesas'
, 2, '1.0.0', 0, 1, 0);

                  
INSERT INTO dbo.parametros 
OUTPUT INSERTED.*
VALUES ('FACTOTALES', 'Habilita FacTotales por evolutivos' 
+ CHAR(10) +  '1.0: Codigo de barras original'
+ CHAR(10) +  '2.0: Codigo de barras con facTotales (para pruebas)'
+ CHAR(10) +  '2.1: Codigo de barras con facTotales (para producción)'
, 2, '2.1', 0, 1, 0);
