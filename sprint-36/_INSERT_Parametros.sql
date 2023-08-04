--DECLARE @VALOR INT = 0;
--SELECT  @VALOR = 120 FROM PARAMETROS WHERE pgsclave='EXPLOTACION' AND pgsValor IN ('Soria', 'Melilla')

--INSERT INTO parametros VALUES
--('OT_MAXDIASENTRELECTURAS', 'OT', 1, @VALOR, 0, 1, 0);

--GO

DELETE FROM parametros  WHERE pgsclave IN  ('OT_MAXDIASENTRELECTURAS', 'OT_MASDATOS_CC', 'MAXDIASENTRELECTURAS')

DECLARE @VALOR INT = 0;
SELECT  @VALOR = 5 FROM PARAMETROS WHERE pgsclave='EXPLOTACION' 

INSERT INTO parametros VALUES
('OT_MASDATOS_CC', 'Cambio de contador desde la OT: Datos adicionales. El valor indica el numero de facturas visibles en el formulario de cambio contador.', 1, @VALOR, 0, 1, 0);

GO

DECLARE @VALOR INT = 0;
SELECT  @VALOR = 120 FROM PARAMETROS WHERE pgsclave='EXPLOTACION' AND pgsValor IN ('Soria', 'Melilla')

INSERT INTO parametros VALUES
('MAXDIASENTRELECTURAS', 'OT', 1, @VALOR, 0, 1, 0);

GO


SELECT * FROM parametros AS P WHERE pgsclave IN  ('OT_MAXDIASENTRELECTURAS', 'OT_MASDATOS_CC', 'MAXDIASENTRELECTURAS')
