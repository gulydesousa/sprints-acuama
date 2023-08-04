--SELECT * FROM fContadoresxOperacion ('I', '20220101', '20220201')
--SELECT * FROM fContadoresxOperacion ('R', '20220101', '20220201')

CREATE FUNCTION dbo.fContadoresxOperacion
(
  @operacion VARCHAR(1)
, @fDesde AS DATE
, @fHasta AS DATE
)
RETURNS TABLE
AS
RETURN(
SELECT C.conId, C.ctrCod, C.[I.ctcFec], C.[R.ctcFec], esCtrUltimaInst = C.esUltimaInstalacion, esCtrPrimerContador = IIF(C.[I.RN]=1, 1, 0)
FROM dbo.vCambiosContador AS C
WHERE (@operacion IS NOT NULL AND @fDesde IS NOT NULL AND @fHasta IS NOT NULL) 
AND(
	 (@operacion = 'I' AND  C.[I.ctcFec] IS NOT NULL AND C.[I.ctcFec]>=@fDesde AND C.[I.ctcFec] <@fHasta) 
	  OR
	 (@operacion = 'R' AND  C.[R.ctcFec] IS NOT NULL AND C.[R.ctcFec]>=@fDesde AND C.[R.ctcFec] <@fHasta)
	)

)
