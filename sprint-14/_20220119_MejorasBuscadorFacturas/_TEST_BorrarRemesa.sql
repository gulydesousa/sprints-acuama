--*********************
--PRUEBAS: BORRAR REMESA
--*********************
/*
--TRUNCATE TABLE errorlog
Para borrar todo lo referente a una remesa
	• @numeroRemesa
	SELECT facNumeroRemesa, facFechaRemesa, CN= COUNT(facNumeroRemesa) 
	FROM facturas 
	GROUP BY facNumeroRemesa, facFechaRemesa 
	ORDER BY facNumeroRemesa DESC
	
	• @fechaRemesa
	SELECT DISTINCT FORMAT(facFechaRemesa,'yyyyMMdd HH:mm:ss.fff')
	FROM facturas 
	WHERE facNumeroRemesa=409
	
	• @usuarioRemesa
	SELECT DISTINCT cobUsr 
	FROM cobros 
	WHERE cobOrigen='remesa' AND cobConcepto LIKE '%64%'
*/



DECLARE @numeroRemesa INT = 409
DECLARE @fechaRemesa DATETIME = '20220112 18:28:37.773'
DECLARE @usuarioRemesa VARCHAR(20)= 'gmdesousa'
DECLARE @soloConsulta BIT = 0
DECLARE @RESULT INT;

EXEC @RESULT = Cobros_BorrarRemesa @numeroRemesa, @fechaRemesa, @usuarioRemesa, @soloConsulta
