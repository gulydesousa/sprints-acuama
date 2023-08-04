/*
DECLARE @contratoD INT=1, @contratoH INT=1000
, @clienteD INT, @clienteH INT
, @uso INT
, @cualquierRepre BIT
, @representante AS VARCHAR(80)
, @servicio SMALLINT=1
, @tarifaD SMALLINT
, @tarifaH SMALLINT
, @orden AS VARCHAR(50)

EXEC ReportingServices.CC067_ContratosRepLegal @contratoD, @contratoH, @clienteD, @clienteH, @uso, @cualquierRepre, @representante, @servicio, @tarifaD, @tarifaH, @orden
*/

ALTER PROCEDURE ReportingServices.CC067_ContratosRepLegal (
  @contratoD INT=NULL
, @contratoH INT=NULL
, @clienteD INT=NULL
, @clienteH INT=NULL
, @uso INT=NULL
, @cualquierRepre BIT=NULL
, @representante AS VARCHAR(80)=NULL
, @servicio SMALLINT=NULL
, @tarifaD SMALLINT=NULL
, @tarifaH SMALLINT=NULL
, @orden AS VARCHAR(50)=NULL
)

AS

WITH S AS(
--Servicio sin fecha de baja
SELECT   CS.ctsctrcod
, CS.ctslin 
, CS.ctssrv
, CS.ctstar
, CS.ctsfecAlt
--[RN]=1: Si hay varias ocurrencias del servicio activos nos quedamos con el mas reciente 
, [RN] = ROW_NUMBER() OVER(PARTITION BY CS.ctsctrcod ORDER BY  CS.ctsfecAlt DESC, CS.ctslin ASC)
FROM dbo.contratoServicio AS CS
WHERE @servicio IS NOT NULL
AND CS.ctsfecbaj IS NULL
AND CS.ctssrv = @servicio
AND (ISNULL(@tarifaD, 0) = 0 OR CS.ctstar>=@tarifaD)
AND (ISNULL(@tarifaH, 0) = 0 OR CS.ctstar<=@tarifaH)
AND CS.ctsfecbaj IS NULL)

SELECT C.ctrcod
, CC.ctrTitCod
, C.ctrTitNom
, CC.ctrTlf1
, CC.ctrTlf2
, CC.ctrTlfRef1
, CC.ctrTlfRef2
, CC.ctrEmail
, U.usocod
, U.usodes
, CC.ctrRepresent
, CC.ctrValorc4
, R.clitelefono1
, R.clitelefono2
, R.climail
, R.clidomicilio
, I.inmDireccion
, CC.ctrValorc1
, CC.ctrValorc2
, CC.ctrValorc3
, I.inmEdificio

, T.trfcod
, [tarifa] = IIF(T.trfcod IS NULL, '', FORMATMESSAGE('%03i-%s',T.trfcod, T.trfdes))
FROM dbo.vContratosUltimaVersion AS C
INNER JOIN dbo.contratos AS CC
ON CC.ctrcod = C.ctrCod
AND CC.ctrversion = C.ctrVersion
INNER JOIN dbo.inmuebles  AS I 
ON I.inmCod = C.ctrInmCod
LEFT JOIN dbo.usos AS U
ON U.usocod = CC.ctrUsoCod
LEFT JOIN S
ON S.ctsctrcod = CC.ctrcod
AND S.RN=1
LEFT JOIN dbo.tarifas AS T
ON T.trfsrvcod = S.ctssrv
AND T.trfcod = S.ctstar
LEFT JOIN dbo.clientes AS R
ON R.clicod = CC.ctrValorc4
WHERE (C.ctrbaja = 0) --No puede estar de baja
  AND (@contratoD IS NULL OR CC.ctrcod >= @contratoD) 
  AND (@contratoH IS NULL OR CC.ctrcod <= @contratoH)
  AND (@clienteD IS NULL  OR CC.ctrTitCod >= @clienteD) 
  AND (@clienteH IS NULL  OR CC.ctrTitCod <= @clienteH)
  --*****************************************************
  --Estos criterios de selección, que no sean excluyentes. Es decir, válidos los que cumplan cualquiera de las condiciones.
	AND (
		(@uso IS NULL AND @servicio IS NULL AND ISNULL(@cualquierRepre, 1) = 1) OR 
		(@uso IS NOT NULL AND CC.ctrusocod = @uso) OR
		(@servicio IS NOT NULL AND ISNULL(S.RN, 0)>0) OR
		(@cualquierRepre = 0 AND LEN(ISNULL(CC.ctrRepresent, ''))>0 AND (LEN(ISNULL(@representante, ''))=0 OR CC.ctrRepresent LIKE '%' + @representante + '%'))
		)
		
ORDER BY 
CASE @orden 
WHEN 'ctrTitNom' THEN CC.ctrTitNom 
WHEN 'ctrRepresent' THEN CC.ctrRepresent 
ELSE CC.ctrcod END;

GO