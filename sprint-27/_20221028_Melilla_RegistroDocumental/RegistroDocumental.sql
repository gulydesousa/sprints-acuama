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
DECLARE @p_error_out INT;
DECLARE @p_errMsg_out   NVARCHAR(MAX);

SET @p_params= '<NodoXML><LI><FecDesde></FecDesde><FecHasta></FecHasta></LI></NodoXML>'

EXEC [InformesExcel].[RegistroDocumental] @p_params, @p_error_out OUTPUT, @p_errMsg_out OUTPUT;

*/

ALTER PROCEDURE [InformesExcel].[RegistroDocumental]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS
	SET NOCOUNT ON;
	BEGIN TRY

	--DataTable[1]:  Parametros
	DECLARE @xml AS XML = @p_params;
	DECLARE @params TABLE (FecDesde DATE NULL, fInforme DATETIME, FecHasta DATE NULL);

	INSERT INTO @params
	SELECT  FecDesde = CASE WHEN M.Item.value('FecDesde[1]', 'DATE') = '19000101' THEN NULL 
							ELSE M.Item.value('FecDesde[1]', 'DATE') END
			, fInforme     = GETDATE()
			, FecHasta = CASE WHEN M.Item.value('FecHasta[1]', 'DATE') = '19000101' THEN NULL 
							ELSE M.Item.value('FecHasta[1]', 'DATE') END
	FROM @xml.nodes('NodoXML/LI')AS M(Item);
	
	UPDATE @params SET FecHasta = DATEADD(DAY, 1, FecHasta)
	OUTPUT DELETED.*;

	--*******************************	
	SELECT 
	  [Nº]				= R.regEntNum
	, [Tipo]			= T.regEntTipDesc
	, [Fec.reg.]		= R.regEntFecReg
	, [Asunto]			= R.regEntAsunto
	, [Texto]			= R.regEntTexto
	, [Num.Ficheros]	= COUNT(E.regEntArcRegEntNum) OVER (PARTITION BY R.regEntNum, R.regEntRegEntTipCod)
	, [Fichero]			= E.regEntArcFicheroNombre 
	, [Fichero Desc.]	= E.regEntArcDes
	FROM dbo.registroEntradas AS R
	LEFT JOIN dbo.registroEntradasArchivos AS E
	ON  R.regEntNum = E.regEntArcRegEntNum
	AND R.regEntRegEntTipCod = E.regEntArcRegEntTipCod
	LEFT JOIN dbo.registroEntradasTipo AS T
	ON T.regEntTipCod = R.regEntRegEntTipCod
	INNER JOIN @params AS P
	ON  (P.FecDesde IS NULL OR R.regEntFecReg>=P.FecDesde) 
	AND (P.FecHasta IS NULL OR R.regEntFecReg<P.FecHasta) 
	ORDER BY R.regEntFecReg DESC;

	END TRY
	

	BEGIN CATCH	
		SELECT  @p_errId_out = ERROR_NUMBER()
			 ,  @p_errMsg_out= ERROR_MESSAGE();
	END CATCH

GO
