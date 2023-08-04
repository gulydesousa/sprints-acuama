INSERT INTO MENU
SELECT 
  menuid= (SELECT MAX(menuid)+1 FROM menu) 
, menuPadre = 35
, menutitulo_es = 'Carga masiva OT'
, menuToolTip_es = 'Carga por fichero CSV'
, menucolorpagina = NULL
, menuurl = '~/Almacen/TO035_OtCargaMasiva.aspx'
, menucss = NULL	
, menujs = NULL	
, menuicono = NULL	
, menuorden = 200
, menuvisible = 1
, menuactivo =1


--SELECT * FROM menu WHERE menutitulo_es='Órdenes de trabajo'
--DELETE FROM MENU WHERE  menuurl = '~/Almacen/TO035_OtCargaMasiva.aspx'