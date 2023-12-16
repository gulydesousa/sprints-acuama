--SELECT * FROM dbo.vCatastro WHERE CnDirecciones>1 ORDER BY DIRECCION

CREATE VIEW dbo.vCatastro AS

SELECT NIF
	 , REFCATASTRAL	
	 , RefsxPropietario = COUNT(REFCATASTRAL) OVER(PARTITION BY NIF, NOMBRE)
	 , RefsxDireccion = COUNT(REFCATASTRAL) OVER (PARTITION BY DIRECCION)
	 , PaisText = SUBSTRING(NIF, 1, CHARINDEX ('-', NIF) - 1)
	 , DocIdenText = REPLACE (SUBSTRING(NIF, CHARINDEX ('-', NIF) + 1, LEN (NIF)),'-','')
	 , NOMBRE
	 , NombreText = REPLACE(REPLACE (NOMBRE, '*', ' '), '  ', ' ')
	 , DIRECCION
FROM dbo.Catastro;

GO


