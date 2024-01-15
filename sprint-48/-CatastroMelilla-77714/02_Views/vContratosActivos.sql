--SELECT * FROM dbo.vContratosActivos WHERE REFCATASTRAL IS NULL AND inmrefcatastral IS NOT NULL
--DROP VIEW dbo.vContratosActivos

ALTER VIEW [dbo].[vContratosActivos]
AS

WITH C AS (
SELECT C.ctrcod
	, C.ctrversion
	, C.ctrTitDocIden
	, C.ctrTitNom
	, C.ctrbaja
	, C.ctrinmcod
	, C.ctrzoncod
	, [Ruta] = FORMATMESSAGE('%s.%s.%s.%s.%s.%s'
							  , ISNULL(C.ctrRuta1,'')
							  , ISNULL(C.ctrRuta2,'')
							  , ISNULL(C.ctrRuta3,'')
							  , ISNULL(C.ctrRuta4,'')
							  , ISNULL(C.ctrRuta5,'')
							  , ISNULL(C.ctrRuta6,''))

	--RN=1 para quedarnos con la ultima version
	, RN = ROW_NUMBER() OVER(PARTITION BY C.ctrcod ORDER BY C.ctrversion DESC)
FROM dbo.contratos AS C WITH(INDEX(PK_contratos_1))

), CTR AS(
SELECT C.ctrcod
	, C.ctrversion
	, C.ctrTitDocIden
	, C.ctrTitNom
	, C.ctrbaja
	, C.ctrinmcod
	, C.ctrzoncod
	, C.Ruta
	--Formateamos los campos de la dirección para que se parezcan a los del catastro
	 , I.inmDireccion
	 , I.inmrefcatastral
	 , calle =  CASE WHEN I.inmCalle LIKE 'AV/ %' THEN REPLACE(I.inmCalle, 'AV/', 'AVDA')
					 WHEN I.inmCalle LIKE 'CL/ %' THEN REPLACE(I.inmCalle, 'CL/', 'CALLE')
					 WHEN I.inmCalle LIKE 'PZ/ %' THEN REPLACE(I.inmCalle, 'PZ/', 'PLAZA')
					 WHEN I.inmCalle LIKE 'CM/ %' THEN REPLACE(I.inmCalle, 'CM/', 'CMNO')
					 WHEN I.inmCalle LIKE 'UR/ %' THEN REPLACE(I.inmCalle, 'UR/', 'URB')
					 WHEN I.inmCalle LIKE 'TR/ %' THEN REPLACE(I.inmCalle, 'TR/', 'TRVA')
					 WHEN I.inmCalle LIKE 'RD/ %' THEN REPLACE(I.inmCalle, 'RD/', 'RONDA')
					 WHEN I.inmCalle LIKE 'PS/ %' THEN REPLACE(I.inmCalle, 'PS/', 'PASEO')
					 WHEN I.inmCalle LIKE 'PZO/ %' THEN REPLACE(I.inmCalle, 'PZO/', 'PZO')
					 WHEN I.inmCalle LIKE 'CR/ %' THEN REPLACE(I.inmCalle, 'CR/', 'CTRA')
					 WHEN I.inmCalle LIKE 'BDA/ %' THEN REPLACE(I.inmCalle, 'BDA/', 'BARDA')
					 WHEN I.inmCalle LIKE 'ESCA/ %' THEN REPLACE(I.inmCalle, 'ESCA/', 'ESCA')
					 WHEN I.inmCalle LIKE 'CJ/ %' THEN REPLACE(I.inmCalle, 'CJ/', 'CLLON')
				     ELSE I.inmCalle END + ','
	 
	 , planta = REPLACE(I.inmPlanta, 'º', '')

	 , puerta = IIF(I.inmPuerta IS NOT NULL , ' PTA ', '') +
				CASE WHEN I.inmPuerta IS NULL THEN ''
					 WHEN ISNUMERIC(I.inmPuerta) = 1 THEN RIGHT('00' + I.inmPuerta, 2) 
					 WHEN I.inmPuerta = 'DCH' THEN 'DR'
					 WHEN I.inmPuerta IN('IZD', 'IZQ') THEN 'IZ'
					 ELSE I.inmPuerta END
	, finca = IIF(ISNUMERIC(I.inmFinca)=1, RIGHT('     ' + I.inmFinca, 5), '   '+ I.inmFinca)
	, complemento = IIF(I.inmcomplemento IS NOT NULL, ' ' + I.inmcomplemento, '') 
	, edificio = IIF(I.inmedificio IS NOT NULL, ' ' + I.inmedificio, '') 
	, entrada =  IIF(I.inmEntrada IS NOT NULL, ' Esc ' + I.inmEntrada, '') 
 	--Nombre de la calle sin el tipo
	, inmcalle = SUBSTRING(I.inmcalle, CHARINDEX('/', I.inmcalle) + 1, LEN(I.inmcalle))
FROM C
INNER JOIN dbo.inmuebles AS I
ON I.inmcod = C.ctrinmcod
--RN=1 para quedarnos con la ultima version
WHERE RN=1 AND ctrbaja=0


), SVC AS(
SELECT C.ctrcod
	, C.ctrversion
	--Servicios activos
	, scvActivos = COUNT(S.ctssrv)
FROM CTR AS C
LEFT JOIN contratoServicio AS S
ON C.ctrcod = S.ctsctrcod
AND (S.ctsfecbaj IS NULL OR S.ctsfecbaj>GETDATE())
GROUP BY C.ctrcod, C.ctrversion

), RESULT AS(

SELECT C.ctrcod
	, C.ctrversion
	, C.ctrTitDocIden
	, C.ctrTitNom

	, C.ctrinmcod
	, C.ctrzoncod
	, C.Ruta
	, C.inmDireccion
 	, inmrefcatastral = ISNULL(C.inmrefcatastral, '')  
	, CC.REFCATASTRAL
	, C.calle
	, C.finca
	--*************************
	, S.scvActivos
	--*************************
	, cnCtrActivosxTitular = SUM(IIF(C.ctrbaja=0, 1, 0) ) OVER (PARTITION BY C.ctrTitDocIden)
	, cnCtrActivosxDireccion = SUM(IIF(C.ctrbaja=0, 1, 0) ) OVER (PARTITION BY C.inmDireccion)
	, fnDireccion = CONCAT( C.calle
						, C.finca
						, C.entrada
						, CASE WHEN ISNUMERIC(C.planta) = 1 THEN ' P' + RIGHT('00' + C.planta, 2) 
							   WHEN C.planta IS NULL THEN ''
							   WHEN C.planta  = 'LOC' THEN ''
							   ELSE ' ' + C.planta END  
						, C.puerta
						, C.complemento
						, C.edificio)
		
	--Agregamos un padding de 12 para comparar los NIF
	, fnTitDocIden = RIGHT('0000000000000' + C.ctrTitDocIden, 12)
 --Calle del inmueble
 , inmcalle
 --Hemos comprobado que en las calles hay a lo sumo una coma
 , coma = CHARINDEX(',', inmcalle)
 , refValidacion = dbo.fValidarReferenciaCatastral(C.inmrefcatastral)
FROM CTR AS C
INNER JOIN SVC AS S
ON C.ctrcod = S.ctrcod
AND C.ctrversion = S.ctrversion
LEFT JOIN dbo.catastro AS CC
ON CC.REFCATASTRAL= C.inmrefcatastral)


SELECT * 
--Quitamos los espacios repetidos en la direccion entera
, fnDireccion_ = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(fnDireccion, ' ', '<>'), '><', ''),'<>',' ')))
--Quitamos los espacios repetidos en el nombre
, fnTitNom_ =  LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(ctrTitNom, ', ', ','), ' ', '<>'), '><', ''),'<>',' ')))
--Juntamos todas las letras del nombre, quitamos caracteres que no sean alfanumericos 
, fnTitNomChars =  LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(ctrTitNom, ',', ''),'-', ''), ' ', '')))
--Quitamos los espacios repetidos en la finca
, fnFinca_ = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(CONCAT(calle, finca), ' ', '<>'), '><', ''),'<>',' ')))
--Nombre de la calle antes de la coma
, calle0 = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(IIF(coma > 0, LEFT(inmcalle, coma-1), inmcalle), ' ', '<>'), '><', ''),'<>',' '))) 
--Nombre de la calle despues de la coma
, calle1 = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(IIF(coma > 0, RIGHT(inmcalle, LEN(inmcalle)-coma), NULL), ' ', '<>'), '><', ''),'<>',' ')))  
FROM RESULT;  

GO


