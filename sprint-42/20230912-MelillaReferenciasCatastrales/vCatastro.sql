--SELECT * FROM dbo.vCatastro WHERE REFCATASTRAL='6156417WE0065N0001RW'
--SELECT * FROM dbo.vCatastro WHERE NIF='ES-S7900010-E'
--DROP VIEW dbo.vCatastro_

ALTER VIEW dbo.vCatastro AS
WITH C AS(
SELECT NIF
	 , NOMBRE
	 , DIRECCION
	 , REFCATASTRAL	
	 , DIRECCION_
	 , id
	 --*************************
	 , fnPais = SUBSTRING(NIF, 1, CHARINDEX ('-', NIF) - 1)
	 , fnNif = REPLACE (SUBSTRING(NIF, CHARINDEX ('-', NIF) + 1, LEN (NIF)),'-','')
	 --Quitamos los espacios repetidos en el nombre
	 , fnTitNom_ = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE (NOMBRE, '*', ' '), ' ', '<>'), '><', ''),'<>',' ')))	 
FROM dbo.Catastro)


SELECT NIF
	 , NOMBRE
	 , DIRECCION
	 , REFCATASTRAL	
	 , id
	--*************************
	 , fnPais
	 , fnNif
	 --Agregamos un padding de 12 para comparar los NIF
	 , fnTitDocIden = IIF(LEN(fnNif) >= 12
						, fnNif
						, RIGHT('000000000000' + fnNif, 12))
	--Quitamos los espacios repetidos en la direccion entera
	, fnDireccion_ = DIRECCION_
	, fnTitNom_ 
	, RefsxPropietario	= COUNT(REFCATASTRAL) OVER(PARTITION BY NIF, NOMBRE)
	, RefsxDireccion	= COUNT(REFCATASTRAL) OVER(PARTITION BY DIRECCION)	
FROM C;

GO

