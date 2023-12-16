--SELECT * FROM menu WHERE menupadre=6
DECLARE @tecnica INT;
DECLARE @informesTecnica INT;
DECLARE @id INT;
DECLARE @orden INT;


SELECT @tecnica=menuid FROM menu WHERE menutitulo_es='Técnica';
SELECT @informesTecnica=menuid FROM menu WHERE menupadre=@tecnica AND menutitulo_es='Informes';
SELECT @id=MAX(menuid) FROM dbo.menu;
SELECT @orden=MAX(menuid) FROM dbo.menu WHERE menupadre=@informesTecnica;


DELETE FROM menu WHERE menuurl='~/Almacen/TO037_InformesControlOT.aspx'


INSERT INTO dbo.menu VALUES(@id+1
, @informesTecnica
, 'Inf. Control: C.Contador'
, 'Informes para control de la producción: C.Contador'
, NULL
, '~/Almacen/TO037_InformesControlOT.aspx'
, '~/Almacen/Css/InformesControlOT.css'
, NULL
, NULL
, @orden+1
, 1
, 1)


--SELECT * FROM menu WHERE menutitulo_es='Inf. Control: C.Contador'