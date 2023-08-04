ALTER PROCEDURE [dbo].[Cobros_InsertSOA]
(       @cobCodExplo varchar(20)
		,@cobScd  smallint
		,@cobPpag smallint
		,@cobUsr varchar(10)
		,@cobFec datetime
		,@cobCtr int
		,@cobNom varchar(40)
		,@cobDocIden varchar(14)
		,@cobImporte money
		,@cobMpc smallint
		,@cobMpcDato1 varchar(40)
		,@cobMpcDato2 varchar(40)
		,@cobMpcDato3 varchar(40)
		,@cobMpcDato4 varchar(40)
		,@cobMpcDato5 varchar(40)
		,@cobMpcDato6 varchar(40)
		,@cobConcepto varchar(50)
		,@cobDevCod varchar(4) = NULL
		,@cobFecContabilizacion datetime = NULL
		,@cobUsrContabilizacion varchar(10) = NULL
		,@cobComCodigo SMALLINT = NULL
		,@cobNum int output
		,@cobOrigen varchar(20) = NULL
		,@cobFecReg datetime = NULL
)
AS
SET NOCOUNT OFF;

	DECLARE @versionNueva VARCHAR(25) = '2.0.1';
	DECLARE @esVersionNueva BIT = 0;
	DECLARE @QUERY NVARCHAR(500);

	--***********************************************************
	--Nombre de la BBDD a utilizar
	DECLARE @BBDD AS VARCHAR(25) = dbo.fDataBaseNameSOA(@cobCodExplo);
	
	--***********************************************************
	--Obtenemos dinámicamente el valor del parametro FAC_APERTURA
	SELECT @QUERY = FORMATMESSAGE('SELECT @pVersionNueva = 1  FROM %s.dbo.parametros AS P WHERE P.pgsclave=''FAC_APERTURA'' AND P.pgsValor>=''%s''', @BBDD, @versionNueva);
	EXEC sp_executesql @QUERY, N'@pVersionNueva BIT OUTPUT', @pVersionNueva=@esVersionNueva OUTPUT;
	--SELECT [@esVersionNueva] = @esVersionNueva;

	--***********************************************************
	--Obtenemos dinámicamente el valor del numero del nuevo cobro que se va a insertar
	IF(@esVersionNueva = 1)
	BEGIN	
		SELECT @QUERY = FORMATMESSAGE('EXEC @pCobNum = %s.dbo.Cobros_IncrementarNumerador @cbnScd=%i, @cbnPpag=%i', @BBDD, @cobScd, @cobPpag);
		EXEC sp_executesql @QUERY, N'@pCobNum INT OUTPUT', @cobNum OUTPUT;
	END
	ELSE
	BEGIN
		SELECT @QUERY = FORMATMESSAGE('SELECT @pCobNum = ISNULL(MAX(cobNum),0) + 1 FROM %s.dbo.Cobros WHERE cobScd=%i AND cobPpag=%i', @BBDD, @cobScd, @cobPpag);
		EXEC sp_executesql @QUERY, N'@pCobNum INT OUTPUT', @pCobNum=@CobNum OUTPUT;
	END
	--SELECT [@cobNum] = @cobNum;

	--***********************************************************
	--Insertamos el cobro donde corresponde
	IF (@cobCodExplo ='001')
	BEGIN			
		INSERT INTO ACUAMA_ALMADEN.dbo.Cobros( cobScd,cobPpag,cobNum,cobFecReg,cobUsr,cobFec,cobCtr,cobNom,cobDocIden,cobImporte,cobMpc,cobMpcDato1,cobMpcDato2,cobMpcDato3,cobMpcDato4,cobMpcDato5,cobMpcDato6,cobConcepto,cobDevCod,cobFecContabilizacion,cobUsrContabilizacion,cobComCodigo, cobOrigen)
		VALUES( @cobScd,@cobPpag,@cobNum,ISNULL(@cobFecReg,dbo.GetAcuamaDate()),@cobUsr,@cobFec,@cobCtr,@cobNom,@cobDocIden,@cobImporte,@cobMpc,@cobMpcDato1,@cobMpcDato2,@cobMpcDato3,@cobMpcDato4,@cobMpcDato5,@cobMpcDato6,@cobConcepto,@cobDevCod,@cobFecContabilizacion,@cobUsrContabilizacion, @cobComCodigo, @cobOrigen)
	END

	IF (@cobCodExplo ='002') 
	BEGIN	
		INSERT INTO ACUAMA_ALAMILLO.dbo.Cobros( cobScd,cobPpag,cobNum,cobFecReg,cobUsr,cobFec,cobCtr,cobNom,cobDocIden,cobImporte,cobMpc,cobMpcDato1,cobMpcDato2,cobMpcDato3,cobMpcDato4,cobMpcDato5,cobMpcDato6,cobConcepto,cobDevCod,cobFecContabilizacion,cobUsrContabilizacion,cobComCodigo, cobOrigen)
		VALUES( @cobScd,@cobPpag,@cobNum,ISNULL(@cobFecReg,dbo.GetAcuamaDate()),@cobUsr,@cobFec,@cobCtr,@cobNom,@cobDocIden,@cobImporte,@cobMpc,@cobMpcDato1,@cobMpcDato2,@cobMpcDato3,@cobMpcDato4,@cobMpcDato5,@cobMpcDato6,@cobConcepto,@cobDevCod,@cobFecContabilizacion,@cobUsrContabilizacion, @cobComCodigo, @cobOrigen)
	END

	IF (@cobCodExplo ='003') 
	BEGIN	
		INSERT INTO ACUAMA_SVB.dbo.Cobros( cobScd,cobPpag,cobNum,cobFecReg,cobUsr,cobFec,cobCtr,cobNom,cobDocIden,cobImporte,cobMpc,cobMpcDato1,cobMpcDato2,cobMpcDato3,cobMpcDato4,cobMpcDato5,cobMpcDato6,cobConcepto,cobDevCod,cobFecContabilizacion,cobUsrContabilizacion,cobComCodigo, cobOrigen)
		VALUES( @cobScd,@cobPpag,@cobNum,ISNULL(@cobFecReg,dbo.GetAcuamaDate()),@cobUsr,@cobFec,@cobCtr,@cobNom,@cobDocIden,@cobImporte,@cobMpc,@cobMpcDato1,@cobMpcDato2,@cobMpcDato3,@cobMpcDato4,@cobMpcDato5,@cobMpcDato6,@cobConcepto,@cobDevCod,@cobFecContabilizacion,@cobUsrContabilizacion, @cobComCodigo, @cobOrigen)
	END

	IF (@cobCodExplo ='004') 
	BEGIN			
		INSERT INTO ACUAMA_GUADALAJARA.dbo.Cobros( cobScd,cobPpag,cobNum,cobFecReg,cobUsr,cobFec,cobCtr,cobNom,cobDocIden,cobImporte,cobMpc,cobMpcDato1,cobMpcDato2,cobMpcDato3,cobMpcDato4,cobMpcDato5,cobMpcDato6,cobConcepto,cobDevCod,cobFecContabilizacion,cobUsrContabilizacion,cobComCodigo, cobOrigen)
		VALUES( @cobScd,@cobPpag,@cobNum,ISNULL(@cobFecReg,dbo.GetAcuamaDate()),@cobUsr,@cobFec,@cobCtr,@cobNom,@cobDocIden,@cobImporte,@cobMpc,@cobMpcDato1,@cobMpcDato2,@cobMpcDato3,@cobMpcDato4,@cobMpcDato5,@cobMpcDato6,@cobConcepto,@cobDevCod,@cobFecContabilizacion,@cobUsrContabilizacion, @cobComCodigo, @cobOrigen)
	END

	IF (@cobCodExplo ='007') 
	BEGIN		
		INSERT INTO ACUAMA_VALDALIGA.dbo.Cobros( cobScd,cobPpag,cobNum,cobFecReg,cobUsr,cobFec,cobCtr,cobNom,cobDocIden,cobImporte,cobMpc,cobMpcDato1,cobMpcDato2,cobMpcDato3,cobMpcDato4,cobMpcDato5,cobMpcDato6,cobConcepto,cobDevCod,cobFecContabilizacion,cobUsrContabilizacion,cobComCodigo, cobOrigen)
		VALUES( @cobScd,@cobPpag,@cobNum,ISNULL(@cobFecReg,dbo.GetAcuamaDate()),@cobUsr,@cobFec,@cobCtr,@cobNom,@cobDocIden,@cobImporte,@cobMpc,@cobMpcDato1,@cobMpcDato2,@cobMpcDato3,@cobMpcDato4,@cobMpcDato5,@cobMpcDato6,@cobConcepto,@cobDevCod,@cobFecContabilizacion,@cobUsrContabilizacion, @cobComCodigo, @cobOrigen)
	END

	IF (@cobCodExplo ='011') 
	BEGIN	
		INSERT INTO ACUAMA_BIAR.dbo.Cobros( cobScd,cobPpag,cobNum,cobFecReg,cobUsr,cobFec,cobCtr,cobNom,cobDocIden,cobImporte,cobMpc,cobMpcDato1,cobMpcDato2,cobMpcDato3,cobMpcDato4,cobMpcDato5,cobMpcDato6,cobConcepto,cobDevCod,cobFecContabilizacion,cobUsrContabilizacion,cobComCodigo, cobOrigen)
		VALUES( @cobScd,@cobPpag,@cobNum,ISNULL(@cobFecReg,dbo.GetAcuamaDate()),@cobUsr,@cobFec,@cobCtr,@cobNom,@cobDocIden,@cobImporte,@cobMpc,@cobMpcDato1,@cobMpcDato2,@cobMpcDato3,@cobMpcDato4,@cobMpcDato5,@cobMpcDato6,@cobConcepto,@cobDevCod,@cobFecContabilizacion,@cobUsrContabilizacion, @cobComCodigo, @cobOrigen)
	END

	IF (@cobCodExplo ='015') 
	BEGIN
		INSERT INTO ACUAMA_RIBADESELLA.dbo.Cobros( cobScd,cobPpag,cobNum,cobFecReg,cobUsr,cobFec,cobCtr,cobNom,cobDocIden,cobImporte,cobMpc,cobMpcDato1,cobMpcDato2,cobMpcDato3,cobMpcDato4,cobMpcDato5,cobMpcDato6,cobConcepto,cobDevCod,cobFecContabilizacion,cobUsrContabilizacion,cobComCodigo, cobOrigen)
		VALUES( @cobScd,@cobPpag,@cobNum,ISNULL(@cobFecReg,dbo.GetAcuamaDate()),@cobUsr,@cobFec,@cobCtr,@cobNom,@cobDocIden,@cobImporte,@cobMpc,@cobMpcDato1,@cobMpcDato2,@cobMpcDato3,@cobMpcDato4,@cobMpcDato5,@cobMpcDato6,@cobConcepto,@cobDevCod,@cobFecContabilizacion,@cobUsrContabilizacion, @cobComCodigo, @cobOrigen)
	END

RETURN @@ERROR


GO


