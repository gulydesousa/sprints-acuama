--SELECT * FROM dbo.vCambiosContador order by ctrcod, [I.RN]

CREATE VIEW dbo.vCambiosContador 
AS

WITH CC AS(
--[01]Cambios de contador
SELECT ctcCtr
, ctcCon
, ctcFecReg
, ctcFec
, ctcLec
, ctcOperacion
, ctcObs
, ctcUsr
, DR= DENSE_RANK() OVER (PARTITION BY ctcCtr ORDER BY ctcFec, ctcFecReg)
, RN= ROW_NUMBER() OVER (PARTITION BY ctcCtr ORDER BY ctcFec, ctcFecReg)
FROM dbo.ctrCon

), II AS(
--[02]Instalaciones
SELECT I.*
, [I.Anterior] = LAG(ctccon) OVER(PARTITION BY ctcCtr ORDER BY ctcFec, ctcFecReg)
, [I.RN]	= ROW_NUMBER() OVER (PARTITION BY ctcCtr ORDER BY ctcFec, ctcFecReg) 
, [I.CN]	= COUNT(ctcCtr) OVER (PARTITION BY ctcCtr) 
FROM CC AS I
WHERE ctcOperacion = 'I' 

), RR AS(
--[03]Retiradas
SELECT R.*
, [R.RN]	= ROW_NUMBER() OVER (PARTITION BY ctcCtr ORDER BY ctcFec, ctcFecReg) 
FROM CC AS R
WHERE ctcOperacion = 'R'

), RESULT AS(
--Macheamos por contrato y contador la retirada
SELECT [ctrCod] = II.ctcCtr
, [I.conId]		= II.ctcCon 
, [I.Anterior]	= II.[I.Anterior]
, [I.Operacion] = II.ctcOperacion
, [I.ctcFec]	= II.ctcFec
, [I.ctcFecReg]	= II.ctcFecReg
--*************************
, [R.Operacion] = RR.ctcOperacion
, [R.ctcFec]	= RR.ctcFec
, [R.ctcFecReg]	= RR.ctcFecReg
--*************************
, [I.ctcLec]	= II.ctcLec
, [R.ctcLec]	= RR.ctcLec
--*************************
, [I.RN]
, [R.RN]
, [esUltimaInstalacion] = CAST(IIF([I.RN] = [I.CN], 1, 0) AS BIT)
--[RN*]=1: Para seleccionar la retirada que corresponde a esta instalacion
, [RN*] = ROW_NUMBER() OVER(PARTITION BY II.ctcCtr, II.RN, RR.ctcCtr, RR.ctcCon ORDER BY RR.ctcFec)
FROM II
--Retiradas de este contador posterior a la instalación
LEFT JOIN RR
ON  II.ctcCtr	 = RR.ctcCtr
AND II.ctcCon	 = RR.ctcCon
AND RR.ctcFec	 >= II.ctcFec)


SELECT ctrCod
, [I.RN]
, [conId]					= [I.conId]
, [conNumSerie]				= CI.conNumSerie
, [conDiametro]				= CI.conDiametro
, [conId.Anterior]			= R.[I.Anterior]
, [conNumSerie.Anterior]	= CR.conNumSerie
, [conDiametro.Anterior]	= CR.conDiametro

, [opInstalacion]			= [I.Operacion]
, [I.ctcFec]
, [I.ctcFecReg]
, [I.ctcLec]
, [opRetirada]				= [R.Operacion]
, [R.ctcFec]
, [R.ctcFecReg]
, [R.ctcLec] 
, [esUltimaInstalacion]
FROM RESULT AS R
LEFT JOIN dbo.contador AS CI
ON CI.conID =  [I.conId]
LEFT JOIN dbo.contador AS CR
ON CR.conID =  [I.Anterior]
WHERE [RN*]=1;


GO


 
