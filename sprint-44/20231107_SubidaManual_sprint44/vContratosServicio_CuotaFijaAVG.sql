--SELECT * FROM dbo.vContratosServicio_CuotaFijaAVG WHERE ctrcod=32380

--Retorna la ultima tarifa de cuota fija de cada contrato
--Se extrae el calibre del contador de la descripción del servicio
CREATE VIEW dbo.vContratosServicio_CuotaFijaAVG
AS
--Solo trae registros para AVG
WITH V AS(
SELECT cuotaAgua = 2, prefijo = 'C.SERVICIO', sufijo = 'MM'
FROM dbo.parametros AS P
WHERE P.pgsclave= 'EXPLOTACION' AND P.pgsvalor='AVG'

), SVC AS(
SELECT S.ctsctrcod
, S.ctssrv
, S.ctstar
, S.ctsfecbaj

--**********************************
--Variables para hacer el substring
, V.prefijo
, V.sufijo
, [lenPrefijo] = LEN(V.prefijo)
--**********************************
, RN = ROW_NUMBER() OVER (PARTITION BY ctsctrcod ORDER BY IIF(S.ctsfecbaj IS NULL, 0, 1), S.ctsfecbaj DESC)
FROM dbo.contratoServicio AS S 
INNER JOIN V 
ON S.ctssrv=V.cuotaAgua)

SELECT [ctrCod] = S.ctsctrcod
, S.ctsfecbaj
, T.trfsrvcod
, T.trfcod
, T.trfdes 
, [Calibre] = CAST ( 
			  IIF(CHARINDEX(S.prefijo, T.trfdes)=0 OR CHARINDEX(sufijo, T.trfdes)=0 , NULL,
				SUBSTRING(T.trfdes
				, CHARINDEX(S.prefijo, T.trfdes) + lenPrefijo
				, CHARINDEX(S.sufijo, T.trfdes) - CHARINDEX(S.prefijo, T.trfdes) - lenPrefijo)) 
			  AS INT)
FROM SVC AS S 
LEFT JOIN dbo.tarifas AS T
ON T.trfsrvcod = S.ctssrv
AND T.trfcod = S.ctstar
--Solo nos interesa el ultimo servicio por contrato activo.
WHERE S.RN=1;

GO