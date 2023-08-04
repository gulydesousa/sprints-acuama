INSERT INTO MENU
SELECT 
  menuid= (SELECT MAX(menuid)+1 FROM menu) 
, menuPadre = 35
, menutitulo_es = 'Cambio contador masivo'
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

SELECT * 
--UPDATE M SET menutitulo_es = 'Cambio contador masivo'
FROM menu AS M
WHERE menutitulo_es = 'Cambio contador masivo'