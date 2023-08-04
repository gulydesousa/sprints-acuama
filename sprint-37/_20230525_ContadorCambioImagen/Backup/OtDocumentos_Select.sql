--EXEC [OtDocumentos_Select] @otNum=22997, @otdTipoCodigo= 'CCR'

--SELECT * FROM otDocumentos
--SELECT * FROM otDocumentoTipo

ALTER PROCEDURE [dbo].[OtDocumentos_Select]
@otSerScd SMALLINT = NULL,
@otSerCod SMALLINT = NULL,
@otNum INT = NULL, 
@otdTipoCodigo VARCHAR(5) = NULL,
--@indice=NULL : Retorna todos los documentos
--@indice<=0 : Retorna solo el mas reciente
--@indice>0 : Retorna el del indice solicitado
@indice TINYINT = 0

AS 
	SET NOCOUNT ON; 
	
	WITH RESULT AS(
	SELECT D.*
	--RN=1: Fichero mas reciente por ot y tipo
	, RN = ROW_NUMBER() OVER(PARTITION BY D.otdSerScd, D.otdSerCod, D.otdNum, D.otdTipoCodigo ORDER BY D.otdFechaReg DESC, D.otdID DESC)
	--CN: Ficheros por tipo
	, CN = COUNT(D.otdID) OVER(PARTITION BY D.otdSerScd, D.otdSerCod, D.otdNum, D.otdTipoCodigo)
	FROM otDocumentos AS D
	WHERE (@otSerScd IS NULL OR D.otdSerScd=@otSerScd)
	  AND (@otSerCod IS NULL OR D.otdSerCod=@otSerCod)
	  AND (@otNum IS NULL OR D.otdNum= @otNum)
	  AND (@otdTipoCodigo IS NULL OR D.otdTipoCodigo= @otdTipoCodigo)
	 )

	 SELECT R.*, T.otdtDescripcion, T.otdtFormato, T.otdtMaxPorTipo
	 FROM RESULT AS R
	 INNER JOIN dbo.otDocumentoTipo AS T
	 ON T.otdtCodigo = R.otdTipoCodigo
	 WHERE 
	 (@indice IS NULL) OR								  --@indice=NULL : Retorna todos los documentos
	 (@indice<=0 AND RN=1) OR							  --@indice<=0 : Retorna solo el mas reciente
	 (@indice >0 AND RN = IIF(@indice > CN, CN, @indice)) --@indice>0 : Retorna el del indice solicitado
	 ORDER BY  otdSerScd, otdSerCod, otdNum, otdTipoCodigo, RN;


GO


