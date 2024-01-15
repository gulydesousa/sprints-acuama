--SELECT * FROM dbo.vCatastro WHERE RefValidacion IS NULL OR RefValidacion<>1
--SELECT * FROM dbo.vCatastro WHERE NIF='ES-S7900010-E'
--DROP VIEW dbo.vCatastro

ALTER VIEW [dbo].[vCatastro] AS
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
	 --Juntamos todas las letras del nombre, quitamos caracteres que no sean alfanumericos 
	 , fnTitNomChars = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE (NOMBRE, '*', ''), '-', ''), ',', ''), ' ', '')))
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
	, fnTitNom_
	, fnTitNomChars
	--Quitamos los espacios repetidos en la direccion entera
	, fnDireccion_ = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(DIRECCION_, ' ', '<>'), '><', ''),'<>',' ')))	
	, RefsxPropietario	= COUNT(REFCATASTRAL) OVER(PARTITION BY NIF, NOMBRE)
	, RefsxDireccion	= COUNT(REFCATASTRAL) OVER(PARTITION BY DIRECCION)
	, RefValidacion = dbo.fValidarReferenciaCatastral(REFCATASTRAL)
FROM C;

GO


