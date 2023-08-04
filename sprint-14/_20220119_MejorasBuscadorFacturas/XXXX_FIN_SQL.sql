TRUNCATE TABLE cobrosNum;
GO

INSERT INTO cobrosNum
SELECT scdcod, ppagCod, cbnNumero FROM dbo.vCobrosNumerador;

--*******************
INSERT INTO dbo.facDeudaEstados 
OUTPUT INSERTED.*
VALUES
(1, 'Deuda Pdte.', 'T.fctCobrado <> T.fctFacturado'),
(2, 'Impagada', '(T.fctCobrado = 0 AND T.fctFacturado <> 0)'),
(3, 'Con Pago Parcial', '(T.fctCobrado > 0 AND T.fctCobrado < T.fctFacturado)'),
(4, 'Pagada', 'T.fctCobrado = T.fctFacturado'),
(5, 'Devolución Pdte.', 'T.fctCobrado > T.fctFacturado');

GO

--******************
EXEC Trabajo.Parametros_FAC_APERTURA '2.0.1';
GO

--******************
EXEC Trabajo.Parametros_ERRORLOG 1;
GO


--*****************
SELECT C.* , V.cbnNumero
--UPDATE C SET C.cbnNumero=V.cbnNumero
FROM dbo.cobrosNum AS C
LEFT JOIN dbo.vCobrosNumerador AS V
ON C.cbnScd = V.scdcod AND C.cbnPpag = V.ppagCod
WHERE V.cbnNumero <> C.cbnNumero
--794.038
