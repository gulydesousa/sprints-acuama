/*
UPDATE X SET  ExcAyuda = 'Desglose del IBAN en contratos activos: <i>Cod.País | Control | Entidad | Oficina | Control | N.Cuenta</i>'
FROM dbo.ExcelConsultas AS X WHERE ExcCod='000/410'


INSERT INTO dbo.ExcelConsultas
VALUES ('000/410',	'Contratos IBAN', 'Contratos IBAN', 0, '[InformesExcel].[Contratos_IBAN]', '001', 'Desglose del IBAN en contratos activos: <i>Cod.País | Control | Entidad | Oficina | Control | N.Cuenta</i>');

INSERT INTO ExcelPerfil
VALUES('000/410', 'root', 3, NULL)

INSERT INTO ExcelPerfil
VALUES('000/410', 'jefeExp', 3, NULL)

INSERT INTO ExcelPerfil
VALUES('000/410', 'jefAdmon', 3, NULL)

INSERT INTO ExcelPerfil
VALUES('000/410', 'comerc', 3, NULL)

*/


/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI></LI></NodoXML>';

EXEC [InformesExcel].[Contratos_IBAN] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/

ALTER PROCEDURE [InformesExcel].[Contratos_IBAN]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS

	SET NOCOUNT ON;   


	--DataTable[1]:  Parametros
	DECLARE @xml AS XML = @p_params;
	
	DECLARE @params TABLE (fInforme DATETIME);

	INSERT INTO @params
	OUTPUT INSERTED.*	
	SELECT fInforme = GETDATE()
	FROM @xml.nodes('NodoXML/LI')AS M(Item);

	WITH CTR AS (
	SELECT ctrCod
	, ctrVersion
	, ctrFecAnu
	, ctrTitNom
	, ctrTitDocIden
	, ctrPagNom
	, ctrPagDocIden
	, ctrIban
	, ctrManRef
	, IBAN = CONCAT(REPLICATE('0',24-len(ISNULL(ctrIban, ''))), ISNULL(ctrIban, '')) 
	, RN = ROW_NUMBER() OVER (PARTITION BY ctrCod ORDER BY ctrVersion DESC) 
	FROM dbo.Contratos
	
	), MAN AS(
	SELECT M.manRef
	, M.manFecFirma
	, M.manEstadoActual
	, C.ctrcod
	, C.ctrVersion
	, RN = ROW_NUMBER() OVER (PARTITION BY ctrCod ORDER BY manFecUltMod DESC) 
	FROM CTR AS C
	INNER JOIN dbo.Mandatos AS M
	ON M.manRef = C.ctrManRef
	AND C.RN=1
	
	), REMPDTE AS(
	SELECT DISTINCT remCtrCod
	FROM dbo.remesasTrab AS R
	WHERE R.remversionCtrCCC = 'UV' AND remVersionCtrCCC<>'EP')  



	SELECT [Contrato] = C.ctrCod
	, [Versión] = C.ctrVersion
	, [F.Anulación] = C.ctrFecAnu
	, [Pagador ID] = ISNULL(C.ctrPagDocIden, C.ctrTitDocIden)
	, [Pagador] = ISNULL(C.ctrPagNom, C.ctrTitNom)
	, [IBAN] = C.ctrIban
	, [País] = SUBSTRING(C.IBAN, 0, 3) 
	, [Control IBAN] = SUBSTRING(C.IBAN, 3, 2) 
	, [Entidad] = SUBSTRING(C.IBAN, 5, 4)
	, [Oficina] = SUBSTRING(C.IBAN, 9, 4)
	, [Control] = SUBSTRING(C.IBAN, 13, 2)
	, [Nº Cuenta] = SUBSTRING(C.IBAN, 15, 10)
	, [Mandato Ref.] = M.manRef
	, [Mandato F.Firma] = M.manFecFirma
	, [Mandato Estado]  = CASE  M.manEstadoActual 
						  WHEN 99 THEN  'No-Definido'
						  WHEN 0 THEN  'Registrado'
						  WHEN 1 THEN  'Activo'
						  WHEN 2 THEN  'A-Confirmar'
						  WHEN 3 THEN  'Bloqueado'
						  WHEN 4 THEN  'Anulado'
						  WHEN 5 THEN  'Obsoleto'
						  WHEN 6 THEN  'Cerrado' 
						  ELSE CAST(M.manEstadoActual AS VARCHAR) END
	
	, [Remesa Pdte.] = CAST(IIF(R.remCtrCod IS NULL, 0, 1) AS BIT)
	FROM CTR AS C 
	LEFT JOIN MAN AS M
	ON M.ctrcod = C.ctrcod
	AND M.RN=1
	LEFT JOIN REMPDTE AS R
	ON R.remCtrCod = C.ctrCod
	WHERE C.RN=1;


GO


