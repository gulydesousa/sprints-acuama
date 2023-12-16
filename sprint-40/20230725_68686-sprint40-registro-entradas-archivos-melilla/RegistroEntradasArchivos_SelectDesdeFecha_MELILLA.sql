/*

DELETE ExcelPerfil WHERE ExPCod='100/003'
DELETE FROM dbo.ExcelConsultas WHERE ExcCod='100/003'

INSERT INTO dbo.ExcelConsultas VALUES ('100/003', 'Registros para Traspasar', 'Registros para Traspasar por fechas', 1, '[InformesExcel].[RegistroEntradasArchivos_SelectDesdeFecha_MELILLA]', '000', '<b>MELILLA: </b>Registros para Traspasar por fechas<br>', NULL, NULL, NULL, NULL);
INSERT INTO ExcelPerfil VALUES('100/003', 'root', 9, NULL)
INSERT INTO ExcelPerfil VALUES('100/003', 'direcc', 9, NULL)

*/


/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);
SET @p_params= '<NodoXML><LI><FecDesde>20100101</FecDesde><FecHasta>20220701</FecHasta></LI></NodoXML>'

EXEC [InformesExcel].[RegistroEntradasArchivos_SelectDesdeFecha_MELILLA] @p_params, @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/

ALTER PROCEDURE [InformesExcel].[RegistroEntradasArchivos_SelectDesdeFecha_MELILLA]
	@p_params NVARCHAR(MAX),
    @p_errId_out INT OUTPUT,
    @p_errMsg_out NVARCHAR(2048) OUTPUT
AS

    --PARAMETROS
    DECLARE @xml AS XML = @p_params
	DECLARE @HOY DATE = (SELECT dbo.GETACUAMADATE());
    DECLARE @params TABLE (FecDesde DATE NULL, fInforme DATETIME, FecHasta DATE NULL);
    
	INSERT INTO @params
    OUTPUT INSERTED.*
	SELECT fechaD = CASE WHEN M.Item.value('FecDesde[1]', 'DATE') = '19000101' THEN DATEADD(WEEK, -1, @HOY) ELSE M.Item.value('FecDesde[1]', 'DATE') END
         , fInforme = GETDATE() 
		 , fechaH = CASE WHEN M.Item.value('FecHasta[1]', 'DATE') = '19000101' THEN @HOY ELSE M.Item.value('FecHasta[1]', 'DATE') END
    FROM @xml.nodes('NodoXML/LI') AS M(Item);
    

    DECLARE @fechaRegDesde DATE, @fechaRegHasta DATE;
    SELECT @fechaRegDesde = P.FecDesde, @fechaRegHasta = DATEADD(DAY, 1, P.FecHasta) FROM @params AS P;
    
	--********************
	--DataTable[2]:  Grupos
	SELECT * 
	FROM (VALUES ('Archivos por fecha')
			   , ('Registro Documental')) 
	AS DataTables(Grupo);

	BEGIN TRY
		--**********************************
		--Registros de entrada con archivos
		--**********************************
		SELECT R.*
		, Año = YEAR(A.regEntArcFecReg)
		--RN=1: Para quedarnos con un expediente
		, RN =ROW_NUMBER() OVER (PARTITION BY R.regEntNum, R.regEntRegEntTipCod ORDER BY A.regEntArcId)
		--CN=1: Ficheros por expediente
		, CN =COUNT( A.regEntArcId) OVER (PARTITION BY R.regEntNum, R.regEntRegEntTipCod)
		INTO #REGS
		FROM dbo.registroEntradas AS R

		INNER JOIN dbo.registroEntradasArchivos AS A
		ON  R.regEntNum = A.regEntArcRegEntNum 
		AND R.regEntRegEntTipCod = A.regEntArcRegEntTipCod
		AND A.regEntArcFichero IS NOT NULL 

		AND A.regEntArcFecReg >= @fechaRegDesde 
		AND A.regEntArcFecReg < @fechaRegHasta
		AND R.regEntRegEntTipCod NOT IN (40, 41);
		--SE EXCLUYEN:
		--40	Entrada Grupo SyV
		--41	Salida Grupo SyV
	
		--**********************************
		--RESULT #1: Archivos por tipo y año
		--**********************************
		WITH R AS(
		SELECT R.Año, R.regEntRegEntTipCod
		, Archivos = COUNT(R.regEntNum) 
		, Registros = SUM(IIF(RN=1, 1, 0)) 
		FROM #REGS AS R
		GROUP BY R.Año, R.regEntRegEntTipCod)
		
		SELECT R.Año
		, [Tipo Documento] = T.regEntTipDesc
		, [Nº Archivos]= R.Archivos
		, [Nº Registros] = R.Registros
		FROM R
		INNER JOIN dbo.registroEntradasTipo AS T
		ON T.regEntTipCod = R.regEntRegEntTipCod
		ORDER BY T.regEntTipDesc, R.Año;


		--**********************************
		--RESULT #2: Registros con archivos
		--**********************************
		SELECT [Reg.Num.] = R.regEntNum
		, [F.Registro] = R.regEntFecReg
		, [Reg.Tipo] = R.regEntRegEntTipCod
		, [Usuario] = R.regEntUsuCodReg
		, [Nº Archivos] = R.CN
		, [Tipo] = T.regEntTipDesc
		, [Asunto] = R.regEntAsunto
		, [Cli.Cod] = C.clicod
		, [Cliente] = C.clinom
		, [Contrato] = R.regEntCtrCod
		, [Dirección] = I.inmDireccion
		, [Texto] = R.regEntTexto
		, [OT Num.] = R.regEntOtNum
		, [Dpto.] =  D.depdes
		, [Exp.Corte] = E.excNumExp
		, [Rec. Cod.] = RC.rclCod
		, [Rec.Motivo]=RC.rclMotivo
		
		FROM #REGS AS R 
		INNER JOIN dbo.registroEntradasTipo AS T
		ON  T.regEntTipCod = R.regEntRegEntTipCod
		AND R.RN=1
		LEFT JOIN dbo.reclamaciones AS RC
		ON RC.rclCod = R.regEntRclCod
		LEFT JOIN dbo.clientes AS C
		ON C.clicod = R.regEntCliCod
		LEFT JOIN dbo.contratos AS CC
		ON  CC.ctrcod = R.regEntCtrCod
		AND CC.ctrversion = R.regEntCtrVer
		LEFT JOIN dbo.inmuebles AS I
		ON I.inmcod = CC.ctrinmcod
		LEFT JOIN dbo.departamentos AS D
		ON D.depcod = R.regEntDepCod
		LEFT JOIN dbo.expedientesCorte AS E
		ON R.regEntExcNumExp = E.excNumExp
		ORDER BY T.regEntTipDesc, R.regEntNum; 
		
		
	
		/*
		SELECT top 500  year([regEntArcFecReg] ) as [Año]
			, regEntTipDesc as Tipo_Documento
			,count(*) as Archivos
    
		FROM [registroEntradasArchivos]
			inner join registroEntradasTipo on [regEntArcRegEntTipCod] = regEntTipCod
			inner join registroEntradas on regEntNum = regEntArcRegEntNum and regEntRegEntTipCod = regEntArcRegEntTipCod
		WHERE
			CAST(regEntArcFecReg AS date) >= @fechaRegDesde and CAST(regEntArcFecReg AS date) <= @fechaRegHasta
			AND regEntTipCod not in ( 40, 41)
			AND regEntArcFichero is not null
			group by year([regEntArcFecReg] )
			, regEntTipDesc
		*/


	END TRY
	BEGIN CATCH
		SELECT  @p_errId_out = ERROR_NUMBER(), @p_errMsg_out= ERROR_MESSAGE();
	END CATCH

	DROP TABLE IF EXISTS #REGS;
GO


