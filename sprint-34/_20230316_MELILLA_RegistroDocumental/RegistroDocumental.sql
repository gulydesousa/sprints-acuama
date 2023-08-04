
/*
INSERT INTO menu(menuid, menupadre, menutitulo_es, menuurl, menucss, menuorden, menuvisible, menuactivo)
VALUES(665, 9, 'Informes Excel', '~/Sistema/BX203_VisorInformesExcelPerfil.aspx?menu=9', '~/Sistema/Css/visorInformesExcelPerfil.css', 999, 1, 1)
*/

/*
INSERT INTO dbo.ExcelConsultas VALUES
('000/009', 'Registro Documental', 'Registro Documental', 1, '[InformesExcel].[RegistroDocumental]', '001', 
'Seleccion del registro documental sus archivos.'
, NULL, NULL, NULL, NULL);
--DELETE FROM ExcelPerfil WHERE ExPCod='000/009'
INSERT INTO ExcelPerfil VALUES ('000/009', 'admon', 9, NULL);
INSERT INTO ExcelPerfil VALUES ('000/009', 'root', 9, NULL);
INSERT INTO ExcelPerfil VALUES ('000/009', 'jefeExp', 9, NULL);
INSERT INTO ExcelPerfil VALUES ('000/009', 'direcc', 9, NULL);
*/

/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(MAX);
SET @p_params= '<NodoXML><LI><FecDesde>2022-10-01</FecDesde><FecHasta>2022-11-15</FecHasta></LI></NodoXML>'
EXEC InformesExcel.RegistroDocumental @p_params, @p_errId_out, @p_errMsg_out
*/

CREATE PROCEDURE [InformesExcel].[RegistroDocumental]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS SET NOCOUNT ON;
BEGIN TRY
	DECLARE @explotacion varchar(100) = NULL
	SELECT @explotacion = CAST(ISNULL(UPPER(pgsvalor),'') AS VARCHAR) FROM parametros WHERE pgsclave = 'EXPLOTACION'
	--DataTable[1]:  Parametros
	DECLARE @xml AS XML = @p_params;
	DECLARE @params TABLE (FecDesde DATE NULL, FecHasta DATE NULL, fInforme DATETIME);
	INSERT INTO @params
	SELECT  FecDesde = CASE WHEN M.Item.value('FecDesde[1]', 'DATE') = '19000101' THEN NULL ELSE M.Item.value('FecDesde[1]', 'DATE') END
			, FecHasta = CASE WHEN M.Item.value('FecHasta[1]', 'DATE') = '19000101' THEN NULL ELSE M.Item.value('FecHasta[1]', 'DATE') END
			, fInforme = GETDATE()
	FROM @xml.nodes('NodoXML/LI')AS M(Item);
	UPDATE @params SET FecHasta = DATEADD(DAY, 1, FecHasta)
	OUTPUT DELETED.*;
	--*******************************	
	SELECT
	  [Nº]					= R.regEntNum
	, [Tipo]				= MAX(T.regEntTipDesc)
	, [Fec.reg.]			= MAX(R.regEntFecReg)
	, [Asunto]				= MAX(R.regEntAsunto)
	, [Texto]				= MAX(CAST(R.regEntTexto AS VARCHAR(MAX)))
	, [Num.Ficheros]		= SUM(IIF(E.regEntArcFichero IS NULL, 0, 1)) 
	, [Fichero]				= STRING_AGG(E.regEntArcFicheroNombre, ', ') 
	--, [Fichero Desc.]		= STRING_AGG(E.regEntArcDes, ', ') 
	, [Usuario]				= MAX(R.regEntUsuCodReg)
	, [Num.Ficheros_Nulos]	= SUM(IIF(regEntArcRegEntNum IS NOT NULL AND E.regEntArcFichero IS NULL, 1, 0))
	FROM dbo.registroEntradas AS R
	LEFT JOIN dbo.registroEntradasArchivos AS E
	ON  R.regEntNum = E.regEntArcRegEntNum
	AND R.regEntRegEntTipCod = E.regEntArcRegEntTipCod
	LEFT JOIN dbo.registroEntradasTipo AS T
	ON T.regEntTipCod = R.regEntRegEntTipCod
	INNER JOIN @params AS P
	ON  (P.FecDesde IS NULL OR R.regEntFecReg>=P.FecDesde) 
	AND (P.FecHasta IS NULL OR R.regEntFecReg<P.FecHasta) 
	GROUP BY R.regEntNum, R.regEntRegEntTipCod
	ORDER BY [Fec.reg.] DESC;
END TRY
BEGIN CATCH	
	SELECT @p_errId_out = ERROR_NUMBER(), @p_errMsg_out= ERROR_MESSAGE();
END CATCH
GO


