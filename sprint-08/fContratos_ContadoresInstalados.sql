ALTER FUNCTION [dbo].[fContratos_ContadoresInstalados] (@fecha DATETIME = NULL)
	RETURNS TABLE 
	AS
	
	RETURN
	--Cambio del 30/04/2021: Se incluyen contadores que no les aparece el calibre.
	SELECT ctrcod AS ctcCtr, ctcCon, ctcFec, ctcLec, ctcUsr, conNumSerie, conDiametro
	FROM contratos AS c1
	LEFT JOIN ctrcon ctc1 
	ON ctcCtr = ctrcod
		AND (@fecha IS NULL OR (@fecha IS NOT NULL AND ctcFec < @fecha))
		AND ctcOperacion = 'I'
		AND ctcFec = (SELECT MAX(ctcFec) FROM ctrcon WHERE ctrCod = ctcCtr AND ctcOperacion = 'I' AND (@fecha IS NULL OR (@fecha IS NOT NULL AND ctcFec < @fecha)))
		AND ctcFecReg = (SELECT MAX(ctcFecReg) FROM ctrcon ctc2 WHERE ctrCod = ctcCtr AND ctc1.ctcFec = ctc2.ctcFec AND ctc2.ctcOperacion = 'I' AND (@fecha IS NULL OR (@fecha IS NOT NULL AND ctcFec < @fecha)))
	LEFT JOIN contador ON conID = ctcCon
	WHERE ctrversion = (SELECT MAX(ctrversion) FROM contratos c2 WHERE c1.ctrcod = c2.ctrcod)
	
	/*
	--Esto incluye varias mejoras y correcciones de errores
	--Sin embargo, se ha dejado como estaba porque justo el día después de su subida la aplicación empezó a generar bloqueos en Soria y Melilla
	RETURN
	
	WITH CTRS AS(
	--Contratos ordenados por version:
	SELECT C.ctrcod
		 , C.ctrversion
		-- [RN] =1: Última version del contrato	
		 , [RN] =ROW_NUMBER() OVER (PARTITION BY C.ctrcod ORDER BY C.ctrversion DESC)
	FROM dbo.contratos AS C
	
	), CC AS(
	--*********
	--Cambiamos la fecha de registro a minutos: [FechaCambio]
	--Mecanismo que encontramos para poder agrupar y ordenar los cambios de contador (R, I)
	--*********
	SELECT C.*
	--[FechaCambio] dd/MM/YYYY HH:mm para agrupar y ordenar los cambios de contador
	, [FechaCambio] = CAST(ctcFecReg AS SMALLDATETIME)
	--[RN] =1: Operación de contador mas reciente 
	, [RN] =ROW_NUMBER() OVER (PARTITION BY C.ctcCtr 
						  ORDER BY CAST(ctcFecReg AS SMALLDATETIME) DESC 
						 , ctcOperacion ASC)
	FROM dbo.ctrcon AS C
	WHERE (@fecha IS NULL OR C.ctcFec < @fecha))

	--***********************************************************
	--Para cada contrato retorna el contador actualmente instalado
	SELECT ctcCtr = CTRS.ctrcod
	, CC.ctcCon
	, CC.ctcFec
	, CC.ctcLec
	, CC.ctcUsr
	, CON.conNumSerie
	, CON.conDiametro
	FROM CTRS 
	LEFT JOIN CC 
	ON  CC.ctcCtr = CTRS.ctrcod
	AND CC.RN=1	--Operación de contador mas reciente 	
	AND CC.ctcOperacion = 'I'
	LEFT JOIN dbo.contador AS CON 
	ON CON.conID = CC.ctcCon
	WHERE CTRS.RN=1; --Ultima versión del contrato
	--***********************************************************
	
	*/





GO


