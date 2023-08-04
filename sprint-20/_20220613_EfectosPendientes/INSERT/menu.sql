DECLARE @menuID  INT = 515;


INSERT INTO menu (menuid, menupadre, menutitulo_es, menuToolTip_es, menucolorpagina, menuurl, menucss, menujs, menuicono, menuorden, menuvisible, menuactivo)
VALUES (@menuID, 5, 'Efectos pendientes', NULL, NULL, NULL, NULL, NULL, NULL, 45, 1, 1)

INSERT INTO menu (menuid, menupadre, menutitulo_es, menuToolTip_es, menucolorpagina, menuurl, menucss, menujs, menuicono, menuorden, menuvisible, menuactivo)
VALUES ( @menuID+1,  @menuID, 'Compromiso de pago', 'Carta de compromiso de pago efectos pendientes', NULL, '~/Cobros/CR057_CompromisoEfectosPendientes.aspx', '~/Cobros/Css/CompromisoEfectosPendientes.css', NULL, NULL, 150, 1, 1)


--SELECT * 
UPDATE M SET M.menupadre = @menuID
FROM menu AS M
WHERE M.menuurl='~/Cobros/CR021_EfectosPendientes.aspx'


--SELECT * 
UPDATE M SET M.menupadre = @menuID
FROM menu AS M
WHERE M.menuurl='~/Cobros/CR037_EfectosPdtesSinCobrar.aspx'



--UPDATE menuPerfil SET meporden=45 WHERE mepid=115 AND mepprfcod='jefAdmon'
--DELETE menuPerfil  WHERE mepprfcod='jefAdmon' AND mepurl='~/Cobros/CR021_EfectosPendientes.aspx'
