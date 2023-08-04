--FAC_APERTURA centraliza todo dejando otros parametros obsoletos 
DELETE FROM parametros WHERE pgsclave='FAC.APERTURA';
DELETE FROM parametros WHERE pgsclave='FACTOTALES';
DELETE FROM parametros WHERE pgsclave='OBTENER_CABECERA';
DELETE FROM parametros WHERE pgsclave='FAC_APERTURA';


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


--*******************
INSERT INTO dbo.facDeudaEstados 
OUTPUT INSERTED.*
VALUES
(1, 'Deuda Pdte.', 'ABS(T.fctFacturado-T.fctCobrado) > 0.02'),
(2, 'Impagada', '(T.fctCobrado = 0 AND T.fctFacturado <> 0)'),
(3, 'Con Pago Parcial', '(T.fctCobrado > 0 AND T.fctCobrado < T.fctFacturado)'),
(4, 'Pagada', 'T.fctCobrado = T.fctFacturado'),
(5, 'Devolución Pdte.', 'T.fctCobrado > T.fctFacturado');

GO


--******************
EXEC Trabajo.Parametros_FAC_APERTURA '2.1.1';
GO

--******************
EXEC Trabajo.Parametros_ERRORLOG 0;
GO




--*****************
SELECT C.* , V.cbnNumero
--UPDATE C SET C.cbnNumero=V.cbnNumero
FROM dbo.cobrosNum AS C
LEFT JOIN dbo.vCobrosNumerador AS V
ON C.cbnScd = V.scdcod AND C.cbnPpag = V.ppagCod
WHERE V.cbnNumero <> C.cbnNumero


--TRUNCATE TABLE cobrosNum;
--GO

--TRUNCATE TABLE facDeudaEstados 
--INSERT INTO cobrosNum
--SELECT scdcod, ppagCod, cbnNumero FROM dbo.vCobrosNumerador;


--SELECT * FROM vCobrosNumerador
--SELECT * FROM cobrosNum
